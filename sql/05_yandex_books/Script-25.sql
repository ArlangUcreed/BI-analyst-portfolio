-- Проект Высоконагруженные системы

-- 1.1. Посмотреть структуру таблицы audition
DESCRIBE TABLE source_db.audition;

-- 1.2. Посмотреть структуру таблицы content
DESCRIBE TABLE source_db.content;

-- 1.3. Проверяем какие значения в main_content_type
SELECT DISTINCT main_content_type
FROM source_db.content;

-- 1.4. Диагностический запрос
SELECT
    main_content_type,
    count()
FROM source_db.content
GROUP BY main_content_type;


-- Задание 1. Топ-20 городов и регионов РФ по суммарной длительности (mobile)
SELECT
    usage_geo_id_name AS city_or_region,
    round(sum(hours_sessions_long)) AS total_hours,
    round(sumIf(hours_sessions_long, usage_platform_ru = 'Букмейт iOS')) AS ios_hours,
    round(sumIf(hours_sessions_long, usage_platform_ru = 'Букмейт Android')) AS android_hours
FROM source_db.audition
WHERE usage_country_name = 'Россия'
  AND usage_platform_ru IN ('Букмейт iOS', 'Букмейт Android')
  AND usage_geo_id_name NOT ILIKE '%федеральный округ%'
GROUP BY usage_geo_id_name
ORDER BY total_hours DESC
LIMIT 20;

-- Вывод. Сервис наиболее активно используется в крупнейших городах и агломерациях. Лидерами по суммарной длительности являются Москва и Санкт‑Петербург. На всех позициях наблюдается доминирование Android‑платформы, однако вклад iOS остаётся значимым, особенно в городах‑миллионниках. Это указывает на необходимость учитывать региональные особенности платформ при планировании маркетинговых активностей.



-- Задание 2. Топ-5 книг + среднее время по форматам
WITH mobile_usage AS (
    SELECT
        c.main_content_name AS book_title,
        c.main_author_name AS author,
        c.main_content_type,
        a.hours_sessions_long
    FROM source_db.audition a
    JOIN source_db.content c USING (main_content_id)
    WHERE a.usage_platform_ru IN ('Букмейт iOS', 'Букмейт Android')
),
books_with_both_formats AS (
    SELECT
        book_title,
        author
    FROM mobile_usage
    GROUP BY book_title, author
    HAVING
        countIf(main_content_type = 'Book') > 0
        AND countIf(main_content_type = 'Audiobook') > 0
)
SELECT
    m.book_title,
    m.author,
    round(sum(m.hours_sessions_long), 2) AS total_hours,
    round(avgIf(m.hours_sessions_long, m.main_content_type = 'Book'), 2) AS avg_text_hours,
    round(avgIf(m.hours_sessions_long, m.main_content_type = 'Audiobook'), 2) AS avg_audio_hours
FROM mobile_usage m
JOIN books_with_both_formats b
  ON m.book_title = b.book_title
 AND m.author = b.author
GROUP BY m.book_title, m.author
ORDER BY total_hours DESC
LIMIT 5;

-- Вывод. В топ-5 книг по суммарной длительности использования на мобильных платформах входят произведения, представленные одновременно в текстовом и аудиоформате. Для большинства книг среднее время прослушивания аудиоверсии выше, чем среднее время чтения текста, что указывает на более длительные сессии потребления аудиоконтента. Исключения (например, «Четвёртое крыло») демонстрируют сопоставимую вовлечённость в оба формата, что может быть связано с особенностями аудитории и жанра.



-- Задание 3. Топ-10 авторов по длительности чтения
SELECT
    c.main_author_name AS author,
    round(sumIf(a.hours_sessions_long, c.main_content_type = 'Book'), 2) AS reading_hours,
    countDistinctIf(a.main_content_id, c.main_content_type = 'Book') AS books_cnt,
    round(
        avgIf(
            a.hours_sessions_long,
            c.main_content_type = 'Audiobook'
            AND a.usage_platform_ru IN ('Букмейт iOS', 'Букмейт Android')
        ),
        2
    ) AS avg_audio_hours
FROM source_db.audition a
JOIN source_db.content c USING (main_content_id)
GROUP BY author
HAVING
    countIf(c.main_content_type = 'Audiobook') > 0
ORDER BY reading_hours DESC
LIMIT 10;

-- Вывод. Лидерами по суммарной длительности чтения являются авторы с большим каталогом текстовых произведений и устойчивой аудиторией. При этом наличие аудиокниг усиливает вовлечённость пользователей: среднее время прослушивания у большинства авторов превышает 1.5 часа, а у отдельных — более 2.5 часов. Это подтверждает значимость аудиоформата как дополнительного канала потребления контента.



-- Задание 4. Сегментация пользователей и проверка гипотезы
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

