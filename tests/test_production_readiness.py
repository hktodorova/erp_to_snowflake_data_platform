from __future__ import annotations

from pathlib import Path

import yaml

ROOT = Path(__file__).resolve().parents[1]


def test_dbt_schema_macro_prevents_target_schema_prefixing() -> None:
    macro = (ROOT / "dbt/macros/generate_schema_name.sql").read_text().lower()
    assert "custom_schema_name" in macro
    assert "target.schema" in macro
    assert "custom_schema_name | trim" in macro


def test_all_declared_dbt_schemas_exist_in_bootstrap_sql_and_terraform() -> None:
    project = yaml.safe_load((ROOT / "dbt/dbt_project.yml").read_text())
    model_cfg = project["models"]["enterprise_snowflake_platform"]
    dbt_schemas = {
        cfg["+schema"].upper()
        for cfg in model_cfg.values()
        if isinstance(cfg, dict) and "+schema" in cfg
    }
    dbt_schemas.add(project["snapshots"]["enterprise_snowflake_platform"]["+target_schema"].upper())

    setup_sql = (ROOT / "sql/00_setup/01_roles_warehouses_databases.sql").read_text().upper()
    terraform = (ROOT / "terraform/main.tf").read_text().upper()

    for schema in dbt_schemas:
        assert f"ENTERPRISE_DWH.{schema}" in setup_sql
        assert f'"{schema}"' in terraform


def test_sample_data_values_match_contract_enums() -> None:
    generator = (ROOT / "scripts/generate_sample_data.py").read_text()
    assert "mid-market" not in generator
    assert "mid_market" in generator


def test_governance_attaches_feature_policy_in_features_schema() -> None:
    governance = (ROOT / "sql/04_governance/01_security_governance.sql").read_text().lower()
    assert "alter table if exists features.feature_customer_revenue_90d" in governance
    assert "alter table if exists marts.feature_customer_revenue_90d" not in governance
