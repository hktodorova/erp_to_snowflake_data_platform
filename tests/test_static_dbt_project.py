from __future__ import annotations

from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def test_customer_satellite_is_append_only_historized() -> None:
    sql = (ROOT / "dbt/models/vault/sat_customer_details.sql").read_text().lower()

    assert "materialized='incremental'" in sql
    assert "unique_key=['customer_hk', 'hashdiff', 'load_datetime']" in sql
    assert "ref('stg_erp_customers_history')" in sql
    assert "lag(hashdiff) over" in sql
    assert "previous_hashdiff <> hashdiff" in sql
    assert "not exists" in sql


def test_production_dag_does_not_generate_sample_data() -> None:
    prod_dag = (ROOT / "orchestration/airflow/dags/enterprise_snowflake_pipeline.py").read_text().lower()
    demo_dag = (ROOT / "orchestration/airflow/dags/local_demo_pipeline.py").read_text().lower()

    assert "generate_sample_data.py" not in prod_dag
    assert "data_quality_local_demo.py" not in prod_dag
    assert "dbt source freshness" in prod_dag
    assert "dbt test" in prod_dag
    assert "generate_sample_data.py" in demo_dag
    assert "data_quality_local_demo.py" in demo_dag


def test_governance_policies_are_applied_to_concrete_marts() -> None:
    sql = (ROOT / "sql/04_governance/01_security_governance.sql").read_text().lower()

    assert "alter table if exists marts.dim_customer" in sql
    assert "set masking policy governance.email_mask" in sql
    assert "set masking policy governance.customer_name_mask" in sql
    assert "add row access policy governance.country_access_policy on (country_code)" in sql
    assert "alter table if exists marts.fact_revenue" in sql
    assert "alter table if exists features.feature_customer_revenue_90d" in sql
