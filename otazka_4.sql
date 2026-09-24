-- 4. Existuje rok, ve kterém byl meziroční nárůst cen potravin
-- výrazně vyšší než růst mezd (větší než 10 %)?

WITH mzdy AS (
    SELECT
        rok,
        AVG(prumerna_mzda) AS prumerna_mzda
    FROM (
        SELECT DISTINCT
            rok,
            industry_branch_code,
            prumerna_mzda
        FROM t_jan_lamka_project_SQL_primary_final
    ) m
    GROUP BY rok
),
rust_mezd AS (
    SELECT
        rok,
        prumerna_mzda,
        LAG(prumerna_mzda) OVER (ORDER BY rok) AS mzda_predchozi_rok
    FROM mzdy
),
ceny_kategorie AS (
    SELECT
        rok,
        category_code,
        AVG(prumerna_cena) AS prumerna_cena
    FROM (
        SELECT DISTINCT
            rok,
            category_code,
            prumerna_cena
        FROM t_jan_lamka_project_SQL_primary_final
    ) c
    GROUP BY
        rok,
        category_code
),
rust_cen_kategorie AS (
    SELECT
        rok,
        category_code,
        prumerna_cena,
        LAG(prumerna_cena) OVER (
            PARTITION BY category_code
            ORDER BY rok
        ) AS cena_predchozi_rok
    FROM ceny_kategorie
),
rust_cen AS (
    SELECT
        rok,
        AVG(
            (prumerna_cena / cena_predchozi_rok - 1) * 100
        ) AS rust_cen_pct
    FROM rust_cen_kategorie
    WHERE cena_predchozi_rok IS NOT NULL
    GROUP BY rok
)
SELECT
    m.rok,
    ROUND(
        ((m.prumerna_mzda / m.mzda_predchozi_rok - 1) * 100)::numeric,
        2
    ) AS rust_mezd_pct,
    ROUND(c.rust_cen_pct::numeric, 2) AS rust_cen_pct,
    ROUND(
        (
            c.rust_cen_pct -
            ((m.prumerna_mzda / m.mzda_predchozi_rok - 1) * 100)
        )::numeric,
        2
    ) AS rozdil_procentnich_bodu
FROM rust_mezd m
JOIN rust_cen c
    ON m.rok = c.rok
WHERE m.mzda_predchozi_rok IS NOT NULL
ORDER BY rozdil_procentnich_bodu DESC;
