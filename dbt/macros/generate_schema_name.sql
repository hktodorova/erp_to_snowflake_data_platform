{% macro generate_schema_name(custom_schema_name, node) -%}
    {#
      Production schema strategy: dbt should write exactly to the schema named by
      +schema instead of prefixing it with target.schema. This prevents accidental
      MARTS_STAGING / MARTS_RAW_VAULT schemas when target.schema is MARTS.
    #}
    {%- if custom_schema_name is none -%}
        {{ target.schema | trim }}
    {%- else -%}
        {{ custom_schema_name | trim }}
    {%- endif -%}
{%- endmacro %}
