-- =========================================================
-- 01. DATA QUALITY AUDIT
-- Tabla: uber_viajes_bookings
-- =========================================================


-- =========================================================
-- 1. VALIDACIÓN DE UNICIDAD DE BOOKING_ID
-- =========================================================

SELECT
    COUNT(*) AS total_registros,
    COUNT(DISTINCT booking_id) AS booking_id_unicos
FROM uber_viajes_bookings;

-- Resultado observado:
-- 150000 registros
-- 148767 booking_id únicos


-- =========================================================
-- 2. IDENTIFICACIÓN DE BOOKING_ID REPETIDOS
-- =========================================================

WITH bookings_repetidos AS (
    SELECT
        booking_id,
        COUNT(*) AS cantidad_registros
    FROM uber_viajes_bookings
    GROUP BY booking_id
    HAVING COUNT(*) > 1
)

SELECT
    COUNT(*) AS booking_id_repetidos,
    SUM(cantidad_registros) AS registros_involucrados,
    SUM(cantidad_registros - 1) AS registros_excedentes,
    MAX(cantidad_registros) AS max_repeticiones
FROM bookings_repetidos;

-- Resultado observado:
-- 1224 booking_id repetidos
-- 2457 registros involucrados
-- 1233 registros excedentes
-- Máximo de 3 apariciones


-- =========================================================
-- 3. DISTRIBUCIÓN DE ESTADO_BOOKING
-- =========================================================

SELECT
    estado_booking,
    COUNT(*) AS cantidad
FROM uber_viajes_bookings
GROUP BY estado_booking
ORDER BY cantidad DESC;

-- Resultado observado:
-- 93000 Completed
-- 27000 Cancelled by Driver
-- 10500 Cancelled by Customer
-- 10500 No Driver Found
-- 9000 Incomplete


-- =========================================================
-- 4. DISTRIBUCIÓN DE TIPO_VEHICULO
-- =========================================================

SELECT
    tipo_vehiculo,
    COUNT(*) AS cantidad
FROM uber_viajes_bookings
GROUP BY tipo_vehiculo
ORDER BY cantidad DESC;

-- Resultado observado:
-- 37419 Auto
-- 29806 Go Mini
-- 27141 Go Sedan
-- 22517 Bike
-- 18111 Premier Sedan
-- 10557 eBike
-- 4449 Uber XL


-- =========================================================
-- 5. INGRESOS Y VALORES NULOS
-- =========================================================

SELECT
    COUNT(*) AS total_registros,
    COUNT(valor_booking) AS con_ingresos,
    COUNT(*) - COUNT(valor_booking) AS nulos
FROM uber_viajes_bookings;

-- Resultado observado:
-- 150000 registros
-- 102000 con ingresos
-- 48000 nulos


-- =========================================================
-- 6. DISTANCIA RECORRIDA
-- =========================================================

SELECT
    MIN(distancia_booking) AS km_min,
    MAX(distancia_booking) AS km_max,
    AVG(distancia_booking) AS km_promedio
FROM uber_viajes_bookings
WHERE distancia_booking IS NOT NULL;

-- Resultado observado:
-- Distancia mínima: 1 km
-- Distancia máxima: 50 km
-- Distancia promedio: 24.637 km


-- =========================================================
-- 7. ESTADO DE VIAJES CON INGRESOS Y NULOS
-- =========================================================

SELECT
    estado_booking,
    COUNT(*) AS total,
    COUNT(valor_booking) AS con_ingresos,
    COUNT(*) - COUNT(valor_booking) AS nulos
FROM uber_viajes_bookings
GROUP BY estado_booking
ORDER BY total DESC;

-- Resultado observado:
-- Completed: 93000 registros, todos con ingresos.
-- Cancelled by Driver: 27000 registros, todos con valor_booking nulo.
-- Cancelled by Customer: 10500 registros, todos con valor_booking nulo.
-- No Driver Found: 10500 registros, todos con valor_booking nulo.
-- Incomplete: 9000 registros, todos con ingresos.


-- =========================================================
-- 8. ESTADO DE VIAJES CON DISTANCIA RECORRIDA
-- =========================================================

SELECT
    estado_booking,
    COUNT(*) AS total,
    COUNT(distancia_booking) AS con_distancia,
    COUNT(*) - COUNT(distancia_booking) AS km_nulos
FROM uber_viajes_bookings
GROUP BY estado_booking
ORDER BY total DESC;

-- Resultado observado:
-- Completed: 93000 registros, todos con distancia.
-- Cancelled by Driver: 27000 registros, todos con distancia nula.
-- Cancelled by Customer: 10500 registros, todos con distancia nula.
-- No Driver Found: 10500 registros, todos con distancia nula.
-- Incomplete: 9000 registros, todos con distancia.


-- =========================================================
-- 9. COMPARACIÓN DE VIAJES COMPLETED VS INCOMPLETE
-- =========================================================

