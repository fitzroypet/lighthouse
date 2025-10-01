from __future__ import annotations

import asyncio
import importlib
import sys
import types
from pathlib import Path
from typing import Any

import jwt
import pytest

# Ensure repo root on sys.path so we can import app.py
ROOT = Path(__file__).resolve().parents[1]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))


class DummyAdapter:
    """Stub for MCPServerAdapter that exposes the required tool names."""

    def __init__(self) -> None:
        self.tools = {
            "pg_safe_query": object(),
            "rag_search": object(),
            "report_compose": object(),
        }


class DummyAgent:
    def __init__(self, *args: Any, **kwargs: Any) -> None:
        self.args = args
        self.kwargs = kwargs


class DummyTask:
    created: list[DummyTask] = []

    def __init__(self, description: str, agent: Any) -> None:
        self.description = description
        self.agent = agent
        DummyTask.created.append(self)


class DummyCrew:
    last_run: dict[str, Any] | None = None

    def __init__(self, agents: list[Any], tasks: list[Any]) -> None:
        self.agents = agents
        self.tasks = tasks

    def kickoff(self) -> str:
        DummyCrew.last_run = {"agents": self.agents, "tasks": self.tasks}
        return "stubbed response"


# Build stub modules so importing app.py does not require real dependencies.
crewai_tools_stub = types.ModuleType("crewai_tools")
crewai_tools_stub.MCPServerAdapter = lambda *args, **kwargs: DummyAdapter()
sys.modules["crewai_tools"] = crewai_tools_stub

crewai_stub = types.ModuleType("crewai")
crewai_stub.Agent = DummyAgent
crewai_stub.Task = DummyTask
crewai_stub.Crew = DummyCrew
sys.modules["crewai"] = crewai_stub

fastapi_stub = types.ModuleType("fastapi")


class HTTPException(Exception):
    def __init__(self, status_code: int, detail: str) -> None:
        super().__init__(detail)
        self.status_code = status_code
        self.detail = detail


def Depends(dependency: Any) -> Any:
    return dependency


def Header(default: Any = None) -> Any:
    return default


class FastAPI:
    def __init__(self, *args: Any, **kwargs: Any) -> None:
        self.routes: dict[str, Any] = {}

    def post(self, path: str):
        def decorator(handler):
            self.routes[path] = handler
            return handler

        return decorator


fastapi_stub.FastAPI = FastAPI
fastapi_stub.Depends = Depends
fastapi_stub.Header = Header
fastapi_stub.HTTPException = HTTPException

responses_stub = types.ModuleType("fastapi.responses")


class JSONResponse(dict):
    def __init__(self, content: dict[str, Any], status_code: int = 200) -> None:
        super().__init__(content)
        self.content = content
        self.status_code = status_code


class StreamingResponse:
    def __init__(self, iterator: Any, media_type: str | None = None) -> None:
        self.iterator = iterator
        self.media_type = media_type


responses_stub.JSONResponse = JSONResponse
responses_stub.StreamingResponse = StreamingResponse
fastapi_stub.responses = responses_stub

sys.modules["fastapi"] = fastapi_stub
sys.modules["fastapi.responses"] = responses_stub

# Import the application module with dependencies patched out.
sys.modules.pop("app", None)
app = importlib.import_module("app")


def _make_token(app_module) -> str:
    return jwt.encode(
        {"uid": 1, "role": "admin", "sid": 1},
        app_module.JWT_SECRET,
        algorithm="HS256",
    )


def test_auth_rejects_invalid_token() -> None:
    with pytest.raises(app.HTTPException) as exc:
        app.auth("Bearer invalid")
    assert exc.value.status_code == 401


def test_chat_returns_stubbed_answer() -> None:
    DummyTask.created.clear()

    token = _make_token(app)
    ctx = app.auth(f"Bearer {token}")
    response = app.chat(
        {"message": "Need help", "persona": "teacher"},
        ctx=ctx,
    )

    assert isinstance(response, app.JSONResponse)
    assert response.content == {"answer": "stubbed response"}
    assert DummyTask.created, "Task should have been instantiated"

    description = DummyTask.created[-1].description
    assert '_auth' in description
    assert "'user_id': 1" in description
    assert 'Need help' in description


def test_chat_stream_emits_chunks() -> None:
    DummyTask.created.clear()

    token = _make_token(app)

    async def invoke_stream():
        ctx = app.auth(f"Bearer {token}")
        response = await app.chat_stream(
            {"message": "Need help", "persona": "parent"},
            ctx=ctx,
        )
        chunks: list[str] = []
        async for chunk in response.iterator:
            chunks.append(chunk)
        return response, chunks

    response, chunks = asyncio.run(invoke_stream())

    assert isinstance(response, app.StreamingResponse)
    assert response.media_type == "text/event-stream"
    assert chunks[0].startswith("data: stubbed response")
    assert chunks[-1] == "event: done\ndata: [DONE]\n\n"

    description = DummyTask.created[-1].description
    assert '_auth' in description
    assert 'Need help' in description
