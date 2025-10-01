
\if :{?include_topics}
\else
\set include_topics true
\endif

-- 05_insert_jss3_curriculum.sql
-- Map the full JSS3 (2020/2021) curriculum for AM Blessed Model Academy into the
-- existing LightHouse schema (subject/theme/topic tables).  Term assignments are
-- intentionally left out so admins can distribute content per term from the UI.
-- The script can be run repeatedly thanks to ON CONFLICT guards.

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'school_name_key'
  ) THEN
    ALTER TABLE school ADD CONSTRAINT school_name_key UNIQUE (name);
  END IF;

  IF EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'class_name_year_term_school_key'
  ) THEN
    ALTER TABLE class DROP CONSTRAINT class_name_year_term_school_key;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'class_name_year_school_key'
  ) THEN
    ALTER TABLE class ADD CONSTRAINT class_name_year_school_key UNIQUE (name, academic_year, school_id);
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'theme_subject_name_key'
  ) THEN
    ALTER TABLE theme ADD CONSTRAINT theme_subject_name_key UNIQUE (subject_id, name);
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'topic_theme_name_key'
  ) THEN
    ALTER TABLE topic ADD CONSTRAINT topic_theme_name_key UNIQUE (theme_id, name);
  END IF;
END $$;

-- ---------------------------------------------------------------------------
-- 1. Ensure the school and class records exist
-- ---------------------------------------------------------------------------

-- Insert the school if it does not already exist
INSERT INTO school (name)
VALUES ('AM Blessed Model Academy')
ON CONFLICT (name) DO NOTHING;

-- Insert the JSS3 class for the 2020/2021 academic year without binding it to a term.
INSERT INTO class (name, academic_year, school_id)
SELECT 'JSS3', '2020/2021', id
FROM school
WHERE name = 'AM Blessed Model Academy'
ON CONFLICT ON CONSTRAINT class_name_year_school_key DO NOTHING;

-- ---------------------------------------------------------------------------
-- 2. Ensure subjects exist for this class
-- ---------------------------------------------------------------------------

-- List of subject names used in the curriculum.  Update or extend this list
-- if new subjects are added to the curriculum in future sessions.
INSERT INTO subject (name, class_id, school_id)
SELECT subj_name, c.id, c.school_id
FROM (
  VALUES
    ('English Language'),
    ('General Mathematics'),
    ('Physical & Health Education'),
    ('Information Technology (IT)'),
    ('Basic Science'),
    ('Basic Technology'),
    ('Social Studies'),
    ('Christian Religious Studies'),
    ('Security Education'),
    ('Civic Education (Basic)'),
    ('Home Economics'),
    ('Agriculture'),
    ('Cultural And Creative Arts'),
    ('French Language')
  ) AS s(subj_name)
JOIN class c ON c.name = 'JSS3' AND c.academic_year = '2020/2021'
JOIN school sc ON c.school_id = sc.id AND sc.name = 'AM Blessed Model Academy'
ON CONFLICT ON CONSTRAINT subject_name_class_id_key DO NOTHING;

-- ---------------------------------------------------------------------------
-- 3. Insert themes and topics for each subject
-- ---------------------------------------------------------------------------

\if :include_topics

-- Helper comment: Each section below inserts a theme into the theme
-- table and then inserts its associated topics into topic.  The
-- cross‑join with VALUES ensures all topics reference the correct theme.  The
-- ON CONFLICT clause prevents duplicate topics if the script is run again.

-- ==============================
-- Subject: English Language
-- ==============================

-- Insert themes for English Language
WITH s AS (
  SELECT sub.id AS subject_id
  FROM subject sub
  JOIN class c ON sub.class_id = c.id
  JOIN school sc ON c.school_id = sc.id
  WHERE sub.name = 'English Language'
    AND c.name = 'JSS3' AND c.academic_year = '2020/2021'
    AND sc.name = 'AM Blessed Model Academy'
),
inserted AS (
  INSERT INTO theme (subject_id, name)
  SELECT subject_id, theme
  FROM s
  CROSS JOIN (
    VALUES
      ('Reading'),
      ('Writing'),
      ('Listening & Speaking'),
      ('Grammatical Accuracy'),
      ('Literature')
  ) AS t(theme)
  ON CONFLICT DO NOTHING
  RETURNING id, name, subject_id
)
SELECT * FROM inserted;

-- Insert topics for the Reading theme
WITH theme AS (
  SELECT ct.id AS theme_id
  FROM theme ct
  JOIN subject sub ON ct.subject_id = sub.id
  JOIN class c ON sub.class_id = c.id
  JOIN school sc ON c.school_id = sc.id
  WHERE ct.name = 'Reading'
    AND sub.name = 'English Language'
    AND c.name = 'JSS3' AND c.academic_year = '2020/2021'
    AND sc.name = 'AM Blessed Model Academy'
)
INSERT INTO topic (theme_id, name)
SELECT theme.theme_id, v.name
FROM theme
CROSS JOIN (
  VALUES
    ('reading for critical evaluation'),
    ('reading for speed'),
    ('reading for summary')
) AS v(name)
ON CONFLICT DO NOTHING;

-- Topics for Writing
WITH theme AS (
  SELECT ct.id AS theme_id
  FROM theme ct
  JOIN subject sub ON ct.subject_id = sub.id
  JOIN class c ON sub.class_id = c.id
  JOIN school sc ON c.school_id = sc.id
  WHERE ct.name = 'Writing'
    AND sub.name = 'English Language'
    AND c.name = 'JSS3' AND c.academic_year = '2020/2021'
    AND sc.name = 'AM Blessed Model Academy'
)
INSERT INTO topic (theme_id, name)
SELECT theme.theme_id, v.name
FROM theme
CROSS JOIN (
  VALUES
    ('composition writing (argumentative, debate, etc.)'),
    ('letter writing (informal & formal)'),
    ('summary writing')
) AS v(name)
ON CONFLICT DO NOTHING;

-- Topics for Listening & Speaking
WITH theme AS (
  SELECT ct.id AS theme_id
  FROM theme ct
  JOIN subject sub ON ct.subject_id = sub.id
  JOIN class c ON sub.class_id = c.id
  JOIN school sc ON c.school_id = sc.id
  WHERE ct.name = 'Listening & Speaking'
    AND sub.name = 'English Language'
    AND c.name = 'JSS3' AND c.academic_year = '2020/2021'
    AND sc.name = 'AM Blessed Model Academy'
)
INSERT INTO topic (theme_id, name)
SELECT theme.theme_id, v.name
FROM theme
CROSS JOIN (
  VALUES
    ('speeches/phonemes'),
    ('intonation, stress & rhythm')
) AS v(name)
ON CONFLICT DO NOTHING;

