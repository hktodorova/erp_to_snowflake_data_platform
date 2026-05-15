select
    o.order_id,
    o.customer_id,
    o.order_date::date as order_date,
    o.currency,
    o.net_amount,
    o.order_status,
    coalesce(c.country_code, 'unknown') as country_code,
    coalesce(c.customer_segment, 'unknown') as customer_segment    
from {{ ref('stg_erp_orders') }} o
left join {{ ref('dim_customer') }} c
    on o.customer_id = c.customer_id
where o.order_status in ('invoiced', 'shipped')