SELECT
    estado_booking,
    COUNT(*) AS cantidad,
    MIN(valor_booking) AS valor_min,
    MAX(valor_booking) AS valor_max,
    AVG(valor_booking) AS valor_promedio,
    MIN(distancia_booking) AS distancia_min,
    MAX(distancia_booking) AS distancia_max,
    AVG(distancia_booking) AS distancia_promedio
FROM uber_viajes_bookings
WHERE estado_booking IN ('Completed', 'Incomplete')
GROUP BY estado_booking;

-- Resultado observado:
-- Completed:
-- 93000 registros
-- Ingreso mínimo: 50
-- Ingreso máximo: 4277
-- Ingreso promedio: 508.178
-- Distancia mínima: 2 km
-- Distancia máxima: 50 km
-- Distancia promedio: 26.0005 km
--
-- Incomplete:
-- 9000 registros
-- Ingreso mínimo: 50
-- Ingreso máximo: 3878
-- Ingreso promedio: 509.512
-- Distancia mínima: 1 km
-- Distancia máxima: 20 km
-- Distancia promedio: 10.5477 km


-- =========================================================
-- 10. CAUSAS DE VIAJES INCOMPLETOS
-- =========================================================

SELECT
    razon_viajes_incompletos,
    COUNT(*) AS cantidad
FROM uber_viajes_bookings
WHERE estado_booking = 'Incomplete'
GROUP BY razon_viajes_incompletos
ORDER BY cantidad DESC;

-- Resultado observado:
-- 3040 Customer Demand
-- 3012 Vehicle Breakdown
-- 2948 Other Issue

-- =========================================================
-- 11. REVISIÓN DE BOOKING_ID REPETIDOS
-- =========================================================

SELECT *
FROM uber_viajes_bookings
WHERE booking_id = 'CNR6337479'
ORDER BY fecha, hora;

-- Hallazgo:
-- El mismo booking_id aparece asociado a diferentes fechas,
-- clientes, campañas, tipos de vehículo, orígenes y destinos.
-- Por lo tanto, no corresponde a un duplicado exacto,
-- sino a una posible reutilización o asignación incorrecta
-- del identificador booking_id.


-- =========================================================
-- Tabla: uber_costo_viajes
-- =========================================================


-- =========================================================
-- 1. VALIDACIÓN DE UNICIDAD DE BOOKING_ID
-- =========================================================

SELECT
    COUNT(*) AS total_registros,
    COUNT(DISTINCT booking_id) AS booking_id_unicos
FROM uber_costo_viajes;

-- Resultado observado:
-- 150000 registros
-- 148767 booking_id únicos


-- =========================================================
-- 2. COMPLETITUD DE VARIABLES DE COSTO
-- =========================================================

SELECT
    COUNT(*) AS total,
    COUNT(pago_chofer) AS pago_chofer_con_dato,
    COUNT(costo_gasolina) AS gasolina_con_dato,
    COUNT(mantenimiento_l) AS mantenimiento_con_dato,
    COUNT(depreciacion_ve) AS depreciacion_con_dato,
    COUNT(costo_seguro) AS seguro_con_dato,
    COUNT(costo_total) AS costo_total_con_dato
FROM uber_costo_viajes;

-- Resultado observado:
-- 150000 registros totales
-- 102000 registros con pago_chofer
-- 102000 registros con costo_gasolina
-- 102000 registros con mantenimiento
-- 102000 registros con depreciación
-- 102000 registros con costo_seguro
-- 150000 registros con costo_total


-- =========================================================
-- 3. VALIDACIÓN DE NULOS
-- =========================================================

SELECT
    COUNT(*) - COUNT(pago_chofer) AS nulos_pago_chofer,
    COUNT(*) - COUNT(costo_gasolina) AS nulos_gasolina,
    COUNT(*) - COUNT(mantenimiento_l) AS nulos_mantenimiento,
    COUNT(*) - COUNT(depreciacion_ve) AS nulos_depreciacion,
    COUNT(*) - COUNT(costo_seguro) AS nulos_seguro,
    COUNT(*) - COUNT(costo_total) AS nulos_costo_total
FROM uber_costo_viajes;

-- Resultado observado:
-- 48000 nulos en pago_chofer
-- 48000 nulos en costo_gasolina
-- 48000 nulos en mantenimiento
-- 48000 nulos en depreciación
-- 48000 nulos en costo_seguro
-- 0 nulos en costo_total


-- =========================================================
-- 4. REGISTROS CON COSTO_TOTAL = 0
-- =========================================================

SELECT
    COUNT(*) AS registros_costo_cero
FROM uber_costo_viajes
WHERE costo_total = 0;

-- Resultado observado:
-- 48000 registros


-- =========================================================
-- 5. DISTRIBUCIÓN DE COSTOS
-- =========================================================

