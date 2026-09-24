-- Vytvoření primární finální tabulky
-- Obsahuje průměrné mzdy podle odvětví a průměrné ceny potravin
-- za společné srovnatelné období 2006–2018.

CREATE TABLE t_jan_lamka_project_SQL_primary_final AS

WITH mzdy AS (
    SELECT
        cp.payroll_year AS rok,
        cp.industry_branch_code,
        cpib.name AS odvetvi,
        AVG(cp.value) AS prumerna_mzda
    FROM czechia_payroll cp
    JOIN czechia_payroll_industry_branch cpib
        ON cp.industry_branch_code = cpib.code
    WHERE cp.value_type_code = 5958
        AND cp.unit_code = 200
        AND cp.calculation_code = 200
        AND cp.industry_branch_code IS NOT NULL
    GROUP BY
        cp.payroll_year,
        cp.industry_branch_code,
        cpib.name
),

ceny AS (
    SELECT
        EXTRACT(YEAR FROM cp.date_from) AS rok,
        cp.category_code,
        cpc.name AS potravina,
        cpc.price_value,
        cpc.price_unit,
        AVG(cp.value) AS prumerna_cena
    FROM czechia_price cp
    JOIN czechia_price_category cpc
        ON cp.category_code = cpc.code
    GROUP BY
        EXTRACT(YEAR FROM cp.date_from),
        cp.category_code,
        cpc.name,
        cpc.price_value,
        cpc.price_unit
)

SELECT
    m.rok,
    m.industry_branch_code,
    m.odvetvi,
    m.prumerna_mzda,
    c.category_code,
    c.potravina,
    c.price_value,
    c.price_unit,
    c.prumerna_cena
FROM mzdy m
JOIN ceny c
    ON m.rok = c.rok
WHERE m.rok BETWEEN 2006 AND 2018
ORDER BY
    m.rok,
    m.industry_branch_code,
    c.category_code;
