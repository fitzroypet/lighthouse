-- 03_readonly_role.sql
-- Create a least-privilege role for agent access.
-- Replace the password below before running.
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'lighthouse_ro') THEN
    CREATE ROLE lighthouse_ro LOGIN PASSWORD 'replace_me_with_a_long_random_pw' NOSUPERUSER NOCREATEDB;
  END IF;
END
$$;

GRANT CONNECT ON DATABASE lighthouse TO lighthouse_ro;
GRANT USAGE ON SCHEMA public TO lighthouse_ro;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO lighthouse_ro;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO lighthouse_ro;
