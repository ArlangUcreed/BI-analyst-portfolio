-- Спринт ClickHouse как аналитическая СУБД

-- Посчитайте средний рейтинг фильмов (столбец ratings)  в таблице screenings. Ответ укажите в виде числа с двумя знаками после точки. Например: 4.07.
-- Для округления результата используйте функцию round(column, n), где column — это столбец для округления, а n — это количество знаков округления.

SELECT round(avg(ratings), 2) AS avg_rating
FROM source_db.screenings

-- Посчитайте уникальное количество кодов стран (столбец country_id) в таблице screenings. Например: 238

SELECT uniqExact(country_id) AS unique_countries
FROM source_db.screenings

-- Практика. Извлечение данных с помощью ClickHouse

-- Менеджеры просят вас отобрать все фильмы, которые выходили за последний год. Это поможет понять, какие из них можно повторно выпускать в прокат или рекомендовать зрителям.
-- Составьте SQL-запрос, который выберет только те фильмы, которые стартовали в последний год. В результат должны войти все столбцы таблицы screenings.
-- Для решения задачи вам может понадобиться функция date_trunc('year', column).

WITH (
    SELECT date_trunc('year', max(show_start_date))
    FROM source_db.screenings
) AS last_year
SELECT *
FROM source_db.screenings
WHERE show_start_date >= last_year

-- Итак, вы нашли все фильмы, которые вышли за последний год. Теперь вам поставили новую задачу — определить топ-5 фильмов по рейтингу (столбец ratings) в порядке убывания. Такие фильмы можно затем рекомендовать зрителям. В результат должны войти все поля таблицы screenings.
WITH
  (SELECT date_trunc('year', max(show_start_date))
   FROM source_db.screenings) AS last_year
SELECT *
FROM source_db.screenings
WHERE show_start_date >= last_year
ORDER BY ratings DESC
LIMIT 5


-- Дополните код предыдущего задания. Отберите записи с условием, что рейтинг фильма должен быть меньше или равен 10.
-- Предкод

WITH (
	SELECT date_trunc('year', max(show_start_date))
	FROM source_db.screenings
) AS last_year
SELECT *
FROM source_db.screenings
WHERE show_start_date >= last_year
-- Добавьте условие для фильтрации
ORDER BY ratings DESC
LIMIT 5

-- Подсказка: Допишите условие в WHERE: ratings должен быть меньше или равен 10.

WITH (
    SELECT date_trunc('year', max(show_start_date))
    FROM source_db.screenings
) AS last_year
SELECT *
FROM source_db.screenings
WHERE show_start_date >= last_year
  AND ratings <= 10
ORDER BY ratings DESC
LIMIT 5



-- Вы составили список лучших фильмов последнего года. Теперь перед вами стоит новая аналитическая задача — определить, какая страна выпустила самые качественные фильмы за этот период.
-- Чтобы не просто выбрать несколько отдельных фильмов, вас просят рассчитать средний рейтинг картин для каждой страны country_id и выявить топ-5 стран по этому значению. При этом в топ должны войти только страны, которые выпустили 5 или более фильмов за последний год. Условия для отбираемых фильмов те же: это должны быть фильмы за последний год с рейтингом не больше 10.
-- Напишите SQL-запрос, который решит эту задачу. Округлите среднее значение до двух знаков после точки, пользуясь функцией round().
-- В результат должны войти следующие столбцы:
-- country_id — идентификатор страны-производителя фильма;
-- avg_ratings — средний рейтинг фильмов, округлённый до двух знаков после точки;

WITH (
    SELECT date_trunc('year', max(show_start_date))
    FROM source_db.screenings
) AS last_year
SELECT
    country_id,
    round(avg(ratings), 2) AS avg_ratings,
    count() AS cnt
FROM source_db.screenings
WHERE show_start_date >= last_year
  AND ratings <= 10
GROUP BY country_id
HAVING cnt >= 5
ORDER BY avg_ratings DESC
LIMIT 5


-- Соедините таблицы, чтобы получить название страны-производителя фильма.
-- В прошлом задании вы получили топ-5 стран, но удобнее выводить их названия, а не ountry_id. Объедините результат с таблицей top_country, чтобы получить поле production_country. Используйте вид соединения INNER.
-- В результат должны войти следующие столбцы:
-- production_country — название страны-производителя фильма;
-- avg_ratings — средний рейтинг фильмов, округлённый до двух знаков после точки;
-- cnt — количество снятых картин за последний год.

WITH (
    SELECT date_trunc('year', max(show_start_date))
    FROM source_db.screenings
) AS last_year,
top_country AS (
    SELECT
        country_id,
        round(avg(ratings), 2) AS avg_ratings,
        count() AS cnt
    FROM source_db.screenings
    WHERE show_start_date >= last_year
          AND ratings <= 10
    GROUP BY country_id
    HAVING cnt >= 5
    ORDER BY avg_ratings DESC
    LIMIT 5
)
SELECT
    pc.production_country,
    tc.avg_ratings,
    tc.cnt
