SELECT *
FROM CovidDeaths
ORDER BY 3, 4

SELECT *
FROM CovidVaccinations
ORDER BY 3,4

-- Select Data that we are going to be using

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM CovidDeaths
ORDER BY 1,2


-- Total Cases vs Total Deaths
-- Shows likelihood of dying if you contract COVID-19 in your country

SELECT location, date, population, total_cases, total_deaths, (total_deaths/total_cases)*100
FROM CovidDeaths
ORDER BY 1,2

-- Here, we encounter an error with the datatype for total_deaths and total_cases
-- We will now change the datatype of these 2 columns

ALTER TABLE CovidDeaths
ALTER COLUMN total_cases FLOAT

ALTER TABLE CovidDeaths
ALTER COLUMN total_deaths FLOAT

-- Now that the correct data types have been assigned, we can perform accurate calculations

SELECT location, date, population,  total_cases, total_deaths, (total_deaths/total_cases)*100 AS death_percentage
FROM CovidDeaths
ORDER BY 1,2

-- Calculating COVID-19 death percentage for the United States using wildcard matching

SELECT location, date, population, total_cases, total_deaths, (total_deaths/total_cases)*100 AS death_percentage
FROM CovidDeaths
WHERE location LIKE '%States%'
ORDER BY 1,2


-- Total Cases vs Population
-- Shows what percentage of population infected with COVID-19

SELECT location, date, population, total_cases, (total_cases/population)*100 AS PercentagePopulationInfected
FROM CovidDeaths
ORDER BY 1,2


-- Countries with Highest Infection Rate compared to Population

SELECT location, population, MAX(total_cases) AS HighestInfectionCount, MAX((total_cases)/population)*100 AS PercentPopulationInfected
FROM CovidDeaths
GROUP BY location, population
ORDER BY PercentPopulationInfected DESC


-- Countries with Highest Death Count per Population

SELECT location, MAX(total_deaths) AS TotalDeathCount
FROM CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY TotalDeathCount DESC


-- BREAKING THINGS DOWN BY CONTINENT

-- Showing continents with Highest Death Count per Population

SELECT continent, MAX(total_deaths) AS TotalDeathCount
FROM CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY TotalDeathCount DESC


-- GLOBAL NUMBERS

SELECT  SUM(new_cases) AS total_cases, SUM(new_deaths) AS total_deaths, SUM(new_deaths)/SUM(new_cases)*100 AS death_percentage
FROM CovidDeaths
WHERE continent IS NOT NULL


-- Total Population vs Vaccinations
-- Shows Percentage of Population that has received at least one Covid Vaccine

SELECT T1.continent, T1.location, T1.date, T1.population, T2.new_vaccinations,
SUM(CONVERT(BIGINT,T2.new_vaccinations)) OVER(PARTITION BY T1.location ORDER BY T1.location, T1.date) AS RollingPeopleVaccinated
FROM CovidDeaths T1
JOIN CovidVaccinations T2
ON T1.location = T2.location
AND T1.date = T2.date
WHERE T1.continent IS NOT NULL
ORDER BY 2, 3


-- Using CTE to perform calculation on Partition By in previous query

WITH PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
AS
(
SELECT T1.continent, T1.location, T1.date, T1.population, T2.new_vaccinations,
SUM(CONVERT(BIGINT,T2.new_vaccinations)) OVER(PARTITION BY T1.location ORDER BY T1.location, T1.date) AS RollingPeopleVaccinated
FROM CovidDeaths T1
JOIN CovidVaccinations T2
ON T1.location = T2.location
AND T1.date = T2.date
WHERE T1.continent IS NOT NULL
--ORDER BY 2, 3
)
SELECT *, (RollingPeopleVaccinated/Population)*100
FROM PopvsVac
ORDER BY 2,3


-- Using Temp Table to perform calculation on PARTITON BY in previous query

DROP TABLE IF EXISTS #PercentPeopleVaccinated
CREATE TABLE #PercentPeopleVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_Vaccinations numeric,
RollingPeopleVaccinated numeric
)

INSERT INTO #PercentPeopleVaccinated
SELECT T1.continent, T1.location, T1.date, T1.population, T2.new_vaccinations,
SUM(CONVERT(BIGINT,T2.new_vaccinations)) OVER(PARTITION BY T1.location ORDER BY T1.location, T1.date) AS RollingPeopleVaccinated
FROM CovidDeaths T1
JOIN CovidVaccinations T2
ON T1.location = T2.location
AND T1.date = T2.date
WHERE T1.continent IS NOT NULL


SELECT *, (RollingPeopleVaccinated/Population)*100
FROM #PercentPeopleVaccinated
ORDER BY 2,3


-- Creating View to store data for later visualizations

CREATE VIEW PercentPopulationVaccinated AS
SELECT T1.continent, T1.location, T1.date, T1.population, T2.new_vaccinations,
SUM(CONVERT(BIGINT,T2.new_vaccinations)) OVER(PARTITION BY T1.location ORDER BY T1.location, T1.date) AS RollingPeopleVaccinated
FROM CovidDeaths T1
JOIN CovidVaccinations T2
ON T1.location = T2.location
AND T1.date = T2.date
WHERE T1.continent IS NOT NULL


SELECT *
FROM PercentPopulationVaccinated