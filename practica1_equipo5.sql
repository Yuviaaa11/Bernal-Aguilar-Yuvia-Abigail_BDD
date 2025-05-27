-- Scrips general con la compilacion de todas las consultas (14). 

--Seleccion de la base a trabajar.
use covidHistorico
go
  
/*
  1. Listar el top 5 de las entidades con más casos confirmados por cada uno de los años 
    registrados en la base de datos.
*/

/*
  2. Listar el municipio con más casos confirmados recuperados por estado y por año.
*/

/*
  3. Listar el porcentaje de casos confirmados en cada una de las siguientes morbilidades a nivel 
    nacional: diabetes, obesidad e hipertensión.
*/

/*
  4. Listar los municipios que no tengan casos confirmados en todas las morbilidades: 
    hipertensión, obesidad, diabetes, tabaquismo.
*/
  
/*
  5. Listar los estados con más casos recuperados con neumonía.
*/

/*
  6. Listar el total de casos confirmados/sospechosos por estado en cada uno de los años 
    registrados en la base de datos.
*/
SELECT 
ENTIDAD_UM AS entidad,
YEAR(FECHA_INGRESO) as año,
SUM(CASE WHEN CLASIFICACION_FINAL=3 THEN 1 ELSE 0 END) AS casos_confirmados,
SUM(CASE WHEN CLASIFICACION_FINAL=6 THEN 1 ELSE 0 END) AS casos_sospechosos
FROM datoscovid 
WHERE CLASIFICACION_FINAL IN (3, 6)
GROUP BY ENTIDAD_UM, YEAR(FECHA_INGRESO)
ORDER BY ENTIDAD_UM, año;
/*
  7. Para el año 2020 y 2021 cuál fue el mes con más casos registrados, confirmados, 
    sospechosos, por estado registrado en la base de datos.
*/
with casos as (
  
SELECT 
ENTIDAD_UM AS entidad,
YEAR(FECHA_INGRESO) as año,
MONTH(FECHA_INGRESO) as mes,
SUM(CASE WHEN CLASIFICACION_FINAL=3 THEN 1 ELSE 0 END) AS casos_confirmados,
SUM(CASE WHEN CLASIFICACION_FINAL=6 THEN 1 ELSE 0 END) AS casos_sospechosos
FROM datoscovid 
WHERE CLASIFICACION_FINAL IN (3, 6) AND YEAR(FECHA_INGRESO) IN (2020, 2021)
GROUP BY ENTIDAD_UM, YEAR(FECHA_INGRESO), MONTH(FECHA_INGRESO)
)

SELECT c.entidad, c.año, c.mes, c.casos_confirmados, c.casos_sospechosos
FROM casos c
JOIN(
SELECT entidad, año, MAX(casos_confirmados+casos_sospechosos) AS m_casos
FROM casos
group by entidad, año
) maximos
ON c.entidad=maximos.entidad
AND c.año=maximos.año
AND (c.casos_confirmados+c.casos_sospechosos)=maximos.m_casos
ORDER BY c.entidad, c.año;
/*
  8. Listar el municipio con menos defunciones en el mes con más casos confirmados con 
    neumonía en los años 2020 y 2021.
*/
WITH casos_neumonia AS (
SELECT TOP 1
YEAR(FECHA_INGRESO) AS año,
MONTH(FECHA_INGRESO) AS mes,
COUNT(*) AS total_casos
FROM datoscovid
WHERE 
YEAR(FECHA_INGRESO) IN (2020, 2021)
AND NEUMONIA = 1  
GROUP BY YEAR(FECHA_INGRESO), MONTH(FECHA_INGRESO)
ORDER BY total_casos DESC
),

defunciones AS (
    
SELECT 
MUNICIPIO_RES AS municipio,
COUNT(*) AS total_defunciones
FROM datoscovid
WHERE 
YEAR(FECHA_INGRESO) IN (2020,2021)
AND FECHA_DEF <> '9999-99-99' 
GROUP BY MUNICIPIO_RES 
)
SELECT * FROM defunciones
ORDER BY total_defunciones ASC;
/*
  9. Listar el top 3 de municipios con menos casos recuperados en el año 2021.
*/
with casos AS(
SELECT 
MUNICIPIO_RES as municipio,
CLASIFICACION_FINAL as casos_confirmados,
YEAR(FECHA_INGRESO) as año,
count(*) as casos_recuperados
FROM datoscovid
where YEAR(FECHA_INGRESO)=2021
and FECHA_DEF='9999-99-99'
and CLASIFICACION_FINAL=3
group by MUNICIPIO_RES, YEAR(FECHA_INGRESO), CLASIFICACION_FINAL
)
select top 3
municipio,
año,casos_recuperados
FROM casos
order by casos_recuperados ASC;
/*
  10. Listar el porcentaje de casos confirmado por género en los años 2020 y 2021.
*/
with casos_confirmados as (
SELECT 
YEAR(FECHA_INGRESO) as año,
SEXO as sexo,
count(*) as total_casos_sexo
FROM datoscovid
where 
CLASIFICACION_FINAL=3
and YEAR(FECHA_INGRESO) IN (2020, 2021)
group by sexo, year(fecha_ingreso)
),