FROM top_country AS tc
INNER JOIN source_db.production_country AS pc 
    ON tc.country_id = pc.country_id
    
    
-- Попробуйте определить, какими типами обладают столбцы title, show_start_date и ratings в таблице screenings. Типы перечислите через запятую, например: Enum, Array, Int32.

-- В ClickHouse можно посмотреть типы столбцов таблицы с помощью запроса:
    
DESCRIBE TABLE source_db.screenings

-- Или

SELECT 
    name AS column_name,
    type AS data_type
FROM system.columns 
WHERE database = 'source_db' 
    AND table = 'screenings'
    

    
    
-- Практическое задание 1
-- Посчитайте длину массива, составленного из значений ratings таблицы screenings с рейтингом от 5.0 до 7.0 включительно.

SELECT length(groupArray(ratings)) AS array_length
FROM source_db.screenings
WHERE ratings BETWEEN 5.0 AND 7.0

-- Практическое задание 2
-- Посчитайте средний рейтинг фильма для массива, составленного из значений ratings таблицы screenings с рейтингом от 5.0 до 7.0 включительно. Результат округлите до двух цифр после точки.

SELECT round(arrayAvg(groupArray(ratings)), 2) AS avg_rating
FROM source_db.screenings
WHERE ratings BETWEEN 5.0 AND 7.0


-- Практика. Изменение типов данных и работа с массивами
-- 1. Перед тем как приступать к аналитике, нужно собрать базу: объединить таблицы, сгруппировать данные и «упаковать» оценки фильмов в массивы. Это будет отправной точкой для всех последующих запросов. Также менеджер из «Синема Аналитики» просит собрать срез по жанрам — так можно будет увидеть, какие оценки получают фильмы в каждой категории.
-- В этом задании вам нужно сгруппировать фильмы по их типу и собрать все оценки в массив. Объедините таблицы screenings  и movies_type и выполните группировку по типу фильмов. В результат должен войти столбец movie_type и массив оценок ratings, названный arr_ratings.

SELECT movie_type,
       groupArray(ratings) AS arr_ratings
FROM source_db.screenings
INNER JOIN source_db.movies_type USING (type_id)
GROUP BY movie_type;

-- 2. Менеджер определил, что фильм с рейтингом выше 8.6 считается «хорошим» — судя по отзывам критиков, эти фильмы чаще всего получают положительные рецензии.
-- Ваша задача — для каждого типа фильма movie_type посчитать:

-- Сколько существует таких фильмов с рейтингом больше или равно 8.6, но меньше или равно 10.0.
-- Каков их средний рейтинг.

--В ответе должно быть три столбца:

-- movie_type — категория фильмов;
--count_good_movies — количество фильмов с указанным рейтингом, которые считаются «хорошими»;
-- avg_good_movies — средний рейтинг фильмов.

--Отсортируйте данные по количеству «хороших» фильмов в порядке убывания. В общем табличном выражении mt_ratings сохранены результаты предыдущего задания — используйте его для решения задачи.

WITH mt_ratings AS (
    SELECT movie_type,
           groupArray(ratings) AS arr_ratings
    FROM source_db.screenings AS s
    INNER JOIN source_db.movies_type AS mt USING (type_id)
    GROUP BY movie_type
)
SELECT 
    movie_type,
    arrayCount(x -> x >= 8.6 AND x <= 10.0, arr_ratings) AS count_good_movies,
    arrayAvg(arrayFilter(x -> x >= 8.6 AND x <= 10.0, arr_ratings)) AS avg_good_movies
FROM mt_ratings
ORDER BY count_good_movies DESC;


-- 3. Вы собрали фильмы, считающиеся хорошими. Теперь выведите топ-3 фильмов по рейтингу для каждого типа. Для этого нужно добавить новый столбец top_three_movies, в котором останутся оценки трёх лучших фильмов. Для решения задачи используйте методы работы с массивами.

WITH mt_ratings AS (
    SELECT movie_type,
           groupArray(ratings) AS arr_ratings
    FROM source_db.screenings AS s
    INNER JOIN source_db.movies_type AS mt USING (type_id)
    GROUP BY movie_type
)
SELECT 
    movie_type,
    arrayCount(film -> film >= 8.6 AND film <= 10.0, arr_ratings) AS count_good_movies,
    arrayAvg(arrayFilter(film -> film >= 8.6 AND film <= 10.0, arr_ratings)) AS avg_good_movies,
    -- Топ-3 фильмов в каждой категории
    arraySlice(
        arrayReverse(
            arraySort(
                arrayFilter(film -> film >= 8.6 AND film <= 10.0, arr_ratings)
            )
        ),
    1, 3) AS top_three_movies
FROM mt_ratings
ORDER BY count_good_movies DESC;

