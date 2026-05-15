{% macro drop_ci_schema(schema_name) %}
    {%- if target.name not in ['ci', 'dev'] -%}
        {{ exceptions.raise_compiler_error('Refusing to drop schema outside ci/dev target. Current target: ' ~ target.name) }}
    {%- endif -%}

    {%- if not schema_name or not schema_name.upper().startswith('CI_') -%}
        {{ exceptions.raise_compiler_error('Refusing to drop non-CI schema: ' ~ schema_name) }}
    {%- endif -%}

    {% set relation = adapter.Relation.create(
        database=target.database,
        schema=schema_name,
        identifier='__dummy__'
    ) %}

    {% set sql %}
        drop schema if exists {{ relation.include(identifier=false) }} cascade
    {% endset %}

    {{ log('Dropping CI schema: ' ~ target.database ~ '.' ~ schema_name, info=true) }}
    {% do run_query(sql) %}
{% endmacro %}