-- Topics for Grammatical Accuracy
WITH theme AS (
  SELECT ct.id AS theme_id
  FROM theme ct
  JOIN subject sub ON ct.subject_id = sub.id
  JOIN class c ON sub.class_id = c.id
  JOIN school sc ON c.school_id = sc.id
  WHERE ct.name = 'Grammatical Accuracy'
    AND sub.name = 'English Language'
    AND c.name = 'JSS3' AND c.academic_year = '2020/2021'
    AND sc.name = 'AM Blessed Model Academy'
)
INSERT INTO topic (theme_id, name)
SELECT theme.theme_id, v.name
FROM theme
CROSS JOIN (
  VALUES
    ('adverbials & tenses'),
    ('adverbs/conjunctions/prepositions'),
    ('active & passive verbs'),
    ('modal forms')
) AS v(name)
ON CONFLICT DO NOTHING;

-- Topics for Literature
WITH theme AS (
  SELECT ct.id AS theme_id
  FROM theme ct
  JOIN subject sub ON ct.subject_id = sub.id
  JOIN class c ON sub.class_id = c.id
  JOIN school sc ON c.school_id = sc.id
  WHERE ct.name = 'Literature'
    AND sub.name = 'English Language'
    AND c.name = 'JSS3' AND c.academic_year = '2020/2021'
    AND sc.name = 'AM Blessed Model Academy'
)
INSERT INTO topic (theme_id, name)
SELECT theme.theme_id, v.name
FROM theme
CROSS JOIN (
  VALUES
    ('non-African folktales'),
    ('myths/legends'),
    ('prose revision'),
    ('poetry revision'),
    ('drama revision')
) AS v(name)
ON CONFLICT DO NOTHING;

-- ==============================
-- Subject: General Mathematics
-- ==============================

-- Insert themes for General Mathematics
WITH s AS (
  SELECT sub.id AS subject_id
  FROM subject sub
  JOIN class c ON sub.class_id = c.id
  JOIN school sc ON c.school_id = sc.id
  WHERE sub.name = 'General Mathematics'
    AND c.name = 'JSS3' AND c.academic_year = '2020/2021'
    AND sc.name = 'AM Blessed Model Academy'
)
INSERT INTO theme (subject_id, name)
SELECT subject_id, theme
FROM s
CROSS JOIN (
  VALUES
    ('Numbers and Numeration'),
    ('Basic Operations'),
    ('Algebraic Processes'),
    ('Mensuration and Geometry'),
    ('Everyday Statistics')
) AS t(theme)
ON CONFLICT DO NOTHING;

-- Topics for Numbers and Numeration
WITH theme AS (
  SELECT ct.id AS theme_id
  FROM theme ct
  JOIN subject sub ON ct.subject_id = sub.id
  JOIN class c ON sub.class_id = c.id
  JOIN school sc ON c.school_id = sc.id
  WHERE ct.name = 'Numbers and Numeration'
    AND sub.name = 'General Mathematics'
    AND c.name = 'JSS3' AND c.academic_year = '2020/2021'
    AND sc.name = 'AM Blessed Model Academy'
)
INSERT INTO topic (theme_id, name)
SELECT theme.theme_id, v.name
FROM theme
CROSS JOIN (
  VALUES
    ('whole numbers'),
    ('rational & non-rational numbers')
) AS v(name)
ON CONFLICT DO NOTHING;

-- Topics for Basic Operations
WITH theme AS (
  SELECT ct.id AS theme_id
  FROM theme ct
  JOIN subject sub ON ct.subject_id = sub.id
  JOIN class c ON sub.class_id = c.id
  JOIN school sc ON c.school_id = sc.id
  WHERE ct.name = 'Basic Operations'
    AND sub.name = 'General Mathematics'
    AND c.name = 'JSS3' AND c.academic_year = '2020/2021'
    AND sc.name = 'AM Blessed Model Academy'
)
INSERT INTO topic (theme_id, name)
SELECT theme.theme_id, v.name
FROM theme
CROSS JOIN (
  VALUES
    ('addition of numbers in base 2'),
    ('subtraction of numbers in base 2'),
    ('multiplication of numbers in base 2'),
    ('division of numbers in base 2')
) AS v(name)
ON CONFLICT DO NOTHING;

-- Topics for Algebraic Processes
WITH theme AS (
  SELECT ct.id AS theme_id
  FROM theme ct
  JOIN subject sub ON ct.subject_id = sub.id
  JOIN class c ON sub.class_id = c.id
  JOIN school sc ON c.school_id = sc.id
  WHERE ct.name = 'Algebraic Processes'
    AND sub.name = 'General Mathematics'
    AND c.name = 'JSS3' AND c.academic_year = '2020/2021'
    AND sc.name = 'AM Blessed Model Academy'
)
INSERT INTO topic (theme_id, name)
SELECT theme.theme_id, v.name
FROM theme
CROSS JOIN (
  VALUES
    ('factorization'),
    ('simple equations involving fractions'),
    ('simultaneous linear equations')
) AS v(name)
ON CONFLICT DO NOTHING;

-- Topics for Mensuration and Geometry
WITH theme AS (
  SELECT ct.id AS theme_id
  FROM theme ct
  JOIN subject sub ON ct.subject_id = sub.id
  JOIN class c ON sub.class_id = c.id
  JOIN school sc ON c.school_id = sc.id
  WHERE ct.name = 'Mensuration and Geometry'
    AND sub.name = 'General Mathematics'
    AND c.name = 'JSS3' AND c.academic_year = '2020/2021'
    AND sc.name = 'AM Blessed Model Academy'
)
INSERT INTO topic (theme_id, name)
SELECT theme.theme_id, v.name
FROM theme
CROSS JOIN (
  VALUES
    ('similar shapes'),
    ('trigonometry'),
    ('area of plane figures'),
    ('construction')
) AS v(name)
ON CONFLICT DO NOTHING;

-- Topics for Everyday Statistics
WITH theme AS (
  SELECT ct.id AS theme_id
  FROM theme ct
  JOIN subject sub ON ct.subject_id = sub.id
  JOIN class c ON sub.class_id = c.id
  JOIN school sc ON c.school_id = sc.id
  WHERE ct.name = 'Everyday Statistics'
    AND sub.name = 'General Mathematics'
    AND c.name = 'JSS3' AND c.academic_year = '2020/2021'
    AND sc.name = 'AM Blessed Model Academy'
)
INSERT INTO topic (theme_id, name)
SELECT theme.theme_id, v.name
FROM theme
CROSS JOIN (
  VALUES
    ('measures of central tendency'),
    ('data presentation')
) AS v(name)
ON CONFLICT DO NOTHING;

-- ==============================
-- Subject: Physical & Health Education
-- ==============================

