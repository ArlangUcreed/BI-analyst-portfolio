# filename=taxi_daily_dag.py

"""
DAG: project_da_aggregator
Описание: Автоматическая агрегация данных о поездках такси

Рабочий процесс:
1. S3KeySensor ожидает появления файла taxi_data.parquet в S3-бакете
2. DataprocCreatePysparkJobOperator запускает PySpark-скрипт на кластере Data Proc
3. Результат записывается в ClickHouse

Расписание: ежедневно в 16:00
"""

from datetime import datetime
from airflow import DAG
from airflow.sensors.s3_key_sensor import S3KeySensor
from airflow.providers.yandex.operators.dataproc import DataprocCreatePysparkJobOperator

# ============================================================================
# ПАРАМЕТРЫ DAG
# ============================================================================

DAG_ID = "project_da_aggregator"
USERNAME = "da_20260202_4d80911297"

# Путь к PySpark-скрипту в S3
SPARK_SCRIPT_PATH = f"s3a://da-plus-dags/{USERNAME}/jobs/the_final_yandex_taxi_project.py"

# Идентификатор кластера Data Proc
CLUSTER_ID = "c9q4134h5vi546h1e148"

# ============================================================================
# ОПРЕДЕЛЕНИЕ DAG
# ============================================================================

with DAG(
    DAG_ID,
    description="Подсчёт агрегированных данных для проекта DA+",
    schedule='0 16 * * *',  # Каждый день в 16:00 (формат cron)
    start_date=datetime(2026, 1, 1),
    catchup=False,
    tags=['project', 'taxi', 'spark']
) as dag:
    
    # ========================================================================
    # TASK 1: S3 СЕНСОР
    # ========================================================================
    # Ожидает появление файла в S3 перед запуском Spark-задачи
    # poke_interval=300: проверка каждые 5 минут
    # timeout=3600: максимальное время ожидания 1 час
    
    wait_for_input = S3KeySensor(
        task_id='data_s3_sensor',
        poke_interval=300,
        timeout=3600,
        bucket_name='da-plus-dags',
        bucket_key="project_04/taxi_data.parquet",
        mode='poke',
        aws_conn_id='s3',
        wildcard_match=False
    )
    
    # ========================================================================
    # TASK 2: ЗАПУСК PYSPARK ЗАДАЧИ НА DATA PROC
    # ========================================================================
    # Запускает PySpark-скрипт на кластере Yandex Data Proc
    # Скрипт выполняет агрегацию данных и записывает результат в ClickHouse
    
    run_pyspark = DataprocCreatePysparkJobOperator(
        task_id="create_pyspark_job",
        cluster_id=CLUSTER_ID,
        main_python_file_uri=SPARK_SCRIPT_PATH
    )
    
    # ========================================================================
    # ОПРЕДЕЛЕНИЕ ПОРЯДКА ВЫПОЛНЕНИЯ ЗАДАЧ
    # ========================================================================
    # Сначала ждем файл, затем запускаем Spark-задачу
    
    wait_for_input >> run_pyspark
