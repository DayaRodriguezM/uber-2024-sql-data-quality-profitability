# Uber 2024 | SQL Data Quality & Profitability

Proyecto de análisis de datos enfocado en **calidad de datos, rentabilidad operativa y desempeño de campañas de marketing**, utilizando información de viajes de Uber correspondiente a 2024.

El análisis comenzó con una auditoría de calidad que permitió identificar inconsistencias en la principal clave de unión (`booking_id`). Antes de calcular indicadores financieros o comerciales, se evaluó el impacto de estas inconsistencias y se construyó una base analítica depurada para trabajar con KPIs confiables.

> **Hallazgo principal:** una relación muchos-a-muchos provocada por `booking_id` inconsistentes sobreestimaba el margen operativo en aproximadamente **5,1%**.

---

## 🎯 Objetivo del proyecto

El proyecto busca responder cuatro preguntas principales:

1. ¿La calidad de los datos permite construir una base analítica confiable?
2. ¿Qué estados y tipos de vehículo generan mayor contribución económica?
3. ¿Cómo evoluciona la rentabilidad operativa durante el año?
4. ¿Qué campañas de marketing generan mayor retorno considerando costos operativos e inversión?

El análisis se desarrolló en cuatro etapas:

- Auditoría de calidad de datos.
- Construcción de una base analítica depurada.
- Análisis operativo y temporal.
- Evaluación de campañas mediante contribución y ROMI.

---

## 📁 Fuentes de datos

El análisis utiliza tres tablas disponibles en el entorno SQL del bootcamp:

| Tabla | Descripción | Registros |
|---|---|---:|
| `uber_viajes_bookings` | Información del viaje, cliente, estado, vehículo, campaña, ingresos y distancia | 150.000 |
| `uber_costo_viajes` | Componentes de costos operativos asociados a cada `booking_id` | 150.000 |
| `uber_campanas_mercadeo` | Descripción y costo de las campañas de marketing | 50 |

**Período analizado:** 2024.

---

# 🔎 1. Auditoría de calidad de datos

Antes de calcular KPIs se validaron:

- unicidad de identificadores,
- valores nulos,
- consistencia de costos,
- estados de viaje,
- correspondencia entre tablas,
- validez de las claves utilizadas en los `JOIN`.

## Hallazgo principal: inconsistencia en `booking_id`

La auditoría encontró:

| Indicador | Resultado |
|---|---:|
| Registros en tabla de viajes | 150.000 |
| `booking_id` distintos | 148.767 |
| Identificadores repetidos | 1.224 |
| Registros involucrados | 2.457 |
| Ocurrencias adicionales | 1.233 |
| Máximo de apariciones por ID | 3 |

La inspección mostró que estos registros **no correspondían a duplicados exactos**.

Un mismo `booking_id` podía estar asociado a diferentes:

- clientes,
- fechas y horas,
- campañas,
- tipos de vehículo,
- estados del viaje,
- ubicaciones de origen y destino.

Por lo tanto, `booking_id` no podía utilizarse como una llave uno-a-uno confiable para relacionar viajes y costos en esos casos.

### Hallazgos adicionales de calidad

- `valor_booking` y `distancia_booking` presentaban **48.000 valores nulos**.
- Los valores nulos estaban asociados principalmente a viajes cancelados o no ejecutados.
- Los viajes con estado `Incomplete` sí presentaban ingresos y distancia.
- Los componentes de costos operativos mostraban el mismo patrón de **48.000 valores nulos**.
- `costo_total = 0` en esas 48.000 filas, consistente con registros sin actividad operativa.
- No se encontraron inconsistencias entre `costo_total` y la suma de sus componentes.
- Las 50 campañas presentaban identificadores únicos, sin valores nulos y con costos válidos.

📄 [Ver auditoría completa en SQL](sql/01_data_quality_audit.sql)

📎 [Ver documentación y resultados en Google Sheets](TU_LINK_DE_GOOGLE_SHEETS)

---

# 🧹 2. Estrategia de limpieza e impacto en los KPIs

Una unión directa entre `uber_viajes_bookings` y `uber_costo_viajes` mediante `booking_id` generaba una relación **muchos-a-muchos** para los identificadores inconsistentes.

El problema no podía resolverse seleccionando arbitrariamente el primer o último registro, ya que la tabla de costos no incluía una llave secundaria —como fecha, cliente u otro identificador— que permitiera determinar con certeza qué costo correspondía a cada viaje.

