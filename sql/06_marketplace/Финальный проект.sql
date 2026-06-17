-- Просмотр таблиц в схеме bi_analyst
SELECT * 
FROM bi_analyst.products 
LIMIT 10;

-- ============================================
-- ШАГ 1: ПОИСК ТАБЛИЦ В БАЗЕ
-- ============================================

-- 1.1. Все схемы в базе данных
SELECT schema_name 
FROM information_schema.schemata 
WHERE schema_name NOT LIKE 'pg_%' 
  AND schema_name != 'information_schema'
ORDER BY schema_name;

-- 1.2. Все таблицы во всех схемах
SELECT table_schema, table_name
FROM information_schema.tables 
WHERE table_schema NOT LIKE 'pg_%' 
  AND table_schema != 'information_schema'
ORDER BY table_schema, table_name;

-- 1.3. Поиск конкретно таблицы users
SELECT table_schema, table_name
FROM information_schema.tables 
WHERE table_name IN ('users', 'orders', 'products', 'reviews')
ORDER BY table_schema, table_name;

-- 1.4. Альтернативный способ поиска
SELECT 
    schemaname as schema_name,
    tablename as table_name
FROM pg_tables
WHERE schemaname NOT LIKE 'pg_%'
ORDER BY schemaname, tablename;

-- ============================================
-- ПРЕДОБРАБОТКА ДАННЫХ МАРКЕТПЛЕЙСА
-- Все таблицы находятся в схеме marketplace
-- ============================================

-- Устанавливаем схему по умолчанию
SET search_path TO marketplace, public;

-- ============================================
-- 1. ПРОВЕРКА ДАННЫХ
-- ============================================

-- 1.1. Проверяем размеры таблиц
SELECT 'users' as table_name, COUNT(*) as row_count FROM marketplace.users
UNION ALL
SELECT 'orders', COUNT(*) FROM marketplace.orders
UNION ALL
SELECT 'order_items', COUNT(*) FROM marketplace.order_items
UNION ALL
SELECT 'products', COUNT(*) FROM marketplace.products
UNION ALL
SELECT 'categories', COUNT(*) FROM marketplace.categories
UNION ALL
SELECT 'transactions', COUNT(*) FROM marketplace.transactions
UNION ALL
SELECT 'reviews', COUNT(*) FROM marketplace.reviews
ORDER BY table_name;

-- ============================================
-- 2. УДАЛЕНИЕ СТАРЫХ ТАБЛИЦ (ЕСЛИ ЕСТЬ)
-- ============================================

-- Удаляем таблицы, если они уже существуют в схеме marketplace
DROP TABLE IF EXISTS marketplace.orders_cleaned CASCADE;
DROP TABLE IF EXISTS marketplace.users_cleaned CASCADE;
DROP TABLE IF EXISTS marketplace.products_cleaned CASCADE;
DROP TABLE IF EXISTS marketplace.reviews_cleaned CASCADE;
DROP TABLE IF EXISTS marketplace.transactions_cleaned CASCADE;
DROP TABLE IF EXISTS marketplace.order_items_cleaned CASCADE;
DROP TABLE IF EXISTS marketplace.categories_cleaned CASCADE;
DROP TABLE IF EXISTS marketplace.orders_jan_jun_2025 CASCADE;

-- ============================================
-- 3. УДАЛЕНИЕ ДУБЛИКАТОВ
-- ============================================

-- 3.1. Удаление дубликатов в orders
CREATE TABLE marketplace.orders_cleaned AS
SELECT DISTINCT ON (order_id) *
FROM marketplace.orders
ORDER BY order_id;

-- 3.2. Удаление дубликатов в users
CREATE TABLE marketplace.users_cleaned AS
SELECT DISTINCT ON (user_id) *
FROM marketplace.users
ORDER BY user_id;

-- 3.3. Удаление дубликатов в products
CREATE TABLE marketplace.products_cleaned AS
SELECT DISTINCT ON (product_id) *
FROM marketplace.products
ORDER BY product_id;

-- 3.4. Удаление дубликатов в reviews
CREATE TABLE marketplace.reviews_cleaned AS
SELECT DISTINCT ON (review_id) *
FROM marketplace.reviews
ORDER BY review_id;

-- 3.5. Удаление дубликатов в transactions
CREATE TABLE marketplace.transactions_cleaned AS
SELECT DISTINCT ON (transaction_id) *
FROM marketplace.transactions
ORDER BY transaction_id;

-- 3.6. Удаление дубликатов в order_items
CREATE TABLE marketplace.order_items_cleaned AS
SELECT DISTINCT ON (order_item_id) *
FROM marketplace.order_items
ORDER BY order_item_id;

-- 3.7. Удаление дубликатов в categories
CREATE TABLE marketplace.categories_cleaned AS
SELECT DISTINCT ON (category_id) *
FROM marketplace.categories
ORDER BY category_id;

SELECT '✅ Таблицы очищены от дубликатов' as status;

-- ============================================
-- 4. ИСПРАВЛЕНИЕ ЛОГИЧЕСКИХ ОШИБОК
-- ============================================

-- 4.1. Исправление отрицательных цен в products
UPDATE marketplace.products_cleaned 
SET price = 0 
WHERE price < 0;

