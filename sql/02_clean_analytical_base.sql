-- =========================================================
-- 02. CLEAN ANALYTICAL BASE
-- Construcción de base analítica para viajes + costos
-- =========================================================


-- =========================================================
-- 1. JOIN SIN TRATAMIENTO DE BOOKING_ID REPETIDOS
-- =========================================================

WITH base_sin_limpieza AS (
    SELECT
        uvb.booking_id AS viaje_id,
        uvb.fecha,
        uvb.hora,
        uvb.cliente_id,
        uvb.estado_booking,
        uvb.tipo_vehiculo,
        uvb.campana_id,
        uvb.valor_booking AS ingresos,
        uvb.distancia_booking AS km_recorrido,
        ucv.costo_total,
        uvb.valor_booking - ucv.costo_total AS margen_operativo
    FROM uber_viajes_bookings uvb
    INNER JOIN uber_costo_viajes ucv
        ON uvb.booking_id = ucv.booking_id
)

SELECT
    COUNT(*) AS total_filas,
    SUM(ingresos::int) AS ingresos_totales,
    AVG(ingresos) AS ingreso_promedio,
    SUM(costo_total::int) AS costos_totales,
    AVG(costo_total) AS costo_promedio,
    SUM(margen_operativo::int) AS margen_total,
    AVG(margen_operativo) AS margen_promedio
FROM base_sin_limpieza;

-- Resultado observado:
-- 152484 filas
-- Ingresos totales: 52712901
-- Ingreso promedio: 508.488
-- Costos totales: 39977868
-- Costo promedio: 262.179
-- Margen total: 12948588
-- Margen promedio: 124.904

-- Hallazgo:
-- El JOIN directo genera más filas que las 150000 originales.
-- Esto ocurre porque los booking_id repetidos producen relaciones
-- muchos-a-muchos entre viajes y costos, inflando los KPIs.


-- =========================================================
-- 2. CONSTRUCCIÓN DE BASE ANALÍTICA LIMPIA
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
        uvb.hora,
        uvb.cliente_id,
        uvb.estado_booking,
        uvb.tipo_vehiculo,
        uvb.campana_id,
        uvb.valor_booking AS ingresos,
        uvb.distancia_booking AS km_recorrido,
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

SELECT *
FROM base_limpia;

-- Regla aplicada:
-- Se excluyen los booking_id con más de una aparición debido a que
-- no existe una llave secundaria que permita relacionar de forma
-- confiable cada viaje con su registro correspondiente de costos.


-- =========================================================
-- 3. KPIs DE LA BASE LIMPIA
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
        uvb.hora,
        uvb.cliente_id,
        uvb.estado_booking,
        uvb.tipo_vehiculo,
        uvb.campana_id,
        uvb.valor_booking AS ingresos,
        uvb.distancia_booking AS km_recorrido,
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
    COUNT(*) AS total_viajes_validos,
    SUM(ingresos::int) AS ingresos_totales,
    AVG(ingresos) AS ingreso_promedio,
    SUM(costo_total::int) AS costos_totales,
    AVG(costo_total) AS costo_promedio,
    SUM(margen_operativo::int) AS margen_total,
    AVG(margen_operativo) AS margen_promedio
FROM base_limpia;

-- Resultado observado:
-- 147543 viajes válidos
-- Ingresos totales: 50991953
-- Ingreso promedio: 508.095
-- Costos totales: 38672667
-- Costo promedio: 262.113
-- Margen total: 12319286
-- Margen promedio: 122.749


-- =========================================================
-- 4. IMPACTO DE LA LIMPIEZA
-- =========================================================

-- JOIN sin limpieza:
-- 152484 filas
-- Ingresos: 52712901
-- Costos:   39977868
-- Margen:   12948588

-- Base analítica limpia:
-- 147543 filas
-- Ingresos: 50991953
-- Costos:   38672667
-- Margen:   12319286

-- Conclusión:
-- La exclusión de booking_id inconsistentes evita la multiplicación
-- de registros causada por una relación muchos-a-muchos y reduce
-- la sobreestimación de ingresos, costos y margen operativo.