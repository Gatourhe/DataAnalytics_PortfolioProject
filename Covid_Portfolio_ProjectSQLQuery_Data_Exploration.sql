SELECT 
	*
FROM PortfolioProject..CovidDeaths
ORDER BY 3,4

--SELECT 
--	*
--FROM PortfolioProject..CovidVaccination
--ORDER BY 3,4


--Getting the usable data for a new table
SELECT
	location,
	date,
	new_cases,
	total_cases,
	new_cases,
	total_deaths,
	population
FROM 
	PortfolioProject..CovidDeaths
ORDER BY 1,2


-- Total Cases vs Total Deaths
--Determine death likehoodness by country
SELECT
	location,
	date,
	total_cases,
	total_deaths,
	(total_deaths/total_cases)* 100 AS deathPercent
FROM 
	PortfolioProject..CovidDeaths
WHERE location LIKE '%Ghana%'
ORDER BY 1,2


-- Total Cases vs Population
-- Show what percentage of population got Covid
SELECT 
	location,
	date,
	total_cases,
	population,
	(total_cases/population * 100) AS PercentPopulationInfected
FROM 
	PortfolioProject..CovidDeaths
WHERE location LIKE '%Ghana%'
ORDER BY 1,2


-- Countries with Highest Infection Rate Compared to Population
SELECT 
	location,
	population,
	MAX(total_cases) AS highestInfectionCount,
	MAX(total_cases/population * 100) AS PercentPopulationInfected 
FROM 
	PortfolioProject..CovidDeaths
GROUP BY location, population
ORDER BY PercentPopulationInfected DESC


--Countries with Highest Death Count per Population
SELECT 
	location,
	population,
	MAX(CAST (total_deaths AS int)) AS highestDeathCount,
	MAX(total_deaths/population * 100) AS PercentHighestDeathCount
FROM 
	PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY highestDeathCount DESC

--- Anotherway
SELECT 
	location,
	MAX(CAST (total_deaths AS int)) AS TotalDeathCount
FROM 
	PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY TotalDeathCount DESC

--SELECT 
--	continent
--FROM PortfolioProject..CovidDeaths
--WHERE continent IS NULL

-- Get Total Death Cases by Continent
SELECT 
	continent,
	MAX(CAST (total_deaths AS int)) AS TotalDeathCount
FROM 
	PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY TotalDeathCount DESC


--GLobal Numbers

SELECT
	date,
	SUM(new_cases) AS totalCases,
	SUM(CAST(new_deaths AS int)) AS totalDeaths,
	(SUM(CAST(new_deaths AS int))/ (SUM(new_cases)))* 100 AS deathPercentage
FROM 
	PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY 1,2


SELECT
	--date,
	SUM(new_cases) AS totalCases,
	SUM(CAST(new_deaths AS int)) AS totalDeaths,
	--Used the Case Statement to take caree of the issue of divisible by 0 
	CASE
		WHEN SUM(new_cases) = 0 THEN NULL
		ELSE (SUM(CAST(new_deaths AS int))/ (SUM(new_cases)))* 100
	 END AS deathPercentage
FROM 
	PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
--GROUP BY date
ORDER BY 1,2



----------------------------------------------------------------------------------------
---------------------- Work on the Covid Vaccination -----------------------------------
SELECT
	*
FROM
	PortfolioProject..CovidVaccination

-- Join the CovidDeaths and the CovidVaccination tables
SELECT
	*
FROM PortfolioProject..CovidDeaths deaths
JOIN PortfolioProject..CovidVaccination vacc
	ON deaths.location = vacc.location
	AND deaths.date = vacc.date


-- Total Population vs Vaccination
SELECT
	deaths.continent,
	deaths.location,
	deaths.population,
	vacc.new_vaccinations
FROM PortfolioProject..CovidDeaths deaths
JOIN PortfolioProject..CovidVaccination vacc
	ON deaths.location = vacc.location
	AND deaths.date = vacc.date