SELECT 'products_cleaned: Отрицательные цены исправлены' as result,
       COUNT(*) as affected_rows 
FROM marketplace.products_cleaned 
WHERE price < 0;

-- 4.2. Исправление отрицательного количества в order_items
UPDATE marketplace.order_items_cleaned 
SET quantity = 0 
WHERE quantity < 0;

SELECT 'order_items_cleaned: Отрицательное количество исправлено' as result,
       COUNT(*) as affected_rows 
FROM marketplace.order_items_cleaned 
WHERE quantity < 0;

-- 4.3. Исправление отрицательного stock_quantity
UPDATE marketplace.products_cleaned 
SET stock_quantity = 0 
WHERE stock_quantity < 0;

SELECT 'products_cleaned: Отрицательный остаток исправлен' as result,
       COUNT(*) as affected_rows 
FROM marketplace.products_cleaned 
WHERE stock_quantity < 0;

-- 4.4. Проверка и исправление рейтингов (1-5)
UPDATE marketplace.reviews_cleaned 
SET rating = NULL 
WHERE rating < 1 OR rating > 5;

SELECT 'reviews_cleaned: Некорректные рейтинги удалены' as result,
       COUNT(*) as affected_rows 
FROM marketplace.reviews_cleaned 
WHERE rating < 1 OR rating > 5;

-- ============================================
-- 5. ДОБАВЛЕНИЕ КАТЕГОРИАЛЬНЫХ ПРИЗНАКОВ
-- ============================================

-- 5.1. Добавляем колонку для категории рейтинга
ALTER TABLE marketplace.reviews_cleaned 
ADD COLUMN rating_category VARCHAR(20);

-- 5.2. Заполняем категории
UPDATE marketplace.reviews_cleaned 
SET rating_category = 
    CASE 
        WHEN rating = 1 THEN 'очень плохо'
        WHEN rating = 2 THEN 'плохо'
        WHEN rating = 3 THEN 'удовлетворительно'
        WHEN rating = 4 THEN 'хорошо'
        WHEN rating = 5 THEN 'отлично'
        ELSE NULL
    END;

-- 5.3. Добавляем бинарный признак
ALTER TABLE marketplace.reviews_cleaned 
ADD COLUMN is_positive_review BOOLEAN;

UPDATE marketplace.reviews_cleaned 
SET is_positive_review = (rating >= 4);

-- 5.4. Добавляем группировку рейтинга
ALTER TABLE marketplace.reviews_cleaned 
ADD COLUMN rating_group VARCHAR(10);

UPDATE marketplace.reviews_cleaned 
SET rating_group = 
    CASE 
        WHEN rating <= 2 THEN 'низкий'
        WHEN rating <= 4 THEN 'средний'
        WHEN rating = 5 THEN 'высокий'
        ELSE NULL
    END;

SELECT '✅ Категориальные признаки добавлены в reviews_cleaned' as status;

-- ============================================
-- 6. АНАЛИЗ ПРОПУЩЕННЫХ ЗНАЧЕНИЙ
-- ============================================

-- 6.1. Общий анализ по таблицам
WITH table_stats AS (
    SELECT 'users_cleaned' as table_name, COUNT(*) as total_rows,
           SUM(CASE WHEN user_id IS NULL THEN 1 ELSE 0 END) as null_rows
    FROM marketplace.users_cleaned
    UNION ALL
    SELECT 'orders_cleaned', COUNT(*),
           SUM(CASE WHEN order_id IS NULL THEN 1 ELSE 0 END)
    FROM marketplace.orders_cleaned
    UNION ALL
    SELECT 'products_cleaned', COUNT(*),
           SUM(CASE WHEN product_id IS NULL THEN 1 ELSE 0 END)
    FROM marketplace.products_cleaned
    UNION ALL
    SELECT 'reviews_cleaned', COUNT(*),
           SUM(CASE WHEN review_id IS NULL THEN 1 ELSE 0 END)
    FROM marketplace.reviews_cleaned
    UNION ALL
    SELECT 'transactions_cleaned', COUNT(*),
           SUM(CASE WHEN transaction_id IS NULL THEN 1 ELSE 0 END)
    FROM marketplace.transactions_cleaned
    UNION ALL
    SELECT 'order_items_cleaned', COUNT(*),
           SUM(CASE WHEN order_item_id IS NULL THEN 1 ELSE 0 END)
    FROM marketplace.order_items_cleaned
    UNION ALL
    SELECT 'categories_cleaned', COUNT(*),
           SUM(CASE WHEN category_id IS NULL THEN 1 ELSE 0 END)
    FROM marketplace.categories_cleaned
)
SELECT table_name, total_rows, null_rows,
       ROUND(null_rows * 100.0 / total_rows, 2) as null_percent
FROM table_stats
ORDER BY null_percent DESC;

-- 6.2. Детальный анализ пропусков для ключевых таблиц
SELECT 'users_cleaned - анализ пропусков:' as analysis,
       COUNT(*) FILTER (WHERE name IS NULL) as missing_name,
       COUNT(*) FILTER (WHERE email IS NULL) as missing_email,
       COUNT(*) FILTER (WHERE phone IS NULL) as missing_phone
