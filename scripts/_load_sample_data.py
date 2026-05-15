"""Load CSV sample data into Snowflake RAW tables as VARIANT payload."""
import os
import csv
import json
from pathlib import Path
from dotenv import load_dotenv
import snowflake.connector

load_dotenv()
ROOT = Path(__file__).parent.parent

cx = snowflake.connector.connect(
    account=os.environ["SNOWFLAKE_ACCOUNT"],
    user=os.environ["SNOWFLAKE_USER"],
    password=os.environ["SNOWFLAKE_PASSWORD"],
    role=os.environ["SNOWFLAKE_ROLE"],
    database="ENTERPRISE_DWH",
    warehouse="WH_INGEST_XS",
)
cur = cx.cursor()

# 1) Create raw tables
setup_sql = (ROOT / "sql/01_ingestion/01_raw_tables_and_pipes.sql").read_text()
for stmt in setup_sql.split(";"):
    s = stmt.strip()
    if s and not s.startswith("--"):
        try:
            cur.execute(s)
            preview = s[:70].replace("\n", " ")
            print(f"  OK: {preview}")
        except Exception as e:
            print(f"  WARN: {e}")


def load_csv_as_variant(cur, csv_path, table):
    """Read CSV and insert each row as a JSON VARIANT using SELECT UNION ALL."""
    with open(csv_path, newline="") as f:
        rows = list(csv.DictReader(f))
    # Build SELECT ... UNION ALL — Snowflake allows PARSE_JSON in SELECT
    selects = "\nUNION ALL\n".join(
        f"SELECT PARSE_JSON($${json.dumps(r)}$$), 'ERP', 'batch_demo'" for r in rows
    )
    cur.execute(
        f"INSERT INTO {table}(payload, source_system, batch_id)\n{selects}"
    )
    print(f"Loaded {len(rows)} rows into {table}")


# Truncate first to avoid duplicates on re-run
cur.execute("TRUNCATE TABLE IF EXISTS RAW.RAW_ERP_CUSTOMERS")
cur.execute("TRUNCATE TABLE IF EXISTS RAW.RAW_ERP_ORDERS")

load_csv_as_variant(cur, ROOT / "sample_data/erp_customers.csv", "RAW.RAW_ERP_CUSTOMERS")
load_csv_as_variant(cur, ROOT / "sample_data/erp_orders.csv", "RAW.RAW_ERP_ORDERS")

cx.close()
print("Done.")