-- Вывод. Среди Android‑пользователей количество читателей и слушателей сопоставимо, тогда как на iOS явно преобладают читатели. Гипотеза продакт‑менеджера подтверждается частично: различия между платформами действительно существуют и выражены достаточно заметно.


-- Задание 5. Формат использования и день недели
SELECT
    c.main_content_type AS content_type,
    if(toDayOfWeek(a.msk_business_dt_str) IN (6,7), 'Выходной', 'Будний') AS day_type,
    round(avg(a.hours_sessions_long)) AS avg_hours
FROM source_db.audition a
JOIN source_db.content c USING (main_content_id)
GROUP BY content_type, day_type;

-- Вывод. Использование как текстовых, так и аудиокниг в среднем выше в будние дни. Существенного роста аудиопотребления в выходные не наблюдается ни на одной из платформ, включая веб‑версию.


-- Задание 6. Доля пользователей с последней версией приложения
WITH last_versions AS (
    SELECT
        usage_platform_ru,
        max(app_version) AS last_version
    FROM source_db.audition
    WHERE usage_platform_ru IN ('Букмейт iOS', 'Букмейт Android')
    GROUP BY usage_platform_ru
),
user_versions AS (
    SELECT
        puid,
        usage_platform_ru,
        argMax(app_version, msk_business_dt_str) AS user_version
    FROM source_db.audition
    WHERE usage_platform_ru IN ('Букмейт iOS', 'Букмейт Android')
    GROUP BY puid, usage_platform_ru
)
SELECT
    u.usage_platform_ru AS platform,
    round(100 * countIf(user_version = last_version) / count(), 2) AS percent_latest
FROM user_versions u
JOIN last_versions l USING (usage_platform_ru)
GROUP BY platform;

-- Вывод. Доля пользователей с последней версией приложения значительно выше на Android по сравнению с iOS. Это может быть связано с различиями в механизмах обновления и пользовательских привычках на платформах.


-- Задание 7. Частота обновлений приложения
WITH updates AS (
    SELECT
        puid,
        usage_platform_ru,
        countDistinct(app_version) - 1 AS updates_cnt
    FROM source_db.audition
    WHERE usage_platform_ru IN ('Букмейт iOS', 'Букмейт Android')
    GROUP BY puid, usage_platform_ru
)
SELECT
    usage_platform_ru AS platform,
    round(avg(updates_cnt), 2) AS update_rate
FROM updates
GROUP BY platform;

-- Вывод. Пользователи Android в среднем обновляют приложение чаще, чем пользователи iOS. Гипотеза о большей активности обновлений на iOS не подтвердилась.



-- Задание 8. Количество книг с тегом «Магия»
SELECT
    countDistinct(main_content_id) AS magic_books_cnt
FROM source_db.content
WHERE has(published_topic_title_list, 'Магия');

-- Вывод. В каталоге сервиса содержится 46 книг, отмеченных тегом «Магия».



-- Задание 9. «Магия» в названии без тега «Магия»
SELECT
    countDistinct(main_content_id) AS books_cnt
FROM source_db.content
WHERE lower(main_content_name) LIKE '%магия%'
  AND NOT has(published_topic_title_list, 'Магия')
  AND NOT has(published_topic_title_list, 'Художественная литература');

-- Вывод. Обнаружено 18 книг, в названии которых присутствует слово «магия», но при этом отсутствует соответствующий тематический тег.



-- Задание 10. Среднее количество категорий
SELECT
    round(avg(length(published_topic_title_list)), 2) AS avg_all_books,
    round(avgIf(length(published_topic_title_list),
        has(published_topic_title_list, 'Магия')
    ), 2) AS avg_magic_books
FROM source_db.content;

-- Вывод. Среднее количество категорий у книг с тегом «Магия» составляет 3,22, по каталогу в целом — 3,77. В большинстве случаев рекомендованное количество категорий (3–4) не превышается.



-- Задание 11. Аномалии по коэффициенту вариации
SELECT
    usage_country_name,
    usage_platform_ru,
    stddevPop(hours_sessions_long) / avg(hours_sessions_long) AS variation_coeff
FROM source_db.audition
WHERE usage_platform_ru IN ('Букмейт iOS', 'Букмейт Android')
GROUP BY usage_country_name, usage_platform_ru
ORDER BY variation_coeff DESC
LIMIT 1;

-- Вывод. Наибольшая аномалия по коэффициенту вариации длительности сессий выявлена в Латвии на платформе «Букмейт Android». Это может указывать на проблему с качеством данных или особенностями сбора метрик в данной стране и требует дополнительной проверки.

-- Итоговый вывод. Проведённый анализ позволил выявить ключевые паттерны использования сервиса «Яндекс Книги», различия между платформами и потенциальные точки роста, а также обнаружить аномалии в данных, требующие внимания со стороны команды.
