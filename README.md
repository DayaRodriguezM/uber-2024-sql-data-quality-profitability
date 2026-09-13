# Uber 2024 | Calidad de Datos SQL y Rentabilidad

Proyecto SQL enfocado en **calidad de datos, rentabilidad operativa y desempeño de campañas de marketing** utilizando datos de viajes de Uber correspondientes a 2024.

El análisis comenzó con una auditoría de calidad de datos que permitió identificar inconsistencias en la principal clave de unión (`booking_id`). Luego de evaluar su impacto, se construyó una base analítica depurada para calcular KPIs operativos y de marketing de manera confiable.

---

## 🎯 Objetivo del proyecto

Los principales objetivos fueron:

- Evaluar la calidad e integridad de tres conjuntos de datos relacionados.
- Identificar problemas que pudieran afectar las uniones y el cálculo de KPIs.
- Construir una base analítica depurada para el cálculo confiable de indicadores.
- Analizar volumen de viajes, ingresos, costos operativos y márgenes.
- Evaluar el desempeño de las campañas de marketing mediante contribución y ROMI.

---

## 🗂️ Fuentes de datos

El análisis se realizó utilizando tres tablas disponibles en el entorno SQL del bootcamp:

| Tabla | Descripción | Registros |
|---|---|---:|
| `uber_viajes_bookings` | Información del viaje, cliente, estado, vehículo, campaña, ingresos y distancia | 150.000 |
| `uber_costo_viajes` | Componentes de pago y costos operativos asociados a cada `booking_id` | 150.000 |
| `uber_campanas_mercadeo` | Descripción y costo de las campañas de marketing | 50 |

El período analizado corresponde al año **2024**.

---

## 🔍 Auditoría de calidad de datos

La primera etapa consistió en validar identificadores, valores nulos, reglas de negocio y consistencia entre las tablas.

### Hallazgo principal: inconsistencia en `booking_id`

Aunque `booking_id` debía identificar cada reserva individual, la auditoría encontró:

- **150.000** filas en la tabla de viajes.
- **148.767** `booking_id` distintos.
- **1.224** identificadores repetidos.
- **2.457** filas asociadas a identificadores repetidos.
- **1.233** ocurrencias adicionales.
- **1.215** identificadores aparecieron dos veces.
- **9** identificadores aparecieron tres veces.

La inspección mostró que estos casos no correspondían a duplicados exactos.

Un mismo `booking_id` podía estar asociado a diferentes:

- fechas y horas,
- clientes,
- campañas,
- tipos de vehículo,
- ubicaciones de origen y destino,
- estados del viaje.

Esto impedía establecer una relación uno a uno confiable entre viajes y costos.

![Booking ID inconsistente](images/01_booking_id_inconsistente.png)

### Hallazgos adicionales de calidad

- `valor_booking` y `distancia_booking` presentaban **48.000 valores nulos**, asociados principalmente a viajes cancelados o no ejecutados.
- Los viajes con estado `Incomplete` presentaban ingresos y distancia, lo que indica viajes iniciados o interrumpidos, y no simples cancelaciones.
- Los componentes de costos operativos presentaban el mismo patrón de **48.000 valores nulos**.
- `costo_total = 0` en esas 48.000 filas, consistente con registros sin actividad operativa.
- No se encontraron inconsistencias entre `costo_total` y la suma de sus componentes.
- La tabla de campañas contenía **50 campañas únicas**, sin identificadores nulos ni costos de campaña inválidos.

Consulta completa de auditoría:

[`01_data_quality_audit.sql`](sql/01_data_quality_audit.sql)

---

## 🧹 Estrategia de limpieza de datos

Una unión directa entre `uber_viajes_bookings` y `uber_costo_viajes` mediante `booking_id` generaba una relación **muchos-a-muchos** para los identificadores repetidos.

### JOIN sin tratamiento

La unión directa produjo:

- **152.484 filas**
- Ingresos: **52.712.901**
- Costos operativos: **39.977.868**
- Margen operativo: **12.948.588**

![JOIN sin limpieza](images/02_join_sin_limpieza.png)

El problema no podía resolverse seleccionando arbitrariamente uno de los registros repetidos, ya que la tabla de costos no contenía una fecha, cliente u otro identificador que permitiera determinar con certeza qué costo correspondía a cada viaje.

Por esta razón, se tomó la siguiente decisión metodológica:

> **Excluir de la base analítica integrada todos los registros asociados a `booking_id` inconsistentes, manteniendo intactas las tablas originales.**

### Base analítica depurada

Luego del tratamiento:

- **147.543 registros confiables**
- Ingresos: **50.991.953**
- Costos operativos: **38.672.667**
- Margen operativo: **12.319.286**

![Base analítica depurada](images/03_base_limpia.png)

Al comparar ambos escenarios, el JOIN sin tratamiento sobreestimaba aproximadamente:

- **3,4% de los ingresos**
- **3,4% de los costos operativos**
- **5,1% del margen operativo**

Esto demuestra cómo una inconsistencia relativamente pequeña en una clave de unión puede alterar de manera material los KPIs financieros.

Lógica de limpieza:

[`02_clean_analytical_base.sql`](sql/02_clean_analytical_base.sql)

---

## 📊 Preguntas de negocio

A partir de la base analítica depurada se plantearon cuatro preguntas principales:

1. ¿Cómo se distribuyen los viajes según estado, tipo de vehículo y período?
2. ¿Qué tipos de viaje generan mayores ingresos y margen operativo?
3. ¿Qué campañas concentran mayor volumen de viajes e ingresos?
4. ¿Qué campañas generan el mejor retorno considerando costos operativos y costo de marketing?

---