SELECT
    MIN(pago_chofer) AS min_pago,
    MAX(pago_chofer) AS max_pago,
    AVG(pago_chofer) AS avg_pago,
    MIN(costo_gasolina) AS min_gasolina,
    MAX(costo_gasolina) AS max_gasolina,
    MIN(costo_total) AS min_total,
    MAX(costo_total) AS max_total,
    AVG(costo_total) AS avg_total
FROM uber_costo_viajes;

-- Resultado observado:
-- Pago mínimo al chofer: 35
-- Pago máximo al chofer: 2993.9
-- Pago promedio al chofer: 355.807
-- Costo mínimo de gasolina: 2.5
-- Costo máximo de gasolina: 213.85
-- Costo total mínimo: 0
-- Costo total máximo: 3243.73
-- Costo total promedio: 262.139


-- =========================================================
-- 6. VALIDACIÓN DE CONSISTENCIA ARITMÉTICA
-- =========================================================

SELECT
    COUNT(*) AS registros_inconsistentes
FROM uber_costo_viajes
WHERE costo_total IS NOT NULL
  AND ROUND(costo_total, 3) <>
      ROUND(
          COALESCE(pago_chofer, 0)
        + COALESCE(costo_gasolina, 0)
        + COALESCE(mantenimiento_l, 0)
        + COALESCE(depreciacion_ve, 0)
        + COALESCE(costo_seguro, 0),
        3
      );

-- Resultado observado:
-- 0 registros inconsistentes


-- =========================================================
-- 7. IDENTIFICACIÓN DE BOOKING_ID REPETIDOS
-- =========================================================

WITH repetidos AS (
    SELECT
        booking_id,
        COUNT(*) AS cantidad
    FROM uber_costo_viajes
    GROUP BY booking_id
    HAVING COUNT(*) > 1
)

SELECT
    COUNT(*) AS booking_id_repetidos,
    SUM(cantidad) AS registros_involucrados,
    SUM(cantidad - 1) AS registros_excedentes,
    MAX(cantidad) AS max_repeticiones
FROM repetidos;

-- Resultado observado:
-- 1224 booking_id repetidos
-- 2457 registros involucrados
-- 1233 registros excedentes
-- Máximo de 3 apariciones

-- =========================================================
-- 8. VALIDACIÓN DE BOOKING_ID REPETIDOS ENTRE TABLAS
-- =========================================================

WITH repetidos_viajes AS (
    SELECT booking_id
    FROM uber_viajes_bookings
    GROUP BY booking_id
    HAVING COUNT(*) > 1
),

repetidos_costos AS (
    SELECT booking_id
    FROM uber_costo_viajes
    GROUP BY booking_id
    HAVING COUNT(*) > 1
)

SELECT
    COUNT(*) AS booking_repetidos_en_ambas
FROM repetidos_viajes rv
INNER JOIN repetidos_costos rc
    ON rv.booking_id = rc.booking_id;

-- Resultado observado:
-- 1224 booking_id repetidos coinciden en ambas tablas

-- =========================================================
-- Tabla: uber_campanas_mercadeo
-- =========================================================


-- =========================================================
-- 1. VALIDACIÓN DE UNICIDAD DE CAMPANA_ID
-- =========================================================

SELECT
    COUNT(*) AS total_registros,
    COUNT(DISTINCT campana_id) AS campanas_unicas,
    COUNT(DISTINCT campana_descripcion) AS descripciones_unicas
FROM uber_campanas_mercadeo;

-- Resultado observado:
-- 50 registros totales
-- 50 campana_id únicos
-- 50 descripciones de campaña únicas


-- =========================================================
-- 2. VALIDACIÓN DE NULOS
-- =========================================================

SELECT
    COUNT(*) - COUNT(campana_id) AS nulos_id,
    COUNT(*) - COUNT(campana_descripcion) AS nulos_descripcion,
    COUNT(*) - COUNT(costo_campana) AS nulos_costo
FROM uber_campanas_mercadeo;

-- Resultado observado:
-- 0 campana_id nulos
-- 0 descripciones nulas
-- 0 costos nulos


-- =========================================================
-- 3. DISTRIBUCIÓN DE COSTOS DE CAMPAÑA
-- =========================================================

SELECT
    MIN(costo_campana) AS costo_min,
    MAX(costo_campana) AS costo_max,
    AVG(costo_campana) AS costo_promedio
FROM uber_campanas_mercadeo;

-- Resultado observado:
-- Costo mínimo: 27300
-- Costo máximo: 777000
-- Costo promedio: 126420


-- =========================================================
-- 4. VALIDACIÓN DE COSTOS NO VÁLIDOS
-- =========================================================

SELECT
    COUNT(*) AS costos_no_validos
FROM uber_campanas_mercadeo
WHERE costo_campana <= 0;

-- Resultado observado:
-- 0 costos no válidos


