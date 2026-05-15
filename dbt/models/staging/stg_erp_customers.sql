select
    coalesce(payload:customer_id::string, payload:CUSTOMER_ID::string) as customer_id,
    coalesce(payload:customer_name::string, payload:CUSTOMER_NAME::string) as customer_name,
    coalesce(payload:email::string, payload:EMAIL::string) as email,
    coalesce(payload:country_code::string, payload:COUNTRY_CODE::string) as country_code,
    coalesce(payload:customer_segment::string, payload:CUSTOMER_SEGMENT::string) as customer_segment,
    try_to_timestamp_ntz(coalesce(payload:updated_at::string, payload:UPDATED_AT::string)) as updated_at,
    ingested_at,
    source_system,
    batch_id
from {{ source('raw', 'RAW_ERP_CUSTOMERS') }}
qualify row_number() over (partition by coalesce(payload:customer_id::string, payload:CUSTOMER_ID::string) order by ingested_at desc) = 1
