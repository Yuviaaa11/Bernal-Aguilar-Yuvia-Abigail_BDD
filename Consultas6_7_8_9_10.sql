
/* 6. LISTAR EL TOTAL DE CASOS CONFIRMADOS/SOSPECHOSOS POR ESTADO EN 
CADA UNO DE LOS AÑOS REGISTRADOS EN LA BASE DE DATOS*/
SELECT 
ENTIDAD_UM AS entidad,
YEAR(FECHA_INGRESO) as año,
SUM(CASE WHEN CLASIFICACION_FINAL=3 THEN 1 ELSE 0 END) AS casos_confirmados,
SUM(CASE WHEN CLASIFICACION_FINAL=6 THEN 1 ELSE 0 END) AS casos_sospechosos
FROM datoscovid 
WHERE CLASIFICACION_FINAL IN (3, 6)
GROUP BY ENTIDAD_UM, YEAR(FECHA_INGRESO)
ORDER BY ENTIDAD_UM, año;

/*7. PARA EL AÑO 2020 Y 2021 CUAL FUE EL MES CON MAS CASOS REGISTRADOS, 
CONFIRMADOS, SOSPECHOSOS, POR ESTADO REGISTRADO EN LA BASE DE DATOS*/

with casos as (SELECT 
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
)maximos
ON c.entidad=maximos.entidad
AND c.año=maximos.año
AND (c.casos_confirmados+c.casos_sospechosos)=maximos.m_casos
ORDER BY c.entidad, c.año;

/*8.- LISTAR EL MUNICIPIO CON MENOS DEFUNCIONES EN EL MES CON MAS CASOS CONFIRMADOS CON NEUMONIA EN 2020 Y 2021*/
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
        --AND MONTH(FECHA_INGRESO)
        AND FECHA_DEF <> '9999-99-99' 
    GROUP BY MUNICIPIO_RES 
)

SELECT * FROM defunciones
 ORDER BY total_defunciones ASC;

/* 9. LISTAR EL TOP 3 DE MUNICIPIOS CON MENOS CASOS RECUPERADOS EN 2021*/

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

/*10. LISTAR EL PORCENTAJE DE CASOS CONFIRMADOS POR GENERO EN LOS AÑOS 2020 Y 2021*/
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
