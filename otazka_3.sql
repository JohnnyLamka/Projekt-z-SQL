-- 3. Která kategorie potravin zdražuje nejpomaleji
-- (je u ní nejnižší percentuální meziroční nárůst)?

WITH ceny AS (
    SELECT DISTINCT
        rok,
        category_code,
        potravina,
        prumerna_cena
    FROM t_jan_lamka_project_SQL_primary_final
),
mezirocni_zmeny AS (
    SELECT
        rok,
        category_code,
        potravina,
        prumerna_cena,
        LAG(prumerna_cena) OVER (
            PARTITION BY category_code
            ORDER BY rok
        ) AS cena_predchozi_rok
    FROM ceny
)
SELECT
    potravina,
    ROUND(
        AVG(
            (prumerna_cena / cena_predchozi_rok - 1) * 100
        )::numeric,
        2
    ) AS prumerny_mezirocni_rust_pct
FROM mezirocni_zmeny
WHERE cena_predchozi_rok IS NOT NULL
GROUP BY
    category_code,
    potravina
ORDER BY
    prumerny_mezirocni_rust_pct ASC;
