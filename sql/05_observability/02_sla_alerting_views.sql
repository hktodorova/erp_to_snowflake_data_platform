-- Observability views for freshness, quality failures, task health and cost.
USE DATABASE ENTERPRISE_DWH;
CREATE SCHEMA IF NOT EXISTS OBSERVABILITY;

CREATE OR REPLACE VIEW OBSERVABILITY.V_RAW_FRESHNESS AS
SELECT
    'RAW_ERP_ORDERS' AS dataset_name,
    MAX(ingested_at) AS last_ingested_at,
    DATEDIFF('minute', MAX(ingested_at), CURRENT_TIMESTAMP()) AS freshness_lag_minutes,
    CASE WHEN DATEDIFF('minute', MAX(ingested_at), CURRENT_TIMESTAMP()) > 60 THEN 'BREACH' ELSE 'OK' END AS sla_status
FROM RAW.RAW_ERP_ORDERS
UNION ALL
SELECT
    'RAW_ERP_CUSTOMERS',
    MAX(ingested_at),
    DATEDIFF('minute', MAX(ingested_at), CURRENT_TIMESTAMP()),
    CASE WHEN DATEDIFF('minute', MAX(ingested_at), CURRENT_TIMESTAMP()) > 60 THEN 'BREACH' ELSE 'OK' END
FROM RAW.RAW_ERP_CUSTOMERS;

CREATE OR REPLACE VIEW OBSERVABILITY.V_TASK_FAILURES_24H AS
SELECT
    name AS task_name,
    state,
    scheduled_time,
    completed_time,
    error_code,
    error_message
FROM SNOWFLAKE.ACCOUNT_USAGE.TASK_HISTORY
WHERE scheduled_time >= DATEADD('hour', -24, CURRENT_TIMESTAMP())
  AND state = 'FAILED';

CREATE OR REPLACE VIEW OBSERVABILITY.V_WAREHOUSE_COST_7D AS
SELECT
    warehouse_name,
    SUM(credits_used) AS credits_used_7d,
    COUNT(*) AS metering_intervals
FROM SNOWFLAKE.ACCOUNT_USAGE.WAREHOUSE_METERING_HISTORY
WHERE start_time >= DATEADD('day', -7, CURRENT_TIMESTAMP())
GROUP BY warehouse_name;
