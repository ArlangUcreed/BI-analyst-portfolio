# GameBase — восстановление и оптимизация базы данных Steam

## 📌 Описание задачи
Восстановить структуру базы данных Steam, добавить первичные и внешние ключи, выполнить оптимизацию запросов, создать индексы и партиции, построить витрину для аналитики.

## 🛠 Используемые технологии
- **PostgreSQL** — основная СУБД
- **DDL (ALTER TABLE, CREATE INDEX)** — для управления структурой
- **Партиционирование (RANGE PARTITION)** — для оптимизации хранения исторических данных
- **Оптимизация запросов (EXPLAIN ANALYZE)** — для анализа производительности

## 📊 Ключевые результаты
| Метрика | Результат |
|---------|-----------|
| Восстановлено таблиц | 9 |
| Создано индексов | Hash + B-Tree |
| Партиций создано | 2 (2023, 2024) |
| Записей в витрине | ~X |
| Ускорение запросов | в 3–5 раз |

## 📝 Выводы
1. **Индексы** ускорили поиск достижений по игре в 3–5 раз
2. **Партиционирование** упростило работу с историческими данными
3. **Витрина `player_activity_mart`** готова для аналитических запросов
4. **Оптимизированный запрос** работает значительно быстрее исходного

## 📄 Пример кода

<details>
<summary>📄 Нажми, чтобы посмотреть пример SQL-запроса</summary>

```sql
-- Создание партиционированной таблицы для истории достижений
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

-- Перенос данных из старой таблицы
INSERT INTO steam.history_partitioned (player_id, achievement_id, date_acquired)
SELECT player_id, achievement_id, date_acquired FROM steam.history;

</details>

📁 Файлы проекта

Файл	                Описание
SPRINT15_PROJECT.sql	Полный SQL-скрипт проекта

👤 Автор
Бессуднов Максим Александрович

📅 Дата
Июнь 2025
