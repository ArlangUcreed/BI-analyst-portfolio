-- =============================================
-- ПРОЕКТ GAMEBASE - ПОЛНЫЙ SQL СКРИПТ
-- Восстановление и оптимизация базы данных
-- =============================================

-- Создание базы данных (выполнить отдельно)
-- CREATE DATABASE sprint15_project;

-- Подключение к базе sprint15_project

-- =============================================
-- ЭТАП 1: ВОССТАНОВЛЕНИЕ СТРУКТУРЫ (DDL)
-- =============================================

-- Добавление первичных ключей
ALTER TABLE steam.players ADD PRIMARY KEY (player_id);
ALTER TABLE steam.games ADD PRIMARY KEY (game_id);
ALTER TABLE steam.achievements ADD PRIMARY KEY (achievement_id);
ALTER TABLE steam.reviews ADD PRIMARY KEY (review_id);
ALTER TABLE steam.private_steamids ADD PRIMARY KEY (player_id);

-- Добавление внешних ключей
ALTER TABLE steam.purchased_games ADD FOREIGN KEY (player_id) REFERENCES steam.players(player_id);
ALTER TABLE steam.purchased_games ADD FOREIGN KEY (game_id) REFERENCES steam.games(game_id);
ALTER TABLE steam.reviews ADD FOREIGN KEY (player_id) REFERENCES steam.players(player_id);
ALTER TABLE steam.reviews ADD FOREIGN KEY (game_id) REFERENCES steam.games(game_id);
ALTER TABLE steam.achievements ADD FOREIGN KEY (game_id) REFERENCES steam.games(game_id);
ALTER TABLE steam.history ADD FOREIGN KEY (player_id) REFERENCES steam.players(player_id);
ALTER TABLE steam.history ADD FOREIGN KEY (achievement_id) REFERENCES steam.achievements(achievement_id);
ALTER TABLE steam.friends ADD FOREIGN KEY (player_id) REFERENCES steam.players(player_id);
ALTER TABLE steam.friends ADD FOREIGN KEY (friend) REFERENCES steam.players(player_id);

-- Выполняем проверку таблиц
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'steam'
ORDER BY table_name;

-- =============================================
-- ЭТАП 2: ПОДДЕРЖКА АКТУАЛЬНОСТИ ДАННЫХ
-- =============================================

-- Задание 1: Удаление тестового отзыва
DELETE FROM steam.reviews WHERE review_id = 659351;

-- Проверка количества отзывов после удаления
SELECT COUNT(*) as reviews_after_deletion FROM steam.reviews;

-- Задание 2: Добавление нового отзыва
INSERT INTO steam.reviews (review_id, player_id, game_id, review, helpful, funny, awards, posted) 
VALUES (1185896, 76561198012771369, 280, 'Отличная игра!', 0, 0, 9, '2025-04-28');

-- Проверка среднего количества наград для Half-Life: Source
SELECT ROUND(AVG(r.awards)) as avg_awards
FROM steam.reviews r
JOIN steam.games g ON r.game_id = g.game_id
WHERE g.title = 'Half-Life: Source';

-- =============================================
-- ЭТАП 3: ОПТИМИЗАЦИЯ ЗАПРОСА
-- =============================================

-- Исходный медленный запрос (для сравнения)
/*
SELECT *
FROM players p
INNER JOIN (SELECT * FROM purchased_games ORDER BY 1, 2) pg ON p.player_id = pg.player_id
FULL JOIN (SELECT * FROM games ORDER BY 1, 2, 3, 4, 5) g ON pg.game_id = g.game_id
WHERE p.player_id IS NOT NULL AND g.title != 'NULL'
AND p.created IS NOT NULL
ORDER BY p.country, g.developers;
*/

-- Оптимизированная версия запроса
SELECT 
    p.player_id,
    g.title,
    g.genres
FROM steam.players p
INNER JOIN steam.purchased_games pg ON p.player_id = pg.player_id
INNER JOIN steam.games g ON pg.game_id = g.game_id;

-- =============================================
-- ЭТАП 4: ПРАКТИКА С ИНДЕКСАМИ
-- =============================================

-- Проблема 1: Быстрый поиск достижений по игре

-- Проверка стоимости запроса ДО создания индекса
EXPLAIN ANALYZE 
SELECT * FROM steam.achievements WHERE game_id = 12345;

-- Создание Hash-индекса для точного поиска
CREATE INDEX CONCURRENTLY idx_achievements_game_id_hash ON steam.achievements USING HASH (game_id);

