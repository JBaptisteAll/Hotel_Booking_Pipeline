FROM apache/airflow:3.3.1

# Install dbt (core + postgres adapter) into the airflow user's environment.
# Must run as the "airflow" user, not root, to match the base image's
# permission model (packages need to be importable by the airflow user
# that the scheduler/worker processes run as).
USER airflow

COPY requirements-dbt.txt /requirements-dbt.txt

RUN pip install --no-cache-dir -r /requirements-dbt.txt
