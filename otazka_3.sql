OTÁZKA Č. 3
Která kategorie potravin zdražuje nejpomaleji
(je u ní nejnižší percentuální meziroční nárůst)?
--------------------------------------------------

WITH yearly_prices AS (
    SELECT
        EXTRACT(YEAR FROM cp.date_from)::int AS year,
        cp.category_code,
        cpc.name,
        AVG(cp.value) AS average_price
    FROM czechia_price cp
    JOIN czechia_price_category cpc
        ON cp.category_code = cpc.code
    GROUP BY
        EXTRACT(YEAR FROM cp.date_from),
        cp.category_code,
        cpc.name
),
prices_with_previous AS (
    SELECT
        year,
        category_code,
        name,
        average_price,
        LAG(average_price) OVER (
            PARTITION BY category_code
            ORDER BY year
        ) AS previous_year_price
    FROM yearly_prices
),
price_changes AS (
    SELECT
        year,
        category_code,
        name,
        ((average_price - previous_year_price)
        / previous_year_price) * 100 AS price_change_percent
    FROM prices_with_previous
    WHERE previous_year_price IS NOT NULL
)
SELECT
    name,
    ROUND(AVG(price_change_percent)::numeric, 2)
        AS average_yearly_growth_percent
FROM price_changes
GROUP BY category_code, name
ORDER BY average_yearly_growth_percent ASC;

--------------------------------------------------------------
ODPOVĚĎ:

Nejnižší průměrnou meziroční změnu ceny vykazoval cukr krystalový,
přibližně -1,92 %.

Jeho cena tedy ve sledovaném období v průměru meziročně spíše klesala
než rostla. Druhou nejnižší hodnotu měla rajská jablka červená kulatá
s přibližně -0,74 %.

