-- =========================================================
-- 03. OPERATIONAL ANALYSIS
-- Análisis por estado de viaje, tipo de vehículo y periodo
-- Base utilizada: base analítica limpia
-- =========================================================


-- =========================================================
-- 1. INGRESOS Y MARGEN POR ESTADO DE VIAJE
-- =========================================================

WITH ids_repetidos AS (
    SELECT
        booking_id
    FROM uber_viajes_bookings
    GROUP BY booking_id
    HAVING COUNT(*) > 1
),

base_limpia AS (
    SELECT
        uvb.booking_id AS viaje_id,
        uvb.fecha,
        uvb.estado_booking,
        uvb.tipo_vehiculo,
        uvb.valor_booking AS ingresos,
        ucv.costo_total,
        uvb.valor_booking - ucv.costo_total AS margen_operativo
    FROM uber_viajes_bookings uvb
    INNER JOIN uber_costo_viajes ucv
        ON uvb.booking_id = ucv.booking_id
    WHERE uvb.booking_id NOT IN (
        SELECT booking_id
        FROM ids_repetidos
    )
)

SELECT
    estado_booking,
    COUNT(*) AS cantidad_viajes,
    SUM(ingresos::int) AS ingresos_totales,
    AVG(ingresos) AS ingreso_promedio,
    SUM(costo_total::int) AS costos_totales,
    SUM(margen_operativo::int) AS margen_total,
    AVG(margen_operativo) AS margen_promedio
FROM base_limpia
GROUP BY estado_booking
ORDER BY ingresos_totales DESC NULLS LAST;


-- Resultado observado:
--
-- Completed:
-- 91.510 viajes
-- Ingresos totales: 46.489.770
-- Ingreso promedio: 508.029
-- Costos totales: 35.258.141
-- Margen total: 11.231.629
-- Margen promedio: 122.733
--
-- Incomplete:
-- 8.849 viajes
-- Ingresos totales: 4.502.183
-- Ingreso promedio: 508.779
-- Costos totales: 3.414.526
-- Margen total: 1.087.666
-- Margen promedio: 122.914
--
-- Cancelled by Customer:
-- 10.323 viajes
-- Sin ingresos asociados
-- Costos totales: 0
--
-- Cancelled by Driver:
-- 26.547 viajes
-- Sin ingresos asociados
-- Costos totales: 0
--
-- No Driver Found:
-- 10.314 viajes
-- Sin ingresos asociados
-- Costos totales: 0
--
-- Hallazgo:
-- Los viajes Completed concentran la mayor generación de ingresos
-- y margen debido principalmente a su mayor volumen.
--
-- Los viajes Incomplete presentan ingreso y margen promedio
-- similares a los Completed, indicando que corresponden a viajes
-- con actividad económica iniciada, aunque no completada normalmente.



-- =========================================================
-- 2. INGRESOS Y MARGEN POR TIPO DE VEHÍCULO
-- =========================================================

WITH ids_repetidos AS (
    SELECT
        booking_id
    FROM uber_viajes_bookings
    GROUP BY booking_id
    HAVING COUNT(*) > 1
),

base_limpia AS (
    SELECT
        uvb.booking_id AS viaje_id,
        uvb.tipo_vehiculo,
        uvb.valor_booking AS ingresos,
        ucv.costo_total,
        uvb.valor_booking - ucv.costo_total AS margen_operativo
    FROM uber_viajes_bookings uvb
    INNER JOIN uber_costo_viajes ucv
        ON uvb.booking_id = ucv.booking_id
    WHERE uvb.booking_id NOT IN (
        SELECT booking_id
        FROM ids_repetidos
    )
)

SELECT
    tipo_vehiculo,
    COUNT(*) AS cantidad_viajes,
    SUM(ingresos::int) AS ingresos_totales,
    AVG(ingresos) AS ingreso_promedio,
    SUM(costo_total::int) AS costos_totales,
    SUM(margen_operativo::int) AS margen_total,
    AVG(margen_operativo) AS margen_promedio
FROM base_limpia
GROUP BY tipo_vehiculo
ORDER BY margen_total DESC;


