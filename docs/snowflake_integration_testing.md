# Snowflake integration testing

This project has two levels of validation:

1. Static/local checks: pytest, dbt parse, SQLFluff, Terraform validate.
2. Snowflake integration checks: dbt debug, dbt seed, dbt build and dbt test against a real Snowflake development environment.

## Required GitHub Actions secrets

Add these under GitHub repository Settings → Secrets and variables → Actions:

- `SNOWFLAKE_ACCOUNT`
- `SNOWFLAKE_USER`
- `SNOWFLAKE_PASSWORD`
- `SNOWFLAKE_ROLE`
- `SNOWFLAKE_DATABASE`
- `SNOWFLAKE_WAREHOUSE`

The workflow creates an isolated schema named `CI_<github_run_id>_<attempt>` and drops it at the end.

## Recommended Snowflake permissions

The CI role should have only the permissions needed for a temporary integration build:

```sql
grant usage on warehouse WH_TRANSFORM_M to role PROD_TRANSFORM;
grant usage on database ENTERPRISE_DWH to role PROD_TRANSFORM;
grant create schema on database ENTERPRISE_DWH to role PROD_TRANSFORM;
```

If your project creates objects across generated custom schemas, keep CI isolated by setting `SNOWFLAKE_SCHEMA` from the workflow and using the existing dbt schema naming macro.

## Manual local run

From the repository root:

```bash
export SNOWFLAKE_ACCOUNT="..."
export SNOWFLAKE_USER="..."
export SNOWFLAKE_PASSWORD="..."
export SNOWFLAKE_ROLE="..."
export SNOWFLAKE_DATABASE="..."
export SNOWFLAKE_WAREHOUSE="..."
export SNOWFLAKE_SCHEMA="CI_LOCAL_TEST"

cd dbt
dbt deps
dbt debug --profiles-dir . --target ci
dbt seed --profiles-dir . --target ci --full-refresh
dbt build --profiles-dir . --target ci
dbt run-operation drop_ci_schema --args "{schema_name: 'CI_LOCAL_TEST'}" --profiles-dir . --target ci
```

## Production note

Password authentication is acceptable for a demo, but key-pair authentication is better for production CI. See `security/key_pair_auth_setup.md`.
