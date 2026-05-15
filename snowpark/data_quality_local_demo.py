from __future__ import annotations

from pathlib import Path
import pandas as pd

ROOT = Path(__file__).resolve().parents[1]
ORDERS = ROOT / "sample_data" / "erp_orders.csv"
CUSTOMERS = ROOT / "sample_data" / "erp_customers.csv"


def run_checks() -> pd.DataFrame:
    orders = pd.read_csv(ORDERS)
    customers = pd.read_csv(CUSTOMERS)

    results = [
        {"check_name": "orders_total_rows", "value": len(orders), "status": "INFO"},
        {"check_name": "orders_duplicate_order_ids", "value": int(orders["order_id"].duplicated().sum()), "status": "PASS" if not orders["order_id"].duplicated().any() else "FAIL"},
        {"check_name": "orders_negative_net_amount", "value": int((orders["net_amount"] < 0).sum()), "status": "PASS" if (orders["net_amount"] >= 0).all() else "FAIL"},
        {"check_name": "orders_missing_customers", "value": int((~orders["customer_id"].isin(customers["customer_id"])).sum()), "status": "PASS" if orders["customer_id"].isin(customers["customer_id"]).all() else "FAIL"},
    ]
    return pd.DataFrame(results)


if __name__ == "__main__":
    df = run_checks()
    print(df.to_string(index=False))
    if (df["status"] == "FAIL").any():
        raise SystemExit(1)
