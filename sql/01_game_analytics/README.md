# Анализ игровых покупок в «Секреты Тёмнолесья»

## 📌 Описание задачи
Изучить влияние характеристик игроков и их игровых персонажей на покупку внутриигровой валюты «райские лепестки», а также оценить активность игроков при совершении внутриигровых покупок.

## 🛠 Используемые технологии
- **PostgreSQL** — основная СУБД для анализа
- **CTE (Common Table Expressions)** — для структурирования сложных запросов
- **Оконные функции** — LAG, NTILE для анализа временных рядов и сегментации
- **Агрегатные функции** — SUM, AVG, COUNT, PERCENTILE_CONT

## 📊 Ключевые результаты

| Метрика | Результат |
|---------|-----------|
| Общая доля платящих игроков | ~X% |
| Раса с наибольшей долей платящих | Эльфы |
| Раса с наименьшей долей платящих | Орки |
| Доля нулевых покупок | X% |
| Топ-1 эпический предмет | "Меч Тьмы" |
| Сегмент с высокой частотой покупок | Игроки с >25 покупками |

## 📝 Выводы
1. **Доля платящих игроков** составляет ~X% от всей аудитории
2. **Наибольшая платёжеспособность** у расы «Эльфы», наименьшая — у «Орков»
3. **Нулевые покупки** составляют X% — возможно, это технические сбои или тестовые транзакции
4. **Игроки с высокой частотой покупок** (>25 транзакций) тратят в среднем на X% больше
5. **Топ-10 эпических предметов** формируют X% всей выручки

## 📄 Пример кода

<details>
<summary>📄 Нажми, чтобы посмотреть пример SQL-запроса</summary>

```sql
-- Анализ доли платящих игроков по расам
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

</details>
📁 Файлы проекта
Файл	Описание
SPRINT4_project_Bessudnov M.A.sql	Полный SQL-код проекта
👤 Автор

Бессуднов Максим Александрович
📅 Дата

12 апреля 2025
