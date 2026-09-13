-- =========================================================
-- 04. CAMPAIGN ANALYSIS
-- Análisis de volumen, ingresos y retorno de campañas
-- =========================================================


-- =========================================================
-- 1. CONSTRUCCIÓN DE BASE LIMPIA Y MÉTRICAS POR CAMPAÑA
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
        uvb.campana_id,
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

metricas_campana AS (
    SELECT
        campana_id,
        COUNT(*) AS cantidad_viajes,
        SUM(ingresos::int) AS ingresos_totales,
        SUM(costo_total::int) AS costos_operativos,
        SUM(margen_operativo::int) AS margen_operativo_total
    FROM base_limpia
    GROUP BY campana_id
)

SELECT
    mc.campana_id,
    ucm.campana_descripcion,
    mc.cantidad_viajes,
    mc.ingresos_totales,
    mc.costos_operativos,
    mc.margen_operativo_total,
    ucm.costo_campana
FROM metricas_campana mc
INNER JOIN uber_campanas_mercadeo ucm
    ON mc.campana_id = ucm.campana_id
ORDER BY mc.ingresos_totales DESC;

-- Hallazgo:
-- Las campañas presentan volúmenes e ingresos relativamente similares.
-- No existe una campaña que concentre de manera dominante la demanda.


-- =========================================================
-- 2. CAMPAÑAS CON MAYOR VOLUMEN
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
        uvb.campana_id,
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

metricas_campana AS (
    SELECT
        campana_id,
        COUNT(*) AS cantidad_viajes,
        SUM(ingresos::int) AS ingresos_totales,
        SUM(costo_total::int) AS costos_operativos,
        SUM(margen_operativo::int) AS margen_operativo_total
    FROM base_limpia
    GROUP BY campana_id
)

SELECT
    mc.campana_id,
    ucm.campana_descripcion,
    mc.cantidad_viajes,
    mc.ingresos_totales,
    mc.margen_operativo_total,
    ucm.costo_campana
FROM metricas_campana mc
INNER JOIN uber_campanas_mercadeo ucm
    ON mc.campana_id = ucm.campana_id
ORDER BY mc.cantidad_viajes DESC;

-- Resultado observado:
-- VIAJES_DIA_MADRES_58: 3061 viajes
-- PAJARO_TEMPRANERO_42: 3061 viajes
-- BIENVENIDA_NOVATO_841: 3049 viajes
-- PRIMER_VIAJE_GRATIS_2024: 3042 viajes
-- TRABAJADORES_TECH_83: 3041 viajes

-- Hallazgo:
-- VIAJES_DIA_MADRES_58 y PAJARO_TEMPRANERO_42
-- presentan el mayor volumen de viajes, con 3061 cada una.


-- =========================================================
-- 3. CAMPAÑAS CON MAYORES INGRESOS
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
        uvb.campana_id,
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

metricas_campana AS (
    SELECT
        campana_id,
        COUNT(*) AS cantidad_viajes,
        SUM(ingresos::int) AS ingresos_totales,
        SUM(costo_total::int) AS costos_operativos,
        SUM(margen_operativo::int) AS margen_operativo_total
    FROM base_limpia
    GROUP BY campana_id
)

SELECT
    mc.campana_id,
    ucm.campana_descripcion,
    mc.cantidad_viajes,
    mc.ingresos_totales,
    mc.margen_operativo_total,
    ucm.costo_campana
FROM metricas_campana mc
INNER JOIN uber_campanas_mercadeo ucm
    ON mc.campana_id = ucm.campana_id
ORDER BY mc.ingresos_totales DESC;

-- Resultado observado:
-- ESPECIAL_EXTRANJEROS_71: 1069189
-- VIAJES_DIA_MADRES_58: 1064403
-- PAJARO_TEMPRANERO_42: 1063224

-- Hallazgo:
-- ESPECIAL_EXTRANJEROS_71 genera el mayor ingreso total.
-- Las diferencias entre las campañas líderes son relativamente pequeñas.


-- =========================================================
-- 4. CONTRIBUCIÓN Y ROMI POR CAMPAÑA
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
        uvb.campana_id,
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