-- Insert themes for Physical & Health Education
WITH s AS (
  SELECT sub.id AS subject_id
  FROM subject sub
  JOIN class c ON sub.class_id = c.id
  JOIN school sc ON c.school_id = sc.id
  WHERE sub.name = 'Physical & Health Education'
    AND c.name = 'JSS3' AND c.academic_year = '2020/2021'
    AND sc.name = 'AM Blessed Model Academy'
)
INSERT INTO theme (subject_id, name)
SELECT subject_id, theme
FROM s
CROSS JOIN (
  VALUES
    ('Moving Our Body Parts'),
    ('Athletics'),
    ('Contact and Non Contact Games'),
    ('Health Education')
) AS t(theme)
ON CONFLICT DO NOTHING;

-- Topics for Moving Our Body Parts
WITH theme AS (
  SELECT ct.id AS theme_id
  FROM theme ct
  JOIN subject sub ON ct.subject_id = sub.id
  JOIN class c ON sub.class_id = c.id
  JOIN school sc ON c.school_id = sc.id
  WHERE ct.name = 'Moving Our Body Parts'
    AND sub.name = 'Physical & Health Education'
    AND c.name = 'JSS3' AND c.academic_year = '2020/2021'
    AND sc.name = 'AM Blessed Model Academy'
)
INSERT INTO topic (theme_id, name)
SELECT theme.theme_id, v.name
FROM theme
CROSS JOIN (
  VALUES
    ('physical fitness & body conditioning'),
    ('recreation, leisure & dance activities')
) AS v(name)
ON CONFLICT DO NOTHING;

-- Topics for Athletics
WITH theme AS (
  SELECT ct.id AS theme_id
  FROM theme ct
  JOIN subject sub ON ct.subject_id = sub.id
  JOIN class c ON sub.class_id = c.id
  JOIN school sc ON c.school_id = sc.id
  WHERE ct.name = 'Athletics'
    AND sub.name = 'Physical & Health Education'
    AND c.name = 'JSS3' AND c.academic_year = '2020/2021'
    AND sc.name = 'AM Blessed Model Academy'
)
INSERT INTO topic (theme_id, name)
SELECT theme.theme_id, v.name
FROM theme
CROSS JOIN (
  VALUES
    ('track and field'),
    ('ball games'),
    ('group/combined events'),
    ('Nigerian sports heroes')
) AS v(name)
ON CONFLICT DO NOTHING;

-- Topics for Contact and Non Contact Games
WITH theme AS (
  SELECT ct.id AS theme_id
  FROM theme ct
  JOIN subject sub ON ct.subject_id = sub.id
  JOIN class c ON sub.class_id = c.id
  JOIN school sc ON c.school_id = sc.id
  WHERE ct.name = 'Contact and Non Contact Games'
    AND sub.name = 'Physical & Health Education'
    AND c.name = 'JSS3' AND c.academic_year = '2020/2021'
    AND sc.name = 'AM Blessed Model Academy'
)
INSERT INTO topic (theme_id, name)
SELECT theme.theme_id, v.name
FROM theme
CROSS JOIN (
  VALUES
    ('contact games'),
    ('non-contact games')
) AS v(name)
ON CONFLICT DO NOTHING;

-- Topics for Health Education
WITH theme AS (
  SELECT ct.id AS theme_id
  FROM theme ct
  JOIN subject sub ON ct.subject_id = sub.id
  JOIN class c ON sub.class_id = c.id
  JOIN school sc ON c.school_id = sc.id
  WHERE ct.name = 'Health Education'
    AND sub.name = 'Physical & Health Education'
    AND c.name = 'JSS3' AND c.academic_year = '2020/2021'
    AND sc.name = 'AM Blessed Model Academy'
)
INSERT INTO topic (theme_id, name)
SELECT theme.theme_id, v.name
FROM theme
CROSS JOIN (
  VALUES
    ('personal, school and community health I & II'),
    ('pathogens/diseases and prevention'),
    ('family health')
) AS v(name)
ON CONFLICT DO NOTHING;

-- ==============================
-- Subject: Information Technology (IT)
-- ==============================

-- Insert themes for Information Technology (IT)
WITH s AS (
  SELECT sub.id AS subject_id
  FROM subject sub
  JOIN class c ON sub.class_id = c.id
  JOIN school sc ON c.school_id = sc.id
  WHERE sub.name = 'Information Technology (IT)'
    AND c.name = 'JSS3' AND c.academic_year = '2020/2021'
    AND sc.name = 'AM Blessed Model Academy'
)
INSERT INTO theme (subject_id, name)
SELECT subject_id, theme
FROM s
CROSS JOIN (
  VALUES
    ('Basic Computer Operations and Concepts'),
    ('Basic Knowledge of Information Technology'),
    ('Computer Application Packages')
) AS t(theme)
ON CONFLICT DO NOTHING;

-- Topics for Basic Computer Operations and Concepts
WITH theme AS (
  SELECT ct.id AS theme_id
  FROM theme ct
  JOIN subject sub ON ct.subject_id = sub.id
  JOIN class c ON sub.class_id = c.id
  JOIN school sc ON c.school_id = sc.id
  WHERE ct.name = 'Basic Computer Operations and Concepts'
    AND sub.name = 'Information Technology (IT)'
    AND c.name = 'JSS3' AND c.academic_year = '2020/2021'
    AND sc.name = 'AM Blessed Model Academy'
)
INSERT INTO topic (theme_id, name)
SELECT theme.theme_id, v.name
FROM theme
CROSS JOIN (
  VALUES
    ('computer career opportunities'),
    ('computer viruses')
) AS v(name)
ON CONFLICT DO NOTHING;

-- Topics for Basic Knowledge of Information Technology
WITH theme AS (
  SELECT ct.id AS theme_id
  FROM theme ct
  JOIN subject sub ON ct.subject_id = sub.id
  JOIN class c ON sub.class_id = c.id
  JOIN school sc ON c.school_id = sc.id
  WHERE ct.name = 'Basic Knowledge of Information Technology'
    AND sub.name = 'Information Technology (IT)'
    AND c.name = 'JSS3' AND c.academic_year = '2020/2021'
    AND sc.name = 'AM Blessed Model Academy'
)
INSERT INTO topic (theme_id, name)
SELECT theme.theme_id, v.name
FROM theme
CROSS JOIN (
  VALUES
    ('internet'),
    ('digital divide')
) AS v(name)
ON CONFLICT DO NOTHING;

-- Topics for Computer Application Packages
WITH theme AS (
  SELECT ct.id AS theme_id
  FROM theme ct
  JOIN subject sub ON ct.subject_id = sub.id
  JOIN class c ON sub.class_id = c.id
  JOIN school sc ON c.school_id = sc.id
  WHERE ct.name = 'Computer Application Packages'
    AND sub.name = 'Information Technology (IT)'
    AND c.name = 'JSS3' AND c.academic_year = '2020/2021'
    AND sc.name = 'AM Blessed Model Academy'
)
INSERT INTO topic (theme_id, name)
SELECT theme.theme_id, v.name
FROM theme
CROSS JOIN (
  VALUES
    ('database'),
    ('spreadsheet packages'),
    ('worksheets'),
    ('graphs')
) AS v(name)
ON CONFLICT DO NOTHING;

