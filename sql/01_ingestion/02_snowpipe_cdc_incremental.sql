-- Production-style ingestion layer: stages, Snowpipe, streams, metadata and CDC merge pattern.
-- Naming is intentionally aligned with dbt sources.yml and the bootstrap SQL.
USE ROLE ROLE_DATA_ENGINEER;
USE DATABASE ENTERPRISE_DWH;

CREATE SCHEMA IF NOT EXISTS RAW;
CREATE SCHEMA IF NOT EXISTS STAGING;

CREATE TABLE IF NOT EXISTS RAW.FILE_INGESTION_AUDIT (
    file_name STRING,
    source_system STRING,
    stage_name STRING,
    load_started_at TIMESTAMP_NTZ,
    load_completed_at TIMESTAMP_NTZ,
    row_count NUMBER,
    checksum STRING,
    status STRING,
    error_message STRING
);

CREATE TABLE IF NOT EXISTS RAW.RAW_ERP_ORDERS (
    payload VARIANT,
    source_file_name STRING,
    source_row_number NUMBER,
    source_system STRING DEFAULT 'ERP',
    batch_id STRING,
    ingested_at TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);

CREATE TABLE IF NOT EXISTS RAW.RAW_ERP_CUSTOMERS (
    payload VARIANT,
    source_file_name STRING,
    source_row_number NUMBER,
    source_system STRING DEFAULT 'ERP',
    batch_id STRING,
    ingested_at TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);

CREATE OR REPLACE STREAM RAW.RAW_ERP_ORDERS_STREAM ON TABLE RAW.RAW_ERP_ORDERS APPEND_ONLY = TRUE;
CREATE OR REPLACE STREAM RAW.RAW_ERP_CUSTOMERS_STREAM ON TABLE RAW.RAW_ERP_CUSTOMERS APPEND_ONLY = TRUE;

CREATE OR REPLACE PIPE RAW.PIPE_ERP_ORDERS_AUTO_INGEST
  AUTO_INGEST = TRUE
AS
COPY INTO RAW.RAW_ERP_ORDERS (payload, source_file_name, source_row_number, batch_id)
FROM (
    SELECT OBJECT_CONSTRUCT_KEEP_NULL(*), METADATA$FILENAME, METADATA$FILE_ROW_NUMBER, UUID_STRING()
    FROM @RAW.ERP_EXTERNAL_STAGE/orders/
)
FILE_FORMAT = (FORMAT_NAME = RAW.CSV_WITH_HEADER)
ON_ERROR = 'CONTINUE';

CREATE OR REPLACE PIPE RAW.PIPE_ERP_CUSTOMERS_AUTO_INGEST
  AUTO_INGEST = TRUE
AS
COPY INTO RAW.RAW_ERP_CUSTOMERS (payload, source_file_name, source_row_number, batch_id)
FROM (
    SELECT OBJECT_CONSTRUCT_KEEP_NULL(*), METADATA$FILENAME, METADATA$FILE_ROW_NUMBER, UUID_STRING()
    FROM @RAW.ERP_EXTERNAL_STAGE/customers/
)
FILE_FORMAT = (FORMAT_NAME = RAW.CSV_WITH_HEADER)
ON_ERROR = 'CONTINUE';

CREATE TABLE IF NOT EXISTS STAGING.ERP_ORDERS_CDC (
    order_id STRING,
    customer_id STRING,
    order_date DATE,
    order_status STRING,
    net_amount NUMBER(18,2),
    currency STRING,
    source_file_name STRING,
    ingested_at TIMESTAMP_NTZ,
    record_hash STRING
);

CREATE OR REPLACE TASK RAW.TASK_MERGE_ERP_ORDERS_CDC
  WAREHOUSE = WH_INGEST_XS
  SCHEDULE = '5 MINUTE'
  WHEN SYSTEM$STREAM_HAS_DATA('RAW.RAW_ERP_ORDERS_STREAM')
AS
MERGE INTO STAGING.ERP_ORDERS_CDC tgt
USING (
    SELECT
        COALESCE(payload:order_id::STRING, payload:ORDER_ID::STRING) AS order_id,
        COALESCE(payload:customer_id::STRING, payload:CUSTOMER_ID::STRING) AS customer_id,
        TRY_TO_DATE(COALESCE(payload:order_date::STRING, payload:ORDER_DATE::STRING)) AS order_date,
        COALESCE(payload:status::STRING, payload:ORDER_STATUS::STRING, payload:order_status::STRING) AS order_status,
        TRY_TO_DECIMAL(COALESCE(payload:net_amount::STRING, payload:NET_AMOUNT::STRING), 18, 2) AS net_amount,
        COALESCE(payload:currency::STRING, payload:CURRENCY::STRING, 'CHF') AS currency,
        source_file_name,
        ingested_at,
        SHA2(TO_JSON(payload), 256) AS record_hash
    FROM RAW.RAW_ERP_ORDERS_STREAM
) src
ON tgt.order_id = src.order_id AND tgt.record_hash = src.record_hash
WHEN NOT MATCHED THEN INSERT (
    order_id, customer_id, order_date, order_status, net_amount, currency, source_file_name, ingested_at, record_hash
) VALUES (
    src.order_id, src.customer_id, src.order_date, src.order_status, src.net_amount, src.currency, src.source_file_name, src.ingested_at, src.record_hash
);
