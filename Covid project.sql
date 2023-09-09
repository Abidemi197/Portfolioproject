--select *
--from dbo.CovidVaccinations$
--order by 3, 4

select *
from dbo.CovidDeaths$
where continent is not NULL
order by 3, 4

--select Data that will used

select Location, date, total_cases, new_cases, total_deaths, population
from dbo.CovidDeaths$
where continent is not NULL
order by 1, 2

--looking at total cases vs total deaths 
--shows chances of dying if you contract covid in your country
select Location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as deathPercentage
from dbo.CovidDeaths$
where Location = 'Canada'
order by 1, 2

--looking at the total cases vs population
--This shows what percentage of the population contracted covid 

select Location, date, population, total_cases, total_deaths, (total_cases/population)*100 as CasePercentage
from dbo.CovidDeaths$
where continent is not NULL and Location = 'Canada'
order by 1, 2

--Looking at all countries with their highest infection count compared to populations 

select Location, population, MAX(total_cases) as highestInfectionCount, MAX((total_cases/population))*100 as percentPopulationInfected
from dbo.CovidDeaths$
where continent is not NULL
--where Location = 'Canada'
Group by Location, population
order by percentPopulationInfected desc


--looking at the countries with highest death count compared to population

select Location, population, MAX(total_deaths) as TotalDeathCount
from dbo.CovidDeaths$
where continent is not NULL
--where Location = 'Canada'
Group by Location, population
order by TotalDeathCount desc 

-- breaking it down by continent 

select continent, MAX(total_deaths) as TotalDeathCount
from dbo.CovidDeaths$
where continent is not NULL
--where Location = 'Canada'
Group by continent
order by TotalDeathCount desc  

-- GLobal total case to total death ratio per day

select  date, SUM(new_cases) as totalCases, SUM(new_deaths) as totalDeaths, SUM(New_deaths)/SUM(New_cases)*100 as deathPercentage
from dbo.CovidDeaths$
where continent is not NULL
group by date 
order by 1, 2

-- Global total case to total death ratio
select  SUM(new_cases) as totalCases, SUM(new_deaths) as totalDeaths, SUM(New_deaths)/SUM(New_cases)*100 as deathPercentage
from dbo.CovidDeaths$
where continent is not NULL


--Looking at Total Population vs New Vaccination vs total Vaccination 

Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(vac.new_vaccinations) OVER (partition by dea.location order by dea.location,dea.date) as rollingPeopleVaccinations
--(rollingPeopleVaccinations/population)*100
From CovidDeaths$ dea
join CovidVaccinations$ vac
	ON dea.location = vac.location
	and dea.date =vac.date
where dea.continent is not null
order by 2,3

--USE CTE to find total pervent of population vaccinated 

with PopVsVac (continent, location, date, population, new_vaccination, rollingPeopleVaccinations)
as(
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(vac.new_vaccinations) OVER (partition by dea.location order by dea.location,dea.date) as rollingPeopleVaccinations
--,(rollingPeopleVaccinations/population)*100
From CovidDeaths$ dea
join CovidVaccinations$ vac
	ON dea.location = vac.location
	and dea.date =vac.date
where dea.continent is not null
--order by 2,3
)

Select*, (rollingPeopleVaccinations/population)*100 as percentVaccinated
From PopVsVac
order by 2, 3

--TempTable 

DROP table if exists #percentPopulationVaccinated 
Create Table #percentPopulationVaccinated 
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime, 
Population numeric,
New_vaccinations numeric,
rollingPeopleVaccinations numeric
)


Insert into #percentPopulationVaccinated
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(vac.new_vaccinations) OVER (partition by dea.location order by dea.location,dea.date) as rollingPeopleVaccinations
--(rollingPeopleVaccinations/population)*100
From CovidDeaths$ dea
join CovidVaccinations$ vac
	ON dea.location = vac.location
	and dea.date =vac.date
where dea.continent is not null
order by 2,3

select* , (rollingPeopleVaccinations/Population)*100 as percentVaccinated 
From #percentPopulationVaccinated
order by 2, 3


--creating View to store data for visualization 

Create View PercentPopulationVaccinated as 
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(vac.new_vaccinations) OVER (partition by dea.location order by dea.location,dea.date) as rollingPeopleVaccinations
--(rollingPeopleVaccinations/population)*100
From CovidDeaths$ dea
join CovidVaccinations$ vac
	ON dea.location = vac.location
	and dea.date =vac.date
where dea.continent is not null


select *
From PercentPopulationVaccinated