-- ==============================
-- Subject: Basic Science
-- ==============================

-- Insert themes for Basic Science
WITH s AS (
  SELECT sub.id AS subject_id
  FROM subject sub
  JOIN class c ON sub.class_id = c.id
  JOIN school sc ON c.school_id = sc.id
  WHERE sub.name = 'Basic Science'
    AND c.name = 'JSS3' AND c.academic_year = '2020/2021'
    AND sc.name = 'AM Blessed Model Academy'
)
INSERT INTO theme (subject_id, name)
SELECT subject_id, theme
FROM s
CROSS JOIN (
  VALUES
    ('Learning About Our Environment'),
    ('You and Energy'),
    ('Science and Development')
) AS t(theme)
ON CONFLICT DO NOTHING;

-- Topics for Learning About Our Environment
WITH theme AS (
  SELECT ct.id AS theme_id
  FROM theme ct
  JOIN subject sub ON ct.subject_id = sub.id
  JOIN class c ON sub.class_id = c.id
  JOIN school sc ON c.school_id = sc.id
  WHERE ct.name = 'Learning About Our Environment'
    AND sub.name = 'Basic Science'
    AND c.name = 'JSS3' AND c.academic_year = '2020/2021'
    AND sc.name = 'AM Blessed Model Academy'
)
INSERT INTO topic (theme_id, name)
SELECT theme.theme_id, v.name
FROM theme
CROSS JOIN (
  VALUES
    ('family traits'),
    ('environmental hazards I–III'),
    ('drug and substance abuse'),
    ('resources from living and non-living things')
) AS v(name)
ON CONFLICT DO NOTHING;

-- Topics for You and Energy
WITH theme AS (
  SELECT ct.id AS theme_id
  FROM theme ct
  JOIN subject sub ON ct.subject_id = sub.id
  JOIN class c ON sub.class_id = c.id
  JOIN school sc ON c.school_id = sc.id
  WHERE ct.name = 'You and Energy'
    AND sub.name = 'Basic Science'
    AND c.name = 'JSS3' AND c.academic_year = '2020/2021'
    AND sc.name = 'AM Blessed Model Academy'
)
INSERT INTO topic (theme_id, name)
SELECT theme.theme_id, v.name
FROM theme
CROSS JOIN (
  VALUES
    ('light energy'),
    ('sound energy'),
    ('magnetism'),
    ('electrical energy'),
    ('radioactivity')
) AS v(name)
ON CONFLICT DO NOTHING;

-- Topics for Science and Development
WITH theme AS (
  SELECT ct.id AS theme_id
  FROM theme ct
  JOIN subject sub ON ct.subject_id = sub.id
  JOIN class c ON sub.class_id = c.id
  JOIN school sc ON c.school_id = sc.id
  WHERE ct.name = 'Science and Development'
    AND sub.name = 'Basic Science'
    AND c.name = 'JSS3' AND c.academic_year = '2020/2021'
    AND sc.name = 'AM Blessed Model Academy'
)
INSERT INTO topic (theme_id, name)
SELECT theme.theme_id, v.name
FROM theme
CROSS JOIN (
  VALUES
    ('skill acquisition'),
    ('ethical issues in science and development')
) AS v(name)
ON CONFLICT DO NOTHING;

-- ==============================
-- Subject: Basic Technology
-- ==============================

-- Insert themes for Basic Technology
WITH s AS (
  SELECT sub.id AS subject_id
  FROM subject sub
  JOIN class c ON sub.class_id = c.id
  JOIN school sc ON c.school_id = sc.id
  WHERE sub.name = 'Basic Technology'
    AND c.name = 'JSS3' AND c.academic_year = '2020/2021'
    AND sc.name = 'AM Blessed Model Academy'
)
INSERT INTO theme (subject_id, name)
SELECT subject_id, theme
FROM s
CROSS JOIN (
  VALUES
    ('Materials and Processing'),
    ('Drawing Practice'),
    ('Tools, Machines and Processes')
) AS t(theme)
ON CONFLICT DO NOTHING;

-- Topics for Materials and Processing
WITH theme AS (
  SELECT ct.id AS theme_id
  FROM theme ct
  JOIN subject sub ON ct.subject_id = sub.id
  JOIN class c ON sub.class_id = c.id
  JOIN school sc ON c.school_id = sc.id
  WHERE ct.name = 'Materials and Processing'
    AND sub.name = 'Basic Technology'
    AND c.name = 'JSS3' AND c.academic_year = '2020/2021'
    AND sc.name = 'AM Blessed Model Academy'
)
INSERT INTO topic (theme_id, name)
SELECT theme.theme_id, v.name
FROM theme
CROSS JOIN (
  VALUES
    ('processing timber'),
    ('processing metals'),
    ('processing clay/ceramics/glass'),
    ('processing plastics & rubber')
) AS v(name)
ON CONFLICT DO NOTHING;

-- Topics for Drawing Practice
WITH theme AS (
  SELECT ct.id AS theme_id
  FROM theme ct
  JOIN subject sub ON ct.subject_id = sub.id
  JOIN class c ON sub.class_id = c.id
  JOIN school sc ON c.school_id = sc.id
  WHERE ct.name = 'Drawing Practice'
    AND sub.name = 'Basic Technology'
    AND c.name = 'JSS3' AND c.academic_year = '2020/2021'
    AND sc.name = 'AM Blessed Model Academy'
)
INSERT INTO topic (theme_id, name)
SELECT theme.theme_id, v.name
FROM theme
CROSS JOIN (
  VALUES
    ('isometric drawing'),
    ('oblique drawing'),
    ('orthographic projection'),
    ('one-point perspective drawing'),
    ('scales and scale drawing'),
    ('plans and blue-print')
) AS v(name)
ON CONFLICT DO NOTHING;

-- Topics for Tools, Machines and Processes
WITH theme AS (
  SELECT ct.id AS theme_id
  FROM theme ct
  JOIN subject sub ON ct.subject_id = sub.id
  JOIN class c ON sub.class_id = c.id
  JOIN school sc ON c.school_id = sc.id
  WHERE ct.name = 'Tools, Machines and Processes'
    AND sub.name = 'Basic Technology'
    AND c.name = 'JSS3' AND c.academic_year = '2020/2021'
    AND sc.name = 'AM Blessed Model Academy'
)
INSERT INTO topic (theme_id, name)
SELECT theme.theme_id, v.name
FROM theme
CROSS JOIN (
  VALUES
    ('woodwork projects'),
    ('metalwork projects'),
    ('soldering & brazing'),
    ('machine motions'),
    ('rotary motion')
) AS v(name)
ON CONFLICT DO NOTHING;

