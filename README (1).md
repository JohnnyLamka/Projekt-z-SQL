# SQL projekt -- Analýza mezd a cen potravin v České republice

## Popis projektu

Cílem projektu je analyzovat vývoj mezd a cen potravin v České
republice, porovnat kupní sílu obyvatel a posoudit souvislost mezi
vývojem HDP, mezd a cen potravin.

Použité tabulky: `czechia_payroll`, `czechia_payroll_industry_branch`,
`czechia_price`, `czechia_price_category`, `economies`.

Pro mzdy: `value_type_code = 5958` (průměrná hrubá mzda na zaměstnance),
`unit_code = 200` (Kč), `calculation_code = 200` (přepočtený). Česká
republika je v `economies` uvedena jako `Czech Republic`.

------------------------------------------------------------------------

## 1. Rostou v průběhu let mzdy ve všech odvětvích, nebo v některých klesají?

### SQL dotaz

``` sql
WITH wages AS (
    SELECT payroll_year, industry_branch_code, AVG(value) AS average_wage
    FROM czechia_payroll
    WHERE value_type_code = 5958
      AND unit_code = 200
      AND calculation_code = 200
      AND industry_branch_code IS NOT NULL
    GROUP BY payroll_year, industry_branch_code
),
wages_with_previous AS (
    SELECT payroll_year, industry_branch_code, average_wage,
           LAG(average_wage) OVER (
               PARTITION BY industry_branch_code ORDER BY payroll_year
           ) AS previous_year_wage
    FROM wages
)
SELECT w.payroll_year, w.industry_branch_code, ib.name AS industry_name,
       ROUND(w.average_wage::numeric, 2) AS average_wage,
       ROUND(w.previous_year_wage::numeric, 2) AS previous_year_wage,
       ROUND(((w.average_wage - w.previous_year_wage)
              / w.previous_year_wage * 100)::numeric, 2) AS wage_change_percent
FROM wages_with_previous w
JOIN czechia_payroll_industry_branch ib
  ON w.industry_branch_code = ib.code
WHERE w.previous_year_wage IS NOT NULL
  AND w.average_wage < w.previous_year_wage
ORDER BY w.industry_branch_code, w.payroll_year;
```

### Slovní odpověď

Mzdy v průběhu sledovaného období nerostly ve všech odvětvích
nepřetržitě. Ve většině případů je patrný dlouhodobý růst mezd, ale v
některých odvětvích a jednotlivých letech došlo k meziročnímu poklesu.
Nelze tedy říci, že by mzdy každý rok rostly ve všech odvětvích.

------------------------------------------------------------------------

## 2. Kolik je možné si koupit litrů mléka a kilogramů chleba za první a poslední srovnatelné období?

Společným srovnatelným obdobím cen a mezd jsou roky 2006--2018.
Kategorie `111301` je Chléb konzumní kmínový a `114201` Mléko polotučné
pasterované.

### SQL dotaz

``` sql
WITH wages AS (
    SELECT payroll_year AS year, AVG(value) AS average_wage
    FROM czechia_payroll
    WHERE value_type_code = 5958
      AND unit_code = 200
      AND calculation_code = 200
    GROUP BY payroll_year
),
prices AS (
    SELECT EXTRACT(YEAR FROM cp.date_from)::int AS year,
           cp.category_code, cpc.name, AVG(cp.value) AS average_price
    FROM czechia_price cp
    JOIN czechia_price_category cpc ON cp.category_code = cpc.code
    WHERE cp.category_code IN (111301, 114201)
    GROUP BY EXTRACT(YEAR FROM cp.date_from), cp.category_code, cpc.name
)
SELECT w.year, p.name AS food,
       ROUND(w.average_wage::numeric, 2) AS average_wage,
       ROUND(p.average_price::numeric, 2) AS average_price,
       ROUND((w.average_wage / p.average_price)::numeric, 2) AS purchasable_amount
FROM wages w
JOIN prices p ON w.year = p.year
WHERE w.year IN (2006, 2018)
ORDER BY w.year, p.category_code;
```

### Výsledky

  -------------------------------------------------------------------------
  Rok         Potravina       Průměrná mzda            Cena        Množství
  ----------- ------------- --------------- --------------- ---------------
  2006        Chléb            21 083,73 Kč        16,12 Kč     1 307,63 kg
              konzumní                                      
              kmínový                                       

  2006        Mléko            21 083,73 Kč        14,44 Kč      1 460,31 l
              polotučné                                     
              pasterované                                   

  2018        Chléb            33 039,03 Kč        24,24 Kč     1 363,08 kg
              konzumní                                      
              kmínový                                       

  2018        Mléko            33 039,03 Kč        19,82 Kč      1 667,16 l
              polotučné                                     
              pasterované                                   
  -------------------------------------------------------------------------

