# Projekt z SQL – analýza mezd, cen potravin a HDP

## Úvod

Cílem projektu je analyzovat vývoj mezd a cen vybraných základních potravin v České republice a posoudit jejich vzájemný vztah v průběhu času.

Součástí projektu je také porovnání vývoje mezd a cen potravin s vývojem HDP a vytvoření dodatečného datového podkladu obsahujícího ekonomické údaje evropských států.

Pro analýzu byly vytvořeny dvě finální tabulky:

- `t_jan_lamka_project_SQL_primary_final` – obsahuje data o mzdách a cenách potravin v České republice za srovnatelné období.
- `t_jan_lamka_project_SQL_secondary_final` – obsahuje údaje o HDP, populaci a GINI koeficientu evropských států v období 2006–2018.

Následující část projektu odpovídá na jednotlivé výzkumné otázky pomocí SQL dotazů nad vytvořenými finálními tabulkami.

----------------------------------------------------------------------------------------------------------------------------------------------------------------------

## 1. Rostou v průběhu let mzdy ve všech odvětvích, nebo v některých klesají?

Pro porovnání vývoje mezd v jednotlivých odvětvích jsem použil funkci `LAG()`, pomocí které jsem ke každému roku přiřadil průměrnou mzdu z předchozího roku ve stejném odvětví. Následně jsem vypočítal absolutní a procentuální meziroční změnu mzdy.

```sql
WITH porovnani AS (
    SELECT
        rok,
        industry_branch_code,
        odvetvi,
        prumerna_mzda,
        LAG(prumerna_mzda) OVER (
            PARTITION BY industry_branch_code
            ORDER BY rok
        ) AS mzda_predchozi_rok
    FROM (
        SELECT DISTINCT
            rok,
            industry_branch_code,
            odvetvi,
            prumerna_mzda
        FROM t_jan_lamka_project_SQL_primary_final
    ) mzdy
)
SELECT
    rok,
    odvetvi,
    prumerna_mzda,
    mzda_predchozi_rok,
    ROUND(
        (prumerna_mzda - mzda_predchozi_rok)::numeric,
        2
    ) AS rozdil_mzdy,
    ROUND(
        ((prumerna_mzda / mzda_predchozi_rok) - 1) * 100,
        2
    ) AS mezirocni_zmena_pct
FROM porovnani
WHERE mzda_predchozi_rok IS NOT NULL
ORDER BY odvetvi, rok;
```
----------------------------------------------------------
```sql
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
    COUNT(*) AS pocet_poklesu_mezd
FROM porovnani
WHERE mzda_predchozi_rok IS NOT NULL
  AND prumerna_mzda < mzda_predchozi_rok;
```
Kontrolní dotaz ukázal celkem **25 případů meziročního poklesu průměrné mzdy** v jednotlivých odvětvích během sledovaného období.
  
### Odpověď

Mzdy v průběhu sledovaného období **nerostly ve všech odvětvích nepřetržitě**.

Analýza meziročních změn ukázala, že se v datech nachází **25 případů meziročního poklesu průměrné mzdy** v konkrétním odvětví.

Poklesy se vyskytovaly v různých letech a odvětvích. Například v roce 2013 klesla průměrná mzda v odvětví **Peněžnictví a pojišťovnictví přibližně o 8,83 %**, v odvětví **Těžba a dobývání přibližně o 3,24 %** a v odvětví **Profesní, vědecké a technické činnosti přibližně o 3,02 %**.

Z výsledků tedy vyplývá, že ačkoliv mzdy v dlouhodobém horizontu převážně rostou, v některých odvětvích a letech docházelo také k meziročnímu poklesu mezd.
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------



## 2. Kolik je možné si koupit litrů mléka a kilogramů chleba za první a poslední srovnatelné období?

Pro porovnání jsem použil první a poslední společný rok dostupných dat cen a mezd, tedy roky **2006 a 2018**.

V roce **2006** byla průměrná mzda **21 165,18 Kč**. Průměrná cena chleba byla **16,12 Kč/kg** a cena mléka **14,44 Kč/l**. Za průměrnou mzdu tedy bylo možné koupit přibližně **1 312,98 kg chleba** nebo **1 465,73 litrů mléka**.

