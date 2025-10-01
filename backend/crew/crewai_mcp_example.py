# crew/crewai_mcp_example.py
import os
import sys
from pathlib import Path
from crewai import Agent, Task, Crew
from crewai_tools import MCPServerAdapter
from mcp import StdioServerParameters

# Ensure env has DATABASE_URL_RO
assert os.environ.get("DATABASE_URL_RO") or os.environ.get("DATABASE_URL"), "Set DATABASE_URL_RO"

BACKEND_DIR = Path(__file__).resolve().parents[1]
MCP_SCRIPT = BACKEND_DIR / "lighthouse_mcp" / "lighthouse_mcp_server.py"

server_params = StdioServerParameters(
    command=sys.executable,
    args=[str(MCP_SCRIPT)],
    cwd=str(BACKEND_DIR),
    env={**os.environ},
)

with MCPServerAdapter(server_params) as tools:
    teacher = Agent(
        role="Teacher Advisor",
        goal="Explain a student's performance and suggest next steps using school data and curriculum.",
        backstory=(
            "Experienced middle-school educator who reviews grades, attendance, and curriculum"
            " coverage before advising classroom interventions."
        ),
        tools=[tools["pg_safe_query"], tools["rag_search"], tools["report_compose"]],
        allow_delegation=False,
        verbose=True,
    )

    parent = Agent(
        role="Parent Coach",
        goal="Summarize a child's progress in plain English and suggest at-home support.",
        backstory=(
            "Friendly home-learning coach who translates school data into plain-language"
            " updates and practical at-home tips for caregivers."
        ),
        tools=[tools["pg_safe_query"], tools["rag_search"], tools["report_compose"]],
        allow_delegation=False,
        verbose=True,
    )

    orchestrator = Agent(
        role="Chat Orchestrator",
        goal="Route user requests to the right toolset and provide clear answers.",
        backstory=(
            "AI dispatcher that coordinates specialist agents, selects the right tool for"
            " each request, and keeps responses coherent."
        ),
        tools=list(tools),  # ToolCollection is directly iterable over tool handles
        allow_delegation=True,
        verbose=True,
    )

    # Example teacher-centric task
    instructions = ("When calling any tool, include params key `_auth` with this JSON: {\"user_id\":1,\"role\":\"admin\",\"school_id\":1}.")

    t = Task(
        description=instructions + "\nWhat areas is student 1 struggling in based on the most recent results? Use data + curriculum gaps.",
        expected_output=(
            "A concise narrative that explains observed performance issues, cites relevant"
            " data points, and recommends next instructional steps."
        ),
        agent=teacher
    )

    Crew(agents=[orchestrator, teacher, parent], tasks=[t]).kickoff()
