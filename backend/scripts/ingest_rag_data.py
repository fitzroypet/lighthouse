#!/usr/bin/env python3
"""Populate the RAG tables with curriculum topics and (optionally) student result narratives."""

from __future__ import annotations

import argparse
import json
import os
import sys
from typing import Iterable, Sequence

import psycopg
from psycopg import rows

from backend.lighthouse_mcp.lighthouse_mcp_server import EMBEDDING_DIM, EMBEDDING_MODEL, get_embedding


def _require_database_url() -> str:
    url = os.environ.get("DATABASE_URL")
    if not url:
        raise SystemExit("DATABASE_URL environment variable is required for ingestion")
    return url


def _vector_to_sql(vector: Iterable[float]) -> str:
    return "[" + ",".join(f"{value:.8f}" for value in vector) + "]"


def ingest_curriculum_topics(conn: psycopg.Connection, limit: int | None = None) -> int:
    query = """
        SELECT
            t.id AS topic_id,
            t.name AS topic_name,
            t.week_covered,
            t.learning_outcome,
            t.coverage_status,
            t.completed_date,
            th.id AS theme_id,
            th.name AS theme_name,
            subj.id AS subject_id,
            subj.name AS subject_name,
            cls.id AS class_id,
            cls.name AS class_name,
            cls.academic_year
        FROM topic t
        JOIN theme th ON th.id = t.theme_id
        JOIN subject subj ON subj.id = th.subject_id
        JOIN class cls ON cls.id = subj.class_id
        ORDER BY subj.name, th.name, t.name
    """
    params: Sequence[object] = ()
    if limit is not None:
        query += " LIMIT %s"
        params = (limit,)

    with conn.cursor(row_factory=rows.dict_row) as cur:
        cur.execute(query, params)
        rows_to_embed = cur.fetchall()

    inserted = 0
    with conn.cursor() as cur:
        for row in rows_to_embed:
            metadata = {
                "type": "curriculum_topic",
                "topic_id": row["topic_id"],
                "theme_id": row["theme_id"],
                "subject_id": row["subject_id"],
                "class_id": row["class_id"],
                "academic_year": row["academic_year"],
            }
            summary_lines = [
                f"Subject: {row['subject_name']}",
                f"Class: {row['class_name']} ({row['academic_year']})",
                f"Theme: {row['theme_name']}",
                f"Topic: {row['topic_name']}",
            ]
            if row.get("week_covered"):
                summary_lines.append(f"Week covered: {row['week_covered']}")
            if row.get("learning_outcome"):
                summary_lines.append(f"Learning outcomes: {row['learning_outcome']}")
            if row.get("coverage_status"):
                summary_lines.append(f"Coverage status: {row['coverage_status']}")
            if row.get("completed_date"):
                summary_lines.append(f"Completed date: {row['completed_date']}")
            chunk_text = "\n".join(summary_lines)

            # Remove any existing chunk for this topic so reruns stay idempotent.
            cur.execute(
                """
                DELETE FROM rag_document
                WHERE metadata->>'type' = 'curriculum_topic'
                  AND metadata->>'topic_id' = %s
                """,
                (str(row["topic_id"]),),
            )

            doc_id = cur.execute(
                """
                INSERT INTO rag_document (source, metadata)
                VALUES (%s, %s)
                RETURNING id
                """,
                (row["subject_name"], json.dumps(metadata)),
            ).fetchone()[0]

            chunk_id = cur.execute(
                """
                INSERT INTO rag_chunk (document_id, chunk)
                VALUES (%s, %s)
                RETURNING id
                """,
                (doc_id, chunk_text),
            ).fetchone()[0]

            embedding = get_embedding(chunk_text)
            cur.execute(
                """
                INSERT INTO rag_embedding (chunk_id, embedding)
                VALUES (%s, %s::vector)
                """,
                (chunk_id, _vector_to_sql(embedding)),
            )
            inserted += 1

    return inserted