FROM marketplace.users_cleaned
UNION ALL
SELECT 'products_cleaned - анализ пропусков:',
       COUNT(*) FILTER (WHERE title IS NULL),
       COUNT(*) FILTER (WHERE description IS NULL),
       COUNT(*) FILTER (WHERE price IS NULL)
FROM marketplace.products_cleaned
UNION ALL
SELECT 'reviews_cleaned - анализ пропусков:',
       COUNT(*) FILTER (WHERE rating IS NULL),
       COUNT(*) FILTER (WHERE comment IS NULL),
       COUNT(*) FILTER (WHERE comment IS NULL OR comment = '')
FROM marketplace.reviews_cleaned;

-- ============================================
-- 7. ЭКСПОРТ ДАННЫХ ЗА ПЕРИОД
-- ============================================

-- 7.1. Создаем выгрузку заказов с 2025-01-01 по 2025-06-01
CREATE TABLE marketplace.orders_jan_jun_2025 AS
SELECT * 
FROM marketplace.orders_cleaned 
WHERE order_date >= '2025-01-01' 
  AND order_date < '2025-06-01';

-- 7.2. Проверяем результат
SELECT 'orders_jan_jun_2025' as table_name, 
       COUNT(*) as row_count,
       MIN(order_date) as first_order,
       MAX(order_date) as last_order
FROM marketplace.orders_jan_jun_2025;

-- ============================================
-- 8. ФИНАЛЬНЫЙ ОТЧЕТ
-- ============================================

-- 8.1. Проверяем созданные таблицы
SELECT 'Созданные таблицы в схеме marketplace:' as report
UNION ALL
SELECT '--------------------------------------'
UNION ALL
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'marketplace' 
  AND table_name LIKE '%_cleaned%'
UNION ALL
SELECT ''
UNION ALL
SELECT 'orders_jan_jun_2025'
ORDER BY report DESC;

-- 8.2. Сводный отчет
SELECT '=== СВОДНЫЙ ОТЧЕТ ===' as report_section
UNION ALL
SELECT '====================='
UNION ALL
SELECT '1. ✅ Таблицы очищены от дубликатов (7 таблиц)'
UNION ALL
SELECT '2. ✅ Логические ошибки исправлены:'
UNION ALL
SELECT '   - Отрицательные цены → 0'
UNION ALL
SELECT '   - Отрицательное количество → 0'
UNION ALL
SELECT '   - Некорректные рейтинги → NULL'
UNION ALL
SELECT '3. ✅ Добавлены категориальные признаки в reviews:'
UNION ALL
SELECT '   - rating_category (текстовая)'
UNION ALL
SELECT '   - is_positive_review (бинарная)'
UNION ALL
SELECT '   - rating_group (групповая)'
UNION ALL
SELECT '4. ✅ Создана выгрузка заказов за 01.01-01.06.2025'
UNION ALL
SELECT '5. ✅ Данные готовы для анализа'
UNION ALL
SELECT '====================='
UNION ALL
SELECT 'Для экспорта выполните:'
UNION ALL
SELECT 'SELECT * FROM marketplace.orders_jan_jun_2025;'
UNION ALL
SELECT 'Затем правый клик → Экспорт данных → CSV';

-- Проверка NULL-значений в отдельных запросах (выполняйте по одному)

-- 1. Проверка transaction_date
SELECT 
    'transaction_date' as column_name,
    COUNT(*) as total_rows,
    COUNT(transaction_date) as not_null_count,
    COUNT(*) - COUNT(transaction_date) as null_count,
    ROUND((COUNT(*) - COUNT(transaction_date)) * 100.0 / COUNT(*), 2) as null_percent
FROM marketplace.transactions;

-- 2. Проверка price
SELECT 
    'price' as column_name,
    COUNT(*) as total_rows,
    COUNT(price) as not_null_count,
    COUNT(*) - COUNT(price) as null_count,
    ROUND((COUNT(*) - COUNT(price)) * 100.0 / COUNT(*), 2) as null_percent
FROM marketplace.products;

-- 3. Проверка rating
SELECT 
    'rating' as column_name,
    COUNT(*) as total_rows,
    COUNT(rating) as not_null_count,
    COUNT(*) - COUNT(rating) as null_count,
    ROUND((COUNT(*) - COUNT(rating)) * 100.0 / COUNT(*), 2) as null_percent
FROM marketplace.reviews;

-- 4. Проверка parent_category_id
SELECT 
    'parent_category_id' as column_name,
    COUNT(*) as total_rows,
    COUNT(parent_category_id) as not_null_count,
    COUNT(*) - COUNT(parent_category_id) as null_count,
    ROUND((COUNT(*) - COUNT(parent_category_id)) * 100.0 / COUNT(*), 2) as null_percent
FROM marketplace.categories;

-- Проверка NULL-значений в одном запросе
SELECT 
    'transaction_date' as column_name,
    (SELECT COUNT(*) FROM marketplace.transactions) as total_rows,
    (SELECT COUNT(*) - COUNT(transaction_date) FROM marketplace.transactions) as null_count