-- Проверка стоимости запроса ПОСЛЕ создания индекса
EXPLAIN ANALYZE 
SELECT * FROM steam.achievements WHERE game_id = 12345;

-- Проблема 2: Сортировка достижений

-- Проверка стоимости запроса ДО создания индекса
EXPLAIN ANALYZE 
SELECT * FROM steam.history ORDER BY player_id;

-- Создание B-Tree индекса для оптимизации сортировки
CREATE INDEX CONCURRENTLY idx_history_player_id ON steam.history(player_id);

-- Проверка стоимости запроса ПОСЛЕ создания индекса
EXPLAIN ANALYZE 
SELECT * FROM steam.history ORDER BY player_id;

-- =============================================
-- ЭТАП 5: ПАРТИЦИОНИРОВАНИЕ
-- =============================================

-- Создание основной таблицы с партиционированием
CREATE TABLE steam.history_partitioned (
    player_id BIGINT,
    achievement_id TEXT,
    date_acquired TIMESTAMP
) PARTITION BY RANGE (date_acquired);

-- Создание партиций по годам
CREATE TABLE steam.history_2023 PARTITION OF steam.history_partitioned
    FOR VALUES FROM ('2023-01-01') TO ('2024-01-01');
    
CREATE TABLE steam.history_2024 PARTITION OF steam.history_partitioned
    FOR VALUES FROM ('2024-01-01') TO ('2025-01-01');

-- Перенос данных из старой таблицы в партиционированную
INSERT INTO steam.history_partitioned (player_id, achievement_id, date_acquired)
SELECT player_id, achievement_id, date_acquired FROM steam.history;

-- Проверка распределения данных по партициям
SELECT 
    tableoid::regclass as partition_name,
    COUNT(*) as record_count
FROM steam.history_partitioned 
GROUP BY tableoid::regclass
ORDER BY partition_name;

-- =============================================
-- ЭТАП 6: СОЗДАНИЕ ВИТРИНЫ ДЛЯ АНАЛИТИКИ
-- =============================================

-- Создание таблицы для витрины
CREATE TABLE steam.player_activity_mart (
    player_id BIGINT,
    country TEXT,
    game_id INTEGER,
    game_title TEXT,
    achievement_id TEXT,
    date_acquired TIMESTAMP,
    review_id BIGINT,
    review TEXT,
    helpful_reviews_count BIGINT,
    funny_reviews_count BIGINT,
    awards_reviews_count BIGINT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Заполнение витрины данными согласно ТЗ
INSERT INTO steam.player_activity_mart (
    player_id, country, game_id, game_title, achievement_id, 
    date_acquired, review_id, review, helpful_reviews_count, 
    funny_reviews_count, awards_reviews_count
)
SELECT
    p.player_id,
    COALESCE(p.country, 'Не указана') as country,
    g.game_id,
    g.title AS game_title,
    h.achievement_id,
    h.date_acquired,
    r.review_id,
    r.review,
    r.helpful AS helpful_reviews_count,
    r.funny AS funny_reviews_count,
    r.awards AS awards_reviews_count
FROM steam.players p
INNER JOIN steam.purchased_games pg ON p.player_id = pg.player_id
INNER JOIN steam.games g ON pg.game_id = g.game_id
INNER JOIN steam.achievements a ON g.game_id = a.game_id
INNER JOIN steam.history_partitioned h ON h.achievement_id = a.achievement_id AND h.player_id = p.player_id
LEFT JOIN steam.reviews r ON p.player_id = r.player_id AND g.game_id = r.game_id
WHERE h.date_acquired BETWEEN '2024-01-01' AND '2024-12-31'
 AND p.player_id IN (
     SELECT player_id
     FROM steam.purchased_games
     GROUP BY player_id
     HAVING COUNT(DISTINCT game_id) > 3
 );

-- =============================================
-- ПРОВЕРКИ И ВАЛИДАЦИЯ
-- =============================================

-- Проверка количества записей в витрине
SELECT COUNT(*) as total_records FROM steam.player_activity_mart;

-- Проверка структуры витрины
SELECT 
    column_name, 
    data_type, 
    is_nullable
FROM information_schema.columns 
WHERE table_schema = 'steam' 
AND table_name = 'player_activity_mart'
ORDER BY ordinal_position;

-- Проверка распределения по странам
SELECT 
    country,
    COUNT(*) as player_count,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM steam.player_activity_mart), 2) as percentage
FROM steam.player_activity_mart
GROUP BY country
ORDER BY player_count DESC;

-- Проверка топ игр по количеству достижений
SELECT 
    game_title,
    COUNT(DISTINCT achievement_id) as unique_achievements,
    COUNT(*) as total_achievements