-- 4. Финальный штрих: менеджеры просят подготовить результат не в виде массива с топ-3 фильмами, а так, чтобы каждый фильм из подборки был на отдельной строке. Это поможет добавить фильмы в отчёт для презентации. 
-- Выполните разворот массива в строки и назовите столбец movies_rating. Выполните преобразование столбца avg_good_movies в тип Decimal32 с двумя знаками в дробной части.

WITH mt_ratings AS (
    SELECT movie_type,
           groupArray(ratings) AS arr_ratings
    FROM source_db.screenings AS s
    INNER JOIN source_db.movies_type AS mt USING (type_id)
    GROUP BY movie_type
),
filtered_ratings AS (
    SELECT 
        movie_type,
        arrayCount(film -> film >= 8.6 AND film <= 10.0, arr_ratings) AS count_good_movies,
        toDecimal32(arrayAvg(arrayFilter(film -> film >= 8.6 AND film <= 10.0, arr_ratings)), 2) AS avg_good_movies,
        arraySlice(
            arraySort(rating -> -rating, 
                arrayFilter(film -> film >= 8.6 AND film <= 10.0, arr_ratings)
            ), 
        1, 3) AS top_three_movies
    FROM mt_ratings
)
SELECT 
    movie_type,
    count_good_movies,
    avg_good_movies,
    arrayJoin(top_three_movies) AS movies_rating
FROM filtered_ratings
WHERE top_three_movies != []  -- Опционально: можно убрать, чтобы показать все типы
ORDER BY count_good_movies DESC, movies_rating DESC;


-- Создайте таблицу чисел от 0 до 50 000 000 и рассчитайте процентную разницу в количестве уникальных значений, подсчитанных функциями uniq() и uniqExact(). Для расчёта процентной разницы воспользуйтесь формулой:
-- Процентная разница=100%⋅(Приближённое значениеТочное значение−1).Процентная разница=100%⋅(Точное значениеПриближённое значение​−1).
-- В качестве результата запишите полученное значение, округлённое до трёх знаков после точки стандартной функцией round(). Например: -0.255.

SELECT 
    round(
        100 * (uniq(number) / uniqExact(number) - 1),
        3
    ) AS percentage_difference
FROM numbers(0, 50000000);



-- Практика. Работа со специфичными агрегирующими функциями и комбинаторами
-- 1. Ключевым показателем, с которым вы будете работать в рамках задачи, является рейтинг фильма. Вы уже сталкивались с ситуацией, когда рейтинг превышал 10 баллов, хотя это не предусмотрено платформой и указывает на некорректность данных. Такие аномалии лучше устранить. Точная причина возникновения ошибки неизвестна, поэтому можно хотя бы снизить её влияние — например, заменив выбросы на среднее значение.
-- Подробно расскажем, что нужно сделать:
-- Рассчитать средний рейтинг, используя значения рейтинга строго меньше 10.
-- В таблице screenings создать новую колонку corrected_ratings. Если значение рейтинга превышает 10, то в новой колонке вместо него будет средний рейтинг среди фильмов, для которых не было ошибок. Полученное значение округлите до двух знаков после точки стандартной функцией round().
-- Вывести все столбцы таблицы screenings.

WITH mean_rating AS (
    SELECT 
        ROUND(avgIf(ratings, ratings < 10), 2) AS avg_rounded
    FROM source_db.screenings
)
SELECT 
    s.*,
    ROUND(
        if(
            s.ratings > 10, 
            mr.avg_rounded, 
            s.ratings
        ), 
        2
    ) AS corrected_ratings
FROM source_db.screenings s
CROSS JOIN mean_rating mr;

-- 2. В качестве первой гипотезы можно проверить, существуют ли различия в средних рейтингах между типами фильмов, размещённых на платформе. Возможно, какому-либо типу свойственно аномальное поведение — это позволит сузить круг подозреваемых в расследовании падения пользовательского интереса.
-- Подробно расскажем, что нужно сделать:

-- Для каждого типа фильма movie_type вывести следующие столбцы:
-- best_film — название фильма с максимальным исправленным рейтингом corrected_ratings в категории;
-- best_film_rating — рейтинг этого фильма;
-- mean_category_rating — средний исправленный рейтинг для всей категории, округлённый до двух знаков после точки;
-- total_category_films — количество уникальных фильмов в категории.
-- Отсортировать результат по убыванию количества фильмов в категории.

-- Помните, что во всех заданиях необходимо использовать скорректированный рейтинг фильмов.

