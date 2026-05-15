# Cost and Performance Strategy

## Warehouse Sizing
- `WH_INGEST_XS`: small, auto-suspend after 60 seconds, used for Snowpipe/task processing.
- `WH_TRANSFORM_M`: medium by default, scaled temporarily for backfills.
- `ERP_BI_WH`: small or medium depending on concurrency, isolated from transformation jobs.

## Query Optimization
- Keep raw payloads immutable and project typed columns in staging.
- Use incremental dbt models for high-volume facts.
- Cluster large history and fact tables by business date plus hash key.
- Avoid wide SELECT * marts; publish curated facts and dimensions.

## Cost Controls
- Auto-suspend all warehouses.
- Monitor credit usage daily through `OBSERVABILITY.V_WAREHOUSE_COST_7D`.
- Use dbt state selection and slim CI to avoid unnecessary rebuilds.
- Use zero-copy clones for test environments instead of duplicating storage.

## Backfill Strategy
- Backfill raw-to-staging first, validate reconciliation, then rebuild downstream marts using dbt selectors.
- Run large backfills in isolated windows with explicit warehouse sizing and rollback plan.
