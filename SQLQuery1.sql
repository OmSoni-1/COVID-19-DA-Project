-- EXPLORATORY DATA ANALYSIS COVID-19


use covid_project;

-- Exploration:
------------------------------------------------------------------------------------------------
--First look at the data

Select *
From Deaths
order by 3,4;

---------------------------------------------------------------------------------------------------

-- Selecting the starting point

Select Location, date, total_cases, new_cases, total_deaths, population
From Deaths
Where continent is not null 
order by 1,2;

---------------------------------------------------------------------------------------------------------------------

-- Total Cases vs Total Deaths
-- Death percetage at a given day in a particular location

Select Location, date, total_cases,total_deaths, 
round((cast(total_deaths as float)/cast(total_cases as float)*100), 2) as DeathPercentage
From Deaths
--Where location like '%India%'
where continent is not null 
order by 1,2

----------------------------------------------------------------------------------------------------------------------

-- Total Cases vs Population
-- Shows what percentage of population infected with Covid

Select Location, date, Population, total_cases,  
round((cast(total_cases as float)/population)*100.0,3) as percent_population_infected
From Deaths
--Where location like '%india%'
order by 1,2

----------------------------------------------------------------------------------------------------------------------

-- Location wise Infection count and percentage

Select Location, Population, MAX(total_cases) as Highest_Infection_Count,  
Round(Max((cast(total_cases as float)/population))*100, 2) as percent_population_infected
From Deaths
-- Where location like '%world%'
Group by Location, Population
order by percent_population_infected desc

----------------------------------------------------------------------------------------------------------------------

-- Location wise Death count and percentage

Select Location, population, MAX(total_deaths) as Total_Death_Count,
Round((MAX(cast(total_deaths as float)) / MAX(cast(total_cases as float))) * 100, 2) as Death_Percentage
From Deaths
--Where location like '%states%'
Where continent is not null 
Group by Location, population
order by Total_Death_Count desc

----------------------------------------------------------------------------------------------------------------------

-- Continent Wise Analysis

-- Continent wise Death count and percentage

Select location, Population, MAX(total_cases) as TotalCaseCount, MAX(Total_deaths) as TotalDeathCount,
Round((MAX(cast(total_deaths as float)) / MAX(cast(total_cases as float))) * 100, 2) as Death_Percentage
From Deaths
--Where location like '%states%'
Where continent is null 
Group by location, population
order by TotalDeathCount desc

----------------------------------------------------------------------------------------------------------------------

-- World Statistis

Select total_population, total_cases, total_deaths,
	(ROUND((Total_Cases / Total_Population) * 100, 2)) as InfectionRate,
	(ROUND((Total_Deaths / Total_Cases) * 100,3)) as MortalityRate
	from Totals

----------------------------------------------------------------------------------------------------------------------

-- Population vs Vaccinations

-- Shows Percentage of Population that has recieved at least one Covid Vaccine

Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(cast(vac.new_vaccinations as bigint))
OVER (Partition by dea.Location Order by dea.location, dea.Date) as Total_Vaccinated
--, (Total_Vaccinated/population)*100
From Deaths dea
Join Vaccinations vac
On dea.location = vac.location and 
dea.date = vac.date
where dea.continent is not null 
order by 2,3

-----------------------------------------------------------------------------------------------------------------------------

-- Using CTE to perform Calculations

-- On Partition By in previous query

With PopvsVac as
(
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CONVERT(bigint,vac.new_vaccinations))
OVER (Partition by dea.Location Order by dea.location, dea.Date) as Total_Vaccinated
--, (Total_Vaccinated/population)*100
From Deaths dea
Join Vaccinations vac
On dea.location = vac.location and
dea.date = vac.date
where dea.continent is not null 
--order by 6
)
Select *, Round((Total_Vaccinated/cast(Population as float)*100), 3) as PercentPopulationVaccinated
From PopvsVac

------------------------------------------------------------------------------------------------------------------------------

-- Using Temporary Table to perform Calculation on Partition By in previous query

DROP Table if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
Total_Vaccinated numeric
)

Insert into #PercentPopulationVaccinated
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(cast(vac.new_vaccinations as float)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as Total_Vaccinated
--, (RollingPeopleVaccinated/population)*100
From Deaths dea
Join Vaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
--order by 2,3

Select *, Round((Total_Vaccinated/cast(Population as bigint))*100, 3) as Percent_Vaccinated
From #PercentPopulationVaccinated;

-------------------------------------------------------------------------------------------------------------------------------

-- Making Views for Visualizations

-- For vaccination percentage

Drop view if exists PercentPopulationVaccinated

Go

Create View PercentPopulationVaccinated as(

Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(bigint,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as TotalVaccinated
--, (RollingPeopleVaccinated/population)*100
From Deaths dea
Join Vaccinations vac
On dea.location = vac.location
and dea.date = vac.date
where dea.continent is not null
)
Go
Select * from PercentPopulationVaccinated;

-----------------------------------------------------------------------------------------------------------------------------------------------

-- For death percentage (World Stats)

Drop view if exists MortalityRate;

Go

Create View MortalityRate as
	Select total_population, total_cases, total_deaths,
	(ROUND((Total_Cases / Total_Population) * 100, 2)) as InfectionRate,
	(ROUND((Total_Deaths / Total_Cases) * 100,3)) as MortalityRate
	from Totals

Go

------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------


drop view if exists CountryData

Go

Create view CountryData as
	with World_count as(
		Select location, population,
		MAX(total_cases) as Cases,
		MAX(total_deaths) as Deaths
		from deaths
		group by location, population
		) Select *, Round((cast(Cases as float) / cast(population as bigint)) * 100, 2) as infection_rate,
		Round((cast(deaths as float) / cast(Cases as bigint)) * 100, 2) as death_rate
		from World_count
Go

------------------------------------------------------------------------------------------------------------------------------
-- View for actual locations

drop view if exists true_location;

Go

Create view true_location as
Select distinct location from deaths
where continent is not null;

Go

Select * from true_location

---------------------------------------------------------------------------------------------------------------------------

-- View for Vaccinations vs Deaths

drop view if exists VacVSDeath;

Go

Create view VacVSDeath as
	with VaccJoiner as (
		Select v.location, d.date, v.new_vaccinations, 
		SUM(CAST(new_vaccinations as float)) over (partition by v.location order by v.location, d.date) as total_vaccinations,
		d.new_deaths, d.total_deaths
		from vaccinations v
		left join deaths d
		on v.location = d.location and v.date = d.date
	)Select * from VaccJoiner 

Go

Select * from VacVSDeath order by location, date;