-- 1. Сначала получаем скорректированные рейтинги для всех фильмов
WITH corrected_ratings AS (
    WITH mean_rating AS (
        SELECT 
            ROUND(avgIf(ratings, ratings < 10), 2) AS avg_rounded
        FROM source_db.screenings
    )
    SELECT 
        s.*,
        ROUND(
            if(
                s.ratings > 10, 
                mr.avg_rounded, 
                s.ratings
            ), 
            2
        ) AS corrected_ratings
    FROM source_db.screenings s
    CROSS JOIN mean_rating mr
),
-- 2. Объединяем с таблицей типов фильмов
film_data AS (
    SELECT 
        cr.*,
        mt.movie_type
    FROM corrected_ratings cr
    JOIN source_db.movies_type mt ON cr.type_id = mt.type_id
)
-- 3. Агрегируем данные по типам фильмов
SELECT 
    movie_type,
    -- Название фильма с максимальным исправленным рейтингом
    argMax(title, corrected_ratings) AS best_film,
    -- Рейтинг этого фильма (максимальный)
    MAX(corrected_ratings) AS best_film_rating,
    -- Средний исправленный рейтинг для категории (округленный до 2 знаков)
    ROUND(AVG(corrected_ratings), 2) AS mean_category_rating,
    -- Количество уникальных фильмов в категории
    COUNT(DISTINCT title) AS total_category_films
FROM film_data
GROUP BY movie_type
ORDER BY total_category_films DESC;


-- 3. На предыдущем шаге анализа вы выяснили, что 75% контента платформы составляют художественные фильмы, у которых также наивысшие средние рейтинги. Для оптимизации контентной стратегии необходимо изучить, как менялось качество и представленность этой категории за все годы наблюдений.
-- Вам понадобится проанализировать динамику для художественных и нехудожественных фильмов отдельно по годам. А именно:

-- Определить тренды в их доле относительно общего каталога.
-- Сравнить качество, то есть рейтинги, художественных и нехудожественных фильмов в динамике.
-- Выявить лучшие работы в каждой категории по годам.

-- Теперь подробно расскажем, что нужно сделать:

-- Сгруппировать данные по году выпуска.
-- Для каждого года вывести следующие столбцы:
-- fiction_films_ratio — доля художественных фильмов в % от общего числа уникальных фильмов в этот год;
-- avg_rating — средний рейтинг всех фильмов в этот год;
-- avg_fiction_films_rating — средний рейтинг художественных фильмов в этот год;
-- avg_non_fiction_films_rating — средний рейтинг нехудожественных фильмов в этот год;
-- best_fiction_film — лучший художественный фильм в этот год;
-- best_non_fiction_film — лучший нехудожественный фильм в этот год.
-- Значения всех числовых столбцов округлить до одного знака после точки.
-- Отсортировать результат по убыванию года выпуска.

-- В этом задании вам наверняка пригодится оператор LIKE, знакомый по спринтам об SQL. Он используется и в ClickHouse — помогает сопоставить строки с шаблоном. Например, запрос SELECT str LIKE '%abc%' as str_has_abc FROM example создаст столбец логического типа, в который войдёт true для строк любого размера, содержащих подстроку abc. Учтите, что LIKE чувствителен к регистру. Например, выражение LIKE %abc% позволит найти только подстроки в нижнем регистре.
-- Помните, что во всех заданиях необходимо использовать скорректированный рейтинг фильмов.

-- Пишем подзапрос для расчёта среднего рейтинга
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


-- 4. Итак, одна из потенциальных причин снижения рейтингов платформы выявлена — доля художественных фильмов в последние годы стабильно сокращалась в пользу менее рейтинговых категорий. Однако всё может быть не так однозначно, и в качестве дополнительной гипотезы решено проверить, влияет ли увеличение доли отечественных фильмов в каталоге на рейтинговые показатели.
-- К российским фильмам мы относим те, где Россия является единственным производителем или участвует в производстве (production_country). Фильмы со странами производства вида Россия, Россия и США или Россия, Польша, Германия и Пуэрто-Рико будут считаться российскими.
-- Вам понадобится провести комплексный анализ и отдельно изучить динамику доли художественных фильмов в этой категории. А именно:

-- Выявить динамику доли российских фильмов в общем каталоге.
-- Сравнить качество российского и зарубежного контента с помощью рейтингов.
-- Определить, какая категория (художественные или нехудожественные) преобладает среди российских фильмов.
-- Найти «слабые места» в российском контенте — фильмы с минимальными рейтингами.

-- Теперь подробно расскажем, что нужно сделать:

-- Произвести группировку данных по году выпуска.
-- Для каждого года вывести следующие столбцы:
-- russian_films_ratio — доля российских фильмов в общем каталоге;
-- russian_fiction_films_ratio — доля художественных фильмов среди российских;
-- avg_russian_films_rating — средний рейтинг отечественных фильмов;
-- avg_non_russian_films_rating — средний рейтинг иностранных фильмов;
-- worst_russian_film — название российского фильма с наименьшим рейтингом в году.
-- Отсортировать результат по убыванию года выпуска.

-- Помните, что во всех заданиях необходимо использовать скорректированный рейтинг фильмов.

WITH
  (SELECT avgIf(ratings, ratings < 10)
   FROM source_db.screenings) AS mean_rating