Por esta razón se tomó la siguiente decisión metodológica:

> **Excluir de la base analítica integrada los registros asociados a `booking_id` inconsistentes, manteniendo intactas las tablas originales.**

## Impacto de la limpieza

| Indicador | JOIN sin tratamiento | Base analítica depurada | Impacto | Sobreestimación |
|---|---:|---:|---:|---:|
| Registros resultantes | 152.484 | 147.543 | +4.941 | 3,35% |
| Ingresos totales | 52.712.901 | 50.991.953 | +1.720.948 | 3,37% |
| Costos operativos | 39.977.868 | 38.672.667 | +1.305.201 | 3,37% |
| Margen operativo | 12.948.588 | 12.319.286 | +629.302 | **5,11%** |

### Insight

Aunque la inconsistencia afectaba una proporción relativamente pequeña de identificadores, su impacto sobre los indicadores financieros era material.

El JOIN sin tratamiento sobreestimaba aproximadamente:

- **3,4% de los ingresos**
- **3,4% de los costos**
- **5,1% del margen operativo**

> Una falla en una clave de unión puede alterar significativamente la interpretación financiera del negocio incluso cuando afecta una fracción pequeña de los registros.

📄 [Ver lógica de limpieza y construcción de la base analítica](sql/02_clean_analytical_base.sql)

📎 [Ver comparación completa en Google Sheets](TU_LINK_DE_GOOGLE_SHEETS)

---

# 📊 3. Análisis operativo

Una vez construida la base analítica depurada, se analizaron estados de viaje, tipos de vehículo y comportamiento temporal.

## Estado de los viajes

Los estados `Completed` e `Incomplete` fueron los únicos que presentaron actividad económica relevante.

| Estado | Viajes | Ingresos | Costos operativos | Margen total | Margen promedio |
|---|---:|---:|---:|---:|---:|
| `Completed` | 91.510 | 46.489.770 | 35.258.141 | 11.231.629 | 122,73 |
| `Incomplete` | 8.849 | 4.502.183 | 3.414.526 | 1.087.666 | 122,91 |

Los estados `Cancelled by Customer`, `Cancelled by Driver` y `No Driver Found` no presentaron ingresos ni costos operativos asociados.

### Insight

Los viajes `Incomplete` no deben interpretarse como simples cancelaciones.

Aunque representan un volumen mucho menor, presentan ingresos, costos y un margen promedio prácticamente equivalente al de los viajes `Completed`, lo que sugiere viajes iniciados pero interrumpidos.

---

## Desempeño por tipo de vehículo

Para evaluar el desempeño se analizaron dos perspectivas:

- **contribución total al margen**, influenciada por el volumen;
- **margen promedio por viaje**, como aproximación a la rentabilidad unitaria.

| Tipo de vehículo | Viajes | Margen total | Margen promedio | Rank margen total | Rank margen promedio |
|---|---:|---:|---:|---:|---:|
| Auto | 36.810 | 3.060.684 | 122,47 | **1** | 5 |
| Go Mini | 29.284 | 2.455.035 | 122,65 | 2 | 4 |
| Go Sedan | 26.723 | 2.229.027 | **123,45** | 3 | **1** |
| Bike | 22.143 | 1.860.093 | 123,02 | 4 | 3 |
| Premier Sedan | 17.824 | 1.492.276 | 123,09 | 5 | 2 |
| eBike | 10.376 | 859.453 | 121,80 | 6 | 6 |
| Uber XL | 4.383 | 362.718 | 121,02 | 7 | 7 |

### Window Function: `RANK()`

Para comparar ambas dimensiones se utilizaron funciones de ventana:

    RANK() OVER (ORDER BY margen_total DESC)

    RANK() OVER (ORDER BY margen_promedio DESC)

### Insight

**Auto** ocupa el primer lugar en margen total debido principalmente a su escala, pero solo el quinto en margen promedio.

**Go Sedan**, en cambio, ocupa el tercer lugar en contribución total y el **primer lugar en margen promedio por viaje**.

**Premier Sedan** también muestra esta diferencia: quinto en margen total y segundo en margen promedio.

> **Mayor volumen no implica necesariamente mayor rentabilidad unitaria.**

Este resultado sugiere que las decisiones operativas deberían considerar simultáneamente escala y eficiencia por viaje.

