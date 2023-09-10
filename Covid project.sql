--Retrieve all records with non-null continents, ordered by columns 3 and 4
--this is done because sone conntinents are also listed as locations and their continent is NULL.
SELECT *
FROM dbo.CovidDeaths$
WHERE continent IS NOT NULL
ORDER BY 3, 4;

--Retrieve specific columns for analysis, filtering out records with null continents and ordering them by location and date
SELECT Location, date, total_cases, new_cases, total_deaths, population
FROM dbo.CovidDeaths$
WHERE continent IS NOT NULL
ORDER BY 1, 2;

--Calculate the death percentage in Canada, showing the chances of dying if one contracts COVID-19 in Canada
SELECT 
    Location, 
    date, 
    total_cases, 
    total_deaths, 
    (total_deaths / NULLIF(total_cases, 0)) * 100 AS deathPercentage
FROM dbo.CovidDeaths$
WHERE Location = 'Canada'
ORDER BY 1, 2;

--Calculate the case percentage in Canada, indicating the percentage of the population that contracted COVID-19
SELECT 
    Location, 
    date, 
    population, 
    total_cases, 
    total_deaths, 
    (total_cases / NULLIF(population, 0)) * 100 AS CasePercentage
FROM dbo.CovidDeaths$
WHERE Location = 'Canada'
ORDER BY 1, 2;

--Find the highest infection count and the percentage of the population infected for each location
SELECT 
    Location, 
    population, 
    MAX(total_cases) AS highestInfectionCount, 
    MAX((total_cases / NULLIF(population, 0))) * 100 AS percentPopulationInfected
FROM dbo.CovidDeaths$
WHERE continent IS NOT NULL
GROUP BY Location, population
ORDER BY percentPopulationInfected DESC;

--Find the highest death count for each location
SELECT 
    Location, 
    population, 
    MAX(total_deaths) AS TotalDeathCount
FROM dbo.CovidDeaths$
WHERE continent IS NOT NULL
GROUP BY Location, population
ORDER BY TotalDeathCount DESC;

--Find the highest death count for each continent
SELECT 
    Location, 
    MAX(total_deaths) AS TotalDeathCount
FROM dbo.CovidDeaths$
WHERE continent IS NULL
  AND Location IN ('Europe', 'North America', 'South America', 'Asia', 'Africa', 'Oceania')
GROUP BY Location
ORDER BY TotalDeathCount DESC;

--Calculate the global death percentage per day
SELECT  
    date, 
    SUM(new_cases) AS totalCases, 
    SUM(new_deaths) AS totalDeaths, 
    (SUM(New_deaths) / NULLIF(SUM(New_cases), 0)) * 100 AS deathPercentage
FROM dbo.CovidDeaths$
WHERE continent IS NOT NULL
GROUP BY date 
ORDER BY 1, 2;

--Calculate the global total death percentage
SELECT  
    SUM(new_cases) AS totalCases, 
    SUM(new_deaths) AS totalDeaths, 
    (SUM(New_deaths) / NULLIF(SUM(New_cases), 0)) * 100 AS deathPercentage
FROM dbo.CovidDeaths$
WHERE continent IS NOT NULL;

--Analyze vaccination data to calculate the rolling sum of people vaccinated and the percentage of the population vaccinated
WITH PopVsVac AS (
    SELECT 
        dea.continent, 
        dea.location, 
        dea.date, 
        dea.population, 
        vac.new_vaccinations, 
        SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS rollingPeopleVaccinations
    FROM dbo.CovidDeaths$ dea
    JOIN dbo.CovidVaccinations$ vac
        ON dea.location = vac.location
        AND dea.date = vac.date
    WHERE dea.continent IS NOT NULL
)
SELECT *, 
    (rollingPeopleVaccinations / NULLIF(population, 0)) * 100 AS percentVaccinated
FROM PopVsVac
ORDER BY 2, 3;

--Create a temporary table to store vaccination data and calculate the percentage of the population vaccinated
DROP TABLE IF EXISTS #percentPopulationVaccinated;

CREATE TABLE #percentPopulationVaccinated (
    Continent NVARCHAR(255),
    Location NVARCHAR(255),
    Date DATETIME, 
    Population NUMERIC,
    New_vaccinations NUMERIC,
    rollingPeopleVaccinations NUMERIC
);

INSERT INTO #percentPopulationVaccinated
SELECT 
    dea.continent, 
    dea.location, 
    dea.date, 
    dea.population, 
    vac.new_vaccinations, 
    SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS rollingPeopleVaccinations
FROM dbo.CovidDeaths$ dea
JOIN dbo.CovidVaccinations$ vac
    ON dea.location = vac.location
    AND dea.date = vac.date
WHERE dea.continent IS NOT NULL;

SELECT 
    *, 
    (rollingPeopleVaccinations / NULLIF(Population, 0)) * 100 AS percentVaccinated 
FROM #percentPopulationVaccinated
ORDER BY 2, 3;

--Create a view to store data for visualization and retrieve all records from the view
CREATE VIEW PercentPopulationVaccinated AS 
SELECT 
    dea.continent, 
    dea.location, 
    dea.date, 
    dea.population, 
    vac.new_vaccinations, 
    SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS rollingPeopleVaccinations
FROM dbo.CovidDeaths$ dea
JOIN dbo.CovidVaccinations$ vac
    ON dea.location = vac.location
    AND dea.date = vac.date
WHERE dea.continent IS NOT NULL;

SELECT *
FROM PercentPopulationVaccinated;

--Analyze the relationship between the percentage of the population that is fully vaccinated and the number of new COVID-19 cases
SELECT 
    vac.date, 
    vac.location, 
    vac.people_fully_vaccinated_per_hundred * 10000 AS people_fully_vaccinated_per_million, 
    dbo.CovidDeaths$.new_cases_per_million
FROM dbo.CovidVaccinations$ vac
JOIN dbo.CovidDeaths$ ON vac.iso_code = dbo.CovidDeaths$.iso_code AND vac.date = dbo.CovidDeaths$.date
WHERE vac.people_fully_vaccinated_per_hundred IS NOT NULL AND dbo.CovidDeaths$.new_cases_per_million IS NOT NULL AND vac.continent is not null
ORDER BY vac.location, vac.date;


--Retrieve the total percentage of the country infected, population density, and death rate per country 
SELECT 
    location, MAX(population) AS population, MAX(total_cases) as cases, MAX(total_deaths) as deaths,
    MAX(population_density) AS population_density, 
    (MAX(total_cases) / MAX(population)) * 100 AS percent_infected,
    (MAX(total_deaths) / MAX(total_cases)) * 100 AS death_rate
FROM dbo.CovidDeaths$
WHERE 
    population_density IS NOT NULL 
    AND total_cases IS NOT NULL 
    AND total_deaths IS NOT NULL 
    AND population IS NOT NULL
GROUP BY location
ORDER BY death_rate DESC;


--This query will help analyze the impact of COVID-19 on different age groups, using the median age and the percentage of the population above 65 and 70 years.
SELECT 
    location, 
    max(median_age) as median_age, 
   max(aged_65_older) as age_65_older, 
   max(aged_70_older) as age_70_older, 
    (max(total_deaths)/max(total_cases))*100 as percent_death_rate
FROM dbo.CovidDeaths$
WHERE 
   median_age IS NOT NULL 
   AND aged_65_older IS NOT NULL 
   AND aged_70_older IS NOT NULL
    AND total_deaths IS NOT NULL 
   AND total_cases IS NOT NULL
group by location
order by percent_death_rate desc 
