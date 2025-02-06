/*
Covid 19 Data Exploration using SQL

Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types
*/

select *
from PortifolioProject..CovidDeaths
order by 3,4;

select *
from PortifolioProject..CovidVaccinations
order by 3,4;

-- Selecting Data columns that we are going to start our Exploration with

select location, date, total_cases, new_cases, total_deaths, population
from PortifolioProject..CovidDeaths
order by 1,2;

-- Total Cases vs Total Deaths
-- Shows likelihood of dying if you contract covid in your country

select location, date, total_cases, total_deaths, 
(total_deaths/total_cases) * 100 as PercentPopulationDied
from PortifolioProject..CovidDeaths
where location like '%indi%'
order by 1,2;


-- Total Cases vs Population
-- Shows what percentage of population infected with Covid in your country

select location, date, population, total_cases,
(total_cases/population) * 100 as PercentPopulationInfected
from PortifolioProject..CovidDeaths
where location like '%indi%'
order by 1,2;

-- --------------------------------------------------------------------------------------------------------------------------------
--Infection Rate Analysis

-- Countries with the highest percentage of their population infected with COVID.
/*
The query finds the highest recorded infection count and the percentage of the population infected for each location, 
then sorts the results in descending order of infection percentage.
*/

select location, population, max(total_cases) as HighestInfectionCount,
max((total_cases/population) * 100) as PercentPopulationInfected
from PortifolioProject..CovidDeaths
--where location like '%indi%'
group by location, population
order by PercentPopulationInfected desc;

-- View -> Infection Rate Analysis

create view InfectionRateView as
select location, population, max(total_cases) as HighestInfectionCount,
max((total_cases/population) * 100) as PercentPopulationInfected
from PortifolioProject..CovidDeaths
group by location, population

-- --------------------------------------------------------------------------------------------------------------------------------
-- Death Count
	
-- Countries with the highest death count per capita.

select location, 
	max(cast(total_deaths as int)) as TotalDeathCount
from PortifolioProject..CovidDeaths
group by location
order by TotalDeathCount desc;


-- BREAKING THINGS DOWN BY CONTINENT

-- Countries with the highest death count per capita.

select continent, 
	max(cast(total_deaths as int)) as TotalDeathCount
from PortifolioProject..CovidDeaths
group by continent
order by TotalDeathCount desc;

-- --------------------------------------------------------------------------------------------------------------------------------
-- Mortality Trends View (Death Rate View)

-- Global Numbers -> Total Cases, Total Deaths, Total Percentage of People Died

select 
--date, 
	sum(new_cases) as total_cases, 
	sum(cast(new_deaths as int)) as total_deaths,  
	sum(cast(new_deaths as int))/nullif(sum(new_cases),0) * 100 as PercentPopulationDied
from PortifolioProject..CovidDeaths
--group by date
order by 1,2;

-- View -> Countries with the highest percentage of their population died due to COVID.

Create view DeathRateView as
select  location,
	sum(new_cases) as total_cases, 
	sum(cast(new_deaths as int)) as total_deaths,  
	sum(cast(new_deaths as int))/nullif(sum(new_cases),0) * 100 as PercentPopulationDied
from PortifolioProject..CovidDeaths
group by location

-- --------------------------------------------------------------------------------------------------------------------------------
--Vaccination Progress View
	
--Vaccination Progress Over Time

select location, date, 
       SUM(new_vaccinations) OVER (PARTITION BY location ORDER BY date) AS CumulativeVaccinations,
       population,
       (SUM(new_vaccinations) OVER (PARTITION BY location ORDER BY date) / population) * 100 AS VaccinationRate
FROM PortifolioProject..CovidVaccinations;

-- Use Subquery(inline subquery)  -> Vaccination Progress Over Time
-- Avoids using SUM() OVER(), which some databases might not support.

select location, 
       date, 
       (select sum(v2.new_vaccinations) 
        from portifolioproject..covidvaccinations v2
        where v2.location = v1.location 
        and v2.date <= v1.date) as cumulative_vaccinations, 
       population,  
       ((select sum(v2.new_vaccinations) 
         from portifolioproject..covidvaccinations v2
         where v2.location = v1.location 
         and v2.date <= v1.date) / population) * 100 as vaccination_rate
