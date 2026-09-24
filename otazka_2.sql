-- 2. Kolik je možné si koupit litrů mléka a kilogramů chleba
-- za první a poslední srovnatelné období v dostupných datech cen a mezd?

SELECT
    rok,
    potravina,
    price_unit,
    ROUND(AVG(prumerna_mzda)::numeric, 2) AS prumerna_mzda,
    ROUND(AVG(prumerna_cena)::numeric, 2) AS prumerna_cena,
    ROUND(
        (AVG(prumerna_mzda) / AVG(prumerna_cena))::numeric,
        2
    ) AS mnozstvi_za_mzdu
FROM t_jan_lamka_project_SQL_primary_final
WHERE rok IN (2006, 2018)
  AND (
      LOWER(potravina) LIKE '%mléko%'
      OR LOWER(potravina) LIKE '%chléb%'
  )
GROUP BY
    rok,
    potravina,
    price_unit
ORDER BY
    potravina,
    rok;
