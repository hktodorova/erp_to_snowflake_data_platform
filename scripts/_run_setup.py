from dotenv import load_dotenv
load_dotenv()
import os
import snowflake.connector
from pathlib import Path

ROOT = Path(".")
scripts = [
    "sql/00_setup/01_roles_warehouses_databases.sql",
    "sql/00_setup/02_file_formats_stages.sql",
]

cx = snowflake.connector.connect(
    account=os.environ["SNOWFLAKE_ACCOUNT"],
    user=os.environ["SNOWFLAKE_USER"],
    password=os.environ["SNOWFLAKE_PASSWORD"],
    role=os.environ["SNOWFLAKE_ROLE"],
)
cur = cx.cursor()
for path in scripts:
    sql = (ROOT / path).read_text()
    statements = [s.strip() for s in sql.split(";") if s.strip() and not s.strip().startswith("--")]
    print(f"\n=== {path} ({len(statements)} statements) ===")
    for stmt in statements:
        try:
            cur.execute(stmt)
            print(f"  OK: {stmt[:80].splitlines()[0]}")
        except Exception as e:
            print(f"  WARN: {e}")
cx.close()
print("\nSetup complete.")