-- Resultado observado:
--
-- Auto:
-- 36.810 viajes
-- Ingresos totales: 12.668.559
-- Margen total: 3.060.684
-- Margen promedio: 122.47
--
-- Go Mini:
-- 29.284 viajes
-- Ingresos totales: 10.161.819
-- Margen total: 2.455.035
-- Margen promedio: 122.65
--
-- Go Sedan:
-- 26.723 viajes
-- Ingresos totales: 9.226.616
-- Margen total: 2.229.027
-- Margen promedio: 123.45
--
-- Bike:
-- 22.143 viajes
-- Ingresos totales: 7.699.278
-- Margen total: 1.860.093
-- Margen promedio: 123.02
--
-- Premier Sedan:
-- 17.824 viajes
-- Ingresos totales: 6.176.949
-- Margen total: 1.492.276
-- Margen promedio: 123.09
--
-- eBike:
-- 10.376 viajes
-- Ingresos totales: 3.557.408
-- Margen total: 859.453
-- Margen promedio: 121.80
--
-- Uber XL:
-- 4.383 viajes
-- Ingresos totales: 1.501.324
-- Margen total: 362.718
-- Margen promedio: 121.02
--
-- Hallazgo:
-- Auto genera el mayor ingreso y margen operativo total,
-- principalmente por su mayor volumen de viajes.
--
-- Go Sedan presenta el mayor margen promedio por viaje,
-- mostrando una rentabilidad unitaria ligeramente superior.



-- =========================================================
-- 2.1 RANKING DE RENTABILIDAD POR TIPO DE VEHÍCULO
-- WINDOW FUNCTION: RANK()
-- =========================================================

WITH ids_repetidos AS (
    SELECT
        booking_id
    FROM uber_viajes_bookings
    GROUP BY booking_id
    HAVING COUNT(*) > 1
),

base_limpia AS (
    SELECT
        uvb.booking_id AS viaje_id,
        uvb.tipo_vehiculo,
        uvb.valor_booking AS ingresos,
        ucv.costo_total,
        uvb.valor_booking - ucv.costo_total AS margen_operativo
    FROM uber_viajes_bookings uvb
    INNER JOIN uber_costo_viajes ucv
        ON uvb.booking_id = ucv.booking_id
    WHERE uvb.booking_id NOT IN (
        SELECT booking_id
        FROM ids_repetidos
    )
),

metricas_vehiculo AS (
    SELECT
        tipo_vehiculo,
        COUNT(*) AS cantidad_viajes,
        SUM(ingresos::int) AS ingresos_totales,
        SUM(costo_total::int) AS costos_totales,
        SUM(margen_operativo::int) AS margen_total,
        AVG(margen_operativo) AS margen_promedio
    FROM base_limpia
    GROUP BY tipo_vehiculo
)

SELECT
    tipo_vehiculo,
    cantidad_viajes,
    ingresos_totales,
    costos_totales,
    margen_total,
    ROUND(margen_promedio::numeric, 2) AS margen_promedio,

    RANK() OVER (
        ORDER BY margen_total DESC
    ) AS ranking_margen_total,

    RANK() OVER (
        ORDER BY margen_promedio DESC
    ) AS ranking_margen_promedio

FROM metricas_vehiculo
ORDER BY ranking_margen_total;


-- Resultado observado:
--
-- Tipo              Rank margen total    Rank margen promedio
--
-- Auto                       1                    5
-- Go Mini                    2                    4
-- Go Sedan                   3                    1
-- Bike                       4                    3
-- Premier Sedan              5                    2
-- eBike                      6                    6
-- Uber XL                    7                    7
--
-- Hallazgo:
-- El ranking evidencia que volumen y rentabilidad unitaria
-- no necesariamente siguen el mismo comportamiento.
--
-- Auto ocupa el primer lugar en margen total con 3.060.684,
-- impulsado por sus 36.810 viajes, pero ocupa el quinto lugar
-- en margen promedio por viaje.
--
-- Go Sedan ocupa el tercer lugar en margen total, pero alcanza
-- el primer lugar en margen promedio con 123.45 por viaje.
--
-- Premier Sedan también presenta una diferencia relevante:
-- ocupa el quinto lugar en margen total, pero el segundo lugar
-- en margen promedio.
--
-- Conclusión:
-- El volumen de viajes explica gran parte de la contribución total,
-- mientras que el ranking de margen promedio permite identificar
-- los tipos de vehículo con mayor rentabilidad unitaria.



