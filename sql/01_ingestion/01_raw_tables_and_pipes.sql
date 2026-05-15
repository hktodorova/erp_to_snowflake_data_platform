use database ENTERPRISE_DWH;

create table if not exists RAW.RAW_ERP_ORDERS (
    payload variant,
    source_system string,
    batch_id string,
    ingested_at timestamp_ntz default current_timestamp()
);

create table if not exists RAW.RAW_ERP_CUSTOMERS (
    payload variant,
    source_system string,
    batch_id string,
    ingested_at timestamp_ntz default current_timestamp()
);

create table if not exists RAW.RAW_PAYMENTS (
    payload variant,
    source_system string,
    batch_id string,
    ingested_at timestamp_ntz default current_timestamp()
);

create table if not exists RAW.RAW_CLICKSTREAM (
    payload variant,
    source_system string,
    batch_id string,
    ingested_at timestamp_ntz default current_timestamp()
);

create stream if not exists RAW.RAW_ERP_ORDERS_STREAM on table RAW.RAW_ERP_ORDERS append_only = true;
create stream if not exists RAW.RAW_ERP_CUSTOMERS_STREAM on table RAW.RAW_ERP_CUSTOMERS append_only = true;

-- Example batch load:
-- copy into RAW.RAW_ERP_ORDERS(payload, source_system, batch_id)
-- from (select $1, 'ERP', metadata$filename from @RAW.ERP_STAGE/orders/);