total as(
SELECT SUM(total_casos_sexo) as general FROM casos_confirmados
)

select 
c.sexo, c.total_casos_sexo,
ROUND((c.total_casos_sexo*100.0/ t.general),2) as porcentaje
from casos_confirmados c
CROSS JOIN total t
order by c.sexo;
/*
  11. Listar el porcentaje de casos hospitalizados por estado en el año 2020.
*/
SELECT 
    ENTIDAD_NAC, 
    COUNT(*) * 100.0 / SUM(COUNT(*)) OVER () AS Porcentaje
FROM dbo.datoscovid 
JOIN (
    SELECT COUNT(*) AS Total_Casos
    FROM dbo.datoscovid
    WHERE YEAR(FECHA_INGRESO) IN (2020)
    AND CLASIFICACION_FINAL = '3'
) AS Total ON 1 = 1  -- Esto crea un CROSS JOIN con el total de casos
WHERE YEAR(FECHA_INGRESO) IN (2020)
AND CLASIFICACION_FINAL = '3'
GROUP BY ENTIDAD_NAC;

/* 
  12. Listar total de casos negativos por estado en los años 2020 y 2021.
*/
SELECT 
    d.ENTIDAD_NAC AS Codigo_Entidad, 
    COUNT(*) AS Total_Casos_Negativos
FROM dbo.datoscovid d
JOIN (
    SELECT COUNT(*) AS Total_Casos
    FROM dbo.datoscovid
    WHERE YEAR(FECHA_INGRESO) IN (2020, 2021)
    AND CLASIFICACION_FINAL = '7'
) AS Total ON 1 = 1  -- CROSS JOIN para obtener el total de casos negativos
WHERE YEAR(d.FECHA_INGRESO) IN (2020, 2021)
AND d.CLASIFICACION_FINAL = '7'
GROUP BY d.ENTIDAD_NAC
ORDER BY Total_Casos_Negativos DESC;

/*
  13. Listar porcentajes de casos confirmados por género en el rango de edades de 20 a 30 años, 
      de 31 a 40 años, de 41 a 50 años, de 51 a 60 años y mayores a 60 años a nivel nacional.
*/
WITH Rango_Edad AS (
    SELECT 1 AS Rango_ID, '20-30' AS Rango_Edad, 20 AS Edad_Min, 30 AS Edad_Max
    UNION ALL
    SELECT 2, '31-40', 31, 40
    UNION ALL
    SELECT 3, '41-50', 41, 50
    UNION ALL
    SELECT 4, '51-60', 51, 60
    UNION ALL
    SELECT 5, '60+', 61, NULL
)
SELECT 
    RE.Rango_Edad,
    DC.SEXO AS Genero,
    COUNT(*) AS Total_Casos_Confirmados,
    (COUNT(*) * 100.0 / SUM(COUNT(*)) OVER()) AS Porcentaje_Casos_Confirmados
FROM dbo.datoscovid DC
JOIN Rango_Edad RE
    ON DC.EDAD BETWEEN RE.Edad_Min AND COALESCE(RE.Edad_Max, DC.EDAD)  -- Asegura que no haya problemas con el rango de mayores de 60
WHERE YEAR(DC.FECHA_INGRESO) IN (2020, 2021)
    AND DC.CLASIFICACION_FINAL = '3'  -- Solo casos confirmados
GROUP BY 
    RE.Rango_Edad, 
    DC.SEXO
ORDER BY RE.Rango_Edad, DC.SEXO DESC;

/*
  14. Listar el rango de edad con más casos confirmados y que fallecieron en los años 2020 y 2021.
*/
WITH Rango_Edad AS (
    SELECT 1 AS Rango_ID, '20-30' AS Rango_Edad, 20 AS Edad_Min, 30 AS Edad_Max
    UNION ALL
    SELECT 2, '31-40', 31, 40
    UNION ALL
    SELECT 3, '41-50', 41, 50
    UNION ALL
    SELECT 4, '51-60', 51, 60
    UNION ALL
    SELECT 5, '60+', 61, NULL
)
SELECT TOP 1 
    RE.Rango_Edad,
    COUNT(*) AS Total_Fallecidos
FROM dbo.datoscovid DC
JOIN Rango_Edad RE
    ON DC.EDAD BETWEEN RE.Edad_Min AND COALESCE(RE.Edad_Max, DC.EDAD)
WHERE YEAR(DC.FECHA_INGRESO) IN (2020, 2021)
    AND DC.CLASIFICACION_FINAL = '3'  -- Solo casos confirmados
    AND DC.FECHA_DEF IS NOT NULL  -- Solo personas fallecidas
GROUP BY RE.Rango_Edad
ORDER BY Total_Fallecidos DESC;



