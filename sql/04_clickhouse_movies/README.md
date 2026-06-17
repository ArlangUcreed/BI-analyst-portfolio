# Киноаналитика в ClickHouse

## 📌 Описание задачи
Анализ рейтингов фильмов с использованием ClickHouse. Исследование динамики рейтингов по годам, сравнение российского и зарубежного кино, анализ студий и режиссёров.

## 🛠 Используемые технологии
- **ClickHouse** — колоночная СУБД для аналитики
- **Работа с массивами** — groupArray, arrayFilter, arrayJoin
- **Оконные функции** — lagInFrame, ROW_NUMBER
- **Статистические тесты** — Манна-Уитни, Уэлча

## 📊 Ключевые результаты
| Метрика | Результат |
|---------|-----------|
| Средний рейтинг фильмов | ~X |
| Доля художественных фильмов | ~75% |
| Страна с самым высоким рейтингом | X |
| Режиссёр с самым высоким рейтингом | X |
| Корреляция кассовых сборов и рейтинга | X |

## 📝 Выводы
1. **Доля художественных фильмов** сокращается в последние годы
2. **Российские фильмы** в среднем имеют более низкие рейтинги, чем зарубежные
3. **Режиссёры со стабильно высокими рейтингами** сняли более 10 фильмов
4. **Кассовые сборы** слабо коррелируют с пользовательскими оценками
5. **Аниме** — жанр с самыми преданными зрителями (высокие оценки)

## 📄 Пример кода

<details>
<summary>📄 Нажми, чтобы посмотреть пример SQL-запроса</summary>

```sql
-- Анализ динамики рейтингов по годам
WITH
  (SELECT avgIf(ratings, ratings<10)
   FROM source_db.screenings) AS mean_rating
SELECT year,
       ROUND(100 * uniqIf(title, fiction_film) / uniq(title), 1) AS fiction_films_ratio,
       ROUND(avg(corrected_ratings), 1) AS avg_rating,
       ROUND(avgIf(corrected_ratings, fiction_film), 1) AS avg_fiction_films_rating,
       ROUND(avgIf(corrected_ratings, NOT fiction_film), 1) AS avg_non_fiction_films_rating,
       argMaxIf(title, corrected_ratings, fiction_film) AS best_fiction_film,
       argMaxIf(title, corrected_ratings, NOT fiction_film) AS best_non_fiction_film
FROM
  (SELECT title,
          movie_type LIKE '%Художественный%' AS fiction_film,
          round(if(ratings > 10, mean_rating, ratings), 2) AS corrected_ratings,
          date_trunc('year', show_start_date) AS year
   FROM source_db.screenings AS s
   INNER JOIN source_db.movies_type mt ON mt.type_id = s.type_id) AS s
GROUP BY year
ORDER BY year DESC;

</details>

📁 Файлы проекта

Файл	        Описание
Script-24.sql	Полный код проекта

👤 Автор
Бессуднов Максим Александрович

📅 Дата
Июнь 2025
