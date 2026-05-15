# Production Deployment Runbook

## Release gates

1. `pre-commit run --all-files`
2. `pytest -q`
3. `cd dbt && dbt deps && dbt parse --profiles-dir .`
4. `terraform fmt -check -recursive && terraform validate`
5. In a non-production Snowflake account: `dbt build --select state:modified+ --defer --state target/prod_manifest`.

## Promotion

- Apply Terraform first with an environment-specific variable file.
- Run setup SQL only for bootstrap or controlled migrations.
- Run `dbt snapshot`, then `dbt build`.
- Apply governance policies after the target relations exist.
- Validate source freshness and row-count reconciliation before opening analyst access.

## Rollback

- Revert Terraform from the last approved release tag.
- Use dbt state selection to rebuild only impacted downstream models.
- Restore critical marts from Snowflake Time Travel or zero-copy clones when data corruption is detected.
- Keep raw payloads immutable so staging, vault and marts can be replayed.