-- ==============================
-- Subject: Social Studies
-- ==============================

-- Insert themes for Social Studies
WITH s AS (
  SELECT sub.id AS subject_id
  FROM subject sub
  JOIN class c ON sub.class_id = c.id
  JOIN school sc ON c.school_id = sc.id
  WHERE sub.name = 'Social Studies'
    AND c.name = 'JSS3' AND c.academic_year = '2020/2021'
    AND sc.name = 'AM Blessed Model Academy'
)
INSERT INTO theme (subject_id, name)
SELECT subject_id, theme
FROM s
CROSS JOIN (
  VALUES
    ('Fundamental of Social Studies'),
    ('Family as the Basic Unit of Society'),
    ('Culture and Social Values'),
    ('Social and Health Issues')
) AS t(theme)
ON CONFLICT DO NOTHING;

-- Topics for Fundamental of Social Studies
WITH theme AS (
  SELECT ct.id AS theme_id
  FROM theme ct
  JOIN subject sub ON ct.subject_id = sub.id
  JOIN class c ON sub.class_id = c.id
  JOIN school sc ON c.school_id = sc.id
  WHERE ct.name = 'Fundamental of Social Studies'
    AND sub.name = 'Social Studies'
    AND c.name = 'JSS3' AND c.academic_year = '2020/2021'
    AND sc.name = 'AM Blessed Model Academy'
)
INSERT INTO topic (theme_id, name)
SELECT theme.theme_id, 'contents of social studies'
FROM theme
ON CONFLICT DO NOTHING;

-- Topics for Family as the Basic Unit of Society
WITH theme AS (
  SELECT ct.id AS theme_id
  FROM theme ct
  JOIN subject sub ON ct.subject_id = sub.id
  JOIN class c ON sub.class_id = c.id
  JOIN school sc ON c.school_id = sc.id
  WHERE ct.name = 'Family as the Basic Unit of Society'
    AND sub.name = 'Social Studies'
    AND c.name = 'JSS3' AND c.academic_year = '2020/2021'
    AND sc.name = 'AM Blessed Model Academy'
)
INSERT INTO topic (theme_id, name)
SELECT theme.theme_id, 'roles of extended family members in child development'
FROM theme
ON CONFLICT DO NOTHING;

-- Topics for Culture and Social Values
WITH theme AS (
  SELECT ct.id AS theme_id
  FROM theme ct
  JOIN subject sub ON ct.subject_id = sub.id
  JOIN class c ON sub.class_id = c.id
  JOIN school sc ON c.school_id = sc.id
  WHERE ct.name = 'Culture and Social Values'
    AND sub.name = 'Social Studies'
    AND c.name = 'JSS3' AND c.academic_year = '2020/2021'
    AND sc.name = 'AM Blessed Model Academy'
)
INSERT INTO topic (theme_id, name)
SELECT theme.theme_id, v.name
FROM theme
CROSS JOIN (
  VALUES
    ('human trafficking'),
    ('preventing human trafficking'),
    ('harmful traditional practices'),
    ('promoting peaceful living')
) AS v(name)
ON CONFLICT DO NOTHING;

-- Topics for Social and Health Issues
WITH theme AS (
  SELECT ct.id AS theme_id
  FROM theme ct
  JOIN subject sub ON ct.subject_id = sub.id
  JOIN class c ON sub.class_id = c.id
  JOIN school sc ON c.school_id = sc.id
  WHERE ct.name = 'Social and Health Issues'
    AND sub.name = 'Social Studies'
    AND c.name = 'JSS3' AND c.academic_year = '2020/2021'
    AND sc.name = 'AM Blessed Model Academy'
)
INSERT INTO topic (theme_id, name)
SELECT theme.theme_id, v.name
FROM theme
CROSS JOIN (
  VALUES
    ('social conflicts'),
    ('managing & resolving conflicts'),
    ('controlling cultism'),
    ('preventing drug trafficking')
) AS v(name)
ON CONFLICT DO NOTHING;

-- ==============================
-- Subject: Christian Religious Studies
-- ==============================

-- Insert themes for Christian Religious Studies
WITH s AS (
  SELECT sub.id AS subject_id
  FROM subject sub
  JOIN class c ON sub.class_id = c.id
  JOIN school sc ON c.school_id = sc.id
  WHERE sub.name = 'Christian Religious Studies'
    AND c.name = 'JSS3' AND c.academic_year = '2020/2021'
    AND sc.name = 'AM Blessed Model Academy'
)
INSERT INTO theme (subject_id, name)
SELECT subject_id, theme
FROM s
CROSS JOIN (
  VALUES
    ('The Beginning of the Church'),
    ('The Ministry of the Apostles'),
    ('The Christian Church Today')
) AS t(theme)
ON CONFLICT DO NOTHING;

-- Topics for The Beginning of the Church
WITH theme AS (
  SELECT ct.id AS theme_id
  FROM theme ct
  JOIN subject sub ON ct.subject_id = sub.id
  JOIN class c ON sub.class_id = c.id
  JOIN school sc ON c.school_id = sc.id
  WHERE ct.name = 'The Beginning of the Church'
    AND sub.name = 'Christian Religious Studies'
    AND c.name = 'JSS3' AND c.academic_year = '2020/2021'
    AND sc.name = 'AM Blessed Model Academy'
)
INSERT INTO topic (theme_id, name)
SELECT theme.theme_id, v.name
FROM theme
CROSS JOIN (
  VALUES
    ('promise of the Holy Spirit'),
    ('fellowship in the early church'),
    ('persecution of early believers')
) AS v(name)
ON CONFLICT DO NOTHING;

-- Topics for The Ministry of the Apostles
WITH theme AS (
  SELECT ct.id AS theme_id
  FROM theme ct
  JOIN subject sub ON ct.subject_id = sub.id
  JOIN class c ON sub.class_id = c.id
  JOIN school sc ON c.school_id = sc.id
  WHERE ct.name = 'The Ministry of the Apostles'
    AND sub.name = 'Christian Religious Studies'
    AND c.name = 'JSS3' AND c.academic_year = '2020/2021'
    AND sc.name = 'AM Blessed Model Academy'
)
INSERT INTO topic (theme_id, name)
SELECT theme.theme_id, v.name
FROM theme
CROSS JOIN (
  VALUES
    ('ministry of Peter'),
    ('ministry of Apostle Paul'),
    ('Paul''s first missionary journey')
) AS v(name)
ON CONFLICT DO NOTHING;

