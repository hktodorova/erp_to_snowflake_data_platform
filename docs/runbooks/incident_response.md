# Data Platform Incident Response

## Severity examples

- SEV1: incorrect revenue numbers in executive dashboards, leaked PII, production DAG outage.
- SEV2: delayed ingestion beyond SLA, dbt tests failing for non-critical marts.
- SEV3: isolated source freshness warning or cost anomaly.

## Triage checklist

1. Check Airflow DAG/task status.
2. Check Snowflake task history, query history and warehouse credit usage.
3. Check dbt run artifacts and failing tests.
4. Compare raw ingestion counts with mart counts.
5. Pause dependent dashboards or feature consumers if trust is compromised.

## Recovery actions

- Re-run idempotent ingestion for missing batches.
- Rebuild impacted dbt model subtree.
- Restore from Time Travel for destructive changes.
- Rotate credentials and audit access history for security incidents.