-- =========================================================
-- 3. EVOLUCIÓN MENSUAL DE VIAJES, INGRESOS Y MARGEN
-- =========================================================

WITH ids_repetidos AS (
    SELECT
        booking_id
    FROM uber_viajes_bookings
    GROUP BY booking_id
    HAVING COUNT(*) > 1
),

base_limpia AS (
    SELECT
        uvb.booking_id AS viaje_id,
        uvb.fecha,
        uvb.valor_booking AS ingresos,
        ucv.costo_total,
        uvb.valor_booking - ucv.costo_total AS margen_operativo
    FROM uber_viajes_bookings uvb
    INNER JOIN uber_costo_viajes ucv
        ON uvb.booking_id = ucv.booking_id
    WHERE uvb.booking_id NOT IN (
        SELECT booking_id
        FROM ids_repetidos
    )
)

SELECT
    DATE_TRUNC('month', fecha) AS mes,
    COUNT(*) AS cantidad_viajes,
    SUM(ingresos::int) AS ingresos_totales,
    SUM(costo_total::int) AS costos_totales,
    SUM(margen_operativo::int) AS margen_total
FROM base_limpia
GROUP BY DATE_TRUNC('month', fecha)
ORDER BY mes;


-- Resultado observado:
--
-- Enero:
-- 12.664 viajes
-- Margen total: 1.049.554
--
-- Febrero:
-- 11.708 viajes
-- Margen total: 966.361
--
-- Marzo:
-- 12.510 viajes
-- Margen total: 1.087.588
--
-- Abril:
-- 12.000 viajes
-- Margen total: 1.011.222
--
-- Mayo:
-- 12.569 viajes
-- Margen total: 1.025.413
--
-- Junio:
-- 12.235 viajes
-- Margen total: 1.027.772
--
-- Julio:
-- 12.704 viajes
-- Margen total: 1.039.216
--
-- Agosto:
-- 12.431 viajes
-- Margen total: 1.009.693
--
-- Septiembre:
-- 12.051 viajes
-- Margen total: 994.577
--
-- Octubre:
-- 12.424 viajes
-- Margen total: 1.048.104
--
-- Noviembre:
-- 12.200 viajes
-- Margen total: 1.032.820
--
-- Diciembre:
-- 12.047 viajes
-- Margen total: 1.026.966
--
-- Hallazgo:
-- Marzo presenta el mayor margen operativo total del año.
--
-- Sin embargo, los valores mensuales permanecen relativamente
-- cercanos durante 2024, sin evidencia de una estacionalidad marcada.



-- =========================================================
-- 3.1 VARIACIÓN MENSUAL DEL MARGEN OPERATIVO
-- WINDOW FUNCTION: LAG()
-- =========================================================

WITH ids_repetidos AS (
    SELECT
        booking_id
    FROM uber_viajes_bookings
    GROUP BY booking_id
    HAVING COUNT(*) > 1
),

base_limpia AS (
    SELECT
        uvb.booking_id AS viaje_id,
        uvb.fecha,
        uvb.valor_booking AS ingresos,
        ucv.costo_total,
        uvb.valor_booking - ucv.costo_total AS margen_operativo
    FROM uber_viajes_bookings uvb
    INNER JOIN uber_costo_viajes ucv
        ON uvb.booking_id = ucv.booking_id
    WHERE uvb.booking_id NOT IN (
        SELECT booking_id
        FROM ids_repetidos
    )
),

resumen_mensual AS (
    SELECT
        DATE_TRUNC('month', fecha) AS mes,
        COUNT(*) AS cantidad_viajes,
        SUM(ingresos::int) AS ingresos_totales,
        SUM(costo_total::int) AS costos_totales,
        SUM(margen_operativo::int) AS margen_total
    FROM base_limpia
    GROUP BY DATE_TRUNC('month', fecha)
),

