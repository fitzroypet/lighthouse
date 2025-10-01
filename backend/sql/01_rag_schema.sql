-- 01_rag_schema.sql
-- Enable pgvector and create a simple RAG store
CREATE EXTENSION IF NOT EXISTS vector;

CREATE TABLE IF NOT EXISTS rag_document (
  id BIGSERIAL PRIMARY KEY,
  source TEXT NOT NULL,     -- 'NERDC', 'TeacherGuide', 'Internal'
  uri TEXT,
  metadata JSONB,
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE IF NOT EXISTS rag_chunk (
  id BIGSERIAL PRIMARY KEY,
  document_id BIGINT REFERENCES rag_document(id) ON DELETE CASCADE,
  chunk TEXT NOT NULL,
  token_count INT,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Choose a dimension that matches your embedding model
CREATE TABLE IF NOT EXISTS rag_embedding (
  chunk_id BIGINT PRIMARY KEY REFERENCES rag_chunk(id) ON DELETE CASCADE,
  embedding vector(1536)
);

CREATE INDEX IF NOT EXISTS idx_rag_embedding
  ON rag_embedding USING ivfflat (embedding vector_cosine_ops) WITH (lists=100);

CREATE INDEX IF NOT EXISTS idx_rag_document_topic
  ON rag_document ((metadata->>'type'), (metadata->>'topic_id'));

CREATE INDEX IF NOT EXISTS idx_rag_document_result
  ON rag_document ((metadata->>'type'), (metadata->>'result_id'));
