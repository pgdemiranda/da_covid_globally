SELECT *
FROM [PortFolio Project]..CovidDeaths
ORDER BY 3, 4

--SELECT *
--FROM [PortFolio Project]..CovidVaccinations
--ORDER BY 3, 4

-- Select Data
SELECT location, date, total_cases, new_cases, total_deaths, population
FROM [PortFolio Project]..CovidDeaths
ORDER BY 1, 2

-- Look Total cases vs Total Deaths
-- Likelihood of dying if you contract covid in Brazil
SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
FROM [PortFolio Project]..CovidDeaths
WHERE location = 'Brazil'
ORDER BY 1, 2

-- Look Total cases vs Population
-- Percentage of population that got covid
SELECT location, date, population, total_cases, (total_cases/population)*100 as PercentagePopulationInfected
FROM [PortFolio Project]..CovidDeaths
WHERE location like '%raz%'
ORDER BY 1, 2

-- Looking at Countries With Highest Infection Rate Compared To Population
SELECT location, population, MAX(total_cases) as HighestInfectionCount, MAX((total_cases/population))*100 as PercentagePopulationInfected
FROM [PortFolio Project]..CovidDeaths
--WHERE location like '%raz%'
GROUP BY location, population
ORDER BY PercentagePopulationInfected DESC

-- Show Countries with Highest Death Count per Population
SELECT location, MAX(cast(total_deaths as int)) as TotalDeathCount
FROM [PortFolio Project]..CovidDeaths
--WHERE location like '%raz%'
WHERE continent is not null
GROUP BY location
ORDER BY TotalDeathCount DESC

-- Break down by continent
-- Continents with the highest death count per population
SELECT continent, MAX(cast(total_deaths as int)) as TotalDeathCount
FROM [PortFolio Project]..CovidDeaths
-- WHERE location like '%raz%'
WHERE continent is not null
GROUP BY continent
ORDER BY TotalDeathCount DESC

-- Global numbers
SELECT SUM(new_cases) as total_cases, SUM(CAST(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/SUM(new_cases)*100 as DeathPercentage
FROM [PortFolio Project]..CovidDeaths
WHERE continent is not null
ORDER BY 1, 2

-- Using CTE to perform Calculation on Partition By in previous query
WITH PopvsVac (continent, location, date, population, new_vaccinations, RollingPeopleVaccinated)
as
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
FROM [PortFolio Project]..CovidDeaths dea
JOIN [PortFolio Project]..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent is not null 
--order by 2,3
)
SELECT *, (RollingPeopleVaccinated/Population)*100
From PopvsVac

-- Temp Table
DROP Table if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)

INSERT into #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
FROM [PortFolio Project]..CovidDeaths dea
JOIN [PortFolio Project]..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
-- WHERE dea.continent is not null 
-- order by 2,3
SELECT *, (RollingPeopleVaccinated/population)*100
FROM #PercentPopulationVaccinated

-- Create View to store data for later visualizations
CREATE VIEW PercentPopulationVaccinated as
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent is not null 

-- Queries from SQL to Excel and then Dashboard on Tableau
-- 1. 
Select SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/SUM(New_Cases)*100 as DeathPercentage
From [PortFolio Project]..CovidDeaths
where continent is not null 
--Group By date
order by 1,2

-- 2. 
Select location, SUM(cast(new_deaths as int)) as TotalDeathCount
From [PortFolio Project]..CovidDeaths
Where continent is null 
and location not in ('World', 'European Union', 'International')
Group by location
order by TotalDeathCount desc

-- 3.
Select Location, Population, MAX(total_cases) as HighestInfectionCount,  Max((total_cases/population))*100 as PercentPopulationInfected
From [PortFolio Project]..CovidDeaths
Group by Location, Population
order by PercentPopulationInfected desc

-- 4.
Select Location, Population,date, MAX(total_cases) as HighestInfectionCount,  Max((total_cases/population))*100 as PercentPopulationInfected
From [PortFolio Project]..CovidDeaths
Group by Location, Population, date
order by PercentPopulationInfected desc