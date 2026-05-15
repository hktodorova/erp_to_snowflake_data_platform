from __future__ import annotations

from pathlib import Path

import yaml

ROOT = Path(__file__).resolve().parents[1]


def _find_model(schema: dict, name: str) -> dict:
    return next(model for model in schema["models"] if model["name"] == name)


def _find_column(model: dict, name: str) -> dict:
    return next(column for column in model["columns"] if column["name"] == name)


def _accepted_values(column: dict) -> list[str]:
    for test in column.get("data_tests", column.get("tests", [])):
        if isinstance(test, dict) and "accepted_values" in test:
            return test["accepted_values"].get("values") or test["accepted_values"]["arguments"]["values"]
    raise AssertionError(f"No accepted_values test configured for {column['name']}")


def test_order_status_contract_matches_dbt_tests() -> None:
    contract = yaml.safe_load((ROOT / "contracts/erp_orders_contract.yml").read_text())
    schema = yaml.safe_load((ROOT / "dbt/models/schema.yml").read_text())

    contract_status = next(field for field in contract["fields"] if field["name"] == "status")
    contract_values = set(contract_status["allowed_values"])

    stg_orders = _find_model(schema, "stg_erp_orders")
    fact_revenue = _find_model(schema, "fact_revenue")

    assert set(_accepted_values(_find_column(stg_orders, "order_status"))) == contract_values
    assert set(_accepted_values(_find_column(fact_revenue, "order_status"))).issubset(contract_values)


def test_order_contract_required_fields_are_present_in_staging_model() -> None:
    contract = yaml.safe_load((ROOT / "contracts/erp_orders_contract.yml").read_text())
    staging_sql = (ROOT / "dbt/models/staging/stg_erp_orders.sql").read_text().lower()

    field_to_staging_name = {"status": "order_status"}
    for field in contract["fields"]:
        if field.get("required"):
            expected_name = field_to_staging_name.get(field["name"], field["name"])
            assert f" as {expected_name}" in staging_sql or expected_name in staging_sql
