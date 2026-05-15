select
    payload:customer_id::string as customer_id,
    payload:customer_name::string as customer_name,
    payload:email::string as email,
    payload:country_code::string as country_code,
    payload:customer_segment::string as customer_segment,
    payload:updated_at::timestamp_ntz as updated_at,
    ingested_at,
    source_system,
    batch_id
from {{ source('raw', 'RAW_ERP_CUSTOMERS') }}
where payload:customer_id::string is not null
