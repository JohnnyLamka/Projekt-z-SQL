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



## 3. Která kategorie potravin zdražuje nejpomaleji?

Pro každou kategorii potravin byla nejprve vypočtena průměrná cena v jednotlivých letech. 
Pomocí funkce LAG() byla následně získána cena stejné potraviny v předchozím roce 
a vypočtena procentuální meziroční změna ceny. Nakonec byl pro každou kategorii 
vypočten průměr těchto meziročních změn.

Nejnižší průměrnou meziroční změnu ceny měl cukr krystalový, a to přibližně -1,92 %. 
Záporná hodnota znamená, že cena cukru krystalového v období 2006–2018 v průměru meziročně mírně klesala. Druhou nejnižší hodnotu měla rajská jablka červená kulatá s přibližně −0,74 %.




## 4. Existuje rok, ve kterém byl meziroční nárůst cen potravin výrazně vyšší než růst mezd (větší než 10 %)?

Pro jednotlivé roky jsem vypočítal meziroční procentuální růst průměrných mezd a cen potravin a následně jejich rozdíl v procentních bodech.

Největší rozdíl mezi růstem cen potravin a růstem mezd nastal v roce **2013**. Průměrné mzdy meziročně klesly o **1,56 %**, zatímco ceny potravin vzrostly v průměru o **6,01 %**. Rozdíl tedy činil **7,57 procentního bodu**.

### Odpověď

**Ne, v dostupných datech neexistuje rok, ve kterém by meziroční růst cen potravin převýšil meziroční růst mezd o více než 10 procentních bodů.**

Největší rozdíl byl zaznamenán v roce **2013**, kdy činil **7,57 procentního bodu**.



## 5. Má výška HDP vliv na změny ve mzdách a cenách potravin?

Pro posouzení vztahu mezi HDP, mzdami a cenami potravin jsem porovnal meziroční procentuální změny HDP České republiky s meziročními změnami průměrných mezd a cen potravin. Zároveň jsem sledoval změny mezd a cen potravin v následujícím roce.

### Odpověď

Z dostupných dat **není patrný jednoznačný pravidelný vztah**, podle kterého by výraznější růst HDP automaticky vedl k výraznějšímu růstu mezd nebo cen potravin ve stejném či následujícím roce.

Například v roce **2015** vzrostlo HDP o **5,39 %**, zatímco mzdy vzrostly pouze o **2,60 %** a ceny potravin klesly o **0,69 %**. Ani v následujícím roce nedošlo k výraznému růstu cen potravin – mzdy vzrostly o **3,64 %** a ceny potravin klesly o **1,40 %**.

Naopak v roce **2017** vzrostlo HDP o **5,17 %**, mzdy o **6,17 %** a ceny potravin o **7,06 %**. V tomto roce tedy vyšší růst HDP doprovázel také výraznější růst mezd a cen.

Výsledky proto naznačují, že mezi vývojem HDP, mezd a cen potravin může v některých letech existovat souvislost, ale **v analyzovaném období se neprojevuje pravidelně ani jednoznačně**. Samotné porovnání meziročních změn zároveň neprokazuje příčinný vztah.

---


## Závěr

Analýza dat o mzdách, cenách potravin a HDP České republiky ukázala, že ve sledovaném období 2006–2018 docházelo k dlouhodobému růstu mezd, tento růst však nebyl ve všech odvětvích a letech nepřetržitý. V některých případech došlo také k meziročnímu poklesu průměrné mzdy.

Porovnání kupní síly ukázalo, že za průměrnou mzdu bylo v roce 2018 možné koupit větší množství chleba i mléka než v roce 2006.

Z analyzovaných kategorií potravin měl nejnižší průměrný meziroční růst ceny **cukr krystalový**, jehož průměrná meziroční změna činila **−1,92 %**.

Při porovnání růstu cen potravin a mezd nebyl nalezen rok, ve kterém by meziroční růst cen potravin převýšil růst mezd o více než 10 procentních bodů. Největší rozdíl nastal v roce **2013** a činil **7,57 procentního bodu**.

Porovnání vývoje HDP, mezd a cen potravin neprokázalo jednoznačný pravidelný vztah, podle kterého by výraznější růst HDP automaticky vedl k výraznějšímu růstu mezd nebo cen potravin ve stejném či následujícím roce. Výsledky ukazují, že se jejich vývoj v některých letech může pohybovat podobným směrem, v jiných letech se však výrazně liší.

Celkově tedy data ukazují dlouhodobý růst mezd a kupní síly u sledovaných základních potravin, zároveň však potvrzují, že vývoj mezd, cen potravin a HDP není v jednotlivých letech rovnoměrný.
