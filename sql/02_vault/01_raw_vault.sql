use database ENTERPRISE_DWH;

create table if not exists RAW_VAULT.HUB_CUSTOMER (
    customer_hk string not null,
    customer_id string not null,
    load_datetime timestamp_ntz not null,
    record_source string not null
);

create table if not exists RAW_VAULT.HUB_ORDER (
    order_hk string not null,
    order_id string not null,
    load_datetime timestamp_ntz not null,
    record_source string not null
);

create table if not exists RAW_VAULT.LINK_CUSTOMER_ORDER (
    customer_order_hk string not null,
    customer_hk string not null,
    order_hk string not null,
    load_datetime timestamp_ntz not null,
    record_source string not null
);

create table if not exists RAW_VAULT.SAT_CUSTOMER_DETAILS (
    customer_hk string not null,
    customer_name string,
    email string,
    country_code string,
    customer_segment string,
    hashdiff string,
    load_datetime timestamp_ntz not null,
    record_source string not null
);
