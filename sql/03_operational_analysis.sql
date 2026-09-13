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
-- Completed:
-- 91510 viajes
-- Ingresos totales: 46489770
-- Ingreso promedio: 508.029
-- Costos totales: 35258141
-- Margen total: 11231629
-- Margen promedio: 122.733
--
-- Incomplete:
-- 8849 viajes
-- Ingresos totales: 4502183
-- Ingreso promedio: 508.779
-- Costos totales: 3414526
-- Margen total: 1087666
-- Margen promedio: 122.914
--
-- Cancelled by Customer:
-- 10323 viajes
-- Sin ingresos asociados
-- Costos totales: 0
--
-- Cancelled by Driver:
-- 26547 viajes
-- Sin ingresos asociados
-- Costos totales: 0
--
-- No Driver Found:
-- 10314 viajes
-- Sin ingresos asociados
-- Costos totales: 0

-- Hallazgo:
-- Los viajes Completed concentran la mayor generación de ingresos
-- y margen debido a su mayor volumen.
-- Los viajes Incomplete presentan ingresos y margen promedio
-- muy similares a los viajes Completed, aunque con menor volumen.


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
-- Auto:
-- 36810 viajes
-- Ingresos totales: 12668559
-- Margen total: 3060684
-- Margen promedio: 122.466
--
-- Go Mini:
-- 29284 viajes
-- Ingresos totales: 10161819
-- Margen total: 2455035
-- Margen promedio: 122.65
--
-- Go Sedan:
-- 26723 viajes
-- Ingresos totales: 9226616
-- Margen total: 2229027
-- Margen promedio: 123.451
--
-- Bike:
-- 22143 viajes
-- Ingresos totales: 7699278
-- Margen total: 1860093
-- Margen promedio: 123.019
--
-- Premier Sedan:
-- 17824 viajes
-- Ingresos totales: 6176949
-- Margen total: 1492276
-- Margen promedio: 123.094
--
-- eBike:
-- 10376 viajes
-- Ingresos totales: 3557408
-- Margen total: 859453
-- Margen promedio: 121.8
--
-- Uber XL:
-- 4383 viajes
-- Ingresos totales: 1501324
-- Margen total: 362718
-- Margen promedio: 121.021

-- Hallazgo:
-- Auto genera el mayor ingreso y margen operativo total,
-- principalmente por su mayor volumen de viajes.
-- Go Sedan presenta el mayor margen operativo promedio por viaje,
-- mostrando una rentabilidad unitaria ligeramente superior.


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
GROUP BY mes
ORDER BY mes;

-- Resultado observado:
-- Enero:   margen total 1049554
-- Febrero: margen total 966361
-- Marzo:   margen total 1087588
-- Abril:   margen total 1011222
-- Mayo:    margen total 1025413
-- Junio:   margen total 1027772
-- Julio:   margen total 1039216
-- Agosto:  margen total 1009693
-- Septiembre: margen total 994577
-- Octubre: margen total 1048104
-- Noviembre: margen total 1032820
-- Diciembre: margen total 1026966

-- Hallazgo:
-- Marzo presenta el mayor margen operativo total del año.
-- Sin embargo, el volumen de viajes y el margen mensual se mantienen
-- relativamente estables durante 2024, sin una estacionalidad marcada.


-- =========================================================
-- 4. CONCLUSIONES DEL ANÁLISIS OPERATIVO
-- =========================================================

-- 1. Los viajes Completed concentran la mayor generación
--    de ingresos y margen operativo debido a su mayor volumen.
--
-- 2. Los viajes Incomplete también generan actividad económica,
--    con ingreso y margen promedio similares a los Completed.
--
-- 3. Auto lidera en ingresos y margen total.
--
-- 4. Go Sedan presenta el mayor margen promedio por viaje.
--
-- 5. Marzo fue el mes con mayor margen total.
--
-- 6. La evolución mensual muestra un comportamiento relativamente
--    estable durante 2024.