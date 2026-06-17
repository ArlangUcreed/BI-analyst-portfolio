
---

## 🔵 Файл №2: `1st_module_project_Bessudnov M.A.sql`

**Скопируй ЭТОТ текст целиком** и вставь в файл `1st_module_project_Bessudnov M.A.sql` в папке `02_real_estate`:

```sql
/* Проект первого модуля: анализ данных для агентства недвижимости
 * 
 * Автор: Бессуднов Максим Александрович
 * Дата: 29.04.2025
*/

-- Задача 1. Время активности объявлений
WITH filtered_data AS (
    SELECT 
        a.id AS advertisement_id,
        a.first_day_exposition,
        a.days_exposition,
        a.last_price,
        f.id AS flat_id,
        f.city_id,
        f.total_area,
        f.rooms,
        f.balcony,
        f.floors_total,
        c.city
    FROM real_estate.advertisement a
    JOIN real_estate.flats f ON a.id = f.id
    JOIN real_estate.city c ON f.city_id = c.city_id
    WHERE 
        a.days_exposition IS NOT NULL
        AND a.last_price IS NOT NULL
        AND f.total_area > 0
),

categorized_data AS (
    SELECT 
        advertisement_id,
        CASE
            WHEN city = 'Санкт-Петербург' THEN 'Санкт-Петербург'
            ELSE 'ЛенОбл'
        END AS region,
        CASE
            WHEN days_exposition <= 30 THEN 'до месяца'
            WHEN days_exposition BETWEEN 31 AND 90 THEN 'от месяца до трёх месяцев'
            WHEN days_exposition BETWEEN 91 AND 180 THEN 'более трёх месяцев до полугода'
            ELSE 'более полугода'
        END AS activity_segment,
        last_price / total_area AS price_per_sqm,
        total_area,
        rooms,
        balcony,
        floors_total
    FROM filtered_data
),

aggregated_data AS (
    SELECT
        region,
        activity_segment,
        COUNT(advertisement_id) AS count_ads,
        AVG(price_per_sqm) AS avg_price_per_sqm,
        ROUND(AVG(total_area)::numeric, 2) AS avg_area,
        AVG(rooms) AS avg_rooms,
        AVG(balcony) AS avg_balcony,
        AVG(floors_total) AS avg_floor
    FROM categorized_data
    GROUP BY region, activity_segment
)

SELECT *
FROM aggregated_data
ORDER BY region,
         CASE activity_segment
             WHEN 'до месяца' THEN 1
             WHEN 'от месяца до трёх месяцев' THEN 2
             WHEN 'более трёх месяцев до полугода' THEN 3
             ELSE 4
         END;


-- Задача 2. Сезонность объявлений
WITH advertisement_dates AS (
    SELECT 
        a.id AS advertisement_id,
        a.first_day_exposition,
        a.days_exposition,
        a.last_price,
        a.first_day_exposition + INTERVAL '1 day' * a.days_exposition AS removal_date
    FROM real_estate.advertisement a
),

monthly_activity AS (
    SELECT 
        EXTRACT(YEAR FROM first_day_exposition) AS year,
        EXTRACT(MONTH FROM first_day_exposition) AS month,
        COUNT(advertisement_id) AS publication_count,
        0 AS removal_count
    FROM advertisement_dates
    GROUP BY year, month

    UNION ALL

    SELECT 
        EXTRACT(YEAR FROM removal_date) AS year,
        EXTRACT(MONTH FROM removal_date) AS month,
        0 AS publication_count,
        COUNT(advertisement_id) AS removal_count
    FROM advertisement_dates
    GROUP BY year, month
),

aggregated_activity AS (
    SELECT 
        ma.year,
        ma.month,
        SUM(ma.publication_count) AS total_publications,
        SUM(ma.removal_count) AS total_removals,
        AVG(ad.last_price / f.total_area) AS avg_price_per_sqm,
        AVG(f.total_area) AS avg_area
    FROM monthly_activity ma
    LEFT JOIN advertisement_dates ad 
        ON ma.year = EXTRACT(YEAR FROM ad.first_day_exposition) 
        AND ma.month = EXTRACT(MONTH FROM ad.first_day_exposition)
    LEFT JOIN real_estate.flats f ON ad.advertisement_id = f.id
    GROUP BY ma.year, ma.month
)

SELECT 
    year,
    month,
    total_publications,
    total_removals,
    ROUND(avg_price_per_sqm::numeric, 2) AS avg_price_per_sqm,
    ROUND(avg_area::numeric, 2) AS avg_area
FROM aggregated_activity
ORDER BY year, month;


-- Задача 3. Анализ рынка недвижимости Ленобласти
WITH city_activity AS (
    SELECT 
        c.city AS city_name,
        COUNT(a.id) AS total_listings,
        SUM(CASE WHEN a.days_exposition IS NULL THEN 1 ELSE 0 END) AS removed_listings,
        AVG(a.last_price / f.total_area) AS avg_price_per_sqm,
        AVG(f.total_area) AS avg_area,
        AVG(a.days_exposition) AS avg_days_exposition
    FROM real_estate.advertisement a
    JOIN real_estate.flats f ON a.id = f.id
    JOIN real_estate.city c ON f.city_id = c.city_id
    GROUP BY c.city
    HAVING COUNT(a.id) > 50
)

SELECT 
    city_name,
    total_listings,
    removed_listings,
    ROUND((removed_listings::numeric / total_listings) * 100, 2) AS removal_rate,
    avg_price_per_sqm,
    avg_area,
    avg_days_exposition
FROM city_activity
ORDER BY total_listings DESC;


/* ============================================================
   ЧАСТЬ 2. РЕШЕНИЕ AD HOC ЗАДАЧ
   Автор: Бессуднов Максим Александрович
   Дата: 12.05.2025
   ============================================================ */

-- Пример фильтрации данных от аномальных значений
WITH limits AS (
    SELECT
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY total_area) AS total_area_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY rooms) AS rooms_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY balcony) AS balcony_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY ceiling_height) AS ceiling_height_limit_h,
        PERCENTILE_DISC(0.01) WITHIN GROUP (ORDER BY ceiling_height) AS ceiling_height_limit_l
    FROM real_estate.flats
),
filtered_id AS (
    SELECT id
    FROM real_estate.flats  
    WHERE 
        total_area < (SELECT total_area_limit FROM limits)
        AND (rooms < (SELECT rooms_limit FROM limits) OR rooms IS NULL)
        AND (balcony < (SELECT balcony_limit FROM limits) OR balcony IS NULL)
        AND ((ceiling_height < (SELECT ceiling_height_limit_h FROM limits)
            AND ceiling_height > (SELECT ceiling_height_limit_l FROM limits)) OR ceiling_height IS NULL)
)
SELECT *
FROM real_estate.flats
WHERE id IN (SELECT * FROM filtered_id);


-- Задача 1: Время активности объявлений (расширенная версия)
WITH limits AS (
    SELECT  
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY total_area) AS total_area_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY rooms) AS rooms_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY balcony) AS balcony_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY ceiling_height) AS ceiling_height_limit_h,
        PERCENTILE_DISC(0.01) WITHIN GROUP (ORDER BY ceiling_height) AS ceiling_height_limit_l
    FROM real_estate.flats     
),
filtered_id AS (
    SELECT id
    FROM real_estate.flats  
    WHERE 
        total_area < (SELECT total_area_limit FROM limits)
        AND (rooms < (SELECT rooms_limit FROM limits) OR rooms IS NULL)
        AND (balcony < (SELECT balcony_limit FROM limits) OR balcony IS NULL)
        AND ((ceiling_height < (SELECT ceiling_height_limit_h FROM limits)
            AND ceiling_height > (SELECT ceiling_height_limit_l FROM limits)) OR ceiling_height IS NULL)
),
filtered_data AS (
    SELECT 
        a.id AS advertisement_id,
        a.first_day_exposition,
        a.days_exposition,
        a.last_price,
        f.id AS flat_id,
        f.city_id,
        f.total_area,
        f.rooms,
        f.balcony,
        f.floors_total,
        c.city
    FROM real_estate.advertisement a
    JOIN real_estate.flats f USING (id)
    JOIN real_estate.city c USING (city_id)
    JOIN real_estate.type t ON f.type_id = t.type_id
    WHERE 
        a.last_price IS NOT NULL
        AND f.total_area > 0
        AND f.id IN (SELECT id FROM filtered_id)
        AND t.type = 'город'
),
categorized_data AS (
    SELECT 
        advertisement_id,
        CASE
            WHEN city = 'Санкт-Петербург' THEN 'Санкт-Петербург'
            ELSE 'ЛенОбл'
        END AS region,
        CASE
            WHEN days_exposition IS NULL THEN 'незакрытые'
            WHEN days_exposition <= 30 THEN 'до месяца'
            WHEN days_exposition BETWEEN 31 AND 90 THEN 'от месяца до трёх месяцев'
            WHEN days_exposition BETWEEN 91 AND 180 THEN 'более трёх месяцев до полугода'
            ELSE 'более полугода'
        END AS activity_segment,
        last_price / total_area AS price_per_sqm,
        total_area,
        rooms,
        balcony,
        floors_total
    FROM filtered_data
),
aggregated_data AS (
    SELECT
        region,
        activity_segment,
        COUNT(advertisement_id) AS count_ads,
        AVG(price_per_sqm) AS avg_price_per_sqm,
        ROUND(AVG(total_area)::numeric, 2) AS avg_area,
        AVG(rooms) AS avg_rooms,
        AVG(balcony) AS avg_balcony,
        AVG(floors_total) AS avg_floor,
        COUNT(*) / SUM(COUNT(*)) OVER() AS share_total,
        COUNT(*) / SUM(COUNT(*)) OVER(PARTITION BY region) AS share_region
    FROM categorized_data
    GROUP BY region, activity_segment
)
SELECT *
FROM aggregated_data;


-- Задача 2: Сезонность объявлений (расширенная версия)
WITH limits AS (
    SELECT  
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY total_area) AS total_area_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY rooms) AS rooms_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY balcony) AS balcony_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY ceiling_height) AS ceiling_height_limit_h,
        PERCENTILE_DISC(0.01) WITHIN GROUP (ORDER BY ceiling_height) AS ceiling_height_limit_l
    FROM real_estate.flats     
),
filtered_id AS (
    SELECT id
    FROM real_estate.flats  
    WHERE 
        total_area < (SELECT total_area_limit FROM limits)
        AND (rooms < (SELECT rooms_limit FROM limits) OR rooms IS NULL)
        AND (balcony < (SELECT balcony_limit FROM limits) OR balcony IS NULL)
        AND ((ceiling_height < (SELECT ceiling_height_limit_h FROM limits)
            AND ceiling_height > (SELECT ceiling_height_limit_l FROM limits)) OR ceiling_height IS NULL)
),
advertisement_dates AS (
    SELECT 
        a.id AS advertisement_id,
        a.first_day_exposition,
        a.days_exposition,
        a.last_price,
        a.first_day_exposition + INTERVAL '1 day' * a.days_exposition AS removal_date
    FROM real_estate.advertisement a  
    JOIN real_estate.flats f ON a.id = f.id
    WHERE f.city_id IS NOT NULL
      AND f.total_area > 0
      AND a.last_price IS NOT NULL
      AND f.id IN (SELECT id FROM filtered_id)
),
monthly_publications AS (
    SELECT 
        EXTRACT(YEAR FROM first_day_exposition) AS year,
        EXTRACT(MONTH FROM first_day_exposition) AS month,
        COUNT(advertisement_id) AS publication_count,
        AVG(last_price / f.total_area) AS avg_price_per_sqm,
        AVG(f.total_area) AS avg_area
    FROM advertisement_dates ad
    JOIN real_estate.flats f ON ad.advertisement_id = f.id
    GROUP BY year, month
),
monthly_removals AS (
    SELECT 
        EXTRACT(YEAR FROM removal_date) AS year,
        EXTRACT(MONTH FROM removal_date) AS month,
        COUNT(advertisement_id) AS removal_count,
        AVG(last_price / f.total_area) AS avg_price_per_sqm,
        AVG(f.total_area) AS avg_area
    FROM advertisement_dates ad
    JOIN real_estate.flats f ON ad.advertisement_id = f.id
    WHERE ad.days_exposition IS NOT NULL
    GROUP BY year, month
)
SELECT 
    COALESCE(p.year, r.year) AS year,
    COALESCE(p.month, r.month) AS month,
    COALESCE(p.publication_count, 0) AS total_publications,
    COALESCE(r.removal_count, 0) AS total_removals,
    ROUND(COALESCE(p.avg_price_per_sqm, 0)::numeric, 2) AS avg_price_per_sqm,
    ROUND(COALESCE(p.avg_area, 0)::numeric, 2) AS avg_area,
    ROUND(COALESCE(p.publication_count, 0)::numeric / NULLIF(SUM(COALESCE(p.publication_count, 0)) OVER(), 0), 4) AS share_publications,
    ROUND(COALESCE(r.removal_count, 0)::numeric / NULLIF(SUM(COALESCE(r.removal_count, 0)) OVER(), 0), 4) AS share_removals
FROM monthly_publications p
FULL OUTER JOIN monthly_removals r ON p.year = r.year AND p.month = r.month
WHERE (p.year IS NOT NULL OR r.year IS NOT NULL)
ORDER BY year, month;


-- Задача 3: Анализ рынка недвижимости Ленобласти (расширенная версия)
WITH limits AS (
    SELECT  
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY total_area) AS total_area_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY rooms) AS rooms_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY balcony) AS balcony_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY ceiling_height) AS ceiling_height_limit_h,
        PERCENTILE_DISC(0.01) WITHIN GROUP (ORDER BY ceiling_height) AS ceiling_height_limit_l
    FROM real_estate.flats     
),
filtered_id AS (
    SELECT id
    FROM real_estate.flats  
    WHERE 
        total_area < (SELECT total_area_limit FROM limits)
        AND (rooms < (SELECT rooms_limit FROM limits) OR rooms IS NULL)
        AND (balcony < (SELECT balcony_limit FROM limits) OR balcony IS NULL)
        AND ((ceiling_height < (SELECT ceiling_height_limit_h FROM limits)
            AND ceiling_height > (SELECT ceiling_height_limit_l FROM limits)) OR ceiling_height IS NULL)
),
advertisement_filtered AS (
    SELECT 
        a.id AS advertisement_id,
        a.first_day_exposition,
        a.days_exposition,
        a.last_price,
        f.total_area,
        f.city_id
    FROM real_estate.advertisement a  
    JOIN real_estate.flats f ON a.id = f.id
    WHERE f.city_id IS NOT NULL
      AND f.total_area > 0
      AND a.last_price IS NOT NULL
      AND f.id IN (SELECT id FROM filtered_id)
),
city_activity AS (
    SELECT 
        c.city AS city_name,
        f.city_id,
        COUNT(a.advertisement_id) AS total_listings,
        COUNT(CASE WHEN a.days_exposition IS NOT NULL AND a.days_exposition > 0 THEN a.advertisement_id END) AS removed_listings,
        AVG(a.last_price / f.total_area) AS avg_price_per_sqm,
        AVG(f.total_area) AS avg_area,
        AVG(a.days_exposition) AS avg_days_exposition
    FROM advertisement_filtered a
    JOIN real_estate.flats f ON a.advertisement_id = f.id
    JOIN real_estate.city c ON f.city_id = c.city_id
    WHERE c.city != 'Санкт-Петербург'
    GROUP BY c.city, f.city_id
    HAVING COUNT(a.advertisement_id) > 50
       AND AVG(a.last_price / f.total_area) > 0
       AND AVG(f.total_area) > 0
       AND AVG(a.days_exposition) > 0
)
SELECT 
    ca.city_name,
    ca.total_listings,
    ca.removed_listings,
    ROUND((ca.removed_listings::numeric / ca.total_listings) * 100, 2) AS removal_rate,
    ca.avg_price_per_sqm,
    ca.avg_area,
    ca.avg_days_exposition
FROM city_activity ca
ORDER BY ca.total_listings DESC;
