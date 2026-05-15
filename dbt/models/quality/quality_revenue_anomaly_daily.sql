{{ config(materialized='view', tags=['quality', 'anomaly']) }}

with daily_revenue as (
    select
        order_date,
        sum(net_amount) as revenue
    from {{ ref('fact_revenue') }}
    group by 1
),
scored as (
    select
        order_date,
        revenue,
        avg(revenue) over (order by order_date rows between 14 preceding and 1 preceding) as trailing_avg_revenue,
        stddev_samp(revenue) over (order by order_date rows between 14 preceding and 1 preceding) as trailing_stddev_revenue
    from daily_revenue
)

select
    order_date,
    revenue,
    trailing_avg_revenue,
    trailing_stddev_revenue,
    case
        when trailing_stddev_revenue is null or trailing_stddev_revenue = 0 then 0
        else abs(revenue - trailing_avg_revenue) / trailing_stddev_revenue
    end as revenue_z_score,
    case
        when trailing_stddev_revenue > 0 and abs(revenue - trailing_avg_revenue) / trailing_stddev_revenue >= 3 then true
        else false
    end as is_anomaly
from scored
