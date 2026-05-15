{{ config(unique_key='customer_order_hk') }}

select
    {{ dbt_utils.generate_surrogate_key(['o.order_id', 'o.customer_id']) }} as customer_order_hk,
    {{ dbt_utils.generate_surrogate_key(['o.order_id']) }} as order_hk,
    {{ dbt_utils.generate_surrogate_key(['o.customer_id']) }} as customer_hk,
    o.ingested_at as load_datetime,
    'ERP' as record_source
from {{ ref('stg_erp_orders') }} as o
where o.customer_id is not null