SELECT year,
       round(uniqIf(title, russian_film) / uniq(title), 2) AS russian_films_ratio,
       round(uniqIf(title, russian_film
                    AND fiction_film) / uniqIf(title, russian_film), 2) AS russian_fiction_films_ratio,
       round(avgIf(corrected_ratings, russian_film), 1) AS avg_russian_films_rating,
       round(avgIf(corrected_ratings, NOT russian_film), 1) AS avg_non_russian_films_rating,
       argMinIf(title, corrected_ratings, russian_film) AS worst_russian_film
FROM
  (SELECT title,
          date_trunc('year', show_start_date) AS year,
          round(if(ratings > 10, mean_rating, ratings), 2) AS corrected_ratings,
          production_country LIKE '%Россия%' AS russian_film,
          movie_type LIKE '%Художественный%' AS fiction_film
   FROM source_db.screenings AS s
   INNER JOIN source_db.production_country AS pc ON pc.country_id = s.country_id
   INNER JOIN source_db.movies_type AS mt ON mt.type_id = s.type_id) AS s
GROUP BY year
ORDER BY year DESC;

-- 5. По результатам проведённого анализа удалось установить два основных источника проблем:

-- Доля высокорейтинговых художественных фильмов падала, и их замещали менее популярными категориями.
-- Доля отечественного кино увеличивалась, хотя в среднем оно меньше нравится зрителю.

-- В качестве финальной задачи вам необходимо понять, как соотносятся российские и зарубежные фильмы в разных категориях рейтинга. Для этого вам предстоит:

-- Выявить, в каких диапазонах рейтингов концентрируется российский контент.
-- Определить, существует ли дисбаланс в качестве между российскими и зарубежными фильмами.
-- Классифицировать фильмы по уровням рейтинга для оптимизации рекомендаций.

-- Теперь подробно расскажем, что нужно сделать:

-- Разделить фильмы на четыре категории в соответствии с их скорректированным рейтингом:
-- 1_Low: 0–3.
-- 2_Medium: 3.01–6.
-- 3_High: 6.01–8.
-- 4_Very High: > 8.
-- Категории войдут в столбец rating_tier.
-- Для каждой из четырёх созданных групп рейтинга произвести подсчёт фильмов:
-- total — общее количество уникальных фильмов в категории;
-- russian_films — российские фильмы в категории (production_country LIKE '%Россия%');
-- non_russian_films — зарубежные фильмы в категории.
-- Результат отсортировать по возрастанию rating_tier.

-- Помните, что во всех заданиях необходимо использовать скорректированный рейтинг фильмов.

WITH
  (SELECT avgIf(ratings, ratings < 10)
   FROM source_db.screenings) AS mean_rating
SELECT 
    rating_tier,
    COUNT(DISTINCT title) AS total,
    COUNT(DISTINCT if(russian_film, title, NULL)) AS russian_films,
    COUNT(DISTINCT if(NOT russian_film, title, NULL)) AS non_russian_films
FROM
  (SELECT 
        s.title,
        round(if(s.ratings > 10, mean_rating, s.ratings), 2) AS corrected_ratings,
        pc.production_country LIKE '%Россия%' AS russian_film,
        -- Классификация по уровням рейтинга
        multiIf(
            round(if(s.ratings > 10, mean_rating, s.ratings), 2) <= 3, '1_Low',
            round(if(s.ratings > 10, mean_rating, s.ratings), 2) <= 6, '2_Medium',
            round(if(s.ratings > 10, mean_rating, s.ratings), 2) <= 8, '3_High',
            '4_Very High'
        ) AS rating_tier
   FROM source_db.screenings AS s
   INNER JOIN source_db.production_country AS pc ON pc.country_id = s.country_id) AS s
GROUP BY rating_tier
ORDER BY rating_tier;



-- С помощью теста Уэлча выясните, существуют ли значимые отличия рейтингов фильмов, в производстве которых участвовала Россия, от рейтингов остальных фильмов. Фильмы считаются произведёнными с участием России, если строка в поле production_country содержит подстроку «Россия».
-- Гипотезы для проверки:

-- Нулевая гипотеза (H0H0​ ): средние рейтинги фильмов, в производстве которых участвовала Россия, не отличаются от рейтингов фильмов, произведённых без участия России.
-- Альтернативная гипотеза (H1H1​ ): средние рейтинги фильмов, в производстве которых участвовала Россия, отличаются от рейтингов остальных фильмов.

-- Напишите запрос, который выполнит сравнение, и сформулируйте статистический вывод. Обратите внимание, что здесь вы имеете дело с категориальным признаком на основе текстового поля production_country, а для применения функции Уэлча требуются значения в виде 0 и 1. Подумайте, какую функцию из предыдущих уроков здесь можно использовать?
-- В ответе укажите значение p-value, округлённое до десятых. Пример: 0.1.

