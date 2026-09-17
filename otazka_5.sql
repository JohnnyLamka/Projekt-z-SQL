OTÁZKA Č. 5
Má výška HDP vliv na změny ve mzdách a cenách potravin?
Pokud HDP vzroste výrazněji v jednom roce, projeví se to na cenách
potravin či mzdách ve stejném nebo následujícím roce výraznějším růstem?
------------------------------------------------------------------------

WITH yearly_wages AS (
    SELECT
        payroll_year AS year,
        AVG(value) AS average_wage
    FROM czechia_payroll
    WHERE value_type_code = 5958
      AND unit_code = 200
      AND calculation_code = 200
    GROUP BY payroll_year
),
wage_growth AS (
    SELECT
        year,
        ((average_wage - LAG(average_wage) OVER (ORDER BY year))
        / LAG(average_wage) OVER (ORDER BY year)) * 100
            AS wage_growth_percent
    FROM yearly_wages
),
category_yearly_prices AS (
    SELECT
        EXTRACT(YEAR FROM date_from)::int AS year,
        category_code,
        AVG(value) AS average_price
    FROM czechia_price
    GROUP BY
        EXTRACT(YEAR FROM date_from),
        category_code
),
category_price_growth AS (
    SELECT
        year,
        category_code,
        ((average_price - LAG(average_price) OVER (
            PARTITION BY category_code ORDER BY year))
        / LAG(average_price) OVER (
            PARTITION BY category_code ORDER BY year)) * 100
            AS price_growth_percent
    FROM category_yearly_prices
),
yearly_price_growth AS (
    SELECT
        year,
        AVG(price_growth_percent) AS price_growth_percent
    FROM category_price_growth
    WHERE price_growth_percent IS NOT NULL
    GROUP BY year
),
gdp_growth AS (
    SELECT
        year,
        ((gdp - LAG(gdp) OVER (ORDER BY year))
        / LAG(gdp) OVER (ORDER BY year)) * 100
            AS gdp_growth_percent
    FROM economies
    WHERE country = 'Czech Republic'
),
combined AS (
    SELECT
        g.year,
        g.gdp_growth_percent,
        w.wage_growth_percent,
        p.price_growth_percent
    FROM gdp_growth g
    JOIN wage_growth w
        ON g.year = w.year
    JOIN yearly_price_growth p
        ON g.year = p.year
)
SELECT
    year,
    ROUND(gdp_growth_percent::numeric, 2) AS gdp_growth_percent,
    ROUND(wage_growth_percent::numeric, 2) AS wage_growth_same_year,
    ROUND(price_growth_percent::numeric, 2) AS price_growth_same_year,
    ROUND(
        LEAD(wage_growth_percent) OVER (ORDER BY year)::numeric, 2
    ) AS wage_growth_next_year,
    ROUND(
        LEAD(price_growth_percent) OVER (ORDER BY year)::numeric, 2
    ) AS price_growth_next_year
FROM combined
WHERE year BETWEEN 2007 AND 2018
ORDER BY year;
-------------------------------------------------------------------------

ODPOVĚĎ:

Z výsledků nelze potvrdit jednoznačnou přímou závislost mezi růstem HDP
a růstem mezd či cen potravin.

Například v roce 2017 vzrostlo HDP o 5,17 %, mzdy o 6,19 %
a ceny potravin o 7,06 %. V tomto roce je tedy určitá souvislost patrná.

Tento vztah však není pravidelný. V roce 2015 vzrostlo HDP o 5,39 %,
zatímco mzdy pouze o 2,62 % a ceny potravin klesly o 0,69 %.
V následujícím roce vzrostly mzdy o 3,68 %, ale ceny potravin
opět klesly o 1,41 %.

Data tedy nenaznačují, že by výraznější růst HDP pravidelně vedl
k výraznějšímu růstu mezd nebo cen potravin ve stejném či následujícím roce.
Výsledky ukazují souvislosti v jednotlivých obdobích, nikoliv důkaz
příčinného vztahu.

