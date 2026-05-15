-- Performance examples: clustering, query pruning and incremental mart strategy.
USE DATABASE ENTERPRISE_DWH;

ALTER TABLE IF EXISTS RAW_VAULT.SAT_CUSTOMER_DETAILS CLUSTER BY (customer_hk, valid_from);
ALTER TABLE IF EXISTS MARTS.FACT_REVENUE CLUSTER BY (order_date, customer_hk);

CREATE OR REPLACE VIEW OBSERVABILITY.V_CLUSTERING_HEALTH AS
SELECT
    table_schema,
    table_name,
    clustering_key,
    row_count,
    bytes,
    ROUND(bytes / NULLIF(row_count, 0), 2) AS bytes_per_row
FROM INFORMATION_SCHEMA.TABLES
WHERE table_schema IN ('RAW_VAULT', 'MARTS')
  AND table_type = 'BASE TABLE';
