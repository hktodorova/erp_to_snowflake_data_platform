# Changelog

## 2.0.0 - Production-hardening pass

- Added deterministic dbt schema naming macro to prevent accidental schema prefixing.
- Aligned sample data generator with dbt accepted values and contracts.
- Aligned SQL bootstrap, Terraform and dbt schemas.
- Aligned governance policy attachment with the actual FEATURES schema.
- Added production deployment and incident response runbooks.
- Added production-readiness tests for schema, governance and sample-data consistency.
- Added pre-commit configuration and environment/tfvars examples.
