-- 04_rls_policies.sql
-- Template RLS policies. Adjust table/column names to your ERD and run once.

-- Parents can only see results for their linked children
ALTER TABLE IF EXISTS result ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS parent_can_view_child_results ON result;
CREATE POLICY parent_can_view_child_results ON result
USING (
  EXISTS (
    SELECT 1 FROM student_parent sp
    WHERE sp.student_id = result.student_id
      AND sp.parent_user_id = current_setting('app.user_id')::bigint
  )
);

-- Teachers can only see results for their assigned classes
DROP POLICY IF EXISTS teacher_can_view_class_results ON result;
CREATE POLICY teacher_can_view_class_results ON result
USING (
  EXISTS (
    SELECT 1 FROM teacher_assignment ta
    WHERE ta.class_id = result.class_id
      AND ta.teacher_user_id = current_setting('app.user_id')::bigint
  )
);

-- Admins can see results within their school
DROP POLICY IF EXISTS admin_can_view_school_results ON result;
CREATE POLICY admin_can_view_school_results ON result
USING (
  EXISTS (
    SELECT 1 FROM app_user u
    WHERE u.id = current_setting('app.user_id')::bigint
      AND u.role = 'admin'
      AND u.school_id = result.school_id
  )
);
