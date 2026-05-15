{{ config(unique_key='customer_id') }}

select
    customer_id,
    current_timestamp() as as_of_timestamp,
    '{{ invocation_id }}' as run_id,
    count(*) as orders_90d,
    sum(net_amount) as revenue_90d,
    avg(net_amount) as avg_order_value_90d
from {{ ref('fact_revenue') }}
where order_date >= dateadd(day, -90, current_date())
group by customer_id