WITH film_stats AS (
    SELECT 
        CASE WHEN pc.production_country LIKE '%Россия%' THEN 1 ELSE 0 END AS group_id,
        COUNT() AS n,
        AVG(s.ratings) AS mean,
        VAR_SAMP(s.ratings) AS variance,
        STDDEV_SAMP(s.ratings) AS stddev
    FROM source_db.screenings s
    INNER JOIN source_db.production_country pc ON pc.country_id = s.country_id
    GROUP BY group_id
),
welch_calc AS (
    SELECT 
        r.mean AS mean_russian,
        nr.mean AS mean_non_russian,
        r.n AS n_russian,
        nr.n AS n_non_russian,
        r.variance AS var_russian,
        nr.variance AS var_non_russian,
        -- t-статистика по формуле Уэлча
        (r.mean - nr.mean) / SQRT(r.variance/r.n + nr.variance/nr.n) AS t_stat,
        -- степени свободы по формуле Уэлча-Саттертуэйта
        POW(r.variance/r.n + nr.variance/nr.n, 2) / 
        (POW(r.variance/r.n, 2)/(r.n-1) + POW(nr.variance/nr.n, 2)/(nr.n-1)) AS df
    FROM film_stats r, film_stats nr
    WHERE r.group_id = 1 AND nr.group_id = 0
)
SELECT 
    t_stat,
    df,
    -- Приближенное p-value (для больших выборок можно использовать нормальное распределение)
    ROUND(2 * (1 - erf(ABS(t_stat) / SQRT(2))), 1) AS p_value_approx
FROM welch_calc;


-- С помощью теста Манна — Уитни сравните пользовательские рейтинги фильмов двух крупнейших студий: киностудии «Мосфильм» и «Уорнер Бразерс».
--Гипотезы для проверки:

-- Нулевая гипотеза (H0H0​ ): распределения пользовательских рейтингов фильмов студии «Мосфильм» и студии «Уорнер Бразерс» одинаковы.
-- Альтернативная гипотеза (H1H1​ ): распределения рейтингов различаются.

-- У вас есть таблицы с данными о рейтингах screenings и студиях, выпустивших их: punumber_studio и studio_names. Необходимо выяснить, различаются ли оценки фильмов, выпущенных упомянутыми двумя студиями. В ответ запишите p-value, округлённое до двух знаков после точки. Пример: 0.09.

SELECT round(mw_result.1, 1) AS U_statistic,
       round(mw_result.2, 2) AS p_value
FROM
  (SELECT mannWhitneyUTest('two-sided')(s.ratings,
                                        IF(sn.studio_name = 'Киностудия "Мосфильм"', 0, 1)) AS mw_result
   FROM source_db.screenings AS s
   JOIN source_db.punumber_studio AS ps ON s.punumber = ps.punumber
   JOIN source_db.studio_names AS sn ON ps.studio_id = sn.studio_id
   WHERE s.ratings IS NOT NULL
     AND sn.studio_name IN ('Киностудия "Мосфильм"',
                            'Уорнер Бразерс')) AS sub;


-- Практическое задание
-- Попробуйте применить агрегирующие оконные функции к данным таблицы screenings с информацией о фильмах. Выведите название фильма title, дату начала показа show_start_date, рейтинг ratings и с помощью оконной функции определите, на сколько рейтинг каждого фильма отличается от среднего по всем фильмам. Это значение запишите в отдельный столбец diff_from_avg.

SELECT 
    title,
    show_start_date,
    ratings,
    ratings - AVG(ratings) OVER() AS diff_from_avg
FROM source_db.screenings;



-- Практическое задание
-- Нужно проанализировать интерес пользователей к фильмам разных жанров и определить топ-3 наиболее популярных фильмов в жанре аниме. Данные о фильмах, их жанрах и оценках находятся в таблицах screenings, punumber_genres и genre_names.
-- Напишите SQL-запрос, который объединит таблицы, отберёт только фильмы жанра 'аниме' и отсортирует их по убыванию рейтинга. Важно учесть, что рейтинг фильмов может совпадать. Чтобы в результате получить только три строки, можно воспользоваться оконной функцией ROW_NUMBER(), которая присвоит уникальные порядковые номера даже при равных значениях рейтинга.

SELECT *
FROM
  (SELECT s.title,
          g.genres_name,
          s.ratings,
          ROW_NUMBER() OVER (PARTITION BY g.genres_name
                             ORDER BY s.ratings DESC) AS rn
   FROM source_db.screenings s
   JOIN source_db.punumber_genres pg ON s.punumber = pg.punumber
   JOIN source_db.genre_names g ON pg.genres_id = g.genres_id
   WHERE g.genres_name = 'аниме') t
WHERE rn <= 3;


-- Практическое задание
-- Найдите фильмы, у которых вырос рейтинг по сравнению с предыдущим фильмом того же режиссёра.
-- Для этого сделайте следующее:

-- Используйте оконную функцию lagInFrame() для получения рейтинга предыдущего фильма.
-- Рассчитайте разницу между текущим и предыдущим рейтингами.
-- Отберите только те случаи, когда оба рейтинга положительные (> 0) и текущий рейтинг выше предыдущего.
-- Отсортируйте фильмы по наибольшему приросту рейтинга.