-- Topics for The Christian Church Today
WITH theme AS (
  SELECT ct.id AS theme_id
  FROM theme ct
  JOIN subject sub ON ct.subject_id = sub.id
  JOIN class c ON sub.class_id = c.id
  JOIN school sc ON c.school_id = sc.id
  WHERE ct.name = 'The Christian Church Today'
    AND sub.name = 'Christian Religious Studies'
    AND c.name = 'JSS3' AND c.academic_year = '2020/2021'
    AND sc.name = 'AM Blessed Model Academy'
)
INSERT INTO topic (theme_id, name)
SELECT theme.theme_id, v.name
FROM theme
CROSS JOIN (
  VALUES
    ('unity among Christians'),
    ('Christian living')
) AS v(name)
ON CONFLICT DO NOTHING;

-- ==============================
-- Subject: Security Education
-- ==============================

-- Insert theme for Security Education
WITH s AS (
  SELECT sub.id AS subject_id
  FROM subject sub
  JOIN class c ON sub.class_id = c.id
  JOIN school sc ON c.school_id = sc.id
  WHERE sub.name = 'Security Education'
    AND c.name = 'JSS3' AND c.academic_year = '2020/2021'
    AND sc.name = 'AM Blessed Model Academy'
)
INSERT INTO theme (subject_id, name)
SELECT subject_id, 'Common Crimes and Security Management III'
FROM s
ON CONFLICT DO NOTHING;

-- Topics for Common Crimes and Security Management III
WITH theme AS (
  SELECT ct.id AS theme_id
  FROM theme ct
  JOIN subject sub ON ct.subject_id = sub.id
  JOIN class c ON sub.class_id = c.id
  JOIN school sc ON c.school_id = sc.id
  WHERE ct.name = 'Common Crimes and Security Management III'
    AND sub.name = 'Security Education'
    AND c.name = 'JSS3' AND c.academic_year = '2020/2021'
    AND sc.name = 'AM Blessed Model Academy'
)
INSERT INTO topic (theme_id, name)
SELECT theme.theme_id, v.name
FROM theme
CROSS JOIN (
  VALUES
    ('common crimes and associated punishment'),
    ('crimes and National Security')
) AS v(name)
ON CONFLICT DO NOTHING;

-- ==============================
-- Subject: Civic Education (Basic)
-- ==============================

-- Insert themes for Civic Education (Basic)
WITH s AS (
  SELECT sub.id AS subject_id
  FROM subject sub
  JOIN class c ON sub.class_id = c.id
  JOIN school sc ON c.school_id = sc.id
  WHERE sub.name = 'Civic Education (Basic)'
    AND c.name = 'JSS3' AND c.academic_year = '2020/2021'
    AND sc.name = 'AM Blessed Model Academy'
)
INSERT INTO theme (subject_id, name)
SELECT subject_id, theme
FROM s
CROSS JOIN (
  VALUES
    ('Citizenship'),
    ('Our Values'),
    ('Democracy')
) AS t(theme)
ON CONFLICT DO NOTHING;

-- Topics for Citizenship
WITH theme AS (
  SELECT ct.id AS theme_id
  FROM theme ct
  JOIN subject sub ON ct.subject_id = sub.id
  JOIN class c ON sub.class_id = c.id
  JOIN school sc ON c.school_id = sc.id
  WHERE ct.name = 'Citizenship'
    AND sub.name = 'Civic Education (Basic)'
    AND c.name = 'JSS3' AND c.academic_year = '2020/2021'
    AND sc.name = 'AM Blessed Model Academy'
)
INSERT INTO topic (theme_id, name)
SELECT theme.theme_id, v.name
FROM theme
CROSS JOIN (
  VALUES
    ('The Constitution'),
    ('Supremacy of the Constitution')
) AS v(name)
ON CONFLICT DO NOTHING;

-- Topics for Our Values
WITH theme AS (
  SELECT ct.id AS theme_id
  FROM theme ct
  JOIN subject sub ON ct.subject_id = sub.id
  JOIN class c ON sub.class_id = c.id
  JOIN school sc ON c.school_id = sc.id
  WHERE ct.name = 'Our Values'
    AND sub.name = 'Civic Education (Basic)'
    AND c.name = 'JSS3' AND c.academic_year = '2020/2021'
    AND sc.name = 'AM Blessed Model Academy'
)
INSERT INTO topic (theme_id, name)
SELECT theme.theme_id, v.name
FROM theme
CROSS JOIN (
  VALUES
    ('National Values: Right Attitude to Work'),
    ('Negative Behaviour')
) AS v(name)
ON CONFLICT DO NOTHING;

-- Topics for Democracy
WITH theme AS (
  SELECT ct.id AS theme_id
  FROM theme ct
  JOIN subject sub ON ct.subject_id = sub.id
  JOIN class c ON sub.class_id = c.id
  JOIN school sc ON c.school_id = sc.id
  WHERE ct.name = 'Democracy'
    AND sub.name = 'Civic Education (Basic)'
    AND c.name = 'JSS3' AND c.academic_year = '2020/2021'
    AND sc.name = 'AM Blessed Model Academy'
)
INSERT INTO topic (theme_id, name)
SELECT theme.theme_id, v.name
FROM theme
CROSS JOIN (
  VALUES
    ('Elections and Electoral Bodies in Nigeria'),
    ('Democratic Process')
) AS v(name)
ON CONFLICT DO NOTHING;

-- ==============================
-- Subject: Home Economics
-- ==============================

-- Insert themes for Home Economics
WITH s AS (
  SELECT sub.id AS subject_id
  FROM subject sub
  JOIN class c ON sub.class_id = c.id
  JOIN school sc ON c.school_id = sc.id
  WHERE sub.name = 'Home Economics'
    AND c.name = 'JSS3' AND c.academic_year = '2020/2021'
    AND sc.name = 'AM Blessed Model Academy'
)
INSERT INTO theme (subject_id, name)
SELECT subject_id, theme
FROM s
CROSS JOIN (
  VALUES
    ('Family Living and Resource Management'),
    ('Clothing and Textile'),
    ('Food and Nutrition')
) AS t(theme)
ON CONFLICT DO NOTHING;

-- Topics for Family Living and Resource Management
WITH theme AS (
  SELECT ct.id AS theme_id
  FROM theme ct
  JOIN subject sub ON ct.subject_id = sub.id
  JOIN class c ON sub.class_id = c.id
  JOIN school sc ON c.school_id = sc.id
  WHERE ct.name = 'Family Living and Resource Management'
    AND sub.name = 'Home Economics'
    AND c.name = 'JSS3' AND c.academic_year = '2020/2021'
    AND sc.name = 'AM Blessed Model Academy'
)
INSERT INTO topic (theme_id, name)
SELECT theme.theme_id, v.name
FROM theme
CROSS JOIN (
  VALUES
    ('Consumer Challenges and Rights'),
    ('Child Development and Care')
) AS v(name)
ON CONFLICT DO NOTHING;