comparacion_mensual AS (
    SELECT
        mes,
        cantidad_viajes,
        ingresos_totales,
        costos_totales,
        margen_total,

        LAG(margen_total) OVER (
            ORDER BY mes
        ) AS margen_mes_anterior

    FROM resumen_mensual
)

SELECT
    mes,
    cantidad_viajes,
    ingresos_totales,
    costos_totales,
    margen_total,
    margen_mes_anterior,

    ROUND(
        (
            (margen_total - margen_mes_anterior)::numeric
            / NULLIF(margen_mes_anterior, 0)
        ) * 100,
        2
    ) AS variacion_margen_pct

FROM comparacion_mensual
ORDER BY mes;


-- Resultado observado:
--
-- Enero:
-- Margen total: 1.049.554
-- Mes anterior: NULL
-- Variación: NULL
--
-- Febrero:
-- Margen total: 966.361
-- Variación mensual: -7.93%
--
-- Marzo:
-- Margen total: 1.087.588
-- Variación mensual: +12.54%
--
-- Abril:
-- Margen total: 1.011.222
-- Variación mensual: -7.02%
--
-- Mayo:
-- Margen total: 1.025.413
-- Variación mensual: +1.40%
--
-- Junio:
-- Margen total: 1.027.772
-- Variación mensual: +0.23%
--
-- Julio:
-- Margen total: 1.039.216
-- Variación mensual: +1.11%
--
-- Agosto:
-- Margen total: 1.009.693
-- Variación mensual: -2.84%
--
-- Septiembre:
-- Margen total: 994.577
-- Variación mensual: -1.50%
--
-- Octubre:
-- Margen total: 1.048.104
-- Variación mensual: +5.38%
--
-- Noviembre:
-- Margen total: 1.032.820
-- Variación mensual: -1.46%
--
-- Diciembre:
-- Margen total: 1.026.966
-- Variación mensual: -0.57%
--
-- Hallazgo:
-- La mayor variación positiva se produjo en marzo,
-- cuando el margen aumentó 12.54% respecto a febrero.
--
-- La mayor caída mensual se produjo en febrero,
-- con una disminución de 7.93% respecto a enero.
--
-- Abril también presentó una reducción relevante de 7.02%
-- después del máximo registrado en marzo.
--
-- A partir de mayo, las variaciones mensuales fueron
-- considerablemente menores, generalmente dentro de ±3%,
-- excepto octubre, cuando el margen aumentó 5.38%.
--
-- Conclusión:
-- Aunque existen fluctuaciones mensuales, el margen operativo
-- presenta un comportamiento relativamente estable durante el año.
--
-- LAG() permite comparar cada periodo con el inmediatamente anterior
-- sin realizar un JOIN adicional de la tabla consigo misma.



-- =========================================================
-- 4. CONCLUSIONES DEL ANÁLISIS OPERATIVO
-- =========================================================

-- 1. Los viajes Completed concentran la mayor generación
--    de ingresos y margen operativo debido principalmente
--    a su mayor volumen.
--
-- 2. Los viajes Incomplete también generan actividad económica,
--    con ingreso y margen promedio similares a los Completed.
--
-- 3. Auto lidera en ingresos y margen total debido a su escala,
--    alcanzando 3.060.684 de margen operativo.
--
-- 4. Go Sedan presenta el mayor margen promedio por viaje,
--    con 123.45, aunque ocupa el tercer lugar en margen total.
--
-- 5. RANK() evidencia que liderazgo por volumen y rentabilidad
--    unitaria son dimensiones diferentes del desempeño.
--
-- 6. Marzo fue el mes con mayor margen operativo del año,
--    alcanzando 1.087.588.
--
-- 7. Mediante LAG() se identificó que marzo también presentó
--    el mayor crecimiento mensual, con +12.54% respecto a febrero.
--
-- 8. Febrero registró la mayor caída mensual, con -7.93%.
--
-- 9. El comportamiento del margen durante 2024 fue relativamente
--    estable, sin evidencia de una estacionalidad pronunciada.
--
-- 10. Las funciones de ventana permiten enriquecer el análisis
--     manteniendo el nivel de detalle de los resultados y facilitando
--     comparaciones entre categorías y periodos.