-- To avoid issues with CREATE OR ALTER, suspend all of the tasks from root to child
-- ALTER TASK IF EXISTS ensures this file can execute on first run each time a task is added
ALTER TASK IF EXISTS run_tasty_bytes_subset SUSPEND;
ALTER TASK IF EXISTS run_tasty_bytes_full SUSPEND;
ALTER TASK IF EXISTS test_tasty_bytes SUSPEND;

-- This would be an example scenario where you have a subset of the DAG that needs to be available early for business needs:
CREATE OR ALTER TASK run_tasty_bytes_subset
  WAREHOUSE = tasty_bytes_dbt_wh
  SCHEDULE = '2 MINUTES'
  AS
      execute dbt project TASTY_BYTES_DBT_OBJECT_GH_ACTION args='run --select RAW_CUSTOMER_CUSTOMER_LOYALTY --target prod';

-- Kick off a complete run of the full project
CREATE OR ALTER TASK run_tasty_bytes_full
  WAREHOUSE = tasty_bytes_dbt_wh
  AFTER run_tasty_bytes_subset
  AS
      execute dbt project TASTY_BYTES_DBT_OBJECT_GH_ACTION args='run --target prod';

-- Run any data quality tests you've defined
CREATE OR ALTER TASK test_tasty_bytes
  WAREHOUSE = tasty_bytes_dbt_wh
  AFTER run_tasty_bytes_full
  AS
      execute dbt project TASTY_BYTES_DBT_OBJECT_GH_ACTION args='test --target prod';

-- When a task is first created or if an existing task it paused, it MUST BE RESUMED to be activated
-- The tasks must be enabled in REVERSE ORDER from child to root
ALTER TASK IF EXISTS test_tasty_bytes RESUME;
ALTER TASK IF EXISTS run_tasty_bytes_full RESUME;
ALTER TASK IF EXISTS run_tasty_bytes_subset RESUME;
