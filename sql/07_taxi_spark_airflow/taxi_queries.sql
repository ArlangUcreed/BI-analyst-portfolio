-- 1. Создание таблицы и проверка
CREATE TABLE IF NOT EXISTS taxi_payment_summary (
    payment_type String,
    trip_count UInt64,
    avg_fare Float64,
    avg_tips Float64,
    total_revenue Float64,
    processing_date Date DEFAULT today()
) 
ENGINE = MergeTree()
ORDER BY (payment_type, processing_date)
PARTITION BY toYYYYMM(processing_date);

-- Удалить старую таблицу
DROP TABLE IF EXISTS taxi_payment_summary;

-- Создать новую с правильной структурой
CREATE TABLE taxi_payment_summary (
    payment_type String,
    trip_count UInt64,
    avg_fare Float64,
    avg_tips Float64,
    total_revenue Float64
) ENGINE = MergeTree()
ORDER BY payment_type;

-- Проверить структуру
SHOW CREATE TABLE taxi_payment_summary;

-- Проверить, что таблица создана
SELECT * FROM taxi_payment_summary;

-- Показать все таблицы в базе данных
SHOW TABLES;

-- Описать структуру таблицы
DESCRIBE taxi_payment_summary;

-- Проверить создание
SHOW CREATE TABLE taxi_payment_summary;

-- Основные запросы для проверки в DBeaver

-- 1. Проверить, что данные есть в таблице:
SELECT * FROM taxi_payment_summary;

-- 2. Проверить количество записей
SELECT COUNT(*) FROM taxi_payment_summary;

-- 3. Посмотреть все способы оплаты и показатели:
SELECT 
    payment_type,
    trip_count,
    ROUND(avg_fare, 2) as avg_fare,
    ROUND(avg_tips, 2) as avg_tips,
    ROUND(total_revenue, 2) as total_revenue
FROM taxi_payment_summary
ORDER BY payment_type;

-- 4. Проверить общую статистику:
SELECT 
    SUM(trip_count) as total_trips,
    SUM(total_revenue) as total_revenue
FROM taxi_payment_summary;

-- 5. Проверить структуру таблицы:
SHOW CREATE TABLE taxi_payment_summary;

-- 6. Проверить распределение по способам оплаты:
SELECT 
    payment_type,
    trip_count,
    ROUND(100.0 * trip_count / (SELECT SUM(trip_count) FROM taxi_payment_summary), 2) as percentage
FROM taxi_payment_summary
ORDER BY trip_count DESC;

-- Итоговая проверка по заданию:
SELECT * FROM taxi_payment_summary;
