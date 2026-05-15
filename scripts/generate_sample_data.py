from __future__ import annotations

from pathlib import Path
import csv
import random
from datetime import datetime, timedelta

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "sample_data"
OUT.mkdir(exist_ok=True)
random.seed(42)

countries = ["CH", "DE", "AT", "FR"]
segments = ["enterprise", "mid_market", "smb", "strategic"]
statuses = ["open", "released", "invoiced", "shipped"]

customers = []
for i in range(1, 101):
    customers.append({
        "customer_id": f"C{i:05d}",
        "customer_name": f"Customer {i:05d}",
        "email": f"customer{i:05d}@example.com",
        "country_code": random.choice(countries),
        "customer_segment": random.choice(segments),
        "updated_at": datetime(2025, 1, 1).isoformat(),
    })

orders = []
for i in range(1, 1001):
    dt = datetime(2025, 1, 1) + timedelta(days=random.randint(0, 120))
    orders.append({
        "order_id": f"O{i:07d}",
        "customer_id": random.choice(customers)["customer_id"],
        "order_date": dt.isoformat(),
        "currency": "CHF",
        "net_amount": round(random.uniform(50, 5000), 2),
        "status": random.choice(statuses),
    })

for name, rows in [("erp_customers.csv", customers), ("erp_orders.csv", orders)]:
    with (OUT / name).open("w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=list(rows[0].keys()))
        writer.writeheader()
        writer.writerows(rows)

print(f"Generated {len(customers)} customers and {len(orders)} orders in {OUT}")
