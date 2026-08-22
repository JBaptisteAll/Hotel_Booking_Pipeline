from datetime import timedelta

from airflow.sdk import DAG
from airflow.providers.standard.operators.bash import BashOperator
import pendulum

DBT_PROJECT_DIR = "/opt/airflow/dbt_project"
DBT_TARGET = "docker"

# Base command every task will use: move into the dbt project directory
# and always point dbt at the "docker" profile target (host: hotel_postgres).
DBT_CMD = f"cd {DBT_PROJECT_DIR} && dbt"

default_args = {
    "owner": "jb",
    "retries": 1,
    "retry_delay": timedelta(minutes=5),
    "depends_on_past": False,
}

with DAG(
    dag_id="hotel_booking_pipeline",
    description="Orchestrates the Hotel Booking dbt pipeline (seed -> staging -> intermediate -> marts)",
    default_args=default_args,
    schedule=None,  # manual trigger only, for now
    start_date=pendulum.datetime(2026, 1, 1, tz="UTC"),
    catchup=False,
    tags=["dbt", "hotel_booking_pipeline"],
) as dag:

    dbt_seed = BashOperator(
        task_id="dbt_seed",
        bash_command=f"{DBT_CMD} seed --profiles-dir . --target {DBT_TARGET}",
    )

    run_staging = BashOperator(
        task_id="dbt_run_staging",
        bash_command=f"{DBT_CMD} run --select stg_bookings --profiles-dir . --target {DBT_TARGET}",
    )

    test_staging = BashOperator(
        task_id="dbt_test_staging",
        bash_command=f"{DBT_CMD} test --select stg_bookings --indirect-selection=cautious --profiles-dir . --target {DBT_TARGET}",
    )

    run_intermediate = BashOperator(
        task_id="dbt_run_intermediate",
        bash_command=f"{DBT_CMD} run --select int_bookings_with_season --profiles-dir . --target {DBT_TARGET}",
    )

    test_intermediate = BashOperator(
        task_id="dbt_test_intermediate",
        bash_command=f"{DBT_CMD} test --select int_bookings_with_season --indirect-selection=cautious --profiles-dir . --target {DBT_TARGET}",
    )

    # --- Marts: independent from each other, so they can run in parallel ---

    run_mart_pricing = BashOperator(
        task_id="dbt_run_mart_pricing_consistency",
        bash_command=f"{DBT_CMD} run --select mart_pricing_consistency --profiles-dir . --target {DBT_TARGET}",
    )
    test_mart_pricing = BashOperator(
        task_id="dbt_test_mart_pricing_consistency",
        bash_command=f"{DBT_CMD} test --select mart_pricing_consistency --indirect-selection=cautious --profiles-dir . --target {DBT_TARGET}",
    )

    run_mart_cancellation = BashOperator(
        task_id="dbt_run_mart_cancellation_rate",
        bash_command=f"{DBT_CMD} run --select mart_cancellation_rate --profiles-dir . --target {DBT_TARGET}",
    )
    test_mart_cancellation = BashOperator(
        task_id="dbt_test_mart_cancellation_rate",
        bash_command=f"{DBT_CMD} test --select mart_cancellation_rate --indirect-selection=cautious --profiles-dir . --target {DBT_TARGET}",
    )

    run_mart_revenue = BashOperator(
        task_id="dbt_run_mart_revenue",
        bash_command=f"{DBT_CMD} run --select mart_revenue --profiles-dir . --target {DBT_TARGET}",
    )
    test_mart_revenue = BashOperator(
        task_id="dbt_test_mart_revenue",
        bash_command=f"{DBT_CMD} test --select mart_revenue --indirect-selection=cautious --profiles-dir . --target {DBT_TARGET}",
    )

    # --- Dependencies ---

    dbt_seed >> run_staging >> test_staging >> run_intermediate >> test_intermediate

    test_intermediate >> run_mart_pricing >> test_mart_pricing
    test_intermediate >> run_mart_cancellation >> test_mart_cancellation
    test_intermediate >> run_mart_revenue >> test_mart_revenue