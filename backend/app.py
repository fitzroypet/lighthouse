# app.py
# Minimal FastAPI backend that fronts the CrewAI + MCP toolchain.
# Provides:
#  - POST /chat          -> returns JSON answer
#  - POST /chat/stream   -> Server-Sent Events (SSE) streaming of the answer
#
# Notes:
# - This sample assumes your MCP server file is at lighthouse_mcp/lighthouse_mcp_server.py.
# - For role-based filtering with Postgres RLS, make sure your MCP server reads an `_auth`
#   dict from tool payloads and calls `SET LOCAL app.user_id/role/school_id` before queries.
# - In production, consider running the MCP server as a long-lived process and connecting over
#   SSE/HTTP transport instead of stdio.

import os, sys, asyncio, jwt
import sysconfig
from pathlib import Path
from fastapi import FastAPI, Depends, Header, HTTPException
from fastapi.responses import JSONResponse, StreamingResponse
from crewai import Agent, Task, Crew
try:  # Prefer built-in adapter when available
    from crewai_tools import MCPServerAdapter  # type: ignore
except ImportError:  # pragma: no cover - fallback for versions without MCP adapter
    from backend.mcp_adapter import MCPServerAdapter

try:
    from mcp import StdioServerParameters
except ImportError:  # Local backend/mcp package shadowed the dependency
    sys.modules.pop("mcp", None)
    purelib = sysconfig.get_paths()["purelib"]
    if purelib not in sys.path:
        sys.path.insert(0, purelib)
    from mcp import StdioServerParameters  # type: ignore

JWT_SECRET = os.environ.get("JWT_SECRET", "dev-secret-change-me")

app = FastAPI(title="LightHouse API")

BACKEND_DIR = Path(__file__).resolve().parent
MCP_SCRIPT = BACKEND_DIR / "lighthouse_mcp" / "lighthouse_mcp_server.py"

# Spawn MCP server (stdio) and keep it alive for performance
server_params = StdioServerParameters(
    command=sys.executable,
    args=[str(MCP_SCRIPT)],
    cwd=str(BACKEND_DIR),
    env={**os.environ},
)
adapter = MCPServerAdapter(server_params)

def auth(authorization: str = Header(...)):
    try:
        token = authorization.split(" ")[1]
        payload = jwt.decode(token, JWT_SECRET, algorithms=["HS256"])
        return {
            "user_id": payload["uid"],
            "role": payload["role"],
            "school_id": payload["sid"],
        }
    except Exception:
        raise HTTPException(401, "Invalid token")

def build_agent(persona: str, tools):
    if persona == "parent":
        role = "Parent Coach"
        goal = "Summarize a child's progress in plain English and suggest at-home support."
        backstory = (
            "You are a friendly coach who translates school data for parents and offers"
            " practical tips for learning at home."
        )
    elif persona == "admin":
        role = "School Insights"
        goal = "Provide school-level analytics and risks from available data."
        backstory = (
            "You monitor trends across the school, highlighting risks and opportunities"
            " using academic and behavioural signals."
        )
    else:
        role = "Teacher Advisor"
        goal = "Explain a student's performance and suggest next steps using school data and curriculum."
        backstory = (
            "You support classroom teachers by analysing curriculum coverage and results"
            " to recommend actionable next steps."
        )
    return Agent(
        role=role,
        goal=goal,
        backstory=backstory,
        tools=[tools["pg_safe_query"], tools["rag_search"], tools["report_compose"]],
        allow_delegation=False,
        verbose=False,
    )

@app.post("/chat")
def chat(body: dict, ctx=Depends(auth)):
    persona = body.get("persona", "teacher")
    message = body["message"]
    chat_id = body.get("chat_id", "default")

    tools = adapter.tools
    agent = build_agent(persona, tools)

    # IMPORTANT: We instruct the agent to include `_auth` in every tool call.
    # Your MCP tools should pop `_auth` and set Postgres GUCs via SET LOCAL.
    instructions = (
        "When calling any tool, always include a params key `_auth` with this JSON:\n"
        f"{ctx}\n"
        "Use pg_safe_query for DB reads and rag_search for curriculum/help. Be concise."
    )
    task = Task(
        description=f"{instructions}\n\nUser says: {message}",
        expected_output="A concise, student-friendly answer that references relevant school data.",
        agent=agent,
    )
    result = Crew(agents=[agent], tasks=[task]).kickoff()
    return JSONResponse({"answer": str(result)})

@app.post("/chat/stream")
async def chat_stream(body: dict, ctx=Depends(auth)):
    persona = body.get("persona", "teacher")
    message = body["message"]
    chat_id = body.get("chat_id", "default")

    tools = adapter.tools
    agent = build_agent(persona, tools)

    instructions = (
        "When calling any tool, always include a params key `_auth` with this JSON:\n"
        f"{ctx}\n"
        "Use pg_safe_query for DB reads and rag_search for curriculum/help. Be concise."
    )
    task = Task(
        description=f"{instructions}\n\nUser says: {message}",
        expected_output="A concise, student-friendly answer that references relevant school data.",
        agent=agent,
    )
    result = Crew(agents=[agent], tasks=[task]).kickoff()
    text = str(result)

    async def event_gen():
        # Naive chunking into SSE events. Replace with token streaming when your LLM supports it.
        for i in range(0, len(text), 256):
            chunk = text[i:i+256]
            yield f"data: {chunk}\n\n"
            await asyncio.sleep(0)
        yield "event: done\ndata: [DONE]\n\n"

    return StreamingResponse(event_gen(), media_type="text/event-stream")
