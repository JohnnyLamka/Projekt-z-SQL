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

Pro porovnání vývoje mezd byla u každého odvětví vypočítána meziroční změna průměrné mzdy. Pomocí funkce `LAG()` byla hodnota mzdy v daném roce porovnána s předchozím rokem.

### SQL dotaz


```sql
WITH mezirocni_mzdy AS (
    SELECT
        odvetvi,
        payroll_year,
        prumernyplat,
        LAG(prumernyplat) OVER (
            PARTITION BY odvetvi
            ORDER BY payroll_year
        ) AS plat_predchozi_rok
    FROM t_jan_lamka_project_SQL_primary_final
    WHERE prumernyplat IS NOT NULL
)
SELECT
    odvetvi,
    payroll_year,
    plat_predchozi_rok,
    prumernyplat,
    ROUND(
        ((prumernyplat / plat_predchozi_rok) - 1) * 100,
        2
    ) AS mezirocni_zmena_pct
FROM mezirocni_mzdy
WHERE prumernyplat < plat_predchozi_rok
ORDER BY payroll_year, odvetvi;
```

### Výsledek

Mzdy ve sledovaném období nerostly ve všech odvětvích nepřetržitě. V některých odvětvích došlo v jednotlivých letech k meziročnímu poklesu.

SQL dotaz nalezl celkem **26 případů**, kdy byla průměrná mzda v daném odvětví nižší než v předchozím roce.

Poklesy se objevovaly například v odvětvích těžby a dobývání, ubytování, stravování a pohostinství nebo administrativních a podpůrných činností. Více případů poklesu je patrných také v roce 2013.

### Odpověď na výzkumnou otázku

Mzdy tedy **nerostly každý rok ve všech odvětvích**. Přestože je v delším období patrný růst mezd, v jednotlivých letech a odvětvích docházelo také k meziročním poklesům.

-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

## 2. Kolik je možné si koupit litrů mléka a kilogramů chleba za první a poslední srovnatelné období?

Pro porovnání jsem použil první a poslední společný rok dostupných dat, tedy roky 2006 a 2018.

V roce 2006 byla průměrná mzda 21 083,73 Kč. Za tuto mzdu bylo možné koupit přibližně 1 307,63 kg chleba nebo 1 460,31 litrů mléka.

V roce 2018 byla průměrná mzda 33 039,03 Kč. Za tuto mzdu bylo možné koupit přibližně 1 363,08 kg chleba nebo 1 667,16 litrů mléka.

Z výsledků vyplývá, že kupní síla průměrné mzdy se u obou sledovaných potravin mezi lety 2006 a 2018 zvýšila.

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