V roce **2018** byla průměrná mzda **33 091,45 Kč**. Průměrná cena chleba byla **24,24 Kč/kg** a cena mléka **19,82 Kč/l**. Za průměrnou mzdu tedy bylo možné koupit přibližně **1 365,16 kg chleba** nebo **1 669,60 litrů mléka**.

Z výsledků vyplývá, že se kupní síla průměrné mzdy mezi lety 2006 a 2018 u obou sledovaných potravin zvýšila. Nárůst byl výraznější u mléka než u chleba.

```sql
WITH mzdy AS (
    SELECT
        payroll_year AS rok,
        AVG(prumernyplat) AS prumerna_mzda
    FROM t_jan_lamka_project_SQL_primary_final
    WHERE prumernyplat IS NOT NULL
    GROUP BY payroll_year
),
ceny AS (
    SELECT
        EXTRACT(YEAR FROM date_from)::int AS rok,
        category_code,
        AVG(value) AS prumerna_cena
    FROM czechia_price
    WHERE category_code IN (111301, 114201)
    GROUP BY
        EXTRACT(YEAR FROM date_from),
        category_code
)
SELECT
    m.rok,
    ROUND(m.prumerna_mzda::numeric, 2) AS prumerna_mzda,
    CASE
        WHEN c.category_code = 111301 THEN 'Chléb'
        WHEN c.category_code = 114201 THEN 'Mléko'
    END AS potravina,
    ROUND(c.prumerna_cena::numeric, 2) AS prumerna_cena,
    ROUND(
        (m.prumerna_mzda / c.prumerna_cena)::numeric,
        2
    ) AS koupitelne_mnozstvi
FROM mzdy m
JOIN ceny c
    ON m.rok = c.rok
WHERE m.rok IN (2006, 2018)
ORDER BY m.rok, c.category_code;
```

## 3. Která kategorie potravin zdražuje nejpomaleji?

Pro každou kategorii potravin byla nejprve vypočtena průměrná cena v jednotlivých letech. 
Pomocí funkce LAG() byla následně získána cena stejné potraviny v předchozím roce 
a vypočtena procentuální meziroční změna ceny. Nakonec byl pro každou kategorii 
vypočten průměr těchto meziročních změn.

Nejnižší průměrnou meziroční změnu ceny měl cukr krystalový, a to přibližně -1,92 %. 
Jeho cena tedy v období 2006–2018 v průměru meziročně neklesala pouze tempem růstu,
ale skutečně vykazovala mírný pokles. Druhou nejnižší hodnotu měla rajská jablka 
červená kulatá s přibližně -0,74 %.

### SQL dotaz

```sql
WITH rocni_ceny AS (
    SELECT
        EXTRACT(YEAR FROM cp.date_from)::int AS rok,
        cp.category_code,
        cpc.name AS potravina,
        AVG(cp.value) AS prumerna_cena
    FROM czechia_price cp
    JOIN czechia_price_category cpc
        ON cp.category_code = cpc.code
    WHERE EXTRACT(YEAR FROM cp.date_from) BETWEEN 2006 AND 2018
    GROUP BY
        EXTRACT(YEAR FROM cp.date_from),
        cp.category_code,
        cpc.name
),
ceny_s_predchozim_rokem AS (
    SELECT
        rok,
        category_code,
        potravina,
        prumerna_cena,
        LAG(prumerna_cena) OVER (
            PARTITION BY category_code
            ORDER BY rok
        ) AS cena_predchozi_rok
    FROM rocni_ceny
),
mezirocni_zmeny AS (
    SELECT
        rok,
        category_code,
        potravina,
        ((prumerna_cena / cena_predchozi_rok) - 1) * 100
            AS mezirocni_zmena_pct
    FROM ceny_s_predchozim_rokem
    WHERE cena_predchozi_rok IS NOT NULL
)
SELECT
    potravina,
    ROUND(AVG(mezirocni_zmena_pct)::numeric, 2)
        AS prumerny_mezirocni_rust_pct
FROM mezirocni_zmeny
GROUP BY
    category_code,
    potravina
ORDER BY
    prumerny_mezirocni_rust_pct ASC;

## 4. Existuje rok, ve kterém byl meziroční nárůst cen potravin výrazně vyšší než růst mezd?

*Bude doplněno.*

---

## 5. Má výška HDP vliv na změny ve mzdách a cenách potravin?

*Bude doplněno.*

---

## Závěr

*Bude doplněno po vyhodnocení všech výzkumných otázek.*