from portifolioproject..covidvaccinations v1;

-- Use Subquery -> Vaccination Progress Over Time

select *,  
       (cumulative_vaccinations / population) * 100 as vaccination_rate
from (
    select location, 
           date, 
           sum(new_vaccinations) over (partition by location order by date) as cumulative_vaccinations, 
           population
    from portifolioproject..covidvaccinations
) as vaccination_subquery;

-- Use CTE -> Vaccination Progress Over Time

with vaccination_cte as (
    select location, date, 
           sum(new_vaccinations) over (partition by location order by date) as cumulative_vaccinations, 
           population
    from portifolioproject..covidvaccinations
)
select *,  -- Selects all columns from the CTE
       (cumulative_vaccinations / population) * 100 as vaccination_rate
from vaccination_cte;

-- View -> Vaccination Progress Over Time

create view VaccinationProgressView as
SELECT location, date, 
       SUM(new_vaccinations) OVER (PARTITION BY location ORDER BY date) AS CumulativeVaccinations,
       population,
       (SUM(new_vaccinations) OVER (PARTITION BY location ORDER BY date) / population) * 100 AS VaccinationRate
FROM PortifolioProject..CovidVaccinations;
	
-- --------------------------------------------------------------------------------------------------------------------------------
-- Total Populations vs Vaccinations

select d.continent, d.location, d.date, d.population, v.new_vaccinations
, sum(convert(int, v.new_vaccinations)) over(partition by d.location order by d.location, d.date) as RollingPeopleVaccinated
--, (RollingPeopleVacccinated/poulation) * 100
from PortifolioProject..CovidDeaths d
Join PortifolioProject..CovidVaccinations v
	on d.location = v.location
	and d.date = v.date
order by 2,3;

-- Use CTE -> "percentage of population vaccinated"

with PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
as
(
select d.continent, d.location, d.date, d.population,v.new_vaccinations
, sum(convert(int, v.new_vaccinations)) over(partition by d.location order by
d.location, d.date) as RollingPeopleVaccinated
--, (RollingPeopleVacccinated/poulation) * 100
from PortifolioProject..CovidDeaths d
Join PortifolioProject..CovidVaccinations v
	on d.location = v.location
	and d.date = v.date
--order by 2,3
)
select *, (RollingPeopleVaccinated/Population)*100 as PercentPeopleVaccinated
from PopvsVac;

-- Temporary Table -> "percentage of population vaccinated"

Drop table if exists #PercentPopulationVaccinated
Create table #PercentPopulationVaccinated
(
Continent nvarchar(225),
Location nvarchar(225),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)

insert into #PercentPopulationVaccinated
select d.continent, d.location, d.date, d.population,v.new_vaccinations
, sum(convert(int, v.new_vaccinations)) over(partition by d.location order by
d.location, d.date) as RollingPeopleVaccinated
--, (RollingPeopleVacccinated/poulation) * 100
from PortifolioProject..CovidDeaths d
Join PortifolioProject..CovidVaccinations v
	on d.location = v.location
	and d.date = v.date
--order by 2,3

select *, (RollingPeopleVaccinated/Population)*100 as PercentPeopleVaccinated
from #PercentPopulationVaccinated;


-- Views -> "percentage of population vaccinated"

Create View PercentPopulationVaccinated as
select d.continent, d.location, d.date, d.population,v.new_vaccinations
, sum(convert(int, v.new_vaccinations)) over(partition by d.location order by
d.location, d.date) as RollingPeopleVaccinated
--, (RollingPeopleVacccinated/poulation) * 100
from PortifolioProject..CovidDeaths d
Join PortifolioProject..CovidVaccinations v
	on d.location = v.location
	and d.date = v.date
--order by 2,3

select *, (RollingPeopleVaccinated/Population)*100 as PercentPeopleVaccinated
from PercentPopulationVaccinated;
