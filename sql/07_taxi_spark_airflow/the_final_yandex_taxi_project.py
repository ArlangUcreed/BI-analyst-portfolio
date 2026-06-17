# filename=the_final_yandex_taxi_project.py

import os
from pyspark.sql import SparkSession
from pyspark.sql import functions as F

# ============================================================================
# 1. НАСТРОЙКА SPARK СЕССИИ
# ============================================================================
# Конфигурация для работы с S3 (Yandex Object Storage)
# Оптимизация ресурсов для небольшого объема данных
# Подключение JDBC-драйвера для ClickHouse

spark = (
    SparkSession.builder.appName("myAggregateTest")
    .config("fs.s3a.endpoint", "storage.yandexcloud.net")
    .config("spark.dynamicAllocation.enabled", "false")
    .config("spark.executor.instances", "1")
    .config("spark.executor.cores", "1")
    .config("spark.executor.memory", "1g")
    .config("spark.driver.memory", "1g")
    .config("spark.jars.packages", "com.clickhouse:clickhouse-jdbc:0.6.5")
    .getOrCreate()
)

print("=== Spark сессия успешно создана ===")

# ============================================================================
# 2. ПАРАМЕТРЫ ПОДКЛЮЧЕНИЯ
# ============================================================================
# Логин и пароль вынесены в переменные (пароль рекомендуется брать из env)
# Это обеспечивает безопасность и упрощает поддержку кода

USERNAME = "da_20260202_4d80911297"
PASSWORD = os.environ.get("CLICKHOUSE_PASSWORD", "9092048c73894b2b9a464a404a46dbd9")

JDBC_PORT = 8443
JDBC_HOST = "rc1a-3jouval14nne7aun.mdb.yandexcloud.net"
JDBC_DATABASE = f"playground_{USERNAME}"
JDBC_URL = f"jdbc:clickhouse://{JDBC_HOST}:{JDBC_PORT}/{JDBC_DATABASE}?ssl=true"

# Путь к данным в S3
PARQUET_PATH = "s3a://da-plus-dags/project_04/taxi_data.parquet"

print(f"Подключение к ClickHouse: {JDBC_URL}")

# ============================================================================
# 3. ЗАГРУЗКА ДАННЫХ ИЗ S3
# ============================================================================
# Читаем Parquet-файл (формат обеспечивает высокую производительность)

taxi_data_df = spark.read.parquet(PARQUET_PATH)
print("=== Исходные данные ===")
taxi_data_df.show(n=20, truncate=False)

# ============================================================================
# 4. ОЧИСТКА ДАННЫХ
# ============================================================================
# Удаляем дубликаты строк, чтобы не искажать результаты агрегации
# Дубликаты могут возникать при повторной загрузке или ошибках в источнике

taxi_data_df = taxi_data_df.dropDuplicates()
print(f"После удаления дубликатов: {taxi_data_df.count()} записей")

# ============================================================================
# 5. ПРОВЕРКА СХЕМЫ ДАННЫХ
# ============================================================================
# Выводим структуру данных для отладки и контроля качества

print("=== Схема данных ===")
taxi_data_df.printSchema()

# ============================================================================
# 6. АГРЕГАЦИЯ ПОКАЗАТЕЛЕЙ ПО ТИПУ ОПЛАТЫ
# ============================================================================
# Рассчитываем ключевые метрики для финансовой и продуктовой аналитики:
# - trip_count   : количество поездок (общий спрос и загрузка сервиса)
# - avg_fare     : средняя стоимость поездки (уровень среднего чека)
# - avg_tips     : средние чаевые (индикатор удовлетворённости клиентов)
# - total_revenue: суммарная выручка (ключевой показатель дохода компании)

taxi_payment_summary_df = taxi_data_df.groupBy("payment_type").agg(
    F.count("*").alias("trip_count"),
    F.avg("fare").alias("avg_fare"),
    F.avg("tips").alias("avg_tips"),
    F.sum("trip_total").alias("total_revenue")
)

print("=== Результаты агрегации ===")
taxi_payment_summary_df.show(truncate=False)

# ============================================================================
# 7. ЗАПИСЬ РЕЗУЛЬТАТОВ В CLICKHOUSE
# ============================================================================
# Используем JDBC-драйвер для записи агрегированных данных
# createTableOptions: движок MergeTree для оптимальной работы аналитических запросов
# mode("overwrite"): перезаписываем таблицу при каждом запуске (актуальные данные)

taxi_payment_summary_df.write \
    .format("jdbc") \
    .option("url", JDBC_URL) \
    .option("dbtable", "taxi_payment_summary") \
    .option("user", USERNAME) \
    .option("password", PASSWORD) \
    .option("driver", "com.clickhouse.jdbc.ClickHouseDriver") \
    .option("createTableOptions", "ENGINE=MergeTree() ORDER BY payment_type") \
    .mode("overwrite") \
    .save()

print("=== Данные успешно записаны в ClickHouse! ===")

# ============================================================================
# 8. ЗАВЕРШЕНИЕ РАБОТЫ
# ============================================================================
# Останавливаем Spark сессию для освобождения ресурсов кластера

spark.stop()
print("Spark сессия остановлена")
