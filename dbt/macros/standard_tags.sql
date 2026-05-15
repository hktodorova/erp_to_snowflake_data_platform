{% macro standard_query_tag() -%}
    {{ return('enterprise_snowflake_platform:' ~ target.name ~ ':' ~ invocation_id) }}
{%- endmacro %}
