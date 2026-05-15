# ADR 0002: Secrets and Least-Privilege Service Roles

## Status
Accepted

## Context
Production data platforms should not use human admin credentials or password-based automation. Leaked credentials are a common failure mode.

## Decision
Use dedicated service users, key-pair authentication, GitHub/Airflow/enterprise secret stores and least-privilege Snowflake roles. `ACCOUNTADMIN` is only used for bootstrap administration and never for application pipelines.

## Consequences
- Lower blast radius for ingestion and transformation workloads.
- Easier credential rotation and auditability.
- More setup effort is required during environment bootstrap.
