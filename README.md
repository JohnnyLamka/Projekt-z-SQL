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

*Bude doplněno.*

---

## 3. Která kategorie potravin zdražuje nejpomaleji?

*Bude doplněno.*

---

## 4. Existuje rok, ve kterém byl meziroční nárůst cen potravin výrazně vyšší než růst mezd?

*Bude doplněno.*

---

## 5. Má výška HDP vliv na změny ve mzdách a cenách potravin?

*Bude doplněno.*

---

## Závěr

*Bude doplněno po vyhodnocení všech výzkumných otázek.*
