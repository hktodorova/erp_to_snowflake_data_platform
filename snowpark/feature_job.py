from __future__ import annotations

from snowflake.snowpark import Session
from snowflake.snowpark.functions import col, count, sum as sf_sum, avg, current_timestamp, lit


def build_customer_revenue_features(session: Session, run_id: str) -> None:
    fact = session.table("ENTERPRISE_DWH.MARTS.FACT_REVENUE")
    features = (
        fact.group_by("CUSTOMER_ID")
        .agg(
            count("ORDER_ID").alias("ORDERS_TOTAL"),
            sf_sum("NET_AMOUNT").alias("REVENUE_TOTAL"),
            avg("NET_AMOUNT").alias("AVG_ORDER_VALUE"),
        )
        .with_column("RUN_ID", lit(run_id))
        .with_column("AS_OF_TIMESTAMP", current_timestamp())
    )
    features.write.mode("overwrite").save_as_table("ENTERPRISE_DWH.FEATURES.CUSTOMER_REVENUE_FEATURES")
