from __future__ import annotations

from datetime import datetime, timedelta
from pathlib import Path

from airflow import DAG
from airflow.models.baseoperator import chain
from airflow.operators.bash import BashOperator
from airflow.operators.empty import EmptyOperator
from airflow.operators.python import BranchPythonOperator
from airflow.providers.snowflake.operators.snowflake import SnowflakeOperator
from airflow.providers.snowflake.sensors.snowflake import SnowflakeSqlApiSensor
from airflow.utils.task_group import TaskGroup
from airflow.utils.trigger_rule import TriggerRule
from cosmos import DbtTaskGroup, ExecutionConfig, ProfileConfig, ProjectConfig, RenderConfig
from cosmos.profiles import SnowflakeUserPrivateKeyPemProfileMapping

PROJECT_ROOT = Path(__file__).resolve().parents[3]
DBT_PROJECT_DIR = PROJECT_ROOT / "dbt"


def notify_failure(context: dict) -> None:
    """Hook for PagerDuty/Slack integration in production."""
    task = context.get("task_instance")
    dag_id = context.get("dag").dag_id if context.get("dag") else "unknown"
    print(f"ALERT dag={dag_id} task={task.task_id if task else 'unknown'} status=failed")


def choose_ingestion_mode(**context: dict) -> str:
    dag_run = context.get("dag_run")
    mode = (dag_run.conf or {}).get("mode", "incremental") if dag_run else "incremental"
    return "ingestion.full_refresh" if mode == "full" else "ingestion.incremental_load"


profile_config = ProfileConfig(
    profile_name="enterprise_snowflake_platform",
    target_name="prod",
    profile_mapping=SnowflakeUserPrivateKeyPemProfileMapping(
        conn_id="snowflake_default",
        profile_args={
            "database": "ENTERPRISE_DWH",
            "schema": "MARTS",
            "warehouse": "WH_TRANSFORM_M",
            "role": "ROLE_TRANSFORM",
            "threads": 6,
        },
    ),
)

DEFAULT_ARGS = {
    "owner": "data-platform",
    "depends_on_past": False,
    "retries": 3,
    "retry_delay": timedelta(minutes=5),
    "execution_timeout": timedelta(hours=2),
    "on_failure_callback": notify_failure,
}

with DAG(
    dag_id="enterprise_snowflake_pipeline",
    description="Production ERP Snowflake pipeline with ingestion, dbt, quality gates and SLA checks.",
    start_date=datetime(2025, 1, 1),
    schedule="0 * * * *",
    catchup=False,
    max_active_runs=1,
    default_args=DEFAULT_ARGS,
    sla_miss_callback=notify_failure,
    tags=["snowflake", "dbt", "erp", "production"],
) as dag:
    start = EmptyOperator(task_id="start")

    with TaskGroup(group_id="ingestion") as ingestion:
        wait_for_snowpipe = SnowflakeSqlApiSensor(
            task_id="wait_for_recent_raw_orders",
            snowflake_conn_id="snowflake_default",
            sql="""
            SELECT COUNT(*)
            FROM ENTERPRISE_DWH.RAW.RAW_ERP_ORDERS
            WHERE ingested_at >= DATEADD('hour', -2, CURRENT_TIMESTAMP())
            """,
            poke_interval=120,
            timeout=1800,
        )

        decide_mode = BranchPythonOperator(
            task_id="choose_ingestion_mode",
            python_callable=choose_ingestion_mode,
        )

        incremental_load = SnowflakeOperator(
            task_id="incremental_load",
            snowflake_conn_id="snowflake_default",
            sql="ALTER TASK ENTERPRISE_DWH.RAW.TASK_MERGE_ERP_ORDERS_CDC RESUME; EXECUTE TASK ENTERPRISE_DWH.RAW.TASK_MERGE_ERP_ORDERS_CDC;",
        )

        full_refresh = BashOperator(
            task_id="full_refresh",
            bash_command=f"cd {DBT_PROJECT_DIR} && dbt run --full-refresh --select staging --profiles-dir . --target prod",
        )

        ingestion_complete = EmptyOperator(
            task_id="complete",
            trigger_rule=TriggerRule.NONE_FAILED_MIN_ONE_SUCCESS,
        )

        wait_for_snowpipe >> decide_mode >> [incremental_load, full_refresh] >> ingestion_complete

    dbt_build = DbtTaskGroup(
        group_id="dbt_build_enterprise_platform",
        project_config=ProjectConfig(dbt_project_path=DBT_PROJECT_DIR),
        profile_config=profile_config,
        execution_config=ExecutionConfig(dbt_executable_path="dbt"),
        render_config=RenderConfig(select=["staging", "vault", "marts", "features"]),
        operator_args={"install_deps": True},
    )

    with TaskGroup(group_id="quality_gates") as quality_gates:
        source_freshness = BashOperator(
            task_id="dbt_source_freshness",
            bash_command=f"cd {DBT_PROJECT_DIR} && dbt source freshness --profiles-dir . --target prod",
        )

        dbt_tests = BashOperator(
            task_id="dbt_tests",
            bash_command=f"cd {DBT_PROJECT_DIR} && dbt test --select staging vault marts features --profiles-dir . --target prod",
        )

        row_count_reconciliation = SnowflakeOperator(
            task_id="row_count_reconciliation",
            snowflake_conn_id="snowflake_default",
            sql="""
            SELECT CASE
                WHEN raw_count >= staging_count THEN 'OK'
                ELSE SYSTEM$RAISE_ERROR('Staging row count exceeds raw row count')
            END
            FROM (
                SELECT
                    (SELECT COUNT(*) FROM ENTERPRISE_DWH.RAW.RAW_ERP_ORDERS) AS raw_count,
                    (SELECT COUNT(*) FROM ENTERPRISE_DWH.STAGING.ERP_ORDERS_CDC) AS staging_count
            );
            """,
        )

        source_freshness >> dbt_tests >> row_count_reconciliation

    publish_metrics = SnowflakeOperator(
        task_id="publish_sla_metrics",
        snowflake_conn_id="snowflake_default",
        sql="SELECT * FROM ENTERPRISE_DWH.OBSERVABILITY.V_RAW_FRESHNESS WHERE sla_status = 'BREACH';",
        trigger_rule="all_done",
    )

    end = EmptyOperator(task_id="end")

    chain(start, ingestion, dbt_build, quality_gates, publish_metrics, end)
