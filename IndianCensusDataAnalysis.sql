SELECT *
FROM IndianCensusDataAnalysis.dbo.Data1
SELECT *
FROM IndianCensusDataAnalysis.dbo.Data2

-- Number of rows into our dataset

SELECT COUNT(*)
FROM IndianCensusDataAnalysis..Data1;
SELECT COUNT(*)
FROM IndianCensusDataAnalysis..Data2;
-- Dataset for two states
SELECT *
FROM IndianCensusDataAnalysis..Data1
WHERE state in ( 'jharkhand', 'Bihar' );

-- Total Population of India

SELECT SUM(Population) AS TotalPopulation
FROM IndianCensusDataAnalysis..Data2

-- Avg Growth rate in Percentage of India population

SELECT state,
       AVG(growth) * 100 AS Avg_Growth
from IndianCensusDataAnalysis..Data1
group by state;
-- Average sex-ratio

SELECT state,
       round(AVG(Sex_Ratio), 0) AS Avg_Sex_Ratio
from IndianCensusDataAnalysis..Data1
group by state
order by Avg_Sex_Ratio desc;

-- Average Literacy Rate

SELECT state,
       round(AVG(Literacy), 0) AS Avg_Literacy_Ratio
from IndianCensusDataAnalysis..Data1
group by state
HAVING round(AVG(Literacy), 0) > 70
order by Avg_Literacy_Ratio desc;


-- Top 3 States showing the Highest Growth Ratio

SELECT top 3
    state,
    AVG(growth) * 100 AS Avg_Growth
from IndianCensusDataAnalysis..Data1
group by state
Order by Avg_Growth desc;

---- Top 3 States showing the Highest Growth Ratio Using Limit Function

--SELECT state,
--       AVG(growth) * 100 AS Avg_Growth
--from IndianCensusDataAnalysis..Data1
--group by state
--Order by Avg_Growth desc Limit 3
--;

-- Bottom 3 States showing the Lowest Sex Ratio

SELECT top 3
    state,
    round(AVG(Sex_Ratio), 0) AS Avg_Sex_Ratio
from IndianCensusDataAnalysis..Data1
group by state
order by Avg_Sex_Ratio asc;


-- Top And Bottom 3 States Literacy Ratio
DROP TABLE IF EXISTS #topStates
Create table #topStates
(
    state nvarchar(255),
    topStates float,
)

insert into #topStates
SELECT state,
       ROUND(AVG(Literacy), 0) AS Avg_Literacy_Ratio
from IndianCensusDataAnalysis..Data1
group by state
Order by Avg_Literacy_Ratio desc;

SELECT top 3
    *
FROM #topStates
Order By #topStates.topStates desc

-- Bottom States

DROP TABLE IF EXISTS #bottomStates
Create table #bottomStates
(
    state nvarchar(255),
    bottomStates float,
)

insert into #bottomStates
SELECT state,
       ROUND(AVG(Literacy), 0) AS Avg_Literacy_Ratio
from IndianCensusDataAnalysis..Data1
group by state
Order by Avg_Literacy_Ratio desc;

SELECT top 3
    *
FROM #bottomStates
Order By #bottomStates.bottomStates asc

-- Union Operator
SELECT *
FROM
(
    SELECT top 3
        *
    FROM #topStates
    Order By #topStates.topStates desc
) UpValue
Union
SELECT *
FROM
(
    SELECT top 3
        *
    FROM #bottomStates
    Order By #bottomStates.bottomStates asc
) BottomValue;


-- States starting with specific letter
SELECT DISTINCT
    STATE
FROM IndianCensusDataAnalysis..Data1
WHERE LOWER(state) like 'a%'
      or LOWER(state) like 'b%';



-- Joining Both Tables
-- Total males & Total females

SELECT stateData.State,
       SUM(stateData.males) AS Total_Males,
       SUM(stateData.Females) AS Total_Females
FROM
(
    SELECT genderData.District,
           genderData.State,
           ROUND(genderData.population / (genderData.Sex_Ratio + 1), 0) AS males,
           round((genderData.population * genderData.Sex_Ratio) / (genderData.Sex_Ratio + 1), 0) AS Females
    FROM
    (
        SELECT d1.District,
               d1.State,
               d1.Sex_Ratio / 1000 Sex_Ratio,
               d2.population
        from IndianCensusDataAnalysis..Data1 As d1
            inner join IndianCensusDataAnalysis..Data2 As d2
                on d1.District = d2.District
    ) AS genderData
) stateData
group by stateData.state


