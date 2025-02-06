select *
from PortifolioProject..CovidDeaths
order by 3,4;

select *
from PortifolioProject..CovidVaccinations
order by 3,4;

-- View data 

select location, date, total_cases, new_cases, total_deaths, population
from PortifolioProject..CovidDeaths
order by 1,2;

-- total cases vs total deaths

select location, date, total_cases, total_deaths, 
(total_deaths/total_cases) * 100 as PercentPopulationDied
from PortifolioProject..CovidDeaths
where location like '%indi%'
order by 1,2;


-- Total cases vs population(% of the population affected with covid)

select location, date, population, total_cases,
(total_cases/population) * 100 as PercentPopulationInfected
from PortifolioProject..CovidDeaths
where location like '%indi%'
order by 1,2;

-- Countries with Highest infection rate compared to population

select location, population, max(total_cases) as HighestInfectionCount,
max((total_cases/population) * 100) as PercentPopulationInfected
from PortifolioProject..CovidDeaths
--where location like '%indi%'
group by location, population
order by PercentPopulationInfected desc;

-- Countries with Highest Death Count 

select location, max(cast(total_deaths as int)) as TotalDeathCount
from PortifolioProject..CovidDeaths
group by location
order by TotalDeathCount desc;

-- Continent with Highest Death Count

select continent, max(cast(total_deaths as int)) as TotalDeathCount
from PortifolioProject..CovidDeaths
group by continent
order by TotalDeathCount desc;

-- Global Numbers

select 
--date, 
sum(new_cases) as total_cases, sum(cast(new_deaths as int)) as total_deaths,  
sum(cast(new_deaths as int))/nullif(sum(new_cases),0) * 100 as PercentPopulationDied
from PortifolioProject..CovidDeaths
--group by date
order by 1,2;

-- Total Populations vs Vaccinations

select d.continent, d.location, d.date, d.population,v.new_vaccinations
, sum(convert(int, v.new_vaccinations)) over(partition by d.location order by
d.location, d.date) as RollingPeopleVaccinated
--, (RollingPeopleVacccinated/poulation) * 100
from PortifolioProject..CovidDeaths d
Join PortifolioProject..CovidVaccinations v
	on d.location = v.location
	and d.date = v.date
order by 2,3;

-- Use CTE

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

-- Temporary Table

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


-- Views

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

select *
from PercentPopulationVaccinated;