-- 06_apply_term_and_rag_index_updates.sql
-- One-off patch to align existing deployments with the latest schema updates.
-- 1. Allow classes without a fixed term so curriculum loaders can create records.
-- 2. Ensure RAG metadata lookups stay performant on re-ingest.

ALTER TABLE class ALTER COLUMN term DROP NOT NULL;

CREATE INDEX IF NOT EXISTS idx_rag_document_topic
  ON rag_document ((metadata->>'type'), (metadata->>'topic_id'));

CREATE INDEX IF NOT EXISTS idx_rag_document_result
  ON rag_document ((metadata->>'type'), (metadata->>'result_id'));
