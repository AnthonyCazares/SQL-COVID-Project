/* 
Preparacion de datos en Dataset de COVID-19

Skills utilizadas: Joins, CTE, Tablas temporales, Funciones de ventana, Funciones de agregacion, Creacion de vistas, Conversión de tipos de datos

*/



-- Seleccionando datos con los que empezaremos 

Select Location, date, total_cases, new_cases, total_deaths, population
From SQLProyect..MuertesCovid
Where continent is not null 
order by 1,2

 
-- Casos totales vs muertes totales
-- Probabilidad de morir si se contrae covid

Select Location, date, total_cases,total_deaths, (total_deaths/total_cases)*100 as PorcentajeDeMuerte
From SQLProyect..MuertesCovid
Where location like '%Mexico%'
and continent is not null 
order by 1,2


-- Casos totales vs poblacion
-- Porcentaje de poblacion infectada con COVID-19

Select Location, date, Population, total_cases,  (total_cases/population)*100 as PorcentajePoblacionContagiada
From SQLProyect..MuertesCovid
order by 1,2


-- Paises con el porcentaje mas alto de infecciones comparado con la poblacion

Select Location, Population, MAX(total_cases) as HighestInfectionCount,  Max((total_cases/population))*100 as PorcentajePoblacionContagiada
From SQLProyect..MuertesCovid
Group by Location, Population
order by PorcentajePoblacionContagiada desc


-- Paises con el numero de muertes mas alto por poblacion

Select Location, MAX(cast(Total_deaths as int)) as TotalDeMuertes
From SQLProyect..MuertesCovid
Where continent is not null 
Group by Location
order by TotalDeMuertes desc



-- DESGLOSE POR CONTINENTE

-- Mostrando continentes con el mayor numero de muertes por poblacion

Select continent, MAX(cast(Total_deaths as int)) as TotalDeMuertes
From SQLProyect..MuertesCovid
Where continent is not null 
Group by continent
order by TotalDeMuertes desc



-- Numeros globales

Select SUM(new_cases) as CasosTotales, SUM(cast(new_deaths as int)) as MuertesTotales, SUM(cast(new_deaths as int))/SUM(New_Cases)*100 as PorcentajeDeMuerte
From SQLProyect..MuertesCovid
where continent is not null 
order by 1,2



-- Total de poblacion vs vacunaciones
-- Porcentaje de poblacion con almenos una vacuna 

Select muerts.continent, muerts.location, muerts.date, muerts.population, vacuns.new_vaccinations
, SUM(CONVERT(int,vacuns.new_vaccinations)) OVER (Partition by muerts.Location Order by muerts.location, muerts.Date) as SumContinuaPersonasVacunadas
From SQLProyect..MuertesCovid muerts
Join SQLProyect..VacunasCovid vacuns
	On muerts.location = vacuns.location
	and muerts.date = vacuns.date
where muerts.continent is not null 
order by 2,3

-- Usando expreciones comunes de tabla(CTE) para realizar el cálculo en el partition By del Query anterior

With PobvsVacun (Continent, Location, Date, Population, New_Vaccinations, SumContinuaPersonasVacunadas)
as
(
Select muerts.continent, muerts.location, muerts.date, muerts.population, vacuns.new_vaccinations
, SUM(CONVERT(int,vacuns.new_vaccinations)) OVER (Partition by muerts.Location Order by muerts.location, muerts.Date) as SumContinuaPersonasVacunadas
From SQLProyect..MuertesCovid muerts
Join SQLProyect..VacunasCovid vacuns
	On muerts.location = vacuns.location
	and muerts.date = vacuns.date
where muerts.continent is not null 
)
Select *, (SumContinuaPersonasVacunadas/Population)*100
From PobvsVacun



-- Usando tablas temporales para calcular en Partition By del query anterior

DROP Table if exists #PorcentajePoblacionVacunada
Create Table #PorcentajePoblacionVacunada
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
SumContinuaPersonasVacunadas numeric
)

Insert into #PorcentajePoblacionVacunada
Select muerts.continent, muerts.location, muerts.date, muerts.population, vacuns.new_vaccinations
, SUM(CONVERT(int,vacuns.new_vaccinations)) OVER (Partition by muerts.Location Order by muerts.location, muerts.Date) as SumContinuaPersonasVacunadas
From SQLProyect..MuertesCovid muerts
Join SQLProyect..VacunasCovid vacuns
	On muerts.location = vacuns.location
	and muerts.date = vacuns.date
where muerts.continent is not null 
order by 2,3

Select *, (SumContinuaPersonasVacunadas/Population)*100
From #PorcentajePoblacionVacunada




-- Creando vistas para almacenar datos para visualizaciones posteriores

Create View PorcentajePoblacionVacunada as
Select muerts.continent, muerts.location, muerts.date, muerts.population, vacuns.new_vaccinations
, SUM(CONVERT(int,vacuns.new_vaccinations)) OVER (Partition by muerts.Location Order by muerts.location, muerts.Date) as SumContinuaPersonasVacunadas
From SQLProyect..MuertesCovid muerts
Join SQLProyect..VacunasCovid vacuns
	On muerts.location = vacuns.location
	and muerts.date = vacuns.date
where muerts.continent is not null 


