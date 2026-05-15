{{ config(unique_key='order_hk') }}

select
    {{ dbt_utils.generate_surrogate_key(['order_id']) }} as order_hk,
    order_id,
    min(ingested_at) as load_datetime,
    'ERP' as record_source
from {{ ref('stg_erp_orders') }}
group by order_id
