{% snapshot customer_scd2 %}

{{
  config(
    target_schema='snapshots',
    unique_key='customer_id',
    strategy='check',
    check_cols=['customer_name', 'email', 'country_code', 'customer_segment']
  )
}}

select * from {{ ref('stg_erp_customers') }}

{% endsnapshot %}
