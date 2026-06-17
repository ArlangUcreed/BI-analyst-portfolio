Вот исправленный README (можно скопировать целиком)
markdown

# Автоматизация агрегации данных Яндекс Такси

## 📌 Описание задачи
Построить автоматизированный ETL-пайплайн для агрегации данных о поездках такси по способам оплаты.

**Что нужно было сделать:**
1. Написать Spark-скрипт для обработки данных и расчёта метрик
2. Настроить ежедневный запуск через Apache Airflow
3. Сохранять результаты в ClickHouse для подключения к дашбордам

## 🛠 Используемые технологии
| Технология | Назначение |
|------------|------------|
| **Apache Spark** | Обработка и агрегация больших данных |
| **ClickHouse** | Хранение витрины данных (колоночная СУБД) |
| **Apache Airflow** | Оркестрация пайплайна (ежедневный запуск) |
| **Yandex Data Proc** | Выполнение Spark-задач в облаке |
| **S3 (Yandex Object Storage)** | Хранение исходных данных в формате Parquet |

## 📊 Метрики витрины
| Метрика | Описание | Формула |
|---------|----------|---------|
| `trip_count` | Количество поездок по типу оплаты | `COUNT(*)` |
| `avg_fare` | Средняя стоимость поездки | `AVG(fare)` |
| `avg_tips` | Средние чаевые | `AVG(tips)` |
| `total_revenue` | Суммарная выручка | `SUM(trip_total)` |

## 🔄 Архитектура пайплайна

┌─────────────────┐
│ S3 (Parquet) │
│ taxi_data.parquet│
└────────┬────────┘
│
▼
┌─────────────────┐
│ Apache Spark │
│ Агрегация по │
│ payment_type │
└────────┬────────┘
│
▼
┌─────────────────┐
│ ClickHouse │
│taxi_payment_ │
│ summary │
└─────────────────┘
▲
│
┌─────────────────┐
│ Apache Airflow │
│ (ежедневно в │
│ 16:00) │
└─────────────────┘
text


## 📈 Пример результата
| payment_type | trip_count | avg_fare | avg_tips | total_revenue |
|--------------|------------|----------|----------|---------------|
| Cash | 12,500 | 450.50 | 50.20 | 5,631,250.00 |
| Card | 8,700 | 520.30 | 85.40 | 4,526,610.00 |
| Apple Pay | 3,400 | 490.10 | 92.10 | 1,666,340.00 |

## 📝 Ключевые результаты
1. **Пайплайн полностью автоматизирован** — данные обновляются ежедневно без участия человека
2. **Время обработки** — менее 1 минуты для всего объёма данных
3. **Данные доступны** в ClickHouse для подключения к дашбордам (Power BI, DataLens)
4. **Основной способ оплаты** — наличные, но средний чек выше у безналичных
5. **Чаевые** — самые высокие у пользователей Apple Pay

## 🚀 Как запустить

### 1. Разместить файлы в S3
```bash
# PySpark скрипт должен лежать по пути:
s3a://da-plus-dags/{username}/jobs/the_final_yandex_taxi_project.py

2. Настроить Airflow Connections
Conn Id	Тип	Параметры
s3	Amazon S3	host: storage.yandexcloud.net, Access Key, Secret Key
clickhouse_conn	Generic	Login, Password, Extra: {"host": "...", "port": 8443, "database": "..."}
3. Активировать DAG

    В интерфейсе Airflow включить DAG project_da_aggregator

    DAG будет запускаться ежедневно в 16:00

4. Проверить результат в ClickHouse (DBeaver)
sql

SELECT * FROM taxi_payment_summary;

📄 Пример кода
<details> <summary>📄 Нажми, чтобы посмотреть пример PySpark-кода</summary>
python

# filename=the_final_yandex_taxi_project.py

from pyspark.sql import SparkSession
from pyspark.sql import functions as F

# Создание Spark-сессии
spark = (
    SparkSession.builder.appName("myAggregateTest")
    .config("fs.s3a.endpoint", "storage.yandexcloud.net")
    .config("spark.jars.packages", "com.clickhouse:clickhouse-jdbc:0.6.5")
    .getOrCreate()
)

# Чтение данных из S3
taxi_data_df = spark.read.parquet("s3a://da-plus-dags/project_04/taxi_data.parquet")

# Агрегация по типу оплаты
taxi_payment_summary_df = taxi_data_df.groupBy("payment_type").agg(
    F.count("*").alias("trip_count"),
    F.avg("fare").alias("avg_fare"),
    F.avg("tips").alias("avg_tips"),
    F.sum("trip_total").alias("total_revenue")
)

# Запись в ClickHouse
taxi_payment_summary_df.write \
    .format("jdbc") \
    .option("url", jdbcUrl) \
    .option("dbtable", "taxi_payment_summary") \
    .mode("overwrite") \
    .save()

</details><details> <summary>📄 Нажми, чтобы посмотреть пример DAG для Airflow</summary>
python

# filename=taxi_daily_dag.py

from datetime import datetime
from airflow import DAG
from airflow.sensors.s3_key_sensor import S3KeySensor
from airflow.providers.yandex.operators.dataproc import DataprocCreatePysparkJobOperator

DAG_ID = "project_da_aggregator"

with DAG(
    DAG_ID,
    description="Подсчёт агрегированных данных для проекта DA+",
    schedule='0 16 * * *',  # Каждый день в 16:00
    start_date=datetime(2026, 1, 1),
    catchup=False,
    tags=['project', 'taxi', 'spark']
) as dag:
    
    # Ожидание файла в S3
    wait_for_input = S3KeySensor(
        task_id='data_s3_sensor',
        poke_interval=300,
        timeout=3600,
        bucket_name='da-plus-dags',
        bucket_key="project_04/taxi_data.parquet",
        aws_conn_id='s3'
    )
    
    # Запуск PySpark задачи
    run_pyspark = DataprocCreatePysparkJobOperator(
        task_id="create_pyspark_job",
        cluster_id="c9q4134h5vi546h1e148",
        main_python_file_uri="s3a://da-plus-dags/.../the_final_yandex_taxi_project.py"
    )
    
    wait_for_input >> run_pyspark

</details>
📁 Файлы проекта
Файл	Описание
the_final_yandex_taxi_project.py	PySpark скрипт для агрегации и записи в ClickHouse
taxi_daily_dag.py	DAG для Airflow (ежедневный запуск)
taxi_queries.sql	Проверочные запросы для DBeaver
🔧 Настройка подключений в Airflow
S3 Connection (Yandex Object Storage)
json

{
  "aws_access_key_id": "your_access_key",
  "aws_secret_access_key": "your_secret_key",
  "host": "storage.yandexcloud.net",
  "use_ssl": true
}

ClickHouse Connection
Поле	Значение
Conn Id	clickhouse_conn
Conn Type	Generic
Login	da_20260202_4d80911297
Password	your_password
Extra	{"host": "rc1a-3jouval14nne7aun.mdb.yandexcloud.net", "port": 8443, "database": "playground_da_20260202_4d80911297"}

👤 Автор
Бессуднов Максим Александрович

📅 Дата
Март 2026