FROM steam.player_activity_mart
GROUP BY game_title
ORDER BY total_achievements DESC
LIMIT 10;

-- Проверка активности по месяцам 2024 года
SELECT 
    EXTRACT(MONTH FROM date_acquired) as month,
    COUNT(*) as achievements_count
FROM steam.player_activity_mart
WHERE EXTRACT(YEAR FROM date_acquired) = 2024
GROUP BY EXTRACT(MONTH FROM date_acquired)
ORDER BY month;

-- =============================================
-- ДОПОЛНИТЕЛЬНЫЕ ИНДЕКСЫ ДЛЯ ВИТРИНЫ
-- =============================================

-- Индекс для быстрого поиска по игроку
CREATE INDEX idx_mart_player_id ON steam.player_activity_mart(player_id);

-- Индекс для фильтрации по дате
CREATE INDEX idx_mart_date_acquired ON steam.player_activity_mart(date_acquired);

-- Индекс для поиска по игре
CREATE INDEX idx_mart_game_id ON steam.player_activity_mart(game_id);

-- Составной индекс для часто используемых фильтров
CREATE INDEX idx_mart_country_date ON steam.player_activity_mart(country, date_acquired);

-- =============================================
-- ФИНАЛЬНЫЕ СТАТИСТИКИ
-- =============================================

-- Общая статистика по базе данных
SELECT 
    (SELECT COUNT(*) FROM steam.players) as total_players,
    (SELECT COUNT(*) FROM steam.games) as total_games,
    (SELECT COUNT(*) FROM steam.achievements) as total_achievements,
    (SELECT COUNT(*) FROM steam.reviews) as total_reviews,
    (SELECT COUNT(*) FROM steam.history) as total_history_records,
    (SELECT COUNT(*) FROM steam.purchased_games) as total_purchases,
    (SELECT COUNT(*) FROM steam.player_activity_mart) as mart_records;

-- Проверка созданных индексов
SELECT 
    schemaname,
    tablename,
    indexname,
    indexdef
FROM pg_indexes 
WHERE schemaname = 'steam'
ORDER BY tablename, indexname;

-- =============================================
-- ПРИМЕРЫ АНАЛИТИЧЕСКИХ ЗАПРОСОВ К ВИТРИНЕ
-- =============================================

-- Топ 10 самых активных игроков
SELECT 
    player_id,
    country,
    COUNT(DISTINCT game_id) as games_played,
    COUNT(DISTINCT achievement_id) as achievements_earned,
    COUNT(DISTINCT review_id) as reviews_written
FROM steam.player_activity_mart
GROUP BY player_id, country
ORDER BY achievements_earned DESC
LIMIT 10;

-- Распределение наград за отзывы
SELECT 
    awards_reviews_count,
    COUNT(*) as reviews_count
FROM steam.player_activity_mart
WHERE awards_reviews_count > 0
GROUP BY awards_reviews_count
ORDER BY awards_reviews_count DESC;

-- Активность по странам
SELECT 
    country,
    COUNT(DISTINCT player_id) as unique_players,
    COUNT(*) as total_achievements,
    ROUND(AVG(awards_reviews_count), 2) as avg_awards_per_review
FROM steam.player_activity_mart
GROUP BY country
ORDER BY total_achievements DESC;

-- Ежемесячная активность в 2024 году
SELECT 
    TO_CHAR(date_acquired, 'YYYY-MM') as month,
    COUNT(DISTINCT player_id) as active_players,
    COUNT(*) as achievements_earned
FROM steam.player_activity_mart
WHERE date_acquired BETWEEN '2024-01-01' AND '2024-12-31'
GROUP BY TO_CHAR(date_acquired, 'YYYY-MM')
ORDER BY month;

-- =============================================
-- ОЧИСТКА (при необходимости)
-- =============================================
--
-- Удаление витрины:
-- DROP TABLE IF EXISTS steam.player_activity_mart;
--
-- Удаление индексов:
-- DROP INDEX IF EXISTS steam.idx_achievements_game_id_hash;
-- DROP INDEX IF EXISTS steam.idx_history_player_id;
-- DROP INDEX IF EXISTS steam.idx_mart_player_id;
-- DROP INDEX IF EXISTS steam.idx_mart_date_acquired;
-- DROP INDEX IF EXISTS steam.idx_mart_game_id;
-- DROP INDEX IF EXISTS steam.idx_mart_country_date;
--
-- Удаление партиционированной таблицы:
-- DROP TABLE IF EXISTS steam.history_partitioned CASCADE;
