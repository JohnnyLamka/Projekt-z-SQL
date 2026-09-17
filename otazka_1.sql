OTÁZKA Č. 1
Rostou v průběhu let mzdy ve všech odvětvích, nebo v některých klesají?
-----------------------------------------------------------------------

WITH wages AS (
    SELECT
        payroll_year,
        industry_branch_code,
        AVG(value) AS average_wage
    FROM czechia_payroll
    WHERE value_type_code = 5958
      AND unit_code = 200
      AND calculation_code = 200
      AND industry_branch_code IS NOT NULL
    GROUP BY payroll_year, industry_branch_code
),
wages_with_previous AS (
    SELECT
        payroll_year,
        industry_branch_code,
        average_wage,
        LAG(average_wage) OVER (
            PARTITION BY industry_branch_code
            ORDER BY payroll_year
        ) AS previous_year_wage
    FROM wages
)
SELECT
    w.payroll_year,
    w.industry_branch_code,
    ib.name AS industry_name,
    ROUND(w.average_wage::numeric, 2) AS average_wage,
    ROUND(w.previous_year_wage::numeric, 2) AS previous_year_wage,
    ROUND(
        ((w.average_wage - w.previous_year_wage)
        / w.previous_year_wage * 100)::numeric, 2
    ) AS wage_change_percent
FROM wages_with_previous w
JOIN czechia_payroll_industry_branch ib
    ON w.industry_branch_code = ib.code
WHERE w.previous_year_wage IS NOT NULL
  AND w.average_wage < w.previous_year_wage
ORDER BY w.industry_branch_code, w.payroll_year;

--------------------------------------------------------------------
ODPOVĚĎ:

Mzdy v průběhu sledovaného období nerostly ve všech odvětvích nepřetržitě.
Ve většině případů je vidět dlouhodobý růst mezd, ale v některých odvětvích
a jednotlivých letech došlo k meziročnímu poklesu.

Nelze tedy říci, že by mzdy každý rok rostly ve všech odvětvích.