metricas_campana AS (
    SELECT
        campana_id,
        COUNT(*) AS cantidad_viajes,
        SUM(ingresos::int) AS ingresos_totales,
        SUM(costo_total::int) AS costos_operativos,
        SUM(margen_operativo::int) AS margen_operativo_total
    FROM base_limpia
    GROUP BY campana_id
)

SELECT
    mc.campana_id,
    ucm.campana_descripcion,
    mc.cantidad_viajes,
    mc.ingresos_totales,
    mc.costos_operativos,
    mc.margen_operativo_total,
    ucm.costo_campana,
    mc.margen_operativo_total - ucm.costo_campana
        AS contribucion_campana,
    ROUND(
        (
            (mc.margen_operativo_total - ucm.costo_campana)
            / ucm.costo_campana::numeric
        ) * 100,
        2
    ) AS romi_pct
FROM metricas_campana mc
INNER JOIN uber_campanas_mercadeo ucm
    ON mc.campana_id = ucm.campana_id
ORDER BY romi_pct DESC;

-- Resultado observado:
-- DESCUENTO_UNIVERSITARIO_55: ROMI 828.75%
-- PROMO_ESCUDO_CLIMA_67: ROMI 688.15%
-- ESPECIAL_CARNAVAL_021: ROMI 650.99%
-- PAQUETE_BIENVENIDA_105: ROMI 625.89%
-- CELEBRACION_CUMPLEAÑOS_126: ROMI 576.24%

-- Hallazgo:
-- DESCUENTO_UNIVERSITARIO_55 presenta el mejor retorno de marketing.
-- Su alto ROMI se explica por una contribución elevada en relación
-- con un costo de campaña relativamente bajo.


-- =========================================================
-- 5. CAMPAÑAS CON ROMI NEGATIVO
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
        uvb.campana_id,
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

metricas_campana AS (
    SELECT
        campana_id,
        COUNT(*) AS cantidad_viajes,
        SUM(ingresos::int) AS ingresos_totales,
        SUM(costo_total::int) AS costos_operativos,
        SUM(margen_operativo::int) AS margen_operativo_total
    FROM base_limpia
    GROUP BY campana_id
)

SELECT
    mc.campana_id,
    ucm.campana_descripcion,
    mc.cantidad_viajes,
    mc.ingresos_totales,
    mc.margen_operativo_total,
    ucm.costo_campana,
    mc.margen_operativo_total - ucm.costo_campana
        AS contribucion_campana,
    ROUND(
        (
            (mc.margen_operativo_total - ucm.costo_campana)
            / ucm.costo_campana::numeric
        ) * 100,
        2
    ) AS romi_pct
FROM metricas_campana mc
INNER JOIN uber_campanas_mercadeo ucm
    ON mc.campana_id = ucm.campana_id
ORDER BY romi_pct ASC;

-- Resultado observado:
-- LANZAMIENTO_CDMX_2024_T3: -69.70%
-- AHORROS_PESOS_MX_191: -53.75%
-- IMPULSO_ECONOMIA_2024_18: -40.47%
-- PRIMER_VIAJE_GRATIS_2024: -36.49%
-- MAGIA_NAVIDAD_2024: -24.99%

-- Hallazgo:
-- Algunas campañas generan un volumen e ingresos relevantes,
-- pero su elevada inversión de marketing supera la contribución
-- generada después de costos operativos, produciendo ROMI negativo.


-- =========================================================
-- 6. CONCLUSIONES DEL ANÁLISIS DE CAMPAÑAS
-- =========================================================

-- 1. VIAJES_DIA_MADRES_58 y PAJARO_TEMPRANERO_42
--    presentan el mayor volumen de viajes.
--
-- 2. ESPECIAL_EXTRANJEROS_71 genera el mayor ingreso total.
--
-- 3. DESCUENTO_UNIVERSITARIO_55 presenta el mayor ROMI,
--    con 828.75%.
--
-- 4. Un mayor volumen o ingreso no implica necesariamente
--    un mejor retorno de marketing.
--
-- 5. Algunas campañas de alta inversión presentan ROMI negativo,
--    por lo que deberían revisarse antes de mantener o aumentar
--    su presupuesto.