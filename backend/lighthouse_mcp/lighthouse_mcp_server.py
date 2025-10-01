# lighthouse_mcp/lighthouse_mcp_server.py
import logging
import os
from functools import lru_cache
from typing import Literal, List, Dict, Any, Optional

import psycopg
from pydantic import BaseModel, Field
try:  # pydantic v2
    from pydantic import ConfigDict
except ImportError:  # pragma: no cover - pydantic v1 fallback
    ConfigDict = None  # type: ignore
from mcp.server.fastmcp import FastMCP

mcp = FastMCP("LightHouse")

DB_RO_URL = os.environ.get("DATABASE_URL_RO") or os.environ.get("DATABASE_URL")
assert DB_RO_URL, "Set DATABASE_URL_RO in your environment"

EMBEDDING_MODEL = os.environ.get("OPENAI_EMBEDDING_MODEL", "text-embedding-3-small")
EMBEDDING_DIM = int(os.environ.get("OPENAI_EMBEDDING_DIM", "1536"))

logger = logging.getLogger(__name__)

# --- Models
class SafeQuery(BaseModel):
    name: Literal["student_profile", "latest_results", "search_results"]
    params: Dict[str, Any] = Field(default_factory=dict)

class RagSearch(BaseModel):
    query: str
    k: int = 8
    filters: Dict[str, Any] = Field(default_factory=dict)

class ReportCompose(BaseModel):
    student_id: int
    session: str
    term: str
    auth: Optional[Dict[str, Any]] = Field(default=None, alias="_auth")

    if ConfigDict is not None:  # pragma: no branch - handled at import
        model_config = ConfigDict(populate_by_name=True, extra="allow")  # type: ignore
    else:  # pragma: no cover - pydantic v1
        class Config:
            allow_population_by_field_name = True
            extra = "allow"

# --- Helpers
def db_rows(sql: str, args: tuple=(), auth: dict | None = None):
    with psycopg.connect(DB_RO_URL) as conn, conn.cursor() as cur:
        # Apply per-call auth context for RLS policies
        if auth:
            try:
                if 'user_id' in auth:
                    cur.execute("SET LOCAL app.user_id = %s", (auth['user_id'],))
                if 'role' in auth:
                    cur.execute("SET LOCAL app.role = %s", (auth['role'],))
                if 'school_id' in auth:
                    cur.execute("SET LOCAL app.school_id = %s", (auth['school_id'],))
            except Exception:
                pass
        cur.execute(sql, args)
        cols = [c[0] for c in cur.description]
        return [dict(zip(cols, r)) for r in cur.fetchall()]

@lru_cache(maxsize=1)
def _get_openai_client():
    try:
        from openai import OpenAI  # type: ignore
    except ImportError as exc:  # pragma: no cover - dependency missing at runtime
        raise RuntimeError(
            "Install the 'openai' package (pip install openai>=1.0.0) to enable embeddings"
        ) from exc

    if not os.environ.get("OPENAI_API_KEY"):
        raise RuntimeError("OPENAI_API_KEY environment variable is required for embeddings")

    return OpenAI()


def get_embedding(text: str) -> List[float]:
    """Return a pgvector-compatible embedding for the provided text."""
    snippet = text.strip()
    if not snippet:
        raise ValueError("Cannot embed empty text")

    client = _get_openai_client()
    try:
        response = client.embeddings.create(model=EMBEDDING_MODEL, input=[snippet])
    except Exception as exc:  # pragma: no cover - network/runtime errors
        raise RuntimeError(f"OpenAI embeddings request failed: {exc}") from exc

    embedding = response.data[0].embedding
    if len(embedding) != EMBEDDING_DIM:
        raise RuntimeError(
            f"Embedding dimension mismatch: expected {EMBEDDING_DIM}, received {len(embedding)}"
        )
    return embedding


def _vector_to_sql(vector: List[float]) -> str:
    return "[" + ",".join(f"{value:.8f}" for value in vector) + "]"

# --- Tools
@mcp.tool()
def pg_safe_query(payload: SafeQuery) -> Any:
    # Execute a whitelisted read-only query or function.
    name = payload.name
    p = payload.params
    if name == "student_profile":
        auth = p.pop('_auth', None)
        return db_rows("SELECT * FROM v_student_profile WHERE student_id = %s", (p["student_id"],), auth)
    if name == "latest_results":
        auth = p.pop('_auth', None)
        return db_rows("SELECT * FROM mv_latest_results WHERE student_id = %s ORDER BY subject_id", (p["student_id"],), auth)
    if name == "search_results":
        auth = p.pop('_auth', None)
        return db_rows("SELECT * FROM tool_search_results(%s,%s,%s)", (p["student_id"], p["subject"], p.get("k",5)), auth)
    return {"error": "unknown query name"}

@mcp.tool()
def rag_search(payload: RagSearch) -> Any:
    # Vector search over curriculum/help chunks.
    emb = get_embedding(payload.query)
    vec_literal = _vector_to_sql(emb)
    sql = (
      "SELECT c.id, c.chunk, d.source, d.metadata, (e.embedding <=> %s::vector)::REAL AS score "
      "FROM rag_embedding e "
      "JOIN rag_chunk c ON c.id = e.chunk_id "
      "JOIN rag_document d ON d.id = c.document_id "
      "ORDER BY e.embedding <=> %s::vector "
      "LIMIT %s"
    )
    return db_rows(sql, (vec_literal, vec_literal, payload.k), auth=None)

@mcp.tool()
def report_compose(payload: ReportCompose) -> Any:
    # Build a term report JSON blob for one student.
    auth = payload.auth
    profile = db_rows(
        "SELECT * FROM v_student_profile WHERE student_id=%s",
        (payload.student_id,),
        auth=auth,
    )
    results = db_rows(
        "SELECT r.subject_id, s.name AS subject, r.total, r.grade, r.teacher_remark "
        "FROM result r JOIN subject s ON s.id=r.subject_id "
        "WHERE r.student_id=%s AND r.session=%s AND r.term=%s "
        "ORDER BY s.name",
        (payload.student_id, payload.session, payload.term),
        auth=auth,
    )
    return {
        "student": profile[0] if profile else {},
        "session": payload.session,
        "term": payload.term,
        "results": results,
    }

if __name__ == "__main__":
    # Run over stdio in local dev
    mcp.run()
