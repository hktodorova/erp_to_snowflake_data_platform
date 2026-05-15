# Technical Design

## Context

The platform supports enterprise reporting and analytics over ERP, CRM, payment and e-commerce event data. The design prioritizes auditability, incremental loading, cost control and clear separation between raw data, governed history and business marts.

## Architecture Layers

1. **Landing / Raw**
   - Stores original payloads with metadata such as ingestion time, source system and batch id.
   - Enables replay after schema evolution.

2. **Raw Vault**
   - Hubs represent stable business keys: customer, order, product.
   - Links represent relationships: customer-order, order-product.
   - Satellites capture descriptive attributes and historical changes.

3. **Business Vault / Marts**
   - Business rules are applied after auditable history is captured.
   - Dimensional marts serve BI and analytics use cases.

4. **Feature Layer**
   - Feature tables include `run_id` and `as_of_timestamp` for reproducibility.

## Why Data Vault + Dimensional Modeling

Data Vault gives auditability and change tracking for ERP modernization scenarios. Dimensional marts give simpler and faster consumption for dashboards and finance users.

## Snowflake Compute Strategy

- `WH_INGEST_XS`: small, auto-suspend warehouse for COPY/Snowpipe and lightweight ingestion operations.
- `WH_TRANSFORM_M`: transformation warehouse for dbt and SQL tasks.
- `WH_ANALYTICS_S`: BI workloads and ad hoc analytics.
- `WH_ML_M`: Snowpark feature engineering and model preparation.

Workloads are isolated to prevent BI queries from being blocked by heavy transformation jobs.

## Governance

- PII columns use masking policies.
- Country-level filtering uses row access policies.
- Analysts use governed views instead of raw tables.
- Audit views expose task failures, long-running queries and access history.

## CI/CD Approach

The public portfolio version validates without Snowflake credentials:

- Python tests
- smoke test
- dbt dependency installation
- dbt parse
- SQLFluff linting
- Terraform validation

A production version would add environment-specific deployment steps and integration tests against dev Snowflake accounts.
