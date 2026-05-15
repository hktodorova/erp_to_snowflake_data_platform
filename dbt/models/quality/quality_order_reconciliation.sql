{{ config(materialized='view', tags=['quality', 'reconciliation']) }}

with raw_orders as (
    select count(*) as raw_order_count
    from {{ source('raw', 'RAW_ERP_ORDERS') }}
),
staged_orders as (
    select count(*) as staged_order_count
    from {{ ref('stg_erp_orders') }}
),
mart_orders as (
    select count(*) as mart_order_count
    from {{ ref('fact_revenue') }}
)

select
    raw_order_count,
    staged_order_count,
    mart_order_count,
    raw_order_count - staged_order_count as raw_to_staging_delta,
    staged_order_count - mart_order_count as staging_to_mart_delta,
    current_timestamp() as checked_at
from raw_orders
cross join staged_orders
cross join mart_orders
