{{ config(unique_key='customer_hk') }}

select
    {{ dbt_utils.generate_surrogate_key(['customer_id']) }} as customer_hk,
    customer_id,
    min(ingested_at) as load_datetime,
    'ERP' as record_source
from {{ ref('stg_erp_customers') }}
group by customer_id