UNION ALL
SELECT 
    'price',
    (SELECT COUNT(*) FROM marketplace.products),
    (SELECT COUNT(*) - COUNT(price) FROM marketplace.products)
UNION ALL
SELECT 
    'rating',
    (SELECT COUNT(*) FROM marketplace.reviews),
    (SELECT COUNT(*) - COUNT(rating) FROM marketplace.reviews)
UNION ALL
SELECT 
    'parent_category_id',
    (SELECT COUNT(*) FROM marketplace.categories),
    (SELECT COUNT(*) - COUNT(parent_category_id) FROM marketplace.categories)
ORDER BY column_name;

-- 1. ОПИСАТЕЛЬНАЯ СТАТИСТИКА
-- Базовая описательная статистика
SELECT 
    'price' as feature,
    COUNT(*) as count,
    AVG(price) as mean,
    MIN(price) as min,
    MAX(price) as max,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY price) as median,
    PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY price) as q1,
    PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY price) as q3,
    STDDEV(price) as std_dev
FROM marketplace.products
WHERE price IS NOT NULL

UNION ALL

SELECT 
    'stock_quantity',
    COUNT(*),
    AVG(stock_quantity),
    MIN(stock_quantity),
    MAX(stock_quantity),
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY stock_quantity),
    PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY stock_quantity),
    PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY stock_quantity),
    STDDEV(stock_quantity)
FROM marketplace.products
WHERE stock_quantity IS NOT NULL
ORDER BY feature;

-- 2. ГИСТОГРАММЫ (Через группировку)
-- Гистограмма для price (ручное создание бинов)
SELECT 
    CASE 
        WHEN price < 100 THEN '0-100'
        WHEN price < 500 THEN '100-500'
        WHEN price < 1000 THEN '500-1000'
        WHEN price < 5000 THEN '1000-5000'
        ELSE '5000+'
    END as price_bin,
    COUNT(*) as frequency,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) as percentage
FROM marketplace.products
WHERE price IS NOT NULL
GROUP BY price_bin
ORDER BY 
    CASE price_bin
        WHEN '0-100' THEN 1
        WHEN '100-500' THEN 2
        WHEN '500-1000' THEN 3
        WHEN '1000-5000' THEN 4
        ELSE 5
    END;

-- Более детальная гистограмма (автоматические бины)
WITH price_bins AS (
    SELECT 
        WIDTH_BUCKET(price, 0, 5000, 20) as bin_num,
        COUNT(*) as frequency
    FROM marketplace.products
    WHERE price IS NOT NULL
    GROUP BY WIDTH_BUCKET(price, 0, 5000, 20)
)
SELECT 
    bin_num,
    ((bin_num - 1) * 250) || '-' || (bin_num * 250) as price_range,
    frequency,
    ROUND(frequency * 100.0 / SUM(frequency) OVER(), 2) as percentage
FROM price_bins
ORDER BY bin_num;

-- 3. ОБНАРУЖЕНИЕ ВЫБРОСОВ (Boxplot статистика)
-- Вычисление статистик для Boxplot
WITH price_stats AS (
    SELECT 
        PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY price) as q1,
        PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY price) as median,
        PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY price) as q3,
        PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY price) 
        - PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY price) as iqr
    FROM marketplace.products
    WHERE price IS NOT NULL
)
SELECT 
    'price' as feature,
    (SELECT MIN(price) FROM marketplace.products WHERE price IS NOT NULL) as min,
    ps.q1,
    ps.median,
    ps.q3,
    (SELECT MAX(price) FROM marketplace.products WHERE price IS NOT NULL) as max,
    ps.q1 - 1.5 * ps.iqr as lower_whisker,
    ps.q3 + 1.5 * ps.iqr as upper_whisker,
    COUNT(CASE WHEN p.price < ps.q1 - 1.5 * ps.iqr THEN 1 END) as lower_outliers,
    COUNT(CASE WHEN p.price > ps.q3 + 1.5 * ps.iqr THEN 1 END) as upper_outliers
FROM price_stats ps, marketplace.products p
GROUP BY ps.q1, ps.median, ps.q3, ps.iqr;

-- -- Вычисление статистик для Boxplot
WITH price_stats AS (
    SELECT 
        PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY price) as q1,
        PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY price) as median,
        PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY price) as q3,
        PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY price) 
        - PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY price) as iqr
    FROM marketplace.products
    WHERE price IS NOT NULL
)
SELECT 
    'price' as feature,
    (SELECT MIN(price) FROM marketplace.products WHERE price IS NOT NULL) as min,
    ps.q1,
    ps.median,
    ps.q3,
    (SELECT MAX(price) FROM marketplace.products WHERE price IS NOT NULL) as max,
    ps.q1 - 1.5 * ps.iqr as lower_whisker,
    ps.q3 + 1.5 * ps.iqr as upper_whisker,
    COUNT(CASE WHEN p.price < ps.q1 - 1.5 * ps.iqr THEN 1 END) as lower_outliers,
    COUNT(CASE WHEN p.price > ps.q3 + 1.5 * ps.iqr THEN 1 END) as upper_outliers
FROM price_stats ps, marketplace.products p
GROUP BY ps.q1, ps.median, ps.q3, ps.iqr;

