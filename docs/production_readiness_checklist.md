# Production Readiness Checklist

- [x] Deterministic schema naming through dbt macro.
- [x] No committed credentials; profile uses environment variables.
- [x] Least-privilege Snowflake role model aligned across SQL, dbt and Terraform.
- [x] Staging, vault, marts, features, snapshots, governance and observability schemas declared in SQL and Terraform.
- [x] Data contracts validated by tests.
- [x] Synthetic data aligned with dbt accepted values.
- [x] CI includes pytest, smoke checks, dbt parse, SQLFluff and Terraform validate.
- [x] Governance policies are attached to concrete mart/feature relations.
- [x] Runbooks cover deployment, rollback and incident response.
- [x] Local project can be validated without Snowflake credentials; live deployment requires account-specific secrets.
