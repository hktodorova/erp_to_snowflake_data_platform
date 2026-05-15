select
    c.customer_id,
    s.customer_name,
    s.email,
    s.country_code,
    s.customer_segment,
    s.updated_at
from {{ ref('hub_customer') }} c
left join {{ ref('sat_customer_details') }} s
    on c.customer_hk = s.customer_hk
qualify row_number() over (partition by c.customer_id order by s.load_datetime desc) = 1