-- 4. КОРРЕЛЯЦИОННЫЙ АНАЛИЗ
-- Корреляция Пирсона между price и stock_quantity
WITH stats AS (
    SELECT 
        COUNT(*) as n,
        SUM(price) as sum_x,
        SUM(stock_quantity) as sum_y,
        SUM(price * stock_quantity) as sum_xy,
        SUM(price * price) as sum_xx,
        SUM(stock_quantity * stock_quantity) as sum_yy
    FROM marketplace.products
    WHERE price IS NOT NULL AND stock_quantity IS NOT NULL
)
SELECT 
    'Корреляция Пирсона' as metric,
    ROUND(
        (n * sum_xy - sum_x * sum_y) / 
        SQRT((n * sum_xx - sum_x * sum_x) * (n * sum_yy - sum_y * sum_y))
    , 4) as value
FROM stats;

-- Корреляционная матрица для нескольких признаков
SELECT 
    CORR(price, stock_quantity) as price_stock_corr,
    CORR(price, 
         CASE WHEN category_id IS NOT NULL THEN category_id ELSE 0 END) as price_category_corr
FROM marketplace.products
WHERE price IS NOT NULL AND stock_quantity IS NOT NULL;

-- 5. ВИЗУАЛИЗАЦИЯ В DBEAVER
-- Способ 1: Встроенные графики

-- Выполните запрос с группировкой (как для гистограммы)

-- Правый клик на результате → "Просмотреть в виде" → "Столбчатая диаграмма"

-- Способ 2: Точечная диаграмма для корреляции
-- Данные для точечной диаграммы
SELECT price, stock_quantity
FROM marketplace.products
WHERE price IS NOT NULL AND stock_quantity IS NOT NULL
ORDER BY RANDOM()
LIMIT 1000;  -- Ограничиваем для лучшей производительности

-- Затем: Правый клик → "Просмотреть в виде" → "Диаграмма X/Y"
--Способ 3: Boxplot через агрегацию
-- Сводная статистика для ручного построения Boxplot
SELECT 
    'price' as feature,
    MIN(price) as min_value,
    PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY price) as q1,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY price) as median,
    PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY price) as q3,
    MAX(price) as max_value,
    COUNT(*) as total_count,
    COUNT(CASE WHEN price > PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY price) 
               + 1.5 * (PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY price) 
               - PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY price)) 
               THEN 1 END) as outliers_count
FROM marketplace.products
WHERE price IS NOT NULL;

-- 6. ПОЛНЫЙ АНАЛИТИЧЕСКИЙ ОТЧЕТ
-- Сводный отчет по анализу
WITH analysis AS (
    -- Основные статистики
    SELECT 
        'Общая статистика' as section,
        'Количество товаров' as metric,
        COUNT(*)::text as value
    FROM marketplace.products
    
    UNION ALL
    
    SELECT 'Общая статистика', 'Товары с ценой',
           COUNT(*) FILTER (WHERE price IS NOT NULL)::text
    FROM marketplace.products
    
    UNION ALL
    
    SELECT 'Общая статистика', 'Товары без цены',
           COUNT(*) FILTER (WHERE price IS NULL)::text
    FROM marketplace.products
    
    UNION ALL
    
    -- Статистики по price
    SELECT 'Анализ цен', 'Средняя цена',
           ROUND(AVG(price), 2)::text
    FROM marketplace.products
    WHERE price IS NOT NULL
    
    UNION ALL
    
    SELECT 'Анализ цен', 'Медианная цена',
           ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY price), 2)::text
    FROM marketplace.products
    WHERE price IS NOT NULL
    
    UNION ALL
    
    SELECT 'Анализ цен', 'Минимальная цена',
           MIN(price)::text
    FROM marketplace.products
    WHERE price IS NOT NULL
    
    UNION ALL
    
    SELECT 'Анализ цен', 'Максимальная цена',
           MAX(price)::text
    FROM marketplace.products
    WHERE price IS NOT NULL
    
    UNION ALL
    
    -- Корреляция
    SELECT 'Корреляционный анализ', 'Корреляция цена-остаток',
           ROUND(CORR(price, stock_quantity), 4)::text
    FROM marketplace.products
    WHERE price IS NOT NULL AND stock_quantity IS NOT NULL
    
    UNION ALL
    
    -- Выбросы
    SELECT 'Анализ выбросов', 'Экстремально дорогие товары',
           COUNT(*) FILTER (WHERE price > 10000)::text
    FROM marketplace.products
    
    UNION ALL
    
    SELECT 'Анализ выбросов', 'Бесплатные товары',
           COUNT(*) FILTER (WHERE price = 0)::text
    FROM marketplace.products
)
SELECT section, metric, value
FROM analysis
ORDER BY 
    CASE section
        WHEN 'Общая статистика' THEN 1
        WHEN 'Анализ цен' THEN 2
        WHEN 'Корреляционный анализ' THEN 3
        WHEN 'Анализ выбросов' THEN 4
    END,
    metric;
    
    -- Экспорт для дальнейшего анализа:
    -- Экспорт данных для анализа в Excel/Python
