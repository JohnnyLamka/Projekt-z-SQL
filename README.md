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

**Z výsledků tedy vyplývá, že ačkoli mzdy v dlouhodobém horizontu převážně rostou, v některých odvětvích a letech docházelo také k meziročnímu poklesu mezd.**




## 2. Kolik je možné si koupit litrů mléka a kilogramů chleba za první a poslední srovnatelné období?

Pro porovnání jsem použil první a poslední společný rok dostupných dat cen a mezd, tedy roky **2006 a 2018**.

V roce **2006** byla průměrná mzda **21 165,18 Kč**. Průměrná cena chleba byla **16,12 Kč/kg** a cena mléka **14,44 Kč/l**. Za průměrnou mzdu tedy bylo možné koupit přibližně **1 312,98 kg chleba** nebo **1 465,73 litrů mléka**.

V roce **2018** byla průměrná mzda **33 091,45 Kč**. Průměrná cena chleba byla **24,24 Kč/kg** a cena mléka **19,82 Kč/l**. Za průměrnou mzdu tedy bylo možné koupit přibližně **1 365,16 kg chleba** nebo **1 669,60 litrů mléka**.

Z výsledků vyplývá, že se kupní síla průměrné mzdy mezi lety 2006 a 2018 u obou sledovaných potravin zvýšila. Nárůst byl výraznější u mléka než u chleba.

```sql
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
```

## 3. Která kategorie potravin zdražuje nejpomaleji?

Pro každou kategorii potravin byla nejprve vypočtena průměrná cena v jednotlivých letech. 
Pomocí funkce LAG() byla následně získána cena stejné potraviny v předchozím roce 
a vypočtena procentuální meziroční změna ceny. Nakonec byl pro každou kategorii 
vypočten průměr těchto meziročních změn.

Nejnižší průměrnou meziroční změnu ceny měl cukr krystalový, a to přibližně -1,92 %. 
Jeho cena tedy v období 2006–2018 v průměru meziročně neklesala pouze tempem růstu, ale skutečně vykazovala mírný pokles. Druhou nejnižší hodnotu měla rajská jablka 
červená kulatá s přibližně -0,74 %.

### SQL dotaz

```sql
WITH ceny AS (
    SELECT DISTINCT
        rok,
        category_code,
        potravina,
        prumerna_cena
    FROM t_jan_lamka_project_SQL_primary_final
),
porovnani AS (
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
),
mezirocni_zmeny AS (
    SELECT
        rok,
        category_code,
        potravina,
        prumerna_cena,
        cena_predchozi_rok,
        ((prumerna_cena / cena_predchozi_rok) - 1) * 100
            AS mezirocni_zmena_pct
    FROM porovnani
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
```

## 4. Existuje rok, ve kterém byl meziroční nárůst cen potravin výrazně vyšší než růst mezd (větší než 10 %)?

Pro jednotlivé roky jsem vypočítal meziroční procentuální růst průměrných mezd a cen potravin a následně jejich rozdíl v procentních bodech.

Největší rozdíl mezi růstem cen potravin a růstem mezd nastal v roce **2013**. Průměrné mzdy meziročně klesly o **1,56 %**, zatímco ceny potravin vzrostly v průměru o **6,01 %**. Rozdíl tedy činil **7,57 procentního bodu**.

### Odpověď

**Ne, v dostupných datech neexistuje rok, ve kterém by meziroční růst cen potravin převýšil meziroční růst mezd o více než 10 procentních bodů.**

Největší rozdíl byl zaznamenán v roce **2013**, kdy činil **7,57 procentního bodu**.

```sql
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
```
---

## 5. Má výška HDP vliv na změny ve mzdách a cenách potravin?

Pro posouzení vztahu mezi HDP, mzdami a cenami potravin jsem porovnal meziroční procentuální změny HDP České republiky s meziročními změnami průměrných mezd a cen potravin. Zároveň jsem sledoval změny mezd a cen potravin v následujícím roce.

### Odpověď

Z dostupných dat **není patrný jednoznačný pravidelný vztah**, podle kterého by výraznější růst HDP automaticky vedl k výraznějšímu růstu mezd nebo cen potravin ve stejném či následujícím roce.

Například v roce **2015** vzrostlo HDP o **5,39 %**, zatímco mzdy vzrostly pouze o **2,60 %** a ceny potravin klesly o **0,69 %**. Ani v následujícím roce nedošlo k výraznému růstu cen potravin – mzdy vzrostly o **3,64 %** a ceny potravin klesly o **1,40 %**.

Naopak v roce **2017** vzrostlo HDP o **5,17 %**, mzdy o **6,17 %** a ceny potravin o **7,06 %**. V tomto roce tedy vyšší růst HDP doprovázel také výraznější růst mezd a cen.

Výsledky proto naznačují, že mezi vývojem HDP, mezd a cen potravin může v některých letech existovat souvislost, ale **v analyzovaném období se neprojevuje pravidelně ani jednoznačně**. Samotné porovnání meziročních změn zároveň neprokazuje příčinný vztah.

---
```sql
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
        ((prumerna_mzda / LAG(prumerna_mzda) OVER (ORDER BY rok)) - 1) * 100
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
    GROUP BY rok, category_code
),
rust_cen_kategorie AS (
    SELECT
        rok,
        category_code,
        ((prumerna_cena / LAG(prumerna_cena) OVER (
            PARTITION BY category_code
            ORDER BY rok
        )) - 1) * 100 AS rust_ceny_pct
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
        ((gdp / LAG(gdp) OVER (ORDER BY year)) - 1) * 100 AS rust_hdp_pct
    FROM t_jan_lamka_project_SQL_secondary_final
    WHERE country = 'Czech Republic'
),
porovnani AS (
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
FROM porovnani
WHERE rust_hdp_pct IS NOT NULL
ORDER BY rok;
```

## Závěr

Analýza dat o mzdách, cenách potravin a HDP České republiky ukázala, že ve sledovaném období 2006–2018 docházelo k dlouhodobému růstu mezd, tento růst však nebyl ve všech odvětvích a letech nepřetržitý. V některých případech došlo také k meziročnímu poklesu průměrné mzdy.

Porovnání kupní síly ukázalo, že za průměrnou mzdu bylo v roce 2018 možné koupit větší množství chleba i mléka než v roce 2006.

Z analyzovaných kategorií potravin měl nejnižší průměrný meziroční růst ceny **cukr krystalový**, jehož průměrná meziroční změna činila **−1,92 %**.

Při porovnání růstu cen potravin a mezd nebyl nalezen rok, ve kterém by meziroční růst cen potravin převýšil růst mezd o více než 10 procentních bodů. Největší rozdíl nastal v roce **2013** a činil **7,57 procentního bodu**.

Porovnání vývoje HDP, mezd a cen potravin neprokázalo jednoznačný pravidelný vztah, podle kterého by výraznější růst HDP automaticky vedl k výraznějšímu růstu mezd nebo cen potravin ve stejném či následujícím roce. Výsledky ukazují, že se jejich vývoj v některých letech může pohybovat podobným směrem, v jiných letech se však výrazně liší.

Celkově tedy data ukazují dlouhodobý růst mezd a kupní síly u sledovaných základních potravin, zároveň však potvrzují, že vývoj mezd, cen potravin a HDP není v jednotlivých letech rovnoměrný.