---

## Evolución mensual del margen operativo

El margen mensual se mantuvo relativamente estable durante 2024.

| Mes | Viajes | Margen total | Variación vs. mes anterior |
|---|---:|---:|---:|
| Enero | 12.664 | 1.049.554 | — |
| Febrero | 11.708 | 966.361 | **-7,93%** |
| Marzo | 12.510 | **1.087.588** | **+12,54%** |
| Abril | 12.000 | 1.011.222 | -7,02% |
| Mayo | 12.569 | 1.025.413 | +1,40% |
| Junio | 12.235 | 1.027.772 | +0,23% |
| Julio | 12.704 | 1.039.216 | +1,11% |
| Agosto | 12.431 | 1.009.693 | -2,84% |
| Septiembre | 12.051 | 994.577 | -1,50% |
| Octubre | 12.424 | 1.048.104 | +5,38% |
| Noviembre | 12.200 | 1.032.820 | -1,46% |
| Diciembre | 12.047 | 1.026.966 | -0,57% |

### Window Function: `LAG()`

Para comparar cada periodo con el inmediatamente anterior se utilizó:

    LAG(margen_total) OVER (ORDER BY mes)

### Insight

Marzo presentó:

- el **mayor margen operativo del año: 1.087.588**
- la **mayor variación positiva mensual: +12,54%**

Febrero registró la mayor caída, con **-7,93%** respecto a enero.

A partir de mayo, la mayoría de las variaciones se mantuvo dentro de un rango relativamente acotado, excepto octubre con un crecimiento de **5,38%**.

> El comportamiento anual fue relativamente estable y no muestra evidencia de una estacionalidad pronunciada.

📄 [Ver análisis operativo completo](sql/03_operational_analysis.sql)

📎 [Ver resultados agregados en Google Sheets](TU_LINK_DE_GOOGLE_SHEETS)

---

# 📣 4. Análisis de campañas de marketing

El análisis de campañas buscó determinar si aquellas con mayor volumen o ingresos eran también las que generaban mayor retorno.

Para evitar duplicar el costo de una campaña por cada viaje asociado, primero se agregaron los resultados por `campana_id` y posteriormente se realizó la unión con la tabla de campañas.

## Métricas utilizadas

### Margen operativo

    Ingresos - Costos operativos

### Contribución de campaña

    Margen operativo - Costo de campaña

### ROMI

    Contribución de campaña / Costo de campaña × 100

---

## Campañas con mayor ROMI

| Campaña | ROMI |
|---|---:|
| `DESCUENTO_UNIVERSITARIO_55` | **828,75%** |
| `PROMO_ESCUDO_CLIMA_67` | 688,15% |
| `ESPECIAL_CARNAVAL_021` | 650,99% |
| `PAQUETE_BIENVENIDA_105` | 625,89% |
| `CELEBRACION_CUMPLEAÑOS_126` | 576,24% |

## Campañas con menor ROMI

| Campaña | ROMI |
|---|---:|
| `LANZAMIENTO_CDMX_2024_T3` | **-69,70%** |
| `AHORROS_PESOS_MX_191` | -53,75% |
| `IMPULSO_ECONOMIA_2024_18` | -40,47% |
| `PRIMER_VIAJE_GRATIS_2024` | -36,49% |
| `MAGIA_NAVIDAD_2024` | -24,99% |

### Insight

`DESCUENTO_UNIVERSITARIO_55` presenta el mayor retorno de marketing debido a una contribución elevada en relación con su costo de campaña.

En contraste, algunas campañas con volumen e ingresos relevantes presentan ROMI negativo porque la inversión realizada supera la contribución generada después de costos operativos.

> **Mayor volumen o mayores ingresos no implican necesariamente mayor eficiencia de marketing.**

📄 [Ver análisis completo de campañas](sql/04_campaign_analysis.sql)

📎 [Ver resultados y KPIs de campañas en Google Sheets](TU_LINK_DE_GOOGLE_SHEETS)

---

# 💡 5. Principales insights accionables

## 1. Implementar controles de calidad sobre claves de unión

La inconsistencia en `booking_id` provocaba una sobreestimación del margen operativo de **5,1%**.

**Acción sugerida:** incorporar controles de unicidad y validación de claves antes de integrar información proveniente de distintas fuentes.

---

## 2. Evaluar rentabilidad considerando escala y eficiencia