## 📈 Análisis operativo

### Estado de los viajes

Los viajes `Completed` concentraron la mayor generación de ingresos y margen operativo debido a su volumen.

Los viajes `Incomplete` también generaron ingresos y costos operativos, reforzando la hipótesis de que corresponden a viajes iniciados pero interrumpidos, en lugar de cancelaciones tradicionales.

### Desempeño por tipo de vehículo

**Auto** presentó el mayor ingreso y margen total debido a su volumen de viajes.

Sin embargo, **Go Sedan** obtuvo el mayor margen promedio por viaje, mostrando que el desempeño total y el desempeño unitario deben analizarse por separado.

### Evolución mensual

El comportamiento mensual durante 2024 fue relativamente estable y no mostró una estacionalidad marcada.

**Marzo** registró el mayor margen operativo total del año.

Consultas del análisis operativo:

[`03_operational_analysis.sql`](sql/03_operational_analysis.sql)

---

## 📣 Análisis de campañas de marketing

Para evitar duplicar el costo de una campaña por cada viaje asociado, primero se agregaron los resultados de viajes por `campana_id` y posteriormente se realizó la unión con la tabla de campañas.

### Métricas utilizadas

**Margen operativo**

```text
Ingresos - Costos operativos
```

**Contribución de campaña**

```text
Margen operativo - Costo de campaña
```

**ROMI**

```text
Contribución de campaña / Costo de campaña × 100
```

### Campañas con mayor ROMI

| Campaña | ROMI |
|---|---:|
| `DESCUENTO_UNIVERSITARIO_55` | 828,75% |
| `PROMO_ESCUDO_CLIMA_67` | 688,15% |
| `ESPECIAL_CARNAVAL_021` | 650,99% |
| `PAQUETE_BIENVENIDA_105` | 625,89% |
| `CELEBRACION_CUMPLEAÑOS_126` | 576,24% |

### Campañas con menor ROMI

| Campaña | ROMI |
|---|---:|
| `LANZAMIENTO_CDMX_2024_T3` | -69,70% |
| `AHORROS_PESOS_MX_191` | -53,75% |
| `IMPULSO_ECONOMIA_2024_18` | -40,47% |
| `PRIMER_VIAJE_GRATIS_2024` | -36,49% |
| `MAGIA_NAVIDAD_2024` | -24,99% |

![ROMI de campañas](images/04_campaign_romi.png)

Consultas del análisis de campañas:

[`04_campaign_analysis.sql`](sql/04_campaign_analysis.sql)

---

## 💡 Principales hallazgos

- Una clave de negocio duplicada puede generar relaciones muchos-a-muchos y distorsionar los KPIs aun cuando afecte a una proporción relativamente pequeña de registros.
- La validación de calidad debe realizarse antes del análisis de rentabilidad.
- Un mayor volumen de viajes no implica necesariamente una mayor rentabilidad promedio.
- `Auto` lidera en margen total debido a su escala, mientras que `Go Sedan` presenta el mayor margen promedio por viaje.
- Las campañas con mayor volumen o ingresos no necesariamente son las más eficientes.
- El ROMI permite evaluar el rendimiento de las campañas considerando también la inversión realizada en marketing.
- `DESCUENTO_UNIVERSITARIO_55` presentó el mayor ROMI debido a una alta contribución en relación con su costo de campaña.

---

## ⚠️ Limitaciones

Las tablas originales se encuentran disponibles únicamente dentro del entorno SQL del bootcamp y la plataforma no permite exportar los conjuntos de datos completos.

Por este motivo, los archivos fuente con los **150.000 registros** no se incluyen en este repositorio.

El repositorio contiene:

- consultas SQL utilizadas durante el análisis,
- evidencias de ejecución,
- documentación de calidad de datos,
- resultados agregados,
- tablas de KPIs,
- documentación complementaria.

Debido a que los datos originales no pueden redistribuirse, este repositorio debe considerarse un **caso analítico documentado**, y no un proyecto completamente reproducible fuera del entorno original.

---

## 🛠️ Herramientas y habilidades aplicadas

- **SQL**
- CTEs
- JOINs
- Agregaciones
- Lógica condicional
- Auditoría de calidad de datos
- Limpieza y preparación de datos
- Desarrollo de KPIs
- Análisis de rentabilidad
- Análisis de campañas
- ROMI
- Google Sheets
- GitHub

---

## 📂 Estructura del repositorio

```text
uber-2024-sql-data-quality-profitability/
│
├── README.md
│
├── sql/
│   ├── 01_data_quality_audit.sql
│   ├── 02_clean_analytical_base.sql
│   ├── 03_operational_analysis.sql
│   └── 04_campaign_analysis.sql
│
└── images/
    ├── 01_booking_id_inconsistente.png
    ├── 02_join_sin_limpieza.png
    ├── 03_base_limpia.png
    └── 04_campaign_romi.png
```

---

## 📎 Documentación complementaria

El proyecto cuenta con un Google Sheets que contiene:

- Diccionario de datos
- Auditoría de calidad
- Impacto de la limpieza
- KPIs operativos
- Resultados de campañas

👉 [Ver documentación y resultados en Google Sheets](https://docs.google.com/spreadsheets/d/1cV1tPN_8tjod6jmD0BccT3mNjbbvwWur6o29MVPij-0/edit?usp=sharing)

---

## 👩‍💻 Autora

**Dayana Rodríguez**

Data Analyst | SQL · Python · Power BI · Tableau · Excel

Este proyecto forma parte de mi portafolio de Data Analytics y busca demostrar cómo las decisiones relacionadas con la calidad de los datos pueden afectar directamente la confiabilidad de los indicadores y las conclusiones de negocio.
