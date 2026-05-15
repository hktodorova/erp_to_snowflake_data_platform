{{
  config(
    materialized='incremental',
    incremental_strategy='merge',
    unique_key=['customer_hk', 'hashdiff', 'load_datetime'],
    on_schema_change='sync_all_columns'
  )
}}

with source_rows as (

    select
        {{ dbt_utils.generate_surrogate_key(['customer_id']) }} as customer_hk,

        customer_name,
        email,
        country_code,
        customer_segment,
        updated_at,

        ingested_at as load_datetime,

        {{ dbt_utils.generate_surrogate_key([
            'customer_name',
            'email',
            'country_code',
            'customer_segment'
        ]) }} as hashdiff,

        {{ dbt_utils.generate_surrogate_key([
            'customer_id',
            'customer_name',
            'email',
            'country_code',
            'customer_segment',
            'ingested_at'
        ]) }} as sat_customer_details_hk,

        coalesce(source_system, 'ERP') as record_source

    from {{ ref('stg_erp_customers_history') }}

),

change_candidates as (

    select
        source_rows.*,

        lag(hashdiff) over (
            partition by customer_hk
            order by load_datetime, updated_at
        ) as previous_hashdiff

    from source_rows

),

final as (

    select
        sat_customer_details_hk,
        customer_hk,
        customer_name,
        email,
        country_code,
        customer_segment,
        updated_at,
        load_datetime,
        hashdiff,
        record_source

    from change_candidates

    where previous_hashdiff is null
       or previous_hashdiff <> hashdiff

)

select *
from final as f

{% if is_incremental() %}

where not exists (

    select 1
    from {{ this }} existing

    where existing.customer_hk = f.customer_hk
      and existing.hashdiff = f.hashdiff
      and existing.load_datetime = f.load_datetime

)

{% endif %}