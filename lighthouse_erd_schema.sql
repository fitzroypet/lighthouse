
-- PostgreSQL ERD Schema for LightHouse (K-12 Nigeria)
-- Uses GENERATED AS IDENTITY for primary keys; enums for role and term.
-- Safe to run multiple times by dropping types if they exist.
-- Note: Add extensions or privileges as needed for your environment.

-- ===== Enums =====
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'user_role') THEN
    CREATE TYPE user_role AS ENUM ('admin','teacher','parent');
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'term_enum') THEN
    CREATE TYPE term_enum AS ENUM ('first','second','third');
  END IF;
END$$;

-- ===== Core Entities =====
CREATE TABLE IF NOT EXISTS school (
  id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  name TEXT NOT NULL,
  address TEXT,
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE IF NOT EXISTS app_user (
  id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  name TEXT NOT NULL,
  email TEXT UNIQUE,
  role user_role NOT NULL,
  school_id BIGINT REFERENCES school(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Optional: assign a primary admin to the school (added post-creation to avoid circular dep issues)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.table_constraints WHERE constraint_name = 'school_admin_user_fk'
  ) THEN
    ALTER TABLE school
      ADD COLUMN IF NOT EXISTS admin_user_id BIGINT,
      ADD CONSTRAINT school_admin_user_fk FOREIGN KEY (admin_user_id) REFERENCES app_user(id) ON DELETE SET NULL;
  END IF;
END $$;

CREATE TABLE IF NOT EXISTS class (
  id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  name TEXT NOT NULL, -- e.g., 'Primary 4', 'JSS2', 'SS3'
  academic_year TEXT NOT NULL, -- e.g., '2025/2026'
  term term_enum NOT NULL,
  school_id BIGINT NOT NULL REFERENCES school(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE IF NOT EXISTS subject (
  id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  name TEXT NOT NULL, -- e.g., 'Mathematics', 'English Language'
  class_id BIGINT NOT NULL REFERENCES class(id) ON DELETE CASCADE,
  school_id BIGINT NOT NULL REFERENCES school(id) ON DELETE CASCADE,
  UNIQUE (name, class_id)
);

-- ===== Curriculum Hierarchy =====
CREATE TABLE IF NOT EXISTS theme (
  id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  name TEXT NOT NULL,
  subject_id BIGINT NOT NULL REFERENCES subject(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS topic (
  id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  name TEXT NOT NULL,
  theme_id BIGINT NOT NULL REFERENCES theme(id) ON DELETE CASCADE,
  week_covered INT,
  learning_outcome TEXT,
  coverage_status TEXT, -- e.g., 'planned','in_progress','completed'
  completed_date DATE
);

-- ===== People =====
CREATE TABLE IF NOT EXISTS student (
  id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  first_name TEXT NOT NULL,
  last_name TEXT NOT NULL,
  dob DATE,
  gender TEXT,
  admission_number TEXT UNIQUE,
  school_id BIGINT NOT NULL REFERENCES school(id) ON DELETE CASCADE,
  current_class_id BIGINT REFERENCES class(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Many-to-many relation: parent(s) to student(s)
CREATE TABLE IF NOT EXISTS student_parent (
  id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  student_id BIGINT NOT NULL REFERENCES student(id) ON DELETE CASCADE,
  parent_user_id BIGINT NOT NULL REFERENCES app_user(id) ON DELETE CASCADE,
  UNIQUE (student_id, parent_user_id)
);

-- Track class placement historically across sessions/terms
CREATE TABLE IF NOT EXISTS enrollment (
  id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  student_id BIGINT NOT NULL REFERENCES student(id) ON DELETE CASCADE,
  class_id BIGINT NOT NULL REFERENCES class(id) ON DELETE CASCADE,
  session TEXT NOT NULL,     -- e.g., '2025/2026'
  term term_enum NOT NULL,
  start_date DATE,
  end_date DATE,
  UNIQUE (student_id, class_id, session, term)
);

-- Teacher assignment to class/subject
CREATE TABLE IF NOT EXISTS teacher_assignment (
  id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  teacher_user_id BIGINT NOT NULL REFERENCES app_user(id) ON DELETE CASCADE,
  class_id BIGINT NOT NULL REFERENCES class(id) ON DELETE CASCADE,
  subject_id BIGINT NOT NULL REFERENCES subject(id) ON DELETE CASCADE,
  start_date DATE,
  end_date DATE,
  UNIQUE (teacher_user_id, class_id, subject_id, start_date)
);

-- ===== Grading & Assessments =====
CREATE TABLE IF NOT EXISTS grading_scheme (
  id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  name TEXT NOT NULL,         -- e.g., 'WAEC Default'
  description TEXT
);

CREATE TABLE IF NOT EXISTS grade_band (
  id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  grading_scheme_id BIGINT NOT NULL REFERENCES grading_scheme(id) ON DELETE CASCADE,
  label TEXT NOT NULL,        -- e.g., 'A1','B2',...,'F9'
  min_score INT NOT NULL,     -- inclusive
  max_score INT NOT NULL,     -- inclusive
  remark TEXT,
  UNIQUE (grading_scheme_id, label)
);

-- Optional: per-class/subject assessment weighting (e.g., CA1 20%, CA2 20%, Exam 60%)
CREATE TABLE IF NOT EXISTS assessment_weight (
  id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  class_id BIGINT NOT NULL REFERENCES class(id) ON DELETE CASCADE,
  subject_id BIGINT NOT NULL REFERENCES subject(id) ON DELETE CASCADE,
  session TEXT NOT NULL,
  term term_enum NOT NULL,
  ca1_weight NUMERIC(5,2) DEFAULT 20.00,
  ca2_weight NUMERIC(5,2) DEFAULT 20.00,
  exam_weight NUMERIC(5,2) DEFAULT 60.00,
  CHECK (ca1_weight + ca2_weight + exam_weight = 100.00),
  UNIQUE (class_id, subject_id, session, term)
);

-- Results table for quick ingestion from teacher spreadsheets
CREATE TABLE IF NOT EXISTS result (
  id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  student_id BIGINT NOT NULL REFERENCES student(id) ON DELETE CASCADE,
  class_id BIGINT NOT NULL REFERENCES class(id) ON DELETE CASCADE,
  subject_id BIGINT NOT NULL REFERENCES subject(id) ON DELETE CASCADE,
  session TEXT NOT NULL,
  term term_enum NOT NULL,
  ca1 NUMERIC(5,2) DEFAULT 0,
  ca2 NUMERIC(5,2) DEFAULT 0,
  exam NUMERIC(5,2) DEFAULT 0,
  total NUMERIC(6,2) GENERATED ALWAYS AS (COALESCE(ca1,0) + COALESCE(ca2,0) + COALESCE(exam,0)) STORED,
  grade TEXT, -- denormalised for speed; validate via trigger against grading_scheme if set
  grading_scheme_id BIGINT REFERENCES grading_scheme(id) ON DELETE SET NULL,
  teacher_remark TEXT,
  head_teacher_remark TEXT,
  created_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE (student_id, class_id, subject_id, session, term)
);

-- Optional: store behaviour/skills info as JSONB snapshots per term
CREATE TABLE IF NOT EXISTS behaviour_skill (
  id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  student_id BIGINT NOT NULL REFERENCES student(id) ON DELETE CASCADE,
  class_id BIGINT NOT NULL REFERENCES class(id) ON DELETE CASCADE,
  session TEXT NOT NULL,
  term term_enum NOT NULL,
  behaviours JSONB, -- e.g., {"punctuality": "Excellent", "neatness": "Good"}
  skills JSONB,     -- e.g., {"teamwork": "Good", "leadership": "Fair"}
  UNIQUE (student_id, class_id, session, term)
);

-- Helpful indexes
CREATE INDEX IF NOT EXISTS idx_subject_class ON subject(class_id);
CREATE INDEX IF NOT EXISTS idx_theme_subject ON theme(subject_id);
CREATE INDEX IF NOT EXISTS idx_topic_theme ON topic(theme_id);
CREATE INDEX IF NOT EXISTS idx_student_school ON student(school_id);
CREATE INDEX IF NOT EXISTS idx_result_student_term ON result(student_id, session, term);
CREATE INDEX IF NOT EXISTS idx_enrollment_student_term ON enrollment(student_id, session, term);
