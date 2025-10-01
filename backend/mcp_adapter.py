"""Lightweight MCP server adapter used when crewai_tools lacks MCPServerAdapter."""
from __future__ import annotations

from importlib import import_module
from typing import Any, Callable, Type

from pydantic import BaseModel

from crewai.tools.base_tool import BaseTool


class MCPFunctionTool(BaseTool):
    """Wrap an MCP tool function behind CrewAI's BaseTool interface."""

    _payload_model: Type[BaseModel]
    _func: Callable[[BaseModel], Any]

    def __init__(
        self,
        *,
        name: str,
        description: str,
        payload_model: Type[BaseModel],
        func: Callable[[BaseModel], Any],
        result_as_answer: bool = False,
    ) -> None:
        super().__init__(
            name=name,
            description=description,
            args_schema=payload_model,
            result_as_answer=result_as_answer,
        )
        self._payload_model = payload_model
        self._func = func

    def _run(self, **data: Any) -> Any:  # type: ignore[override]
        payload = self._payload_model(**data)
        return self._func(payload)


class MCPServerAdapter:
    """Minimal adapter that exposes MCP tools as CrewAI tools without spawning a subprocess."""

    def __init__(self, server_params: Any) -> None:  # noqa: D401 - keeping signature for compatibility
        module = import_module("backend.lighthouse_mcp.lighthouse_mcp_server")

        self.tools = {
            "pg_safe_query": MCPFunctionTool(
                name="pg_safe_query",
                description="Run whitelisted read-only queries via MCP.",
                payload_model=module.SafeQuery,
                func=module.pg_safe_query,
            ),
            "rag_search": MCPFunctionTool(
                name="rag_search",
                description="Search the curriculum/document embeddings store via MCP.",
                payload_model=module.RagSearch,
                func=module.rag_search,
            ),
            "report_compose": MCPFunctionTool(
                name="report_compose",
                description="Compose term reports for a student via MCP.",
                payload_model=module.ReportCompose,
                func=module.report_compose,
            ),
        }

        self._module = module
        self._server_params = server_params

    def shutdown(self) -> None:
        """Placeholder for interface compatibility."""
        return None