### Slovní odpověď

V roce 2006 bylo možné za průměrnou mzdu koupit přibližně **1 307,63 kg
chleba** nebo **1 460,31 litru mléka**. V roce 2018 přibližně **1 363,08
kg chleba** nebo **1 667,16 litru mléka**. Kupní síla průměrné mzdy tedy
vůči oběma sledovaným potravinám vzrostla, výrazněji u mléka.

------------------------------------------------------------------------

## 3. Která kategorie potravin zdražuje nejpomaleji?

### SQL dotaz

``` sql
WITH yearly_prices AS (
    SELECT EXTRACT(YEAR FROM cp.date_from)::int AS year,
           cp.category_code, cpc.name, AVG(cp.value) AS average_price
    FROM czechia_price cp
    JOIN czechia_price_category cpc ON cp.category_code = cpc.code
    GROUP BY EXTRACT(YEAR FROM cp.date_from), cp.category_code, cpc.name
),
prices_with_previous AS (
    SELECT year, category_code, name, average_price,
           LAG(average_price) OVER (
               PARTITION BY category_code ORDER BY year
           ) AS previous_year_price
    FROM yearly_prices
),
price_changes AS (
    SELECT year, category_code, name,
           ((average_price - previous_year_price) / previous_year_price) * 100
               AS price_change_percent
    FROM prices_with_previous
    WHERE previous_year_price IS NOT NULL
)
SELECT name,
       ROUND(AVG(price_change_percent)::numeric, 2) AS average_yearly_growth_percent
FROM price_changes
GROUP BY category_code, name
ORDER BY average_yearly_growth_percent ASC;
```

### Slovní odpověď

Nejnižší průměrnou meziroční změnu ceny vykazoval **cukr krystalový**,
přibližně **−1,92 %**. Jeho cena tedy ve sledovaném období v průměru
meziročně spíše klesala než rostla. Druhou nejnižší hodnotu měla rajská
jablka červená kulatá s přibližně **−0,74 %**.

------------------------------------------------------------------------

## 4. Existuje rok, kdy byl meziroční nárůst cen potravin výrazně vyšší než růst mezd (větší než 10 %)?

U cen se nejprve počítá průměrná cena každé kategorie za rok, poté
meziroční změna každé kategorie a nakonec průměr těchto změn za daný
rok.

### SQL dotaz

``` sql
WITH yearly_wages AS (
    SELECT payroll_year AS year, AVG(value) AS average_wage
    FROM czechia_payroll
    WHERE value_type_code = 5958
      AND unit_code = 200
      AND calculation_code = 200
    GROUP BY payroll_year
),
wage_changes AS (
    SELECT year,
           ((average_wage - LAG(average_wage) OVER (ORDER BY year))
            / LAG(average_wage) OVER (ORDER BY year)) * 100 AS wage_growth_percent
    FROM yearly_wages
),
category_yearly_prices AS (
    SELECT EXTRACT(YEAR FROM date_from)::int AS year,
           category_code, AVG(value) AS average_price
    FROM czechia_price
    GROUP BY EXTRACT(YEAR FROM date_from), category_code
),
category_price_changes AS (
    SELECT year, category_code,
           ((average_price - LAG(average_price) OVER (
               PARTITION BY category_code ORDER BY year))
            / LAG(average_price) OVER (
               PARTITION BY category_code ORDER BY year)) * 100 AS price_growth_percent
    FROM category_yearly_prices
),
yearly_price_growth AS (
    SELECT year, AVG(price_growth_percent) AS price_growth_percent
    FROM category_price_changes
    WHERE price_growth_percent IS NOT NULL
    GROUP BY year
)
SELECT w.year,
       ROUND(w.wage_growth_percent::numeric, 2) AS wage_growth_percent,
       ROUND(p.price_growth_percent::numeric, 2) AS price_growth_percent,
       ROUND((p.price_growth_percent - w.wage_growth_percent)::numeric, 2) AS difference
FROM wage_changes w
JOIN yearly_price_growth p ON w.year = p.year
WHERE w.year BETWEEN 2007 AND 2018
ORDER BY w.year;
```

### Slovní odpověď

Ve sledovaném období **2007--2018 nebyl nalezen rok**, kdy by průměrný
meziroční růst cen potravin převýšil růst mezd o více než **10
procentních bodů**. Největší rozdíl nastal v roce **2013**, kdy mzdy
poklesly o **1,49 %**, zatímco ceny potravin vzrostly v průměru o **6,01
%**. Rozdíl činil **7,50 procentního bodu**.

