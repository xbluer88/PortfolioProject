-- SELECT entirely from CovidDeaths Table
SELECT TOP 100 *
FROM PortfolioProject..CovidDeaths
ORDER BY 3,4

-- SELECT entirely from CovidVaccinations table
SELECT *
FROM PortfolioProject..CovidVaccinations
ORDER BY 3,4

-- SELECT data that we will be using
SELECT location, date, total_cases, new_cases, total_deaths, population
FROM PortfolioProject..CovidDeaths
ORDER BY 1,2

-- Looking at total cases vs total deaths
-- Shows likelihood of dying if you contract covid in your country
SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE location like 'Indonesia'
ORDER BY 1,2

-- Looking at total cases vs population
SELECT location, date, population, total_cases, (total_cases/population)*100 AS PercentagePopulationGotCovid
FROM PortfolioProject..CovidDeaths
WHERE location like 'Indonesia'
ORDER BY 1,2

-- Looking at countries with the highest infection rate compared to population
SELECT location, population, MAX(total_cases) AS totalCases, MAX((total_cases/population))*100 AS InfectionRate
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY 4 desc

-- Looking at countries with highest death count
SELECT location, MAX(CAST(total_deaths AS INT)) AS total_death
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY 2 desc

-- Looking at data per continent

-- Showing continent with highest death count
SELECT continent, SUM(CAST(new_deaths AS INT)) AS TotalDeath
FROM PortfolioProject..CovidDeaths
-- Filter the location so it's not showing the location which is a continent
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY 2 DESC


-- GLOBAL NUMBERS
SELECT location, SUM(new_cases) AS total_cases, SUM(CAST(new_deaths AS INT)) AS TotalDeath, ((SUM(CAST(new_deaths AS INT)))/(SUM(new_cases)))*100 AS DeathPercentageCase
FROM PortfolioProject..CovidDeaths
WHERE location like 'World'
GROUP BY location

SELECT 'World' AS Loc, SUM(new_cases) AS total_cases, SUM(CAST(new_deaths AS INT)) AS TotalDeath, ((SUM(CAST(new_deaths AS INT)))/(SUM(new_cases)))*100 AS DeathPercentageCase
FROM PortfolioProject..CovidDeaths
-- add international to WHERE because it represent cases which not happen in any major continent
WHERE continent IS NOT NULL OR location like 'International'
order by 2,3


-- looking at total population vs vaccination
SELECT d.continent, d.location, d.date, d.population, v.new_vaccinations
, SUM(CONVERT(int,v.new_vaccinations)) OVER (Partition By d.location Order By d.location, d.date) AS VacCount
FROM PortfolioProject..CovidDeaths d
JOIN PortfolioProject..CovidVaccinations v
ON d.location=v.location 
	AND d.date=v.date
WHERE d.continent IS NOT NULL
ORDER BY 2,3

-- USE CTE
WITH PopVsVac (continent, location, date, population, new_vac, vacCount)
AS
(
SELECT d.continent, d.location, d.date, d.population, v.new_vaccinations
, SUM(CONVERT(int,v.new_vaccinations)) OVER (Partition By d.location Order By d.location, d.date) AS VacCount
FROM PortfolioProject..CovidDeaths d
JOIN PortfolioProject..CovidVaccinations v
ON d.location=v.location 
	AND d.date=v.date
WHERE d.continent IS NOT NULL
)
SELECT *, (vacCount/population)*100 AS VacRate
FROM PopVsVac
ORDER BY 2,3


-- Use Temp Table
DROP TABLE if exists #PopulationVaccinated
CREATE TABLE #PopulationVaccinated
(
	continent nvarchar(255),
	location nvarchar(255),
	date datetime,
	population numeric,
	new_vac numeric,
	vac_count numeric
)

INSERT INTO #PopulationVaccinated
SELECT d.continent, d.location, d.date, d.population, v.new_vaccinations
, SUM(CONVERT(int,v.new_vaccinations)) OVER (Partition By d.location Order By d.location, d.date) AS vac_count
FROM PortfolioProject..CovidDeaths d
JOIN PortfolioProject..CovidVaccinations v
ON d.location=v.location 
	AND d.date=v.date
WHERE d.continent IS NOT NULL

SELECT *, (vac_count/population)*100 AS VacRate
FROM #PopulationVaccinated
ORDER BY 2,3


-- Create View to use later
CREATE VIEW PopulationVaccinated AS
SELECT d.continent, d.location, d.date, d.population, v.new_vaccinations
, SUM(CONVERT(int,v.new_vaccinations)) OVER (Partition By d.location Order By d.location, d.date) AS vac_count
FROM PortfolioProject..CovidDeaths d
JOIN PortfolioProject..CovidVaccinations v
ON d.location=v.location 
	AND d.date=v.date
WHERE d.continent IS NOT NULL