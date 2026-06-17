/* Проект «Секреты Тёмнолесья»
 * Цель проекта: изучить влияние характеристик игроков и их игровых персонажей 
 * на покупку внутриигровой валюты «райские лепестки», а также оценить 
 * активность игроков при совершении внутриигровых покупок
 * 
 * Автор: Бессуднов Максим Александрович
 * Дата: 12.04.2025
*/

-- Часть 1. Исследовательский анализ данных
-- Задача 1. Исследование доли платящих игроков
WITH total_players AS (
    SELECT 
        COUNT(*) AS total_players,
        SUM(u.payer) AS paying_players,
        SUM(u.payer) * 1.0 / COUNT(*) AS paying_percentage
    FROM 
        fantasy.users AS u
    JOIN 
        fantasy.events AS e ON u.id = e.id
),
race_stats AS (
    SELECT 
        r.race AS race,
        SUM(u.payer) AS paying_players,
        COUNT(*) AS total_players,
        SUM(u.payer) * 1.0 / COUNT(*) AS paying_percentage
    FROM 
        fantasy.users AS u
    JOIN 
        fantasy.events AS e ON u.id = e.id
    JOIN 
        fantasy.race AS r ON u.race_id = r.race_id
    GROUP BY 
        r.race
)
SELECT 
    'Total' AS category,
    tp.total_players,
    tp.paying_players,
    tp.paying_percentage
FROM 
    total_players tp
UNION ALL
SELECT 
    rs.race AS category,
    rs.total_players,
    rs.paying_players,
    rs.paying_percentage
FROM 
    race_stats rs
ORDER BY 
    paying_players DESC;

-- 1.1. Доля платящих пользователей по всем данным
SELECT 
    COUNT(*) AS total_players,
    SUM(u.payer) AS paying_players,
    AVG(u.payer) AS paying_percentage
FROM 
    fantasy.users AS u
JOIN 
    fantasy.events AS e ON u.id = e.id
ORDER BY 
    total_players DESC;

-- 1.2. Доля платящих пользователей в разрезе расы персонажа
SELECT 
    r.race AS race,
    SUM(u.payer) AS paying_players,
    COUNT(*) AS total_players,
    SUM(u.payer) * 1.0 / COUNT(*) AS paying_percentage
FROM 
    fantasy.users AS u
JOIN 
    fantasy.race AS r ON u.race_id = r.race_id
JOIN 
    fantasy.events AS e ON u.id = e.id
GROUP BY 
    r.race
ORDER BY 
    paying_players DESC;

-- Задача 2. Исследование внутриигровых покупок
-- 2.1. Статистические показатели по полю amount
SELECT 
    COUNT(*) AS total_purchases,
    ROUND(SUM(amount)::numeric, 2) AS total_cost,
    ROUND(MIN(amount)::numeric, 2) AS min_cost,
    ROUND(MAX(amount)::numeric, 2) AS max_cost,
    ROUND(AVG(amount)::numeric, 2) AS avg_cost,
    ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY amount)::numeric, 2) AS median_cost,
    ROUND(STDDEV(amount)::numeric, 2) AS stddev_cost
FROM 
    fantasy.events
WHERE 
    amount > 0;

-- 2.2: Аномальные нулевые покупки
WITH total_purchases AS (
    SELECT COUNT(*) AS total_count
    FROM fantasy.events
),
zero_cost_purchases AS (
    SELECT COUNT(*) AS zero_count
    FROM fantasy.events
    WHERE amount = 0
)
SELECT 
    z.zero_count,
    t.total_count,
    ROUND((z.zero_count::numeric / t.total_count) * 100, 2) AS zero_purchase_percentage
FROM 
    total_purchases AS t,
    zero_cost_purchases AS z;

-- 2.3: Сравнительный анализ активности платящих и неплатящих игроков
SELECT 
    CASE 
        WHEN u.payer = 1 THEN 'Платящий'
        ELSE 'Неплатящий'
    END AS player_type,
    COUNT(DISTINCT u.id) AS player_count,
    COUNT(e.id) AS total_purchases,
    COALESCE(SUM(CAST(e.amount AS numeric)), 0) AS total_revenue,
    COALESCE(COUNT(e.id)::numeric / NULLIF(COUNT(DISTINCT u.id), 0), 0) AS avg_purchases_per_player,
    COALESCE(SUM(CAST(e.amount AS numeric))::numeric / NULLIF(COUNT(DISTINCT u.id), 0), 0) AS avg_revenue_per_player
FROM 
    fantasy.users AS u
JOIN 
    fantasy.events e ON u.id = e.id
GROUP BY 
    u.payer;

-- 2.4: Популярные эпические предметы
SELECT 
    i.item_code,
    i.game_items,
    COUNT(e.transaction_id) AS transaction_count,
    COUNT(DISTINCT e.id) AS unique_players,
    COUNT(DISTINCT e.id) * 1.0 / NULLIF((SELECT COUNT(DISTINCT id) FROM fantasy.events), 0) AS player_share,
    COUNT(e.transaction_id) * 1.0 / NULLIF((SELECT COUNT(transaction_id) FROM fantasy.events), 0) AS transaction_share
