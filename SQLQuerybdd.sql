use covidHistorico;
go


-----Consulta 1---------------------------------------------------------
--Top 5 entidades con m�s casos confirmados por cada a�o.

WITH casos_por_entidad AS (
    SELECT 
        YEAR(FECHA_INGRESO) AS anio,
        ENTIDAD_NAC,
        COUNT(*) AS total_casos
    FROM dbo.datoscovid
    WHERE CLASIFICACION_FINAL = 3 -- Solo casos confirmados
    GROUP BY YEAR(FECHA_INGRESO), ENTIDAD_NAC
)
SELECT anio, ENTIDAD_NAC, total_casos
FROM (
    SELECT 
        anio, 
        ENTIDAD_NAC, 
        total_casos,
        RANK() OVER (PARTITION BY anio ORDER BY total_casos DESC) AS ranking
    FROM casos_por_entidad
) t
WHERE ranking <= 5
ORDER BY anio, ranking;

------Consulta 2---------------------------------------------------------
--Municipio con m�s casos confirmados recuperados por estado y por a�o.

SELECT 
    YEAR(FECHA_INGRESO) AS anio,
    ENTIDAD_NAC,
    MUNICIPIO_RES,
    COUNT(*) AS total_confirmados
FROM dbo.datoscovid
WHERE CLASIFICACION_FINAL = 3  -- Solo casos confirmados
GROUP BY YEAR(FECHA_INGRESO), ENTIDAD_NAC, MUNICIPIO_RES
HAVING COUNT(*) = (
    SELECT MAX(casos)
    FROM (
        SELECT COUNT(*) AS casos
        FROM dbo.datoscovid
        WHERE CLASIFICACION_FINAL = 3
        GROUP BY YEAR(FECHA_INGRESO), ENTIDAD_NAC, MUNICIPIO_RES
    ) AS max_casos
)
ORDER BY anio, ENTIDAD_NAC;

--------Consulta 3--------------------------------------------------------
--Porcentaje de casos confirmados de diabetes, obesidad e hipertensi�n.

SELECT
    'Diabetes' AS morbilidad,
    (COUNT(CASE WHEN DIABETES = 1 AND CLASIFICACION_FINAL = 3 THEN 1 END) * 100.0) / COUNT(CASE WHEN CLASIFICACION_FINAL = 3 THEN 1 END) AS porcentaje
FROM dbo.datoscovid
UNION ALL
SELECT
    'Obesidad' AS morbilidad,
    (COUNT(CASE WHEN OBESIDAD = 1 AND CLASIFICACION_FINAL = 3 THEN 1 END) * 100.0) / COUNT(CASE WHEN CLASIFICACION_FINAL = 3 THEN 1 END) AS porcentaje
FROM dbo.datoscovid
UNION ALL
SELECT
    'Hipertensi�n' AS morbilidad,
    (COUNT(CASE WHEN HIPERTENSION = 1 AND CLASIFICACION_FINAL = 3 THEN 1 END) * 100.0) / COUNT(CASE WHEN CLASIFICACION_FINAL = 3 THEN 1 END) AS porcentaje
FROM dbo.datoscovid;

-------Consulta 4---------------------------------------------------
--Municipios que no tengan casos confirmados de hipertensi�n, obesidad, diabetes y tabaquismo.

SELECT DISTINCT MUNICIPIO_RES
FROM dbo.datoscovid
WHERE MUNICIPIO_RES NOT IN (
    SELECT DISTINCT MUNICIPIO_RES
    FROM dbo.datoscovid
    WHERE CLASIFICACION_FINAL = 3  -- Casos confirmados
    AND (DIABETES = 1 OR OBESIDAD = 1 OR TABAQUISMO = 1)
)
ORDER BY MUNICIPIO_RES;

-------Consulta 5-----------------------------------------------------
--Estados con m�s casos recuperados con neumon�a.

SELECT 
    ENTIDAD_NAC AS estado,
    COUNT(*) AS total_recuperados_con_neumonia
FROM dbo.datoscovid
WHERE CLASIFICACION_FINAL = 3  -- Casos confirmados
AND NEUMONIA = 1              -- Pacientes con neumon�a
AND FECHA_DEF IS NULL         -- Filtramos solo los recuperados (no fallecidos)
GROUP BY ENTIDAD_NAC
ORDER BY total_recuperados_con_neumonia DESC;

SELECT COUNT(*)
FROM dbo.datoscovid
WHERE CLASIFICACION_FINAL = 3 AND NEUMONIA = 1;


----------------------------------------------------------
SELECT 
    ENTIDAD_NAC AS estado,
    COUNT(*) AS total_casos_con_neumonia
FROM dbo.datoscovid
WHERE CLASIFICACION_FINAL = 3  -- Casos confirmados
AND NEUMONIA = 1              -- Pacientes con neumon�a
GROUP BY ENTIDAD_NAC
ORDER BY total_casos_con_neumonia DESC;
------------------------------------------------------------

SELECT DISTINCT ENTIDAD_NAC
FROM dbo.datoscovid
WHERE CLASIFICACION_FINAL = 3  
AND NEUMONIA = 1;