-- Total Litercy Rate

SELECT state_level.State,
       SUM(state_level.literate_people) AS Total_Literate_People,
       SUM(state_level.illiterate_people) AS Total_Illuterate_People
FROM
(
    SELECT literacy_rate.District,
           literacy_rate.state,
           round(literacy_rate.literacy_ratio * literacy_rate.population, 0) AS literate_people,
           ROUND((1 - literacy_rate.literacy_ratio) * literacy_rate.population, 0) AS illiterate_people
    from
    (
        SELECT d1.District,
               d1.State,
               d1.Literacy / 100 Literacy_Ratio,
               d2.population
        from IndianCensusDataAnalysis..Data1 As d1
            inner join IndianCensusDataAnalysis..Data2 As d2
                on d1.District = d2.District
    ) AS literacy_rate
) AS state_level
group by state_level.State

-- population in Previous Census

SELECT SUM(total_population.Pre_Census_Population) AS Total_Pre_Population,
       SUM(total_population.Cur_Census_population) AS Total_Cur_Population
FROM
(
    SELECT state_growth.State,
           SUM(state_growth.Pre_Census_Population) AS Pre_Census_Population,
           SUM(state_growth.current_census_population) AS Cur_Census_population
    FROM
    (
        SELECT pre_census.District,
               pre_census.State,
               ROUND(pre_census.Population / (1 + pre_census.Growth), 0) AS Pre_Census_Population,
               pre_census.Population AS current_census_population
        FROM
        (
            SELECT d1.District,
                   d1.State,
                   d1.Growth Growth,
                   d2.population
            from IndianCensusDataAnalysis..Data1 As d1
                inner join IndianCensusDataAnalysis..Data2 As d2
                    on d1.District = d2.District
        ) AS pre_census
    ) AS state_growth
    GROUP BY state_growth.State
) AS total_population

-- Population VS Area

SELECT area_decreased.Total_Area / area_decreased.Total_Pre_Population AS Total_Pre_Pop_VS_Area,
       area_decreased.Total_Area / area_decreased.Total_Cur_Population AS Total_Cur_Pop_VS_Area
FROM
(
    SELECT india_key1.*,
           india_key2.*
    FROM
    (
        SELECT '1' AS population_key,
               india_population.*
        FROM
        (
            SELECT SUM(total_population.Pre_Census_Population) AS Total_Pre_Population,
                   SUM(total_population.Cur_Census_population) AS Total_Cur_Population
            FROM
            (
                SELECT state_growth.State,
                       SUM(state_growth.Pre_Census_Population) AS Pre_Census_Population,
                       SUM(state_growth.current_census_population) AS Cur_Census_population
                FROM
                (
                    SELECT pre_census.District,
                           pre_census.State,
                           ROUND(pre_census.Population / (1 + pre_census.Growth), 0) AS Pre_Census_Population,
                           pre_census.Population AS current_census_population
                    FROM
                    (
                        SELECT d1.District,
                               d1.State,
                               d1.Growth Growth,
                               d2.population
                        from IndianCensusDataAnalysis..Data1 As d1
                            inner join IndianCensusDataAnalysis..Data2 As d2
                                on d1.District = d2.District
                    ) AS pre_census
                ) AS state_growth
                GROUP BY state_growth.State
            ) AS total_population
        ) AS india_population
    ) AS india_key1
        inner join
        (
            SELECT '1' AS area_key,
                   total_area.*
            from
            (
                SELECT SUM(Area_km2) AS Total_Area
                from IndianCensusDataAnalysis..Data2
            ) AS total_area
        ) AS india_key2
            on india_key1.population_key = india_key2.area_key
) AS area_decreased


-- Take out top 3 Districts from every state with highest literacy rate

SELECT Ranking.*
FROM
(
    Select District,
           State,
           Literacy,
           RANK() over (partition by state order by literacy desc) AS DistRanks
    from IndianCensusDataAnalysis..Data1
) AS Ranking
WHERE Ranking.DistRanks IN ( 1, 2, 3 )
Order By State;