-- Topics for Clothing and Textile
WITH theme AS (
  SELECT ct.id AS theme_id
  FROM theme ct
  JOIN subject sub ON ct.subject_id = sub.id
  JOIN class c ON sub.class_id = c.id
  JOIN school sc ON c.school_id = sc.id
  WHERE ct.name = 'Clothing and Textile'
    AND sub.name = 'Home Economics'
    AND c.name = 'JSS3' AND c.academic_year = '2020/2021'
    AND sc.name = 'AM Blessed Model Academy'
)
INSERT INTO topic (theme_id, name)
SELECT theme.theme_id, v.name
FROM theme
CROSS JOIN (
  VALUES
    ('Textiles—types, properties, production, uses and care'),
    ('Sewing machine and garment construction processes')
) AS v(name)
ON CONFLICT DO NOTHING;

-- Topics for Food and Nutrition
WITH theme AS (
  SELECT ct.id AS theme_id
  FROM theme ct
  JOIN subject sub ON ct.subject_id = sub.id
  JOIN class c ON sub.class_id = c.id
  JOIN school sc ON c.school_id = sc.id
  WHERE ct.name = 'Food and Nutrition'
    AND sub.name = 'Home Economics'
    AND c.name = 'JSS3' AND c.academic_year = '2020/2021'
    AND sc.name = 'AM Blessed Model Academy'
)
INSERT INTO topic (theme_id, name)
SELECT theme.theme_id, v.name
FROM theme
CROSS JOIN (
  VALUES
    ('Food Hygiene and Safety'),
    ('Preparation, Packaging and Marketing of Food Items'),
    ('Responsible Food Management')
) AS v(name)
ON CONFLICT DO NOTHING;

-- ==============================
-- Subject: Agriculture
-- ==============================

-- Insert theme for Agriculture
WITH s AS (
  SELECT sub.id AS subject_id
  FROM subject sub
  JOIN class c ON sub.class_id = c.id
  JOIN school sc ON c.school_id = sc.id
  WHERE sub.name = 'Agriculture'
    AND c.name = 'JSS3' AND c.academic_year = '2020/2021'
    AND sc.name = 'AM Blessed Model Academy'
)
INSERT INTO theme (subject_id, name)
SELECT subject_id, 'Produce Packaging and Marketing'
FROM s
ON CONFLICT DO NOTHING;

-- Topics for Produce Packaging and Marketing
WITH theme AS (
  SELECT ct.id AS theme_id
  FROM theme ct
  JOIN subject sub ON ct.subject_id = sub.id
  JOIN class c ON sub.class_id = c.id
  JOIN school sc ON c.school_id = sc.id
  WHERE ct.name = 'Produce Packaging and Marketing'
    AND sub.name = 'Agriculture'
    AND c.name = 'JSS3' AND c.academic_year = '2020/2021'
    AND sc.name = 'AM Blessed Model Academy'
)
INSERT INTO topic (theme_id, name)
SELECT theme.theme_id, v.name
FROM theme
CROSS JOIN (
  VALUES
    ('Packaging Criteria'),
    ('Pricing and Advertising'),
    ('Records and Book Keeping'),
    ('Agriculture in Stock Exchange'),
    ('Export Promotion in Agriculture')
) AS v(name)
ON CONFLICT DO NOTHING;

-- ==============================
-- Subject: Cultural And Creative Arts
-- ==============================

-- Insert themes for Cultural And Creative Arts
WITH s AS (
  SELECT sub.id AS subject_id
  FROM subject sub
  JOIN class c ON sub.class_id = c.id
  JOIN school sc ON c.school_id = sc.id
  WHERE sub.name = 'Cultural And Creative Arts'
    AND c.name = 'JSS3' AND c.academic_year = '2020/2021'
    AND sc.name = 'AM Blessed Model Academy'
)
INSERT INTO theme (subject_id, name)
SELECT subject_id, theme
FROM s
CROSS JOIN (
  VALUES
    ('Arts and Crafts'),
    ('Performing Arts & Entertainment'),
    ('Patriotism')
) AS t(theme)
ON CONFLICT DO NOTHING;

-- Topics for Arts and Crafts
WITH theme AS (
  SELECT ct.id AS theme_id
  FROM theme ct
  JOIN subject sub ON ct.subject_id = sub.id
  JOIN class c ON sub.class_id = c.id
  JOIN school sc ON c.school_id = sc.id
  WHERE ct.name = 'Arts and Crafts'
    AND sub.name = 'Cultural And Creative Arts'
    AND c.name = 'JSS3' AND c.academic_year = '2020/2021'
    AND sc.name = 'AM Blessed Model Academy'
)
INSERT INTO topic (theme_id, name)
SELECT theme.theme_id, v.name
FROM theme
CROSS JOIN (
  VALUES
    ('Types and Features of Nigerian Traditional Arts'),
    ('Contemporary Nigerian Art and Artists'),
    ('Meaning and Use of Motifs'),
    ('Exhibition and Display Techniques'),
    ('Lettering'),
    ('Construction and Design'),
    ('Marketing of Art Works'),
    ('Introduction to Embroidery'),
    ('Knitting'),
    ('Crocheting'),
    ('Batik Work')
) AS v(name)
ON CONFLICT DO NOTHING;

-- Topics for Performing Arts & Entertainment
WITH theme AS (
  SELECT ct.id AS theme_id
  FROM theme ct
  JOIN subject sub ON ct.subject_id = sub.id
  JOIN class c ON sub.class_id = c.id
  JOIN school sc ON c.school_id = sc.id
  WHERE ct.name = 'Performing Arts & Entertainment'
    AND sub.name = 'Cultural And Creative Arts'
    AND c.name = 'JSS3' AND c.academic_year = '2020/2021'
    AND sc.name = 'AM Blessed Model Academy'
)
INSERT INTO topic (theme_id, name)
SELECT theme.theme_id, v.name
FROM theme
CROSS JOIN (
  VALUES
    ('Uses of Music'),
    ('Creating Music/Solfa Notation values'),
    ('Drama and the development of rural communities'),
    ('Opportunities for career dramatists'),
    ('Process of Choreography'),
    ('Prospects of Studying dance in Nigeria')
) AS v(name)
ON CONFLICT DO NOTHING;

-- Topics for Patriotism
WITH theme AS (
  SELECT ct.id AS theme_id
  FROM theme ct
  JOIN subject sub ON ct.subject_id = sub.id
  JOIN class c ON sub.class_id = c.id
  JOIN school sc ON c.school_id = sc.id
  WHERE ct.name = 'Patriotism'
    AND sub.name = 'Cultural And Creative Arts'
    AND c.name = 'JSS3' AND c.academic_year = '2020/2021'
    AND sc.name = 'AM Blessed Model Academy'
)
INSERT INTO topic (theme_id, name)
SELECT theme.theme_id, 'Unity'
FROM theme
ON CONFLICT DO NOTHING;