Formulace „větší než 10 %" je zde interpretována jako rozdíl větší než
10 procentních bodů mezi meziroční procentní změnou cen a mezd.

------------------------------------------------------------------------

## 5. Má výška HDP vliv na změny ve mzdách a cenách potravin?

Otázka porovnává růst HDP s růstem mezd a cen potravin ve stejném i
následujícím roce.

### SQL dotaz

``` sql
WITH yearly_wages AS (
    SELECT payroll_year AS year, AVG(value) AS average_wage
    FROM czechia_payroll
    WHERE value_type_code = 5958
      AND unit_code = 200
      AND calculation_code = 200
    GROUP BY payroll_year
),
wage_growth AS (
    SELECT year,
           ((average_wage - LAG(average_wage) OVER (ORDER BY year))
            / LAG(average_wage) OVER (ORDER BY year)) * 100 AS wage_growth_percent
    FROM yearly_wages
),
category_yearly_prices AS (
    SELECT EXTRACT(YEAR FROM date_from)::int AS year,
           category_code, AVG(value) AS average_price
    FROM czechia_price
    GROUP BY EXTRACT(YEAR FROM date_from), category_code
),
category_price_growth AS (
    SELECT year, category_code,
           ((average_price - LAG(average_price) OVER (
               PARTITION BY category_code ORDER BY year))
            / LAG(average_price) OVER (
               PARTITION BY category_code ORDER BY year)) * 100 AS price_growth_percent
    FROM category_yearly_prices
),
yearly_price_growth AS (
    SELECT year, AVG(price_growth_percent) AS price_growth_percent
    FROM category_price_growth
    WHERE price_growth_percent IS NOT NULL
    GROUP BY year
),
gdp_growth AS (
    SELECT year,
           ((gdp - LAG(gdp) OVER (ORDER BY year))
            / LAG(gdp) OVER (ORDER BY year)) * 100 AS gdp_growth_percent
    FROM economies
    WHERE country = 'Czech Republic'
),
combined AS (
    SELECT g.year, g.gdp_growth_percent,
           w.wage_growth_percent, p.price_growth_percent
    FROM gdp_growth g
    JOIN wage_growth w ON g.year = w.year
    JOIN yearly_price_growth p ON g.year = p.year
)
SELECT year,
       ROUND(gdp_growth_percent::numeric, 2) AS gdp_growth_percent,
       ROUND(wage_growth_percent::numeric, 2) AS wage_growth_same_year,
       ROUND(price_growth_percent::numeric, 2) AS price_growth_same_year,
       ROUND(LEAD(wage_growth_percent) OVER (ORDER BY year)::numeric, 2)
           AS wage_growth_next_year,
       ROUND(LEAD(price_growth_percent) OVER (ORDER BY year)::numeric, 2)
           AS price_growth_next_year
FROM combined
WHERE year BETWEEN 2007 AND 2018
ORDER BY year;
```

### Slovní odpověď

Z výsledků nelze potvrdit jednoznačnou přímou závislost mezi růstem HDP
a růstem mezd či cen potravin. V některých letech je možné určitou
souvislost pozorovat. Například v roce **2017** vzrostlo HDP o **5,17
%**, mzdy o **6,19 %** a ceny potravin o **7,06 %**. Tento vztah však
není pravidelný.

Například v roce **2015** vzrostlo HDP o **5,39 %**, zatímco mzdy pouze
o **2,62 %** a ceny potravin klesly o **0,69 %**. V následujícím roce
vzrostly mzdy o **3,68 %**, ale ceny potravin opět klesly o **1,41 %**.

Data tedy nenaznačují, že by výraznější růst HDP pravidelně vedl k
výraznějšímu růstu mezd nebo cen potravin ve stejném či následujícím
roce. Výsledky ukazují souvislosti v jednotlivých obdobích, nikoliv
důkaz příčinného vztahu.

------------------------------------------------------------------------

## Závěr

Analýza ukázala, že mzdy v České republice v dlouhodobém horizontu
převážně rostly, avšak v některých odvětvích a jednotlivých letech také
klesaly.

Mezi lety 2006 a 2018 se zvýšila kupní síla průměrné mzdy ve vztahu k
chlebu i mléku. Jednotlivé kategorie potravin se cenově vyvíjely
rozdílně a nejnižší průměrnou meziroční změnu vykázal cukr krystalový.
Ve sledovaném období nebyl nalezen rok, kdy by průměrný růst cen
potravin převýšil růst mezd o více než 10 procentních bodů.

Při porovnání HDP, mezd a cen potravin nebyla nalezena jednoznačná
pravidelná závislost. Vyšší růst HDP byl v některých letech doprovázen
vyšším růstem mezd nebo cen, tento vztah však nebyl konzistentní v celém
sledovaném období.
