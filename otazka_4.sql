OTÁZKA Č. 4
Existuje rok, ve kterém byl meziroční nárůst cen potravin
výrazně vyšší než růst mezd (větší než 10 %)?
----------------------------------------------------------

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
wage_changes AS (
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
category_price_changes AS (
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
    FROM category_price_changes
    WHERE price_growth_percent IS NOT NULL
    GROUP BY year
)
SELECT
    w.year,
    ROUND(w.wage_growth_percent::numeric, 2) AS wage_growth_percent,
    ROUND(p.price_growth_percent::numeric, 2) AS price_growth_percent,
    ROUND((p.price_growth_percent - w.wage_growth_percent)::numeric, 2)
        AS difference
FROM wage_changes w
JOIN yearly_price_growth p
    ON w.year = p.year
WHERE w.year BETWEEN 2007 AND 2018
ORDER BY w.year;
------------------------------------------------------------------------

ODPOVĚĎ:

Ve sledovaném období 2007-2018 nebyl nalezen rok, kdy by průměrný
meziroční růst cen potravin převýšil růst mezd o více než
10 procentních bodů.

Největší rozdíl nastal v roce 2013, kdy mzdy poklesly o 1,49 %,
zatímco ceny potravin vzrostly v průměru o 6,01 %.
Rozdíl činil 7,50 procentního bodu.

Formulace „větší než 10 %“ je zde interpretována jako rozdíl
větší než 10 procentních bodů mezi meziroční změnou cen a mezd.