WHERE deaths.continent IS NOT NULL
ORDER BY 2,3


-- Understanding Total number of New Vaccinations Partitioned over by location and date
SELECT
	deaths.continent,
	deaths.location,
	deaths.date,
	deaths.population,
	CONVERT(INT, vacc.new_vaccinations) AS new_vaccination,
	SUM(CONVERT(FLOAT, vacc.new_vaccinations)) OVER (PARTITION BY deaths.location ORDER BY deaths.location, deaths.date) AS rollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths deaths
JOIN PortfolioProject..CovidVaccination vacc
	ON deaths.location = vacc.location
	AND deaths.date = vacc.date
WHERE deaths.continent IS NOT NULL --AND deaths.location = 'Ghana'
ORDER BY 2,3

--USE CTE to find the percentage of people vaccinated compared to Population
--

WITH popVsVac(Continent, Location, Date, Population, New_Vaccination, rollingPeopleVaccinated)
AS(
	SELECT
		deaths.continent,
		deaths.location,
		deaths.date,
		deaths.population,
		CONVERT(INT, vacc.new_vaccinations) AS new_vaccination,
		SUM(CONVERT(FLOAT, vacc.new_vaccinations)) OVER (PARTITION BY deaths.location ORDER BY deaths.location, deaths.date) AS rollingPeopleVaccinated
	FROM PortfolioProject..CovidDeaths deaths
	JOIN PortfolioProject..CovidVaccination vacc
		ON deaths.location = vacc.location
		AND deaths.date = vacc.date
	WHERE deaths.continent IS NOT NULL --AND deaths.location = 'Ghana'
	--ORDER BY 2,3
	)
SELECT
	*,
	(rollingPeopleVaccinated/Population)* 100 AS Vaccinated_Percent
FROM
	popVsVac


---- ALternatively Use TEMP Tables for the above
DROP TABLE IF EXISTS #percentPopulationVaccinated
CREATE TABLE #percentPopulationVaccinated(
	Continent nvarchar(255),
	Location nvarchar(255),
	Date datetime,
	Population numeric,
	New_Vaccinations numeric,
	RollingPeopleVaccinated numeric
)

INSERT INTO #percentPopulationVaccinated
SELECT
		deaths.continent,
		deaths.location,
		deaths.date,
		deaths.population,
		CONVERT(INT, vacc.new_vaccinations) AS new_vaccination,
		SUM(CONVERT(FLOAT, vacc.new_vaccinations)) OVER (PARTITION BY deaths.location ORDER BY deaths.location, deaths.date) AS rollingPeopleVaccinated
	FROM PortfolioProject..CovidDeaths deaths
	JOIN PortfolioProject..CovidVaccination vacc
		ON deaths.location = vacc.location
		AND deaths.date = vacc.date
	WHERE deaths.continent IS NOT NULL --AND deaths.location = 'Ghana'
	--ORDER BY 2,3

SELECT
	*,
	(rollingPeopleVaccinated/Population)* 100 AS Vaccinated_Percent
FROM
	#percentPopulationVaccinated



-- Creating View to Store data for Onward Visualization --- 
DROP VIEW IF EXISTS percentPopulationVaccinated
CREATE VIEW PercentPopulationVaccinated AS
SELECT
	deaths.continent,
	deaths.location,
	deaths.date,
	deaths.population,
	CONVERT(INT, vacc.new_vaccinations) AS new_vaccination,
	SUM(CONVERT(FLOAT, vacc.new_vaccinations)) OVER (PARTITION BY deaths.location ORDER BY deaths.location, deaths.date) AS rollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths deaths
JOIN PortfolioProject..CovidVaccination vacc
	ON deaths.location = vacc.location
	AND deaths.date = vacc.date
WHERE deaths.continent IS NOT NULL 

SELECT * FROM PercentPopulationVaccinated