-- 1. Rostou v průběhu let mzdy ve všech odvětvích,
-- nebo v některých klesají?

WITH mzdy AS (
    SELECT DISTINCT
        rok,
        industry_branch_code,
        odvetvi,
        prumerna_mzda
    FROM t_jan_lamka_project_SQL_primary_final
),
porovnani AS (
    SELECT
        rok,
        industry_branch_code,
        odvetvi,
        prumerna_mzda,
        LAG(prumerna_mzda) OVER (
            PARTITION BY industry_branch_code
            ORDER BY rok
        ) AS mzda_predchozi_rok
    FROM mzdy
)
SELECT
    rok,
    odvetvi,
    ROUND(mzda_predchozi_rok::numeric, 2) AS mzda_predchozi_rok,
    ROUND(prumerna_mzda::numeric, 2) AS prumerna_mzda,
    ROUND(
        (prumerna_mzda - mzda_predchozi_rok)::numeric,
        2
    ) AS rozdil_mzdy,
    ROUND(
        (
            (prumerna_mzda / mzda_predchozi_rok - 1) * 100
        )::numeric,
        2
    ) AS mezirocni_zmena_pct
FROM porovnani
WHERE mzda_predchozi_rok IS NOT NULL
  AND prumerna_mzda < mzda_predchozi_rok
ORDER BY
    rok,
    odvetvi;