SELECT 
    product_id,
    title,
    price,
    stock_quantity,
    category_id,
    -- Дополнительные вычисляемые поля
    CASE 
        WHEN price < 100 THEN 'низкая'
        WHEN price < 1000 THEN 'средняя'
        ELSE 'высокая'
    END as price_category,
    CASE 
        WHEN stock_quantity = 0 THEN 'нет в наличии'
        WHEN stock_quantity < 10 THEN 'мало'
        WHEN stock_quantity < 100 THEN 'достаточно'
        ELSE 'много'
    END as stock_status
FROM marketplace.products
WHERE price IS NOT NULL
ORDER BY price DESC
LIMIT 1000;

-- Проверка диапазона значений для признаков в таблице products
SELECT 
    'price' as feature,
    MIN(price) as min_value,
    MAX(price) as max_value,
    MAX(price) - MIN(price) as range,
    ROUND(STDDEV(price), 2) as std_dev,
    'ШИРОКИЙ' as range_type
FROM marketplace.products
WHERE price IS NOT NULL

UNION ALL

SELECT 
    'stock_quantity',
    MIN(stock_quantity),
    MAX(stock_quantity),
    MAX(stock_quantity) - MIN(stock_quantity),
    ROUND(STDDEV(stock_quantity), 2),
    CASE 
        WHEN MAX(stock_quantity) - MIN(stock_quantity) > 1000 THEN 'ШИРОКИЙ'
        ELSE 'УЗКИЙ'
    END
FROM marketplace.products
WHERE stock_quantity IS NOT NULL

UNION ALL

SELECT 
    'rating',
    MIN(rating),
    MAX(rating),
    MAX(rating) - MIN(rating),
    ROUND(STDDEV(rating), 2),
    'УЗКИЙ'  -- Фиксированная шкала 1-5
FROM marketplace.reviews  -- rating в таблице reviews!
WHERE rating IS NOT NULL;

-- Реальный запрос для проверки
SELECT 
    ROUND(CORR(price, stock_quantity)::numeric, 4) as correlation,
    CASE 
        WHEN ABS(CORR(price, stock_quantity)) > 0.7 THEN 'Высокая'
        WHEN ABS(CORR(price, stock_quantity)) > 0.3 THEN 'Умеренная'
        WHEN ABS(CORR(price, stock_quantity)) > 0.1 THEN 'Слабая'
        ELSE 'Почти отсутствует'
    END as strength,
    CASE 
        WHEN CORR(price, stock_quantity) > 0 THEN 'положительная'
        WHEN CORR(price, stock_quantity) < 0 THEN 'отрицательная'
        ELSE 'нет'
    END as direction
FROM marketplace.products
WHERE price IS NOT NULL AND stock_quantity IS NOT NULL;

-- Проверяем, какие таблицы есть в схеме marketplace
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'marketplace'
ORDER BY table_name;

-- ПРОВЕРКА ДАННЫХ ДЛЯ ЭКСПОРТА
SELECT 
    '=== СТАТИСТИКА ВЫГРУЗКИ ===' as section,
    'Период: 01.01.2025 - 01.06.2025' as period
UNION ALL
SELECT 'Количество заказов:', COUNT(*)::text
FROM marketplace.orders 
WHERE order_date >= '2025-01-01' AND order_date < '2025-06-01'
UNION ALL
SELECT 'Общая сумма (GMV):', ROUND(SUM(total_amount)::numeric, 2)::text
FROM marketplace.orders 
WHERE order_date >= '2025-01-01' AND order_date < '2025-06-01'
UNION ALL
SELECT 'Средний чек:', ROUND(AVG(total_amount)::numeric, 2)::text
FROM marketplace.orders 
WHERE order_date >= '2025-01-01' AND order_date < '2025-06-01'
UNION ALL
SELECT 'Минимальный заказ:', ROUND(MIN(total_amount)::numeric, 2)::text
FROM marketplace.orders 
WHERE order_date >= '2025-01-01' AND order_date < '2025-06-01'
UNION ALL
SELECT 'Максимальный заказ:', ROUND(MAX(total_amount)::numeric, 2)::text
FROM marketplace.orders 
WHERE order_date >= '2025-01-01' AND order_date < '2025-06-01';

-- ПРЯМОЙ ЗАПРОС ДЛЯ ЭКСПОРТА (без создания таблицы)
SELECT 
    order_id,
    buyer_id,
    order_date,
    status,
    total_amount,
    EXTRACT(YEAR FROM order_date) as order_year,
    EXTRACT(MONTH FROM order_date) as order_month,
    TO_CHAR(order_date, 'Month') as month_name,
    EXTRACT(DAY FROM order_date) as order_day
FROM marketplace.orders 
WHERE order_date >= '2025-01-01' 
  AND order_date < '2025-06-01'
  AND status IS NOT NULL
  AND buyer_id IS NOT NULL
ORDER BY order_date;

-- ПРОВЕРКА ЧТО ДАННЫЕ ЕСТЬ
SELECT 
    'За период 2025-01-01 - 2025-06-01 найдено:' as info,
    COUNT(*) as orders_count,
    TO_CHAR(MIN(order_date), 'DD.MM.YYYY') as first_order,
    TO_CHAR(MAX(order_date), 'DD.MM.YYYY') as last_order
