-- 02_agent_views_and_functions.sql
-- Views and functions the agent can safely call

-- Latest result per (student, subject)
DROP MATERIALIZED VIEW IF EXISTS mv_latest_results;
CREATE MATERIALIZED VIEW mv_latest_results AS
SELECT r.student_id, r.subject_id, r.session, r.term, r.total, r.grade, r.teacher_remark
FROM result r
JOIN (
  SELECT student_id, subject_id, MAX(created_at) AS max_ct
  FROM result GROUP BY 1,2
) m ON m.student_id=r.student_id AND m.subject_id=r.subject_id AND m.max_ct=r.created_at;

-- Simple student profile view
CREATE OR REPLACE VIEW v_student_profile AS
SELECT s.id AS student_id, s.first_name, s.last_name, s.admission_number,
       c.name AS current_class, s.school_id
FROM student s
LEFT JOIN class c ON c.id = s.current_class_id;

-- Whitelisted functions

-- Search results by subject for a student
CREATE OR REPLACE FUNCTION tool_search_results(p_student_id BIGINT, p_subject TEXT, p_k INT DEFAULT 5)
RETURNS TABLE(session TEXT, term TEXT, total NUMERIC, grade TEXT, remark TEXT) AS $$
  SELECT r.session, r.term::TEXT, r.total, r.grade, r.teacher_remark
  FROM result r
  JOIN subject s ON s.id = r.subject_id
  WHERE r.student_id = p_student_id AND s.name ILIKE p_subject
  ORDER BY r.created_at DESC
  LIMIT p_k;
$$ LANGUAGE sql STABLE;

-- Vector similarity search helper
CREATE OR REPLACE FUNCTION tool_similar_chunks(p_embedding vector(1536), p_limit INT DEFAULT 8)
RETURNS TABLE(chunk TEXT, source TEXT, metadata JSONB, score REAL) AS $$
  SELECT c.chunk, d.source, d.metadata, (e.embedding <=> p_embedding)::REAL AS score
  FROM rag_embedding e
  JOIN rag_chunk c ON c.id = e.chunk_id
  JOIN rag_document d ON d.id = c.document_id
  ORDER BY e.embedding <=> p_embedding
  LIMIT p_limit;
$$ LANGUAGE sql STABLE;
