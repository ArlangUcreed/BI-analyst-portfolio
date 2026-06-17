# Анализ поведения пользователей Яндекс Книги

## 📌 Описание задачи
Анализ поведения пользователей сервиса «Яндекс Книги» на разных платформах (iOS, Android), сегментация аудитории, анализ аномалий в данных.

## 🛠 Используемые технологии
- **ClickHouse** — колоночная СУБД
- **Условная агрегация** — sumIf, avgIf, countIf
- **Анализ коэффициента вариации** — для поиска аномалий
- **Сегментация пользователей** — на основе предпочтений (чтение vs аудио)

## 📊 Ключевые результаты
| Метрика | Результат |
|---------|-----------|
| Топ-1 город по длительности | Москва |
| Преобладающая платформа | Android |
| Сегмент с наибольшей долей | Читатели (iOS) |
| Книг с тегом «Магия» | 46 |
| Книг с «магия» в названии без тега | 18 |
| Страна с аномалией | Латвия |

## 📝 Выводы
1. **Сервис** наиболее активно используется в Москве и Санкт-Петербурге
2. **На iOS** преобладают читатели, на **Android** — читатели и слушатели поровну
3. **В будние дни** использование выше, чем в выходные
4. **Пользователи Android** обновляют приложение чаще, чем iOS
5. **Обнаружена аномалия** в данных по Латвии (коэффициент вариации)

## 📄 Пример кода

<details>
<summary>📄 Нажми, чтобы посмотреть пример SQL-запроса</summary>

```sql
-- Сегментация пользователей по предпочтениям
WITH user_stats AS (
    SELECT
        puid,
        sumIf(hours_sessions_long, c.main_content_type = 'AudioBook') AS audio_hours,
        sumIf(hours_sessions_long, c.main_content_type = 'Book') AS book_hours,
        sumIf(hours_sessions_long, usage_platform_ru = 'Букмейт iOS') AS ios_hours,
        sumIf(hours_sessions_long, usage_platform_ru = 'Букмейт Android') AS android_hours
    FROM source_db.audition a
    JOIN source_db.content c USING (main_content_id)
    GROUP BY puid
),
segmented AS (
    SELECT
        puid,
        if(audio_hours >= 0.7 * (audio_hours + book_hours), 'Слушатель',
           if(book_hours >= 0.7 * (audio_hours + book_hours), 'Читатель', 'Оба')) AS segment,
        if(android_hours > ios_hours, 'Android', 'iOS') AS main_platform
    FROM user_stats
    WHERE audio_hours + book_hours > 0
)
SELECT
    main_platform,
    segment,
    count() AS users_cnt
FROM segmented
GROUP BY main_platform, segment;

</details>

📁 Файлы проекта

Файл	        Описание
Script-25.sql	Полный код проекта

👤 Автор
Бессуднов Максим Александрович

📅 Дата
Июнь 2025
