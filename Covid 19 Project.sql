select *
from p1_clean.coviddeaths
where continent <> ''
order by 3, 4;

-- select data  that we are going to be using
select location, date, total_cases, new_cases, total_deaths, population
from p1_clean.coviddeaths p1
where continent <> ''
order by 1, 2;

-- total cases vs total deaths
-- Shows the likelihood of dying if you contract covid in your country 
select location, date, total_cases, total_deaths, 
(total_deaths/total_cases)*100 as MortalityRate
from p1_clean.coviddeaths p1
where location like "%India%" and continent <> ''
order by 1, 2;

-- total cases vs population
-- shows what percentage of population got covid
select location, date, total_cases, population, 
(total_cases/population)*100 as InfectedRate
from p1_clean.coviddeaths p1
where location like "%state%" and continent <> ''
order by 1, 2;

-- countries with highest infection rate compared to population
select location, population, 
max(total_cases) as HighestInfectionCount,
max((total_cases/population))*100 as InfectionRate
from p1_clean.coviddeaths p1
where continent <> ''
group by location, population
order by InfectionRate desc;

-- countries with highest death count per population
select location, MAX(CAST(total_deaths AS SIGNED)) as MaxDeath
from p1_clean.coviddeaths p1
where continent <> ''
group by location
order by MaxDeath desc;

-- The data till now is grouping together continents as countries 
-- we dont want that

-- LETS BREAK THINGS DOWN BY CONTINENT
-- : Showing the continents with the highest death count

select continent, MAX(CAST(total_deaths AS SIGNED)) as MaxDeath
from p1_clean.coviddeaths p1
where continent != ''
group by continent
order by MaxDeath desc;

-- this gave a correct output because of the dataset we have,
-- in that, the location is on the basis of continents as well
-- so if we want to break things down by continent, we have to consider
-- continent as a location where the continent column is null, if its not null then its an empty string 
-- again this is based on the type of dataset i have

-- -------------------------------------------------------------------
-- GLOBAL NUMBERS: 

-- Total cases in the world according to dates
select date, sum(new_cases) as TotalCases, 
sum(cast(new_deaths as signed)) as TotalDeaths, 
sum(new_deaths)/sum(new_cases)*100 as DeathPercentage
from p1_clean.coviddeaths p1
where continent <> ''
group by date
order by DeathPercentage asc;

-- the sum(new_cases) logic is that the sum of new cases will be the total cases 
-- similary, new deaths's sum == total deaths

-- Total death percentage of the world
select sum(new_cases) as TotalCases, 
sum(cast(new_deaths as signed)) as TotalDeaths, 
sum(new_deaths)/sum(new_cases)*100 as DeathPercentage
from p1_clean.coviddeaths p1
where continent <> ''
order by DeathPercentage asc;

-- --------------------------------------------------------------------
-- JOINING THE TWO TABLES ON DATE AND LOCATION
select *
from p1_clean.coviddeaths dea
join p1_clean.covidvaccinations vacc
on dea.location = vacc.location
and dea.date = vacc.date;

-- Total population vs vaccinations

select dea.continent, dea.location, dea.date, dea.population, 
vacc.new_vaccinations,  
sum(vacc.new_vaccinations) over 
(partition by dea.location order by dea.location, dea.date) as CummulativeSumOfPeopleVaccinated
from p1_clean.coviddeaths dea
join p1_clean.covidvaccinations vacc
on dea.location = vacc.location
and dea.date = vacc.date
where dea.continent != ''
order by 2, 3;

-- USING CTE

with PopVSVacc (Continent, Location, Date, Population, NewVaccinations, CummulativeSumOfPeopleVaccinated)
as
(
select dea.continent, dea.location, dea.date, dea.population, 
vacc.new_vaccinations,  
sum(vacc.new_vaccinations) over 
(partition by dea.location order by dea.location, dea.date) as CummulativeSumOfPeopleVaccinated
from p1_clean.coviddeaths dea
join p1_clean.covidvaccinations vacc
on dea.location = vacc.location
and dea.date = vacc.date
where dea.continent != ''
)
select *, (CummulativeSumOfPeopleVaccinated/Population)*100
from PopVSVacc;

-- this shows the data of people vaccinated in each location wrt population of the country
-- First we created a cte which gave us the cummulative sum of people vaccinated as the days went by
-- the tell signs of this being correct is this value should only increase as the days go by since the 
-- population of people vaccinated only increased
-- after getting the number of people getting vaccincated in different locations, we found the percentage of people getting vaccinated
-- this was obtained by dividing the vaccinated people by location and diving the total population at that time

-- TEMP TABLE:
DROP TEMPORARY TABLE IF EXISTS PercentPopulationVaccinated;
CREATE TEMPORARY TABLE PercentPopulationVaccinated (
    Continent VARCHAR(255),
    Location VARCHAR(255),
    Date VARCHAR(10),
    Population NUMERIC,
    New_vaccinations varchar(255) default '',
    CummulativeSumOfPeopleVaccinated NUMERIC
);

INSERT INTO PercentPopulationVaccinated (Continent, Location, Date, Population, New_vaccinations, CummulativeSumOfPeopleVaccinated)
SELECT dea.continent, dea.location, dea.date, dea.population, vacc.new_vaccinations,
    (SELECT SUM(vacc_inner.new_vaccinations) 
     FROM p1_clean.covidvaccinations vacc_inner 
     WHERE vacc_inner.location = dea.location AND vacc_inner.date <= dea.date) 
    AS CummulativeSumOfPeopleVaccinated
FROM p1_clean.coviddeaths dea
JOIN p1_clean.covidvaccinations vacc ON dea.location = vacc.location AND dea.date = vacc.date
WHERE dea.continent != '';

select *, (CummulativeSumOfPeopleVaccinated/Population)*100
from PercentPopulationVaccinated;

-- Creating a VIEW to store data for later visualisation

Create View PercentPopulationVaccinate as 
SELECT dea.continent, dea.location, dea.date, dea.population, vacc.new_vaccinations,
    (SELECT SUM(vacc_inner.new_vaccinations) 
     FROM p1_clean.covidvaccinations vacc_inner 
     WHERE vacc_inner.location = dea.location AND vacc_inner.date <= dea.date) 
    AS CummulativeSumOfPeopleVaccinated
FROM p1_clean.coviddeaths dea
JOIN p1_clean.covidvaccinations vacc ON dea.location = vacc.location AND dea.date = vacc.date
WHERE dea.continent != '';










