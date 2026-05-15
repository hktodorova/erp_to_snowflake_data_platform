select
    coalesce(payload:order_id::string, payload:ORDER_ID::string) as order_id,
    coalesce(payload:customer_id::string, payload:CUSTOMER_ID::string) as customer_id,
    try_to_timestamp_ntz(coalesce(payload:order_date::string, payload:ORDER_DATE::string)) as order_date,
    coalesce(payload:currency::string, payload:CURRENCY::string, 'CHF') as currency,
    try_to_decimal(coalesce(payload:net_amount::string, payload:NET_AMOUNT::string), 18, 2) as net_amount,
    coalesce(payload:status::string, payload:STATUS::string, payload:order_status::string, payload:ORDER_STATUS::string) as order_status,
    ingested_at,
    source_system,
    batch_id
from {{ source('raw', 'RAW_ERP_ORDERS') }}
qualify row_number() over (partition by coalesce(payload:order_id::string, payload:ORDER_ID::string) order by ingested_at desc) = 1
