-- 5. Má výška HDP vliv na změny ve mzdách a cenách potravin?
-- Pokud HDP vzroste výrazněji v jednom roce, projeví se to na cenách
-- potravin či mzdách ve stejném nebo následujícím roce výraznějším růstem?

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
        (prumerna_mzda /
         LAG(prumerna_mzda) OVER (ORDER BY rok) - 1) * 100
            AS rust_mezd_pct
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
        (prumerna_cena /
         LAG(prumerna_cena) OVER (
             PARTITION BY category_code
             ORDER BY rok
         ) - 1) * 100 AS rust_ceny_pct
    FROM ceny_kategorie
),
rust_cen AS (
    SELECT
        rok,
        AVG(rust_ceny_pct) AS rust_cen_pct
    FROM rust_cen_kategorie
    WHERE rust_ceny_pct IS NOT NULL
    GROUP BY rok
),
hdp AS (
    SELECT
        year AS rok,
        gdp,
        (gdp / LAG(gdp) OVER (ORDER BY year) - 1) * 100
            AS rust_hdp_pct
    FROM t_jan_lamka_project_SQL_secondary_final
    WHERE country = 'Czech Republic'
),
spojena_data AS (
    SELECT
        h.rok,
        h.rust_hdp_pct,
        m.rust_mezd_pct,
        c.rust_cen_pct
    FROM hdp h
    JOIN rust_mezd m
        ON h.rok = m.rok
    JOIN rust_cen c
        ON h.rok = c.rok
)
SELECT
    rok,
    ROUND(rust_hdp_pct::numeric, 2) AS rust_hdp_pct,
    ROUND(rust_mezd_pct::numeric, 2) AS rust_mezd_pct,
    ROUND(rust_cen_pct::numeric, 2) AS rust_cen_pct,
    ROUND(
        LEAD(rust_mezd_pct) OVER (ORDER BY rok)::numeric,
        2
    ) AS rust_mezd_nasledujici_rok_pct,
    ROUND(
        LEAD(rust_cen_pct) OVER (ORDER BY rok)::numeric,
        2
    ) AS rust_cen_nasledujici_rok_pct
FROM spojena_data
WHERE rust_hdp_pct IS NOT NULL
ORDER BY rok;
