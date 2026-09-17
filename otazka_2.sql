OTÁZKA Č. 2
Kolik je možné si koupit litrů mléka a kilogramů chleba
za první a poslední srovnatelné období v dostupných datech cen a mezd?
----------------------------------------------------------------------

WITH wages AS (
    SELECT
        payroll_year AS year,
        AVG(value) AS average_wage
    FROM czechia_payroll
    WHERE value_type_code = 5958
      AND unit_code = 200
      AND calculation_code = 200
    GROUP BY payroll_year
),
prices AS (
    SELECT
        EXTRACT(YEAR FROM cp.date_from)::int AS year,
        cp.category_code,
        cpc.name,
        AVG(cp.value) AS average_price
    FROM czechia_price cp
    JOIN czechia_price_category cpc
        ON cp.category_code = cpc.code
    WHERE cp.category_code IN (111301, 114201)
    GROUP BY
        EXTRACT(YEAR FROM cp.date_from),
        cp.category_code,
        cpc.name
)
SELECT
    w.year,
    p.name AS food,
    ROUND(w.average_wage::numeric, 2) AS average_wage,
    ROUND(p.average_price::numeric, 2) AS average_price,
    ROUND((w.average_wage / p.average_price)::numeric, 2) AS purchasable_amount
FROM wages w
JOIN prices p
    ON w.year = p.year
WHERE w.year IN (2006, 2018)
ORDER BY w.year, p.category_code;

------------------------------------------------------------------------
ODPOVĚĎ:

Prvním a posledním srovnatelným obdobím jsou roky 2006 a 2018.

V roce 2006 bylo možné za průměrnou mzdu koupit přibližně
1 307,63 kg chleba nebo 1 460,31 litru mléka.

V roce 2018 bylo možné za průměrnou mzdu koupit přibližně
1 363,08 kg chleba nebo 1 667,16 litru mléka.

Kupní síla průměrné mzdy tedy vůči oběma sledovaným potravinám vzrostla,
výrazněji u mléka.