FROM 
    fantasy.items i
LEFT JOIN 
    fantasy.events e ON i.item_code = e.item_code
GROUP BY 
    i.item_code, i.game_items
ORDER BY 
    transaction_count DESC
LIMIT 10;

-- Часть 2. Решение ad hoc-задач
-- Задача 1. Зависимость активности игроков от расы персонажа
WITH player_activity AS (
    SELECT 
        u.race_id,
        COUNT(DISTINCT u.id) AS total_players,
        COUNT(DISTINCT CASE WHEN u.payer = 1 THEN u.id END) AS paying_players,
        COUNT(DISTINCT e.id) AS buying_players,
        SUM(e.amount) AS total_spent,
        COUNT(e.transaction_id) AS total_purchases
    FROM 
        fantasy.users u
    LEFT JOIN 
        fantasy.events e ON u.id = e.id
    GROUP BY 
        u.race_id
),
paying_clients AS (
    SELECT 
        u.race_id,
        COUNT(DISTINCT u.id) AS unique_paying_clients
    FROM 
        fantasy.users u
    WHERE 
        u.payer = 1
    GROUP BY 
        u.race_id
)
SELECT 
    r.race AS race_name,
    pa.total_players,
    pa.buying_players,
    pa.paying_players,
    CASE 
        WHEN pa.total_players > 0 THEN pa.buying_players * 1.0 / pa.total_players
        ELSE 0
    END AS buying_players_ratio,
    CASE 
        WHEN pa.buying_players > 0 THEN pc.unique_paying_clients * 1.0 / pa.buying_players
        ELSE 0
    END AS paying_players_ratio,
    CASE 
        WHEN pa.buying_players > 0 THEN pa.total_purchases * 1.0 / pa.buying_players
        ELSE 0
    END AS avg_purchases_per_player,
    CASE 
        WHEN pa.total_purchases > 0 THEN pa.total_spent * 1.0 / pa.total_purchases
        ELSE 0
    END AS avg_purchase_value,
    CASE 
        WHEN pa.total_players > 0 THEN pa.total_spent * 1.0 / pa.total_players
        ELSE 0
    END AS avg_total_spent_per_player
FROM 
    player_activity pa
JOIN 
    paying_clients pc ON pa.race_id = pc.race_id
JOIN 
    fantasy.race r ON pa.race_id = r.race_id
ORDER BY 
    r.race;

-- Задача 2: Частота покупок
WITH purchases AS (
    SELECT 
        e.id AS player_id,
        TO_DATE(e.date, 'YYYY-MM-DD') AS purchase_date,
        e.amount
    FROM 
        fantasy.events e
    WHERE e.amount > 0
),
purchases_with_intervals AS (
    SELECT 
        player_id,
        purchase_date,
        LAG(purchase_date) OVER (PARTITION BY player_id ORDER BY purchase_date) AS previous_purchase,
        amount
    FROM 
        purchases
),
purchase_intervals AS (
    SELECT 
        pw.player_id,
        COUNT(*) AS total_purchases,
        AVG((purchase_date - previous_purchase)) AS avg_days_between_purchases,
        CASE 
            WHEN COUNT(*) >= 25 THEN 1
            ELSE 0 
        END AS is_paying
    FROM 
        purchases_with_intervals pw
    WHERE previous_purchase IS NOT NULL
    GROUP BY 
        pw.player_id
    HAVING COUNT(*) >= 25
),
ranked_players AS (
    SELECT 
        pi.player_id,
        pi.total_purchases,
        pi.avg_days_between_purchases,
        CASE 
            WHEN u.payer = 1 THEN 1
            ELSE 0 
        END AS is_paying,
        NTILE(3) OVER (ORDER BY pi.avg_days_between_purchases) AS frequency_group
    FROM 
        purchase_intervals pi
    JOIN 
        fantasy.users u ON pi.player_id = u.id
),
group_summary AS (
    SELECT 
        frequency_group,
        COUNT(DISTINCT player_id) AS player_count,
        SUM(is_paying) AS paying_players,
        AVG(total_purchases) AS avg_purchases_per_player,
        AVG(avg_days_between_purchases) AS avg_days_between_purchases
    FROM 
        ranked_players
    GROUP BY 
        frequency_group
)
SELECT 
    CASE 
        WHEN frequency_group = 1 THEN 'высокая частота'
        WHEN frequency_group = 2 THEN 'умеренная частота'
        WHEN frequency_group = 3 THEN 'низкая частота'
    END AS purchase_frequency,
    player_count,
    paying_players,
    paying_players::FLOAT / player_count AS paying_ratio,
    avg_purchases_per_player,
    avg_days_between_purchases
FROM 
    group_summary
ORDER BY 
    frequency_group;