-- ==============================
-- Subject: French Language
-- ==============================

-- Insert themes for French Language
WITH s AS (
  SELECT sub.id AS subject_id
  FROM subject sub
  JOIN class c ON sub.class_id = c.id
  JOIN school sc ON c.school_id = sc.id
  WHERE sub.name = 'French Language'
    AND c.name = 'JSS3' AND c.academic_year = '2020/2021'
    AND sc.name = 'AM Blessed Model Academy'
)
INSERT INTO theme (subject_id, name)
SELECT subject_id, theme
FROM s
CROSS JOIN (
  VALUES
    ('Identité/Identification'),
    ('Environnement Immédiat'),
    ('Environnement Immédiat (Suite)'),
    ('Environnement Immédiat (Suite II)'),
    ('Activités Humaines'),
    ('Activités Humaines (Suite)'),
    ('Activités Humaines (Suite II)')
) AS t(theme)
ON CONFLICT DO NOTHING;

-- Topics for Identité/Identification
WITH theme AS (
  SELECT ct.id AS theme_id
  FROM theme ct
  JOIN subject sub ON ct.subject_id = sub.id
  JOIN class c ON sub.class_id = c.id
  JOIN school sc ON c.school_id = sc.id
  WHERE ct.name = 'Identité/Identification'
    AND sub.name = 'French Language'
    AND c.name = 'JSS3' AND c.academic_year = '2020/2021'
    AND sc.name = 'AM Blessed Model Academy'
)
INSERT INTO topic (theme_id, name)
SELECT theme.theme_id, v.name
FROM theme
CROSS JOIN (
  VALUES
    ('Parler des professions variees'),
    ('Decrire les qualites admirables'),
    ('Parler des gens que l''on admire beaucoup')
) AS v(name)
ON CONFLICT DO NOTHING;

-- Topics for Environnement Immédiat
WITH theme AS (
  SELECT ct.id AS theme_id
  FROM theme ct
  JOIN subject sub ON ct.subject_id = sub.id
  JOIN class c ON sub.class_id = c.id
  JOIN school sc ON c.school_id = sc.id
  WHERE ct.name = 'Environnement Immédiat'
    AND sub.name = 'French Language'
    AND c.name = 'JSS3' AND c.academic_year = '2020/2021'
    AND sc.name = 'AM Blessed Model Academy'
)
INSERT INTO topic (theme_id, name)
SELECT theme.theme_id, v.name
FROM theme
CROSS JOIN (
  VALUES
    ('Nommer les maladies'),
    ('Discuter les causes'),
    ('Parler des populations affectees'),
    ('Dire l''importance de l''hygiene')
) AS v(name)
ON CONFLICT DO NOTHING;

-- Topics for Environnement Immédiat (Suite)
WITH theme AS (
  SELECT ct.id AS theme_id
  FROM theme ct
  JOIN subject sub ON ct.subject_id = sub.id
  JOIN class c ON sub.class_id = c.id
  JOIN school sc ON c.school_id = sc.id
  WHERE ct.name = 'Environnement Immédiat (Suite)'
    AND sub.name = 'French Language'
    AND c.name = 'JSS3' AND c.academic_year = '2020/2021'
    AND sc.name = 'AM Blessed Model Academy'
)
INSERT INTO topic (theme_id, name)
SELECT theme.theme_id, 'Parler des professionnels de la sante'
FROM theme
ON CONFLICT DO NOTHING;

-- Topics for Environnement Immédiat (Suite II)
WITH theme AS (
  SELECT ct.id AS theme_id
  FROM theme ct
  JOIN subject sub ON ct.subject_id = sub.id
  JOIN class c ON sub.class_id = c.id
  JOIN school sc ON c.school_id = sc.id
  WHERE ct.name = 'Environnement Immédiat (Suite II)'
    AND sub.name = 'French Language'
    AND c.name = 'JSS3' AND c.academic_year = '2020/2021'
    AND sc.name = 'AM Blessed Model Academy'
)
INSERT INTO topic (theme_id, name)
SELECT theme.theme_id, 'Parler de : la pharmacie, l''hopital, chez le dentiste'
FROM theme
ON CONFLICT DO NOTHING;

-- Topics for Activités Humaines
WITH theme AS (
  SELECT ct.id AS theme_id
  FROM theme ct
  JOIN subject sub ON ct.subject_id = sub.id
  JOIN class c ON sub.class_id = c.id
  JOIN school sc ON c.school_id = sc.id
  WHERE ct.name = 'Activités Humaines'
    AND sub.name = 'French Language'
    AND c.name = 'JSS3' AND c.academic_year = '2020/2021'
    AND sc.name = 'AM Blessed Model Academy'
)
INSERT INTO topic (theme_id, name)
SELECT theme.theme_id, 'Decrire ce qu''on fait tous les jours'
FROM theme
ON CONFLICT DO NOTHING;

-- Topics for Activités Humaines (Suite)
WITH theme AS (
  SELECT ct.id AS theme_id
  FROM theme ct
  JOIN subject sub ON ct.subject_id = sub.id
  JOIN class c ON sub.class_id = c.id
  JOIN school sc ON c.school_id = sc.id
  WHERE ct.name = 'Activités Humaines (Suite)'
    AND sub.name = 'French Language'
    AND c.name = 'JSS3' AND c.academic_year = '2020/2021'
    AND sc.name = 'AM Blessed Model Academy'
)
INSERT INTO topic (theme_id, name)
SELECT theme.theme_id, 'Raconter ce qui s''est passe'
FROM theme
ON CONFLICT DO NOTHING;

-- Topics for Activités Humaines (Suite II)
WITH theme AS (
  SELECT ct.id AS theme_id
  FROM theme ct
  JOIN subject sub ON ct.subject_id = sub.id
  JOIN class c ON sub.class_id = c.id
  JOIN school sc ON c.school_id = sc.id
  WHERE ct.name = 'Activités Humaines (Suite II)'
    AND sub.name = 'French Language'
    AND c.name = 'JSS3' AND c.academic_year = '2020/2021'
    AND sc.name = 'AM Blessed Model Academy'
)
INSERT INTO topic (theme_id, name)
SELECT theme.theme_id, v.name
FROM theme
CROSS JOIN (
  VALUES
    ('Ecrire une lettre d''amitie (informelle)'),
    ('Telephoner')
) AS v(name)
ON CONFLICT DO NOTHING;

-- End of script
\else
\echo 'Skipping JSS3 theme/topic seeding because include_topics=false. Re-run with -v include_topics=true when ready to load them.'
\endif
