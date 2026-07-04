# 📊 My Data Analyst Portfolio

![MIT License](https://img.shields.io/badge/License-MIT-green.svg)
![Python](https://img.shields.io/badge/Python-3.9+-blue.svg)
![SQL](https://img.shields.io/badge/SQL-PostgreSQL%20%7C%20ClickHouse-orange.svg)
![Jupyter](https://img.shields.io/badge/Jupyter-Notebook-red.svg)

---

## 👋 About me

**My name is Maksim**, I'm a data analyst.

 I work with large amounts of data, build dashboards, and write complex SQL queries. I'm proficient in Python, SQL, and BI tools.

---

## 🛠 Tools and Technologies

| Category | Technologies |
|-----------|-------------|
| **Databases and SQL** | PostgreSQL, ClickHouse, DBeaver |
| **Data Analysis** | Jupyter Notebook, Python (pandas, numpy, matplotlib) |
| **BI and Visualization** | Yandex DataLens, Apache Superset |
| **Office Tools** | MS Excel, MS PowerPoint, MS Word |

---

## 📁 Portfolio structure
data-analytics-portfolio/
├── python/ # Jupyter Notebook projects
├── sql/ # SQL queries (DBeaver)
└── dashboards/ # Screenshots of dashboards (DataLens, Superset)

---

## 📂 Projects

*This is where your projects will go. Add them as you're ready.*

### 🐍 Jupyter Notebook

| № | Проект | Описание | Ссылка |
|---|--------|----------|--------|
| 1 | **A/B тестирование** | Разработка и анализ A/B-теста для нового алгоритма рекомендаций в развлекательном приложении. Доказано статистически значимое влияние на вовлечённость пользователей (p-value = 0.00031). | [`ab_testing`](./python/ab_testing/) |
| 2 | **Яндекс Книги** | Анализ активности пользователей сервиса: расчёт MAU, Retention, LTV. Проверка гипотезы о различиях между Москвой и Санкт-Петербургом с помощью t-теста. | [`yandex_books`](./python/yandex_books/) |
| 3 | **Исследование стартапов** | Анализ данных об инвестициях и приобретении стартапов. Выявлены категории с высокими ценами и большим разбросом. Даны рекомендации для инвесторов по балансу рисков и доходности. | [`startup_research`](./python/startup_research/) |
| 4 | **Игровая индустрия** | Анализ продаж игр за 2000-2013, региональные предпочтения, топ-7 платформ. Рекомендации по привлечению аудитории для игры «Секреты Темнолесья» с акцентом на RPG-жанр. | [`gaming_industry`](./python/gaming_industry/) |
| 5 | **Общепит Москвы** | Исследование рынка заведений Москвы: распределение по районам, доля сетевых заведений (38.1%), посадочные места, рейтинги, средний чек (от 450 до 1000 ₽ в зависимости от округа). Рекомендации для инвесторов по формату и локации. | [`catering_moscow`](./python/catering_moscow/) |

---

### Краткие итоги по проектам

#### 1. A/B тестирование
- **Задача:** Оценить влияние нового алгоритма рекомендаций на вовлечённость пользователей
- **Методы:** A/B-тест, статистическая проверка (t-тест)
- **Результат:** Новый алгоритм статистически значимо увеличил долю успешных сессий (+1.1 п.п., p-value = 0.00031). **Рекомендация:** внедрять.

#### 2. Яндекс Книги
- **Задача:** Анализ активности пользователей и A/B-теста интернет-магазина BitMotion Kit
- **Методы:** t-тест, расчёт MAU, Retention, LTV, z-тест для конверсии
- **Результат:** Конверсия в тестовой группе (новый интерфейс) — 29.27% против 27.49% в контрольной. Однако z-тест (p-value = 0.9717) показал, что разница статистически не значима. **Рекомендация:** продолжить наблюдение, исключить пересекающиеся тесты.

#### 3. Исследование стартапов
- **Задача:** Выявить параметры, влияющие на успех покупки стартапов
- **Методы:** EDA, визуализация, анализ пропусков, медианные оценки
- **Результат:** Стартапы, выходящие на IPO, проходят больше раундов финансирования. Категории с высокими ценами (Biotechnology, Clean Technology) имеют большой разброс — высокие риски и потенциал. **Рекомендация:** использовать медианные показатели, учитывать волатильность.

#### 4. Игровая индустрия
- **Задача:** Привлечение аудитории к игре «Секреты Темнолесья»
- **Методы:** Фильтрация данных, категоризация оценок, региональный анализ
- **Результат:** Топ-7 платформ: DS, PS2, PS3, X360, Wii, PSP, PC. RPG-жанр наиболее популярен в Японии и Европе. **Рекомендация:** фокус на консольные версии и перевод на японский/европейские языки.

#### 5. Общепит Москвы
- **Задача:** Помочь инвесторам выбрать формат и район для открытия заведения
- **Методы:** EDA, корреляционный анализ, геораспределение
- **Результат:** Самая высокая концентрация заведений — в ЦАО. Лидеры по доле сетевых: булочные, пиццерии, кофейни (до 60%). Средний чек в ЦАО ~1000 ₽, в спальных районах 450-600 ₽. **Рекомендация:** в спальных районах — экономичные форматы (кофейни, булочные), в центре — премиум-сегмент.

---

## 📊 Дашборды (DataLens / Superset)

| Проект | Платформа | Скриншот | Описание |
|--------|-----------|----------|----------|
| **Marketing Performance Dashboard** | Yandex DataLens | ![скрин 1](./dashboards/screenshots/Marketing%20Performanca%20Dashboard.png) | Общий вид: ROI, клиенты, заказы, затраты, выручка |
| | | ![скрин 2](./dashboards/screenshots/Marketing%20Performanca%20Dashboard%202.png) | Аналитическая справка: конверсия (+18.9% PoP), критический ROI (-97.2%) |
| | | ![скрин 3](./dashboards/screenshots/Marketing%20Performanca%20Dashboard%203.png) | RCI по типам рекламы (content, cpc, mail) |
| | | ![скрин 4](./dashboards/screenshots/Marketing%20Performanca%20Dashboard%204.png) | Динамика клиентской базы, ROI по каналам, длительность сессии |
| **Games Analytics Dashboard** | Yandex DataLens | ![скрин 1](./dashboards/screenshots/Games%20Analytics%20Dashboard.png) | Общий вид: 16 773 игры, 3 280 разработчиков |
| | | ![скрин 2](./dashboards/screenshots/Games%20Analytics%20Dashboard%201.png) | Средняя цена (193 ₽), динамика по платформам |
| | | ![скрин 3](./dashboards/screenshots/Games%20Analytics%20Dashboard%202.png) | Изменение цен (YoY), распределение по жанрам |
| | | ![скрин 4](./dashboards/screenshots/Games%20Analytics%20Dashboard%203.png) | Установки (13 046), игроки (2 730) |
| | | ![скрин 5](./dashboards/screenshots/Games%20Analytics%20Dashboard%205.png) | Достижения: Platinum — 419 |
| | | ![скрин 6](./dashboards/screenshots/Games%20Analytics%20Dashboard%207.png) | Ачивки по жанру/платформе |
| **E-commerce аналитический дашборд** | Apache Superset | ![скрин 1](./dashboards/screenshots/Screenshot%202026-06-17%20at%2014-03-37%20E-commerce%20аналитический%20дашборд_max.bessudnoff.png) | Основные метрики, каналы (referral, ads, email, organic) |
| | | ![скрин 2](./dashboards/screenshots/Screenshot%202026-06-17%20at%2014-03-47%20E-commerce%20аналитический%20дашборд_max.bessudnoff.png) | Товары: выручка 5.93M, 55.3K заказов |
| | | ![скрин 3](./dashboards/screenshots/Screenshot%202026-06-17%20at%2014-04-11%20E-commerce%20аналитический%20дашборд_max.bessudnoff.png) | Конверсия в заказ |
| **Панель управления маркетплейсом** | Apache Superset | ![скрин 1](./dashboards/screenshots/Screenshot%202026-06-17%20at%2014-04-44%20Панель%20управления%20маркетплейсом%20Аналитика%20продаж%20и%20пользователей.png) | LTV, DAU, ARPU/ARPPU |
| | | ![скрин 2](./dashboards/screenshots/Screenshot%202026-06-17%20at%2014-05-21%20Панель%20управления%20маркетплейсом%20Аналитика%20продаж%20и%20пользователей.png) | Продавцы vs покупатели |
| | | ![скрин 3](./dashboards/screenshots/Screenshot%202026-06-17%20at%2014-05-46%20Панель%20управления%20маркетплейсом%20Аналитика%20продаж%20и%20пользователей.png) | Топ-10 товаров: Record (5.46M) |
| **Продажи медицинских пробирок** | Yandex DataLens | ![скрин](./dashboards/screenshots/Screenshot%202026-06-17%20at%2013-48-18%20Продажи%20медицинских%20пробирок%20—%20обзор%20и%20детализация.png) | МедТех (130 020.7 млн ₽), Здоровье (73 298.5 млн ₽) |
| **Дашборд для агентства недвижимости** | Yandex DataLens | ![скрин 1](./dashboards/screenshots/Screenshot%202026-06-17%20at%2013-49-15%20Дашборд%20для%20агентства%20недвижимости.png) | 23 650 квартир, средняя цена |
| | | ![скрин 2](./dashboards/screenshots/Screenshot%202026-06-17%20at%2013-49-24%20Дашборд%20для%20агентства%20недвижимости.png) | Топ-5 по количеству квартир (СПб — 15 721) |
| | | ![скрин 3](./dashboards/screenshots/Screenshot%202026-06-17%20at%2013-49-35%20Дашборд%20для%20агентства%20недвижимости.png) | Топ-5 по цене (Репино — 12M) |
| | | ![скрин 4](./dashboards/screenshots/Screenshot%202026-06-17%20at%2013-49-45%20Дашборд%20для%20агентства%20недвижимости.png) | Средняя стоимость 1 м² (СПб — 124 514 ₽) |
| | | ![скрин 5](./dashboards/screenshots/Screenshot%202026-06-17%20at%2013-49-53%20Дашборд%20для%20агентства%20недвижимости.png) | Детализация по дням недели |

---

## 🗄️ SQL (DBeaver)

| # | Project | Description | Technologies | Link |
|---|---------|-------------|--------------|------|
| 1 | **Секреты Тёмнолесья** | Analysis of in-game purchases: share of paying players, segmentation by race, frequency analysis | PostgreSQL, CTE, Window Functions | [📁](./sql/01_game_analytics/) |
| 2 | **Real Estate Market** | Analysis of real estate market in St. Petersburg and Leningrad region: seasonality, regional comparison | PostgreSQL, CTE, Percentiles, FULL OUTER JOIN | [📁](./sql/02_real_estate/) |
| 3 | **GameBase (Steam)** | Database recovery and optimization: indexes, partitioning, data mart creation | PostgreSQL, DDL, Indexes, Partitioning | [📁](./sql/03_steam_gamebase/) |
| 4 | **Movie Analytics (ClickHouse)** | Analysis of movie ratings: dynamics by year, comparison of Russian vs foreign films | ClickHouse, Arrays, Statistical Tests | [📁](./sql/04_clickhouse_movies/) |
| 5 | **Yandex Books** | User behavior analysis: platform differences (iOS vs Android), segmentation, anomaly detection | ClickHouse, Conditional Aggregation, Variation Coefficient | [📁](./sql/05_yandex_books/) |
| 6 | **Marketplace** | Data cleaning and preparation: deduplication, logical error fixing, business metrics calculation | PostgreSQL, Descriptive Statistics, Window Functions | [📁](./sql/06_marketplace/) |
| 7 | **Yandex Taxi** | Automated ETL pipeline: data aggregation by payment type, daily Airflow scheduling | PySpark, ClickHouse, Airflow, S3 | [📁](./sql/07_taxi_spark_airflow/) |
---

## 📫 Контакты

- **Telegram:** @makff15
- **GitHub:** [github.com/ваш_username](https://github.com/ваш_username)

---

## 📄 Лицензия

MIT License — подробнее в файле [LICENSE](./LICENSE)