def ingest_student_results(
    conn: psycopg.Connection,
    student_id: int | None = None,
    limit: int | None = None,
) -> int:
    query = """
        SELECT
            r.id AS result_id,
            r.student_id,
            r.class_id,
            r.subject_id,
            r.session,
            r.term::TEXT AS term,
            r.total,
            r.grade,
            r.teacher_remark,
            r.head_teacher_remark,
            r.created_at,
            stu.first_name,
            stu.last_name,
            cls.name AS class_name,
            subj.name AS subject_name
        FROM result r
        JOIN student stu ON stu.id = r.student_id
        JOIN class cls ON cls.id = r.class_id
        JOIN subject subj ON subj.id = r.subject_id
        WHERE (%(student_id)s IS NULL OR r.student_id = %(student_id)s)
        ORDER BY r.created_at DESC
    """
    params = {"student_id": student_id}
    if limit is not None:
        query += " LIMIT %(limit)s"
        params["limit"] = limit

    with conn.cursor(row_factory=rows.dict_row) as cur:
        cur.execute(query, params)
        rows_to_embed = cur.fetchall()

    inserted = 0
    with conn.cursor() as cur:
        for row in rows_to_embed:
            metadata = {
                "type": "student_result",
                "result_id": row["result_id"],
                "student_id": row["student_id"],
                "class_id": row["class_id"],
                "subject_id": row["subject_id"],
                "session": row["session"],
                "term": row["term"],
            }
            summary_lines = [
                f"Student: {row['first_name']} {row['last_name']} (ID {row['student_id']})",
                f"Class: {row['class_name']} | Subject: {row['subject_name']}",
                f"Session: {row['session']} | Term: {row['term']}",
                f"Total score: {row['total']} | Grade: {row.get('grade') or 'N/A'}",
            ]
            if row.get("teacher_remark"):
                summary_lines.append(f"Teacher remark: {row['teacher_remark']}")
            if row.get("head_teacher_remark"):
                summary_lines.append(f"Head teacher remark: {row['head_teacher_remark']}")
            chunk_text = "\n".join(summary_lines)

            cur.execute(
                """
                DELETE FROM rag_document
                WHERE metadata->>'type' = 'student_result'
                  AND metadata->>'result_id' = %s
                """,
                (str(row["result_id"]),),
            )

            doc_id = cur.execute(
                """
                INSERT INTO rag_document (source, metadata)
                VALUES (%s, %s)
                RETURNING id
                """,
                ("result", json.dumps(metadata)),
            ).fetchone()[0]

            chunk_id = cur.execute(
                """
                INSERT INTO rag_chunk (document_id, chunk)
                VALUES (%s, %s)
                RETURNING id
                """,
                (doc_id, chunk_text),
            ).fetchone()[0]

            embedding = get_embedding(chunk_text)
            cur.execute(
                """
                INSERT INTO rag_embedding (chunk_id, embedding)
                VALUES (%s, %s::vector)
                """,
                (chunk_id, _vector_to_sql(embedding)),
            )
            inserted += 1

    return inserted


def refresh_materialized_views(conn: psycopg.Connection) -> None:
    with conn.cursor() as cur:
        cur.execute("REFRESH MATERIALIZED VIEW mv_latest_results")


def main() -> None:
    parser = argparse.ArgumentParser(
        description=(
            "Generate embeddings for curriculum topics and student results using the "
            f"OpenAI model '{EMBEDDING_MODEL}' ({EMBEDDING_DIM} dims)."
        )
    )
    parser.add_argument(
        "--topics-only",
        action="store_true",
        help="Only embed curriculum topics (skip student results).",
    )
    parser.add_argument(
        "--include-results",
        action="store_true",
        help="Embed student result narratives as well as curriculum topics.",
    )
    parser.add_argument(
        "--student-id",
        type=int,
        help="Limit student result embeddings to a specific student ID.",
    )
    parser.add_argument(
        "--limit",
        type=int,
        help="Optional limit for curriculum topics and/or results processed.",
    )
    args = parser.parse_args()

    if not args.include_results and not args.topics_only:
        # Default behaviour: embed topics and results if requested via flag.
        args.include_results = True

    database_url = _require_database_url()

    with psycopg.connect(database_url) as conn:
        topics_processed = ingest_curriculum_topics(conn, limit=args.limit)
        results_processed = 0
        if args.include_results and not args.topics_only:
            results_processed = ingest_student_results(
                conn, student_id=args.student_id, limit=args.limit
            )
        conn.commit()
        refresh_materialized_views(conn)
        conn.commit()

    print(
        f"Embedded curriculum topics: {topics_processed}; "
        f"student results: {results_processed}",
        file=sys.stdout,
    )


if __name__ == "__main__":  # pragma: no cover - CLI entry point
    main()
