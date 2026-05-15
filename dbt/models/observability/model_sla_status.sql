{{ config(materialized='view', tags=['observability']) }}

select
    'fact_revenue' as model_name,
    max(order_date) as latest_business_date,
    datediff('day', max(order_date), current_date()) as data_lag_days,
    case when datediff('day', max(order_date), current_date()) > 1 then 'BREACH' else 'OK' end as sla_status,
    current_timestamp() as evaluated_at
from {{ ref('fact_revenue') }}