-- Обратите внимание, что ClickHouse не позволяет использовать оконные функции в WHERE напрямую. Поэтому можно сначала вычислить все нужные значения в подзапросе, а затем отфильтровать данные по результатам.

SELECT *,
       current_rating - previous_rating AS rating_growth
FROM
  (SELECT d.director_name AS director_name,
          s.ratings AS current_rating,
          lagInFrame(s.ratings, 1) OVER (PARTITION BY d.director_name
                                         ORDER BY s.show_start_date ROWS BETWEEN 1 PRECEDING AND CURRENT ROW) AS previous_rating
   FROM source_db.screenings s
   JOIN source_db.punumber_director pd ON s.punumber = pd.punumber
   JOIN source_db.director_names d ON pd.director_id = d.director_id) AS sub
WHERE current_rating > 0
  AND previous_rating > 0
  AND current_rating > previous_rating
ORDER BY rating_growth DESC;


-- Практика. Работа с аналитическими функциями в ClickHouse
-- 1.В таблице screenings хранятся оценки, которые пользователи поставили фильмам, а сами фильмы при этом связаны с режиссёрами с помощью вспомогательных таблиц punumber и director_name. Каждому фильму может быть присвоено несколько оценок, а каждый режиссёр мог снять несколько фильмов. Попробуйте найти опытных режиссёров с самыми высокими и стабильными оценками.
-- Чтобы решить задание:

-- Для каждого фильма вычислите его среднюю оценку и отберите только тех режиссёров, у которых три четверти фильмов оцениваются в среднем выше 8.0. Чтобы сохранить значение среднего рейтинга и затем использовать его в расчётах, создайте общее табличное выражение СТЕ с подзапросом: WITH film_avg_ratings AS (SELECT …).
-- Убедитесь, что режиссёры не являются новичками и сняли не менее 10 фильмов.
-- Разброс средних оценок фильмов (стандартное отклонение) должен быть не выше 1.5.

-- Выведите следующие столбцы:

-- director_name — имя и фамилия режиссёра.
-- q75_rating — 75-й квантиль из списка средних оценок фильмов режиссёра. Квантиль рассчитайте с максимальной точностью и округлите до двух знаков после точки.
-- rating_stddev — стандартное отклонение набора средних оценок фильмов режиссёра. Значение округлите до двух знаков после точки.
-- film_count — количество фильмов режиссёра.

-- Результаты отсортируйте в порядке убывания 75-го квантиля q75_rating, а затем по возрастанию разброса оценок rating_stddev.

WITH film_avg_ratings AS
  (SELECT punumber,
          AVG(ratings) AS avg_rating
   FROM source_db.screenings
   GROUP BY punumber)
SELECT dn.director_name AS director_name,
       ROUND(quantileExact(0.75)(f.avg_rating), 2) AS q75_rating,
       ROUND(stddevSamp(f.avg_rating), 2) AS rating_stddev,
       COUNT(*) AS film_count
FROM film_avg_ratings f
JOIN source_db.punumber_director pd ON f.punumber = pd.punumber
JOIN source_db.director_names dn ON pd.director_id = dn.director_id
GROUP BY dn.director_name
HAVING q75_rating > 8
AND rating_stddev <= 1.5
AND film_count >= 10
ORDER BY q75_rating DESC,
         rating_stddev ASC;

-- 2. Фильмы с высокими кассовыми сборами часто считают успешными, но значит ли это, что пользователи оценивают их выше? Или, наоборот, коммерчески успешные проекты не всегда получают высокие оценки?
-- Предлагаем разобраться, существует ли статистически значимая разница в пользовательских оценках между фильмами с высокими и низкими кассовыми сборами. Используя непараметрический критерий Манна — Уитни, сравните распределения пользовательских оценок из столбца ratings между двумя группами фильмов:

-- Группа 0 — фильмы с кассовыми сборами ниже медианы или равными ей.
-- Группа 1 — фильмы с кассовыми сборами выше медианного значения по всем фильмам.

-- Для вычисления медианного значения примените функцию, которая обеспечивает максимальную точность при расчётах. Выведите два столбца:

-- U_statistic — U-статистика;
-- p_value — p-value, округлённое до двух знаков после точки.

WITH film_data AS (
    SELECT 
        s.ratings,
        ps.box_office,
        quantileExact(0.5)(ps.box_office) OVER() AS median_box_office,
        IF(ps.box_office > quantileExact(0.5)(ps.box_office) OVER(), 1, 0) AS group_id
    FROM source_db.screenings s
    JOIN source_db.punumber_show ps ON s.punumber = ps.punumber
    WHERE s.ratings IS NOT NULL
      AND ps.box_office IS NOT NULL
)
SELECT 
    ROUND(mannWhitneyUTest(ratings, group_id).1, 1) AS U_statistic,
    ROUND(mannWhitneyUTest(ratings, group_id).2, 2) AS p_value