FROM marketplace.orders 
WHERE order_date >= '2025-01-01' 
  AND order_date < '2025-06-01';




Документация метрик маркетплейса
1. Базовые метрики
1.1 GMV (Gross Merchandise Value)

Логика расчёта:
sql

SELECT COALESCE(SUM(total_amount), 0) AS gmv
FROM marketplace.orders
WHERE status != 'canceled';

Источник данных: marketplace.orders
Комментарий: Общая сумма всех проведённых транзакций за выбранный период, исключая отменённые заказы. Показывает общий объём продаж на платформе.
Категория: Базовые
1.2 Количество заказов

Логика расчёта:
sql

SELECT COALESCE(COUNT(DISTINCT order_id), 0) AS orders_count
FROM marketplace.orders
WHERE status != 'canceled';

Источник данных: marketplace.orders
Комментарий: Общее количество успешных заказов. Помогает оценивать операционную нагрузку и общую активность на платформе.
Категория: Базовые
1.3 Количество продавцов

Логика расчёта:
sql

SELECT COALESCE(COUNT(DISTINCT user_id), 0) AS sellers_count
FROM marketplace.users
WHERE user_type = 'seller';

Источник данных: marketplace.users
Комментарий: Количество уникальных продавцов на платформе. Показатель разнообразия ассортимента и масштаба маркетплейса.
Категория: Базовые
1.4 Количество покупателей

Логика расчёта:
sql

SELECT COALESCE(COUNT(DISTINCT user_id), 0) AS buyers_count
FROM marketplace.users
WHERE user_type = 'buyer';

Источник данных: marketplace.users
Комментарий: Количество уникальных покупателей. Показатель пользовательской базы и потенциального рынка.
Категория: Базовые
1.5 Количество отзывов

Логика расчёта:
sql

SELECT COALESCE(COUNT(DISTINCT review_id), 0) AS reviews_count
FROM marketplace.reviews
WHERE comment IS NOT NULL AND comment != '';

Источник данных: marketplace.reviews
Комментарий: Количество отзывов с текстовыми комментариями. Показатель вовлечённости пользователей и качества сервиса.
Категория: Базовые
1.6 Средний рейтинг

Логика расчёта:
sql

SELECT ROUND(AVG(rating)::NUMERIC, 2) AS avg_rating
FROM marketplace.reviews;

Источник данных: marketplace.reviews
Комментарий: Средняя оценка товаров/услуг. Индикатор удовлетворённости пользователей и общего качества предложений.
Категория: Базовые
2. Производные метрики
2.1 Конверсия

Логика расчёта:
sql

SELECT 
  ROUND(
    COUNT(DISTINCT o.buyer_id)::NUMERIC / 
    COUNT(DISTINCT u.user_id)::NUMERIC, 
    4
  ) AS conversion_rate
FROM marketplace.users u
LEFT JOIN marketplace.orders o ON u.user_id = o.buyer_id
WHERE u.user_type = 'buyer';

Источник данных: marketplace.users + marketplace.orders
Комментарий: Доля зарегистрированных пользователей, совершивших хотя бы одну покупку. Ключевой показатель эффективности онбординга.
Категория: Производные
2.2 Средний чек

Логика расчёта:
sql

SELECT 
  ROUND(
    SUM(total_amount)::NUMERIC / 
    COUNT(DISTINCT order_id)::NUMERIC, 
    2
  ) AS average_check
FROM marketplace.orders
WHERE status != 'canceled';

Источник данных: marketplace.orders
Комментарий: Средняя стоимость одного заказа. Показывает покупательскую способность и эффективность up-selling стратегий.
Категория: Производные
2.3 Количество позиций в заказе

Логика расчёта:
sql

SELECT 
  ROUND(AVG(order_total_quantity), 2) AS avg_items_per_order
FROM (
  SELECT 
    order_id,
    SUM(quantity) AS order_total_quantity
  FROM marketplace.order_items
  GROUP BY order_id
) AS order_aggregates;

Источник данных: marketplace.order_items
Комментарий: Среднее количество товаров в одном заказе. Показатель эффективности cross-selling и размера корзины.
Категория: Производные
2.4 Retention Rate (когортный анализ)

Логика расчёта:
sql

WITH cohort_users AS (
  SELECT
    DATE_TRUNC('month', registration_date) AS cohort_month,
    COUNT(DISTINCT user_id) AS total_users
  FROM marketplace.users
  GROUP BY DATE_TRUNC('month', registration_date)
),
active_first_month AS (
  SELECT
    DATE_TRUNC('month', u.registration_date) AS cohort_month,
    COUNT(DISTINCT o.buyer_id) AS active_users
  FROM marketplace.users u
  JOIN marketplace.orders o ON u.user_id = o.buyer_id
  WHERE o.order_date >= u.registration_date
    AND o.order_date < u.registration_date + INTERVAL '1 month'
  GROUP BY DATE_TRUNC('month', u.registration_date)
)
SELECT
  c.cohort_month,
  c.total_users,
  COALESCE(a.active_users, 0) AS active_users_first_month,
  ROUND(a.active_users::numeric / c.total_users::numeric, 4) AS retention_rate