Auto genera la mayor contribución total debido a su volumen, mientras que Go Sedan presenta el mayor margen promedio por viaje.

**Acción sugerida:** utilizar simultáneamente indicadores de volumen, margen total y margen unitario antes de tomar decisiones sobre capacidad o mix de vehículos.

---

## 3. Investigar los viajes `Incomplete`

Los viajes `Incomplete` presentan ingresos y margen promedio similares a los viajes completados.

**Acción sugerida:** analizar las causas de interrupción para determinar si existen oportunidades de recuperación operacional o reducción de incidencias.

---

## 4. Revisar campañas con ROMI negativo

Campañas como `LANZAMIENTO_CDMX_2024_T3`, `AHORROS_PESOS_MX_191` y `PRIMER_VIAJE_GRATIS_2024` presentan retorno negativo.

**Acción sugerida:** revisar segmentación, costo de adquisición, incentivos y estrategia antes de mantener o incrementar inversión.

---

## 5. Evaluar escalamiento de campañas eficientes

`DESCUENTO_UNIVERSITARIO_55` alcanza un ROMI de **828,75%**.

**Acción sugerida:** evaluar si la eficiencia se mantiene al aumentar progresivamente la inversión antes de escalar el presupuesto.

---

## 6. Monitorear variaciones mensuales sin asumir estacionalidad

Marzo presentó un crecimiento de **12,54%** respecto a febrero, pero el comportamiento anual fue relativamente estable.

**Acción sugerida:** continuar monitoreando periodos adicionales antes de atribuir las variaciones observadas a un patrón estacional estructural.

---

# ⚠️ 6. Limitaciones

Los datos originales se encuentran disponibles únicamente dentro del entorno SQL del bootcamp y la plataforma no permite exportar los conjuntos completos.

Por este motivo, los archivos fuente con los **150.000 registros** no se incluyen en el repositorio.

El proyecto debe considerarse un:

> **caso analítico documentado y no un pipeline completamente reproducible fuera del entorno original.**

El repositorio contiene:

- consultas SQL,
- evidencias de ejecución,
- documentación de calidad,
- resultados agregados,
- tablas de KPIs,
- documentación complementaria.

### Impacto de excluir registros inconsistentes

La exclusión de los `booking_id` inconsistentes reduce ligeramente la representatividad de la base analítica final.

Sin embargo, debido a que no existe una llave secundaria que permita determinar de forma confiable qué costo corresponde a cada viaje, mantener esos registros habría implicado introducir relaciones potencialmente incorrectas.

Por esta razón se priorizó:

> **confiabilidad de los KPIs sobre conservación artificial de registros cuya relación no podía validarse.**

---

# 🛠️ 7. Herramientas y habilidades aplicadas

### SQL

- CTEs
- `JOIN`
- Subconsultas
- Agregaciones
- `GROUP BY`
- `HAVING`
- Manejo de valores nulos
- Funciones de fecha
- `DATE_TRUNC`

### Window Functions

- `RANK()`
- `LAG()`

### Data Analytics

- Auditoría de calidad de datos
- Validación de claves
- Limpieza y preparación de datos
- Desarrollo de KPIs
- Análisis de rentabilidad
- Análisis temporal
- Análisis de campañas
- ROMI
- Interpretación de resultados
- Recomendaciones de negocio

### Herramientas

- SQL
- Google Sheets

---

# 📂 8. Estructura del repositorio

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
        └── evidencias/

---

# 📎 9. Documentación complementaria

El proyecto cuenta con un Google Sheets que contiene:

- diccionario de datos,
- auditoría de calidad,
- impacto de la limpieza,
- KPIs operativos,
- análisis por tipo de vehículo,
- evolución mensual,
- resultados de campañas,
- ROMI.

👉 [Ver documentación y resultados en Google Sheets](TU_LINK_DE_GOOGLE_SHEETS)

Las consultas completas pueden revisarse directamente en la carpeta [`sql/`](sql/).

---

# 👩‍💻 Autora

**Dayana Rodríguez**

Data Analyst | SQL · Python · Power BI · Tableau · Excel

Este proyecto forma parte de mi portafolio de Data Analytics y busca demostrar cómo la **calidad de los datos, el diseño correcto de las relaciones y la interpretación de KPIs** pueden afectar directamente la confiabilidad de las conclusiones y las decisiones de negocio.