FROM film_data;

-- 3. Говорят, что на оценку зрителей влияет страна производства фильма. Выясните, какие фильмы были оценены ниже среднего в своей стране производства. В WHERE не получится напрямую вывести оконную функцию, поэтому создайте CTE film_with_avg с подзапросом, в котором будут поля:

-- title — название фильма;
-- production_country — страна производства фильма;
-- ratings — рейтинг фильма;
-- avg_country_rating — средний рейтинг по стране.

-- Во внешнем запросе выведите все эти поля, оставив фильмы с рейтингом ниже среднего по стране. Результат отсортируйте в порядке возрастания сначала по стране production_country, а затем по рейтингу ratings.

-- 4. Студии регулярно выпускают фильмы, но зрительские оценки могут меняться: один фильм — хит, следующий — разочарование. Интересно исследовать, насколько стабильна репутация студий с точки зрения пользовательских рейтингов и как она меняется.
-- Ваша цель — отследить изменение рейтингов фильмов внутри каждой студии в порядке выхода фильмов по дате. Для этого сначала отсортируйте фильмы внутри каждой студии по дате выхода. Для каждого фильма рассчитайте:

-- previous_rating — рейтинг предыдущего фильма этой студии, если он есть.
-- rating_diff — разницу между текущим и предыдущим рейтингами. Она может быть как положительной, так и отрицательной.

-- Не забывайте, что при использовании оконной функции для поиска предыдущего значения важно задать фрейм. В него войдёт текущая строка и одна строка до неё.
-- Выведите поля studio_name, show_start_date, ratings, previous_rating и rating_diff. Результат отсортируйте в порядке возрастания сначала по studio_name, а затем по show_start_date.

SELECT 
    sn.studio_name AS studio_name,
    s.show_start_date AS show_start_date,
    s.ratings AS ratings,
    lagInFrame(s.ratings, 1) OVER (PARTITION BY sn.studio_name ORDER BY s.show_start_date) AS previous_rating,
    s.ratings - lagInFrame(s.ratings, 1) OVER (PARTITION BY sn.studio_name ORDER BY s.show_start_date) AS rating_diff
FROM source_db.screenings s
JOIN source_db.punumber_studio ps ON s.punumber = ps.punumber
JOIN source_db.studio_names sn ON ps.studio_id = sn.studio_id
WHERE s.ratings IS NOT NULL
  AND s.show_start_date IS NOT NULL
ORDER BY studio_name ASC, show_start_date ASC;



-- Практическое задание
-- Теперь попробуйте сами создать, переименовать и удалить таблицу. Для этого используйте ранее созданную схему playground_da_….
-- В своей текущей базе данных создайте таблицу test_activity со столбцами:

-- id — целочисленный идентификатор записи типа UInt32;
-- username — имя пользователя типа String;
-- event_date — дата и время события типа DateTime.

-- Таблица должна использовать движок MergeTree, данные нужно партиционировать по месяцу toYYYYMM(event_date) и сортировать внутри партиции по (event_date, id).
-- После того как создадите таблицу, переименуйте её: test_activity → user_activity. А затем удалите таблицу user_activity.

-- 1. Создаём таблицу
CREATE TABLE IF NOT EXISTS playground_da_….test_activity -- Уточните название схемы
(
    id         UInt32,
    username   String,
    event_date DateTime
)
ENGINE = MergeTree()
PARTITION BY toYYYYMM(event_date)
ORDER BY (event_date, id);

-- 2. Переименовываем таблицу test_activity в user_activity
RENAME TABLE test_activity TO user_activity

-- 3. Удаляем таблицу user_activity
DROP TABLE IF EXISTS user_activity;


-- Практическое задание
-- Теперь попробуйте сами добавить, удалить и переименовать столбец. Для этого используйте ранее созданную схему playground_da_….
-- В своей текущей базе данных создайте таблицу screenings на основе существующей в source_db. Таблица должна использовать движок MergeTree, данные нужно партиционировать по месяцу toYYYYMM(event_date) и сортировать внутри партиции по (event_date, id). После того как скопируете таблицу, создайте поле с любым названием, а затем переименуйте и удалите его.

-- 1. Копируем таблицу
CREATE TABLE IF NOT EXISTS playground_da_….screenings -- Уточните название схемы
ENGINE = MergeTree()
PARTITION BY toYYYYMM(event_date)
ORDER BY (event_date, id);
AS
SELECT *
FROM source_db.screenings
LIMIT 1000;

-- 2. Создаём столбец 
ALTER TABLE playground_da_….screenings ADD COLUMN IF NOT EXISTS sample_column

-- 3. Переименовываем столбец 
ALTER TABLE playground_da_….screenings RENAME COLUMN sample_column TO sample_column_1

-- 4. Удаляем столбец
ALTER TABLE playground_da_….screenings DROP COLUMN IF EXISTS sample_column_1