FROM cohort_users c
LEFT JOIN active_first_month a ON c.cohort_month = a.cohort_month
ORDER BY c.cohort_month;

Источник данных: marketplace.users + marketplace.orders
Комментарий: Доля пользователей, совершивших покупку в первый месяц после регистрации. Показатель качества привлечения и первоначального опыта.
Категория: Производные
2.5 LTV (Lifetime Value)

Логика расчёта:
sql

WITH cohort_users AS (
  SELECT
    DATE_TRUNC('month', registration_date) AS cohort_month,
    COUNT(DISTINCT user_id) AS total_users
  FROM marketplace.users
  GROUP BY DATE_TRUNC('month', registration_date)
),
cohort_revenue_3month AS (
  SELECT
    DATE_TRUNC('month', u.registration_date) AS cohort_month,
    SUM(o.total_amount::NUMERIC) AS three_month_revenue
  FROM marketplace.users u
  JOIN marketplace.orders o ON u.user_id = o.buyer_id
  WHERE o.order_date >= u.registration_date
    AND o.order_date < u.registration_date + INTERVAL '3 months'
  GROUP BY DATE_TRUNC('month', u.registration_date)
)
SELECT
  c.cohort_month,
  c.total_users,
  COALESCE(r.three_month_revenue, 0) AS three_month_revenue,
  ROUND(
    COALESCE(r.three_month_revenue, 0) / 
    c.total_users, 
    2
  ) AS ltv_3_month
FROM cohort_users c
LEFT JOIN cohort_revenue_3month r ON c.cohort_month = r.cohort_month
ORDER BY c.cohort_month;

Источник данных: marketplace.users + marketplace.orders
Комментарий: Средняя выручка с пользователя за первые 3 месяца. Показатель долгосрочной ценности клиента и окупаемости CAC.
Категория: Производные
2.6 ARPU (Average Revenue Per User)

Логика расчёта:
sql

WITH total_revenue AS (
  SELECT SUM(total_amount) AS revenue
  FROM marketplace.orders
  WHERE order_date BETWEEN '2025-01-01' AND '2025-05-31'
    AND status != 'canceled'
),
total_users AS (
  SELECT COUNT(DISTINCT user_id) AS users_count
  FROM marketplace.users
  WHERE registration_date <= '2025-05-31'
)
SELECT
  ROUND(tr.revenue::numeric / tu.users_count::numeric) AS ARPU
FROM total_revenue tr, total_users tu;

Источник данных: marketplace.orders
Комментарий: Средний доход на одного зарегистрированного пользователя. Показатель общей монетизации пользовательской базы.
Категория: Производные
2.7 ARPPU (Average Revenue Per Paying User)

Логика расчёта:
sql

WITH paying_users AS (
  SELECT DISTINCT buyer_id
  FROM marketplace.orders
  WHERE order_date BETWEEN '2025-05-01' AND '2025-05-31'
    AND status != 'canceled'
),
revenue AS (
  SELECT
    SUM(total_amount::NUMERIC) AS total_revenue
  FROM marketplace.orders
  WHERE order_date BETWEEN '2025-05-01' AND '2025-05-31'
    AND status != 'canceled'
)
SELECT
  r.total_revenue,
  COUNT(p.buyer_id) AS paying_users_count,
  ROUND(r.total_revenue::numeric / COUNT(p.buyer_id)::numeric, 2) AS arppu
FROM revenue r, paying_users p
GROUP BY r.total_revenue;

Источник данных: marketplace.orders
Комментарий: Средний доход на одного платящего пользователя. Показывает ценность активных клиентов.
Категория: Производные
2.8 DAU (Daily Active Users)

Логика расчёта:
sql

SELECT
  order_date::date AS order_dttm,
  COUNT(DISTINCT buyer_id) AS dau
FROM marketplace.orders
WHERE order_date BETWEEN '2025-05-01' AND '2025-05-31'
GROUP BY order_dttm
ORDER BY order_dttm;

Источник данных: marketplace.orders
Комментарий: Количество уникальных пользователей, совершивших заказы в течение дня. Показатель ежедневной активности и вовлечённости.
Категория: Производные
3. Фильтры для анализа
3.1 Дата

Значение фильтра: Дата
Комментарий: Для анализа данных в заданный период. Позволяет сравнивать показатели за разные периоды времени.
3.2 Категория товара

Значение фильтра: Значение name из таблицы marketplace.categories
Комментарий: Для проверки эффективности отдельных категорий. Помогает анализировать performance конкретных товарных групп.
3.3 Статус заказа

Значение фильтра: Значение status из таблицы marketplace.orders
Комментарий: Для анализа воронки заказов. Позволяет отслеживать конверсию на разных этапах жизненного цикла заказа.
3.4 Диапазон рейтингов

Значение фильтра: Значение rating из таблицы marketplace.reviews (например: 4.5-5, 4-4.5, 3.5-4, 3-3.5, <3)
Комментарий: Для анализа удовлетворённости пользователей. Помогает выявлять проблемные зоны в качестве товаров/услуг.

Дата составления документации: [Текущая дата]
Ответственный: Аналитик маркетплейса
Статус: Завершено
