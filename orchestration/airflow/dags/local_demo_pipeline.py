from __future__ import annotations

from datetime import datetime
from pathlib import Path

from airflow import DAG
from airflow.operators.bash import BashOperator

PROJECT_ROOT = Path(__file__).resolve().parents[3]

with DAG(
    dag_id="local_demo_pipeline",
    start_date=datetime(2025, 1, 1),
    schedule=None,
    catchup=False,
    default_args={"owner": "data-platform", "retries": 0},
    tags=["local", "demo", "non-production"],
) as dag:
    generate_sample_data = BashOperator(
        task_id="generate_sample_data",
        bash_command=f"cd {PROJECT_ROOT} && python scripts/generate_sample_data.py",
    )

    run_local_data_quality = BashOperator(
        task_id="run_local_data_quality",
        bash_command=f"cd {PROJECT_ROOT} && python snowpark/data_quality_local_demo.py",
    )

    generate_sample_data >> run_local_data_quality
