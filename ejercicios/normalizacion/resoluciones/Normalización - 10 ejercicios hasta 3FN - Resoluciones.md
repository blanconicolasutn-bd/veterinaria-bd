# Resolución — 10 ejercicios de normalización hasta 3FN

Resolución de [`Normalización - 10 ejercicios hasta 3FN.md`](../Normalizaci%C3%B3n%20-%2010%20ejercicios%20hasta%203FN.md). Conviene intentarlos antes de mirarla.

En cada paso se muestra **cómo queda la tabla con los datos**, no solo el esquema: así se ve dónde estaba la redundancia y a dónde se fue.

Notación: `tabla(columna PK, columna, columna FK → otra_tabla)`.

---

## Ejercicio 1 — El taller mecánico

### Enunciado

Planilla de órdenes de reparación. En cada orden se anotan los repuestos usados con su cantidad.

| nro_orden | fecha | patente | modelo | marca | dni_dueño | dueño | repuestos |
|---|---|---|---|---|---|---|---|
| 1001 | 02/09/2026 | AB123CD | Corolla | Toyota | 31222333 | Acosta, Raúl | Filtro de aceite x1, Bujía x4 |
| 1002 | 02/09/2026 | AC456EF | Gol | Volkswagen | 29555666 | Bianchi, Laura | Pastillas de freno x2 |
| 1003 | 03/09/2026 | AB123CD | Corolla | Toyota | 31222333 | Acosta, Raúl | Correa x1, Bujía x4 |
| 1004 | 04/09/2026 | AD789GH | Hilux | Toyota | 36777888 | Cabrera, Nora | Filtro de aceite x1, Filtro de aire x1, Bujía x4 |
| 1005 | 05/09/2026 | AE321IJ | Gol | Volkswagen | 31222333 | Acosta, Raúl | Pastillas de freno x2, Correa x1 |
| 1006 | 06/09/2026 | AC456EF | Gol | Volkswagen | 29555666 | Bianchi, Laura | Filtro de aire x1 |

**Supuestos**

- Cada orden es de un solo vehículo.
- Cada vehículo (patente) tiene un solo dueño y es de un solo modelo.
- Cada modelo es de una sola marca.
- Los repuestos se identifican por su nombre.

**Se pide:** llevarla a 3FN, indicando en cada paso qué dependencia eliminaron.

### 0FN
`repuestos` guarda una lista, y cada elemento trae **dos datos**: el repuesto y la cantidad (`Filtro de aceite x1`).

### 1FN — una fila por repuesto

`linea(nro_orden PK, repuesto PK, cantidad, fecha, patente, modelo, marca, dni_dueño, dueño)`

| nro_orden (PK) | repuesto (PK) | cantidad | fecha | patente | modelo | marca | dni_dueño | dueño |
|---|---|---|---|---|---|---|---|---|
| 1001 | Filtro de aceite | 1 | 02/09/2026 | AB123CD | Corolla | Toyota | 31222333 | Acosta, Raúl |
| 1001 | Bujía | 4 | 02/09/2026 | AB123CD | Corolla | Toyota | 31222333 | Acosta, Raúl |
| 1002 | Pastillas de freno | 2 | 02/09/2026 | AC456EF | Gol | Volkswagen | 29555666 | Bianchi, Laura |
| 1003 | Correa | 1 | 03/09/2026 | AB123CD | Corolla | Toyota | 31222333 | Acosta, Raúl |
| 1003 | Bujía | 4 | 03/09/2026 | AB123CD | Corolla | Toyota | 31222333 | Acosta, Raúl |
| 1004 | Filtro de aceite | 1 | 04/09/2026 | AD789GH | Hilux | Toyota | 36777888 | Cabrera, Nora |
| 1004 | Filtro de aire | 1 | 04/09/2026 | AD789GH | Hilux | Toyota | 36777888 | Cabrera, Nora |
| 1004 | Bujía | 4 | 04/09/2026 | AD789GH | Hilux | Toyota | 36777888 | Cabrera, Nora |
| 1005 | Pastillas de freno | 2 | 05/09/2026 | AE321IJ | Gol | Volkswagen | 31222333 | Acosta, Raúl |
| 1005 | Correa | 1 | 05/09/2026 | AE321IJ | Gol | Volkswagen | 31222333 | Acosta, Raúl |
| 1006 | Filtro de aire | 1 | 06/09/2026 | AC456EF | Gol | Volkswagen | 29555666 | Bianchi, Laura |

De 6 filas pasamos a 11, y los datos de la orden quedaron repetidos en cada una. **1FN ordena la tabla, no la limpia.**

### 2FN — sale ORDEN

Todo lo que no sea `cantidad` depende **solo de `nro_orden`**: dependencia parcial.

`orden(nro_orden PK, fecha, patente, modelo, marca, dni_dueño, dueño)`

| nro_orden (PK) | fecha | patente | modelo | marca | dni_dueño | dueño |
|---|---|---|---|---|---|---|
| 1001 | 02/09/2026 | AB123CD | Corolla | Toyota | 31222333 | Acosta, Raúl |
| 1002 | 02/09/2026 | AC456EF | Gol | Volkswagen | 29555666 | Bianchi, Laura |
| 1003 | 03/09/2026 | AB123CD | Corolla | Toyota | 31222333 | Acosta, Raúl |
| 1004 | 04/09/2026 | AD789GH | Hilux | Toyota | 36777888 | Cabrera, Nora |
| 1005 | 05/09/2026 | AE321IJ | Gol | Volkswagen | 31222333 | Acosta, Raúl |
| 1006 | 06/09/2026 | AC456EF | Gol | Volkswagen | 29555666 | Bianchi, Laura |

`detalle(nro_orden PK FK → orden, repuesto PK, cantidad)` — las 11 filas, con solo tres columnas.

### 3FN — dos cadenas transitivas

- `nro_orden → patente → modelo → marca`
- `nro_orden → patente → dni_dueño → dueño`

`dueno(dni_dueño PK, dueño)`

| dni_dueño (PK) | dueño |
|---|---|
| 31222333 | Acosta, Raúl |
| 29555666 | Bianchi, Laura |
| 36777888 | Cabrera, Nora |

`modelo(modelo PK, marca)`

| modelo (PK) | marca |
|---|---|
| Corolla | Toyota |
| Gol | Volkswagen |
| Hilux | Toyota |

`vehiculo(patente PK, modelo FK, dni_dueño FK)`

| patente (PK) | modelo (FK) | dni_dueño (FK) |
|---|---|---|
| AB123CD | Corolla | 31222333 |
| AC456EF | Gol | 29555666 |
| AD789GH | Hilux | 36777888 |
| AE321IJ | Gol | 31222333 |

`orden(nro_orden PK, fecha, patente FK)`

| nro_orden (PK) | fecha | patente (FK) |
|---|---|---|
| 1001 | 02/09/2026 | AB123CD |
| 1002 | 02/09/2026 | AC456EF |
| 1003 | 03/09/2026 | AB123CD |
| 1004 | 04/09/2026 | AD789GH |
| 1005 | 05/09/2026 | AE321IJ |
| 1006 | 06/09/2026 | AC456EF |

### Modelo final

| Tabla | PK | FK | Otras columnas |
|---|---|---|---|
| `dueno` | dni_dueño | — | dueño |
| `modelo` | modelo | — | marca |
| `vehiculo` | patente | modelo, dni_dueño | — |
| `orden` | nro_orden | patente | fecha |
| `detalle` | (nro_orden, repuesto) | nro_orden | cantidad |

**Error común:** dejar `marca` en `vehiculo`. La marca es del modelo: si Corolla es Toyota, lo es en todos los autos, y guardarla por vehículo la repite.

---

## Ejercicio 2 — El cine

### Enunciado

Planilla de entradas vendidas. En cada ticket se anotan las butacas compradas.

| nro_ticket | id_función | fecha | hora | sala | capacidad | película | duración_min | butacas |
|---|---|---|---|---|---|---|---|---|
| T-01 | F10 | 15/11/2026 | 18:00 | Sala 1 | 120 | El último faro | 118 | F5, F6 |
| T-02 | F10 | 15/11/2026 | 18:00 | Sala 1 | 120 | El último faro | 118 | G1 |
| T-03 | F11 | 15/11/2026 | 20:30 | Sala 2 | 80 | Pequeños gigantes | 95 | C3, C4, C5 |
| T-04 | F12 | 16/11/2026 | 18:00 | Sala 1 | 120 | Pequeños gigantes | 95 | A1 |
| T-05 | F11 | 15/11/2026 | 20:30 | Sala 2 | 80 | Pequeños gigantes | 95 | D7, D8 |
| T-06 | F13 | 16/11/2026 | 21:00 | Sala 3 | 60 | Noche en Tilcara | 132 | H2 |

**Supuestos**

- Cada función es de una película, en una sala, en una fecha y hora.
- Cada sala tiene una capacidad fija y cada película una duración fija.
- Un ticket es para una sola función.

**Se pide:** llevarla a 3FN, indicando en cada paso qué dependencia eliminaron.

### 0FN
`butacas` guarda una lista.

### 1FN — una fila por butaca

PK `(nro_ticket, butaca)`. De 6 filas pasamos a 10.

| nro_ticket (PK) | butaca (PK) | id_función | fecha | hora | sala | capacidad | película | duración_min |
|---|---|---|---|---|---|---|---|---|
| T-01 | F5 | F10 | 15/11/2026 | 18:00 | Sala 1 | 120 | El último faro | 118 |
| T-01 | F6 | F10 | 15/11/2026 | 18:00 | Sala 1 | 120 | El último faro | 118 |
| T-02 | G1 | F10 | 15/11/2026 | 18:00 | Sala 1 | 120 | El último faro | 118 |
| T-03 | C3 | F11 | 15/11/2026 | 20:30 | Sala 2 | 80 | Pequeños gigantes | 95 |
| T-03 | C4 | F11 | 15/11/2026 | 20:30 | Sala 2 | 80 | Pequeños gigantes | 95 |
| T-03 | C5 | F11 | 15/11/2026 | 20:30 | Sala 2 | 80 | Pequeños gigantes | 95 |
| T-04 | A1 | F12 | 16/11/2026 | 18:00 | Sala 1 | 120 | Pequeños gigantes | 95 |
| T-05 | D7 | F11 | 15/11/2026 | 20:30 | Sala 2 | 80 | Pequeños gigantes | 95 |
| T-05 | D8 | F11 | 15/11/2026 | 20:30 | Sala 2 | 80 | Pequeños gigantes | 95 |
| T-06 | H2 | F13 | 16/11/2026 | 21:00 | Sala 3 | 60 | Noche en Tilcara | 132 |

### 2FN — sale TICKET

Todo depende solo de `nro_ticket`; `butaca` no determina nada.

`ticket(nro_ticket PK, id_función, fecha, hora, sala, capacidad, película, duración_min)`

| nro_ticket (PK) | id_función | fecha | hora | sala | capacidad | película | duración_min |
|---|---|---|---|---|---|---|---|
| T-01 | F10 | 15/11/2026 | 18:00 | Sala 1 | 120 | El último faro | 118 |
| T-02 | F10 | 15/11/2026 | 18:00 | Sala 1 | 120 | El último faro | 118 |
| T-03 | F11 | 15/11/2026 | 20:30 | Sala 2 | 80 | Pequeños gigantes | 95 |
| T-04 | F12 | 16/11/2026 | 18:00 | Sala 1 | 120 | Pequeños gigantes | 95 |
| T-05 | F11 | 15/11/2026 | 20:30 | Sala 2 | 80 | Pequeños gigantes | 95 |
| T-06 | F13 | 16/11/2026 | 21:00 | Sala 3 | 60 | Noche en Tilcara | 132 |

`entrada(nro_ticket PK FK, butaca PK)` — las 10 filas.

### 3FN — todo pasa por la función

- `nro_ticket → id_función → fecha, hora, sala, película`
- `sala → capacidad` y `película → duración_min`

`pelicula(película PK, duración_min)` · `sala(sala PK, capacidad)`

| película (PK) | duración_min | | sala (PK) | capacidad |
|---|---|---|---|---|
| El último faro | 118 | | Sala 1 | 120 |
| Pequeños gigantes | 95 | | Sala 2 | 80 |
| Noche en Tilcara | 132 | | Sala 3 | 60 |

`funcion(id_función PK, fecha, hora, sala FK, película FK)`

| id_función (PK) | fecha | hora | sala (FK) | película (FK) |
|---|---|---|---|---|
| F10 | 15/11/2026 | 18:00 | Sala 1 | El último faro |
| F11 | 15/11/2026 | 20:30 | Sala 2 | Pequeños gigantes |
| F12 | 16/11/2026 | 18:00 | Sala 1 | Pequeños gigantes |
| F13 | 16/11/2026 | 21:00 | Sala 3 | Noche en Tilcara |

`ticket(nro_ticket PK, id_función FK)` — seis filas de dos columnas.

### Modelo final

| Tabla | PK | FK | Otras columnas |
|---|---|---|---|
| `pelicula` | película | — | duración_min |
| `sala` | sala | — | capacidad |
| `funcion` | id_función | sala, película | fecha, hora |
| `ticket` | nro_ticket | id_función | — |
| `entrada` | (nro_ticket, butaca) | nro_ticket | — |

**Error común:** dejar `fecha` y `hora` en `ticket`. Son de la función: dos tickets de la misma función repiten los mismos valores.

---

## Ejercicio 3 — El gimnasio

### Enunciado

Planilla de asistencias. Cada fila es la asistencia de un socio a una clase en una fecha.

| dni_socio | fecha | cod_clase | socio | plan | precio_plan | clase | instructor | sala |
|---|---|---|---|---|---|---|---|---|
| 33222111 | 01/09/2026 | YOG | Ledesma, Mateo | Libre | 30000 | Yoga | Ramos | Sala A |
| 33222111 | 01/09/2026 | SPN | Ledesma, Mateo | Libre | 30000 | Spinning | Ortiz | Sala B |
| 30999888 | 01/09/2026 | YOG | Moreno, Sofía | 3 veces | 22000 | Yoga | Ramos | Sala A |
| 33222111 | 03/09/2026 | YOG | Ledesma, Mateo | Libre | 30000 | Yoga | Ramos | Sala A |
| 37555444 | 03/09/2026 | FUN | Navarro, Iván | 2 veces | 16000 | Funcional | Ortiz | Sala C |
| 30999888 | 03/09/2026 | SPN | Moreno, Sofía | 3 veces | 22000 | Spinning | Ortiz | Sala B |
| 37555444 | 05/09/2026 | YOG | Navarro, Iván | 2 veces | 16000 | Yoga | Ramos | Sala A |

**Supuestos**

- Un socio no asiste dos veces a la misma clase el mismo día.
- Cada socio tiene un solo plan, y el precio depende del plan.
- Cada clase tiene un instructor y una sala fijos.

**Se pide:**

1. Identificar la clave primaria de la planilla. **Ojo: no es de una sola columna.**
2. Indicar en qué forma normal está, y por qué.
3. Llevarla a 3FN, indicando en cada paso qué dependencia eliminaron.

### Clave primaria
**`(dni_socio, fecha, cod_clase)`**, de tres columnas. Hace falta la fecha: el socio 33222111 fue a Yoga el 01/09 **y** el 03/09.

### 1FN
Ya está: no hay listas y hay PK. La tabla no cambia.

### 2FN — dos dependencias parciales

Cada una sobre una parte distinta de la clave:

| Columnas | Dependen de | Va a |
|---|---|---|
| `socio, plan, precio_plan` | solo `dni_socio` | tabla SOCIO |
| `clase, instructor, sala` | solo `cod_clase` | tabla CLASE |
| *(ninguna)* | la clave completa | ASISTENCIA queda sin atributos |

`socio(dni_socio PK, socio, plan, precio_plan)`

| dni_socio (PK) | socio | plan | precio_plan |
|---|---|---|---|
| 33222111 | Ledesma, Mateo | Libre | 30000 |
| 30999888 | Moreno, Sofía | 3 veces | 22000 |
| 37555444 | Navarro, Iván | 2 veces | 16000 |

`clase(cod_clase PK, clase, instructor, sala)`

| cod_clase (PK) | clase | instructor | sala |
|---|---|---|---|
| YOG | Yoga | Ramos | Sala A |
| SPN | Spinning | Ortiz | Sala B |
| FUN | Funcional | Ortiz | Sala C |

`asistencia(dni_socio PK FK, fecha PK, cod_clase PK FK)`

| dni_socio (PK, FK) | fecha (PK) | cod_clase (PK, FK) |
|---|---|---|
| 33222111 | 01/09/2026 | YOG |
| 33222111 | 01/09/2026 | SPN |
| 30999888 | 01/09/2026 | YOG |
| 33222111 | 03/09/2026 | YOG |
| 37555444 | 03/09/2026 | FUN |
| 30999888 | 03/09/2026 | SPN |
| 37555444 | 05/09/2026 | YOG |

### 3FN — `plan → precio_plan`

`plan(plan PK, precio_plan)`

| plan (PK) | precio_plan |
|---|---|
| Libre | 30000 |
| 3 veces | 22000 |
| 2 veces | 16000 |

`socio(dni_socio PK, socio, plan FK)`

| dni_socio (PK) | socio | plan (FK) |
|---|---|---|
| 33222111 | Ledesma, Mateo | Libre |
| 30999888 | Moreno, Sofía | 3 veces |
| 37555444 | Navarro, Iván | 2 veces |

### Modelo final

| Tabla | PK | FK | Otras columnas |
|---|---|---|---|
| `plan` | plan | — | precio_plan |
| `socio` | dni_socio | plan | socio |
| `clase` | cod_clase | — | clase, instructor, sala |
| `asistencia` | (dni_socio, fecha, cod_clase) | dni_socio, cod_clase | — |

**Error común:** dar `dni_socio` o `(dni_socio, cod_clase)` como PK. Sin la fecha no se pueden registrar dos asistencias del mismo socio a la misma clase en días distintos.

**Nota:** que `asistencia` quede solo con sus tres columnas de clave es correcto. Registra un hecho, sin datos propios.

---

## Ejercicio 4 — Las horas por proyecto

### Enunciado

Planilla mensual de horas. Cada elemento de la lista tiene la forma `código-nombre: horas`.

| legajo | empleado | departamento | jefe_depto | proyectos_y_horas |
|---|---|---|---|---|
| L-10 | Ojeda, Paula | Sistemas | Quiroga | P1-Portal web: 20; P3-App móvil: 10 |
| L-11 | Peralta, Julián | Sistemas | Quiroga | P1-Portal web: 35 |
| L-12 | Rojas, Lucía | Marketing | Suárez | P2-Campaña verano: 25; P1-Portal web: 5 |
| L-13 | Toledo, Bruno | Marketing | Suárez | P2-Campaña verano: 30 |
| L-14 | Vázquez, Elena | Sistemas | Quiroga | P3-App móvil: 40; P2-Campaña verano: 8 |

**Supuestos**

- Cada empleado pertenece a un solo departamento, y cada departamento tiene un solo jefe.
- El código identifica al proyecto.
- Las horas son las que cada empleado trabajó en cada proyecto durante el mes.

**Se pide:** llevarla a 3FN. **Atención:** cada elemento de la lista guarda tres datos distintos, no uno.

### 0FN
`proyectos_y_horas` guarda una lista donde **cada elemento tiene tres datos**: código, nombre y horas (`P1-Portal web: 20`).

### 1FN — una fila por proyecto, con las tres partes separadas

PK `(legajo, cod_proyecto)`.

| legajo (PK) | cod_proyecto (PK) | nombre_proyecto | horas | empleado | departamento | jefe_depto |
|---|---|---|---|---|---|---|
| L-10 | P1 | Portal web | 20 | Ojeda, Paula | Sistemas | Quiroga |
| L-10 | P3 | App móvil | 10 | Ojeda, Paula | Sistemas | Quiroga |
| L-11 | P1 | Portal web | 35 | Peralta, Julián | Sistemas | Quiroga |
| L-12 | P2 | Campaña verano | 25 | Rojas, Lucía | Marketing | Suárez |
| L-12 | P1 | Portal web | 5 | Rojas, Lucía | Marketing | Suárez |
| L-13 | P2 | Campaña verano | 30 | Toledo, Bruno | Marketing | Suárez |
| L-14 | P3 | App móvil | 40 | Vázquez, Elena | Sistemas | Quiroga |
| L-14 | P2 | Campaña verano | 8 | Vázquez, Elena | Sistemas | Quiroga |

### 2FN — dos dependencias parciales

`empleado(legajo PK, empleado, departamento, jefe_depto)`

| legajo (PK) | empleado | departamento | jefe_depto |
|---|---|---|---|
| L-10 | Ojeda, Paula | Sistemas | Quiroga |
| L-11 | Peralta, Julián | Sistemas | Quiroga |
| L-12 | Rojas, Lucía | Marketing | Suárez |
| L-13 | Toledo, Bruno | Marketing | Suárez |
| L-14 | Vázquez, Elena | Sistemas | Quiroga |

`proyecto(cod_proyecto PK, nombre_proyecto)`

| cod_proyecto (PK) | nombre_proyecto |
|---|---|
| P1 | Portal web |
| P2 | Campaña verano |
| P3 | App móvil |

`trabaja(legajo PK FK, cod_proyecto PK FK, horas)` — las 8 filas. **Las horas necesitan las dos columnas de la clave: se quedan acá.**

### 3FN — `departamento → jefe_depto`

`departamento(departamento PK, jefe_depto)`

| departamento (PK) | jefe_depto |
|---|---|
| Sistemas | Quiroga |
| Marketing | Suárez |

`empleado(legajo PK, empleado, departamento FK)` — cinco filas, sin `jefe_depto`.

### Modelo final

| Tabla | PK | FK | Otras columnas |
|---|---|---|---|
| `departamento` | departamento | — | jefe_depto |
| `empleado` | legajo | departamento | empleado |
| `proyecto` | cod_proyecto | — | nombre_proyecto |
| `trabaja` | (legajo, cod_proyecto) | legajo, cod_proyecto | horas |

**Error común:** separar la lista pero dejar `P1-Portal web` junto. El código y el nombre son dos datos: si el proyecto se renombra, habría que editarlo en todas las filas.

---

## Ejercicio 5 — La empresa de transporte

### Enunciado

Planilla de envíos. En cada envío se anota el peso de cada bulto.

| nro_envío | fecha | cuit_remitente | remitente | cp_destino | localidad | provincia | pesos_bultos_kg |
|---|---|---|---|---|---|---|---|
| E-100 | 05/10/2026 | 30-70111222-5 | Distribuidora Norte | 5000 | Córdoba | Córdoba | 10; 5; 5 |
| E-101 | 05/10/2026 | 30-70999888-2 | Agro Sur SA | 2000 | Rosario | Santa Fe | 3.5 |
| E-102 | 06/10/2026 | 30-70111222-5 | Distribuidora Norte | 5800 | Río Cuarto | Córdoba | 12; 8 |
| E-103 | 06/10/2026 | 20-25333444-1 | Benítez, Omar | 5000 | Córdoba | Córdoba | 2; 2; 2; 1 |
| E-104 | 07/10/2026 | 30-70999888-2 | Agro Sur SA | 3000 | Santa Fe | Santa Fe | 20 |

**Supuestos**

- Cada código postal corresponde a una localidad, y cada localidad a una provincia.
- El remitente se identifica por su CUIT.
- **Los bultos no tienen código: de cada uno solo se conoce su peso**, y dos bultos del mismo envío pueden pesar lo mismo.

**Se pide:** llevarla a 3FN. **Atención:** pensá bien cómo identificar cada bulto. El envío E-103 tiene tres bultos de 2 kg.

### 0FN
`pesos_bultos_kg` guarda una lista, y **los valores se repiten**: el E-103 tiene tres bultos de 2 kg.

### 1FN — una fila por bulto, con número de bulto

El peso **no identifica**. Hace falta un número de bulto dentro del envío: el bulto es una **entidad débil**.

| nro_envío (PK) | nro_bulto (PK) | peso_kg | fecha | cuit_remitente | remitente | cp_destino | localidad | provincia |
|---|---|---|---|---|---|---|---|---|
| E-100 | 1 | 10 | 05/10/2026 | 30-70111222-5 | Distribuidora Norte | 5000 | Córdoba | Córdoba |
| E-100 | 2 | 5 | 05/10/2026 | 30-70111222-5 | Distribuidora Norte | 5000 | Córdoba | Córdoba |
| E-100 | 3 | 5 | 05/10/2026 | 30-70111222-5 | Distribuidora Norte | 5000 | Córdoba | Córdoba |
| E-101 | 1 | 3.5 | 05/10/2026 | 30-70999888-2 | Agro Sur SA | 2000 | Rosario | Santa Fe |
| E-102 | 1 | 12 | 06/10/2026 | 30-70111222-5 | Distribuidora Norte | 5800 | Río Cuarto | Córdoba |
| E-102 | 2 | 8 | 06/10/2026 | 30-70111222-5 | Distribuidora Norte | 5800 | Río Cuarto | Córdoba |
| E-103 | 1 | 2 | 06/10/2026 | 20-25333444-1 | Benítez, Omar | 5000 | Córdoba | Córdoba |
| E-103 | 2 | 2 | 06/10/2026 | 20-25333444-1 | Benítez, Omar | 5000 | Córdoba | Córdoba |
| E-103 | 3 | 2 | 06/10/2026 | 20-25333444-1 | Benítez, Omar | 5000 | Córdoba | Córdoba |
| E-103 | 4 | 1 | 06/10/2026 | 20-25333444-1 | Benítez, Omar | 5000 | Córdoba | Córdoba |
| E-104 | 1 | 20 | 07/10/2026 | 30-70999888-2 | Agro Sur SA | 3000 | Santa Fe | Santa Fe |

Las tres filas de 2 kg del E-103 solo se distinguen por `nro_bulto`. Sin esa columna, la clave las rechazaría.

### 2FN — sale ENVIO

`envio(nro_envío PK, fecha, cuit_remitente, remitente, cp_destino, localidad, provincia)`

| nro_envío (PK) | fecha | cuit_remitente | remitente | cp_destino | localidad | provincia |
|---|---|---|---|---|---|---|
| E-100 | 05/10/2026 | 30-70111222-5 | Distribuidora Norte | 5000 | Córdoba | Córdoba |
| E-101 | 05/10/2026 | 30-70999888-2 | Agro Sur SA | 2000 | Rosario | Santa Fe |
| E-102 | 06/10/2026 | 30-70111222-5 | Distribuidora Norte | 5800 | Río Cuarto | Córdoba |
| E-103 | 06/10/2026 | 20-25333444-1 | Benítez, Omar | 5000 | Córdoba | Córdoba |
| E-104 | 07/10/2026 | 30-70999888-2 | Agro Sur SA | 3000 | Santa Fe | Santa Fe |

`bulto(nro_envío PK FK, nro_bulto PK, peso_kg)` — las 11 filas, con tres columnas.

### 3FN — dos cadenas

- `nro_envío → cuit_remitente → remitente`
- `nro_envío → cp_destino → localidad → provincia` *(dos niveles)*

`remitente(cuit_remitente PK, remitente)`

| cuit_remitente (PK) | remitente |
|---|---|
| 30-70111222-5 | Distribuidora Norte |
| 30-70999888-2 | Agro Sur SA |
| 20-25333444-1 | Benítez, Omar |

`localidad(localidad PK, provincia)` · `codigo_postal(cp PK, localidad FK)`

| localidad (PK) | provincia | | cp (PK) | localidad (FK) |
|---|---|---|---|---|
| Córdoba | Córdoba | | 5000 | Córdoba |
| Rosario | Santa Fe | | 2000 | Rosario |
| Río Cuarto | Córdoba | | 5800 | Río Cuarto |
| Santa Fe | Santa Fe | | 3000 | Santa Fe |

`envio(nro_envío PK, fecha, cuit_remitente FK, cp_destino FK)`

| nro_envío (PK) | fecha | cuit_remitente (FK) | cp_destino (FK) |
|---|---|---|---|
| E-100 | 05/10/2026 | 30-70111222-5 | 5000 |
| E-101 | 05/10/2026 | 30-70999888-2 | 2000 |
| E-102 | 06/10/2026 | 30-70111222-5 | 5800 |
| E-103 | 06/10/2026 | 20-25333444-1 | 5000 |
| E-104 | 07/10/2026 | 30-70999888-2 | 3000 |

### Modelo final

| Tabla | PK | FK | Otras columnas |
|---|---|---|---|
| `remitente` | cuit_remitente | — | remitente |
| `localidad` | localidad | — | provincia |
| `codigo_postal` | cp | localidad | — |
| `envio` | nro_envío | cuit_remitente, cp_destino | fecha |
| `bulto` | (nro_envío, nro_bulto) | nro_envío | peso_kg |

**Error común:** usar `(nro_envío, peso_kg)` como PK de los bultos. Con tres bultos de 2 kg en el E-103, esa clave rechaza dos de ellos. Cuando el enunciado dice que algo no tiene identificador, hay que inventarle uno.

---

## Ejercicio 6 — El hospital

### Enunciado

Planilla de internaciones. En cada una se anotan los estudios realizados con su costo.

| nro_internación | ingreso | dni_paciente | paciente | habitación | piso | jefa_enfermería | matrícula | médico | estudios |
|---|---|---|---|---|---|---|---|---|---|
| I-300 | 01/10/2026 | 30555111 | Domínguez, Luis | 201 | 2 | Medina | 6120 | Paredes | Radiografía ($25000), Análisis de sangre ($12000) |
| I-301 | 02/10/2026 | 28777222 | Ponce, Marta | 305 | 3 | Castro | 6345 | Correa | Ecografía ($40000) |
| I-302 | 02/10/2026 | 35111999 | Gallo, Pía | 202 | 2 | Medina | 6120 | Paredes | Análisis de sangre ($12000) |
| I-303 | 04/10/2026 | 40888111 | Figueroa, Juan | 306 | 3 | Castro | 7011 | Villalba | Radiografía ($25000), Ecografía ($40000), Análisis de sangre ($12000) |
| I-304 | 05/10/2026 | 33777444 | Escobar, Inés | 201 | 2 | Medina | 6345 | Correa | Ecografía ($40000) |

**Supuestos**

- Cada internación es de un paciente, en una habitación, con un médico a cargo.
- Cada habitación está en un piso, y cada piso tiene una jefa de enfermería.
- El costo depende solo del estudio.
- Un estudio no se repite dentro de la misma internación.

**Se pide:** llevarla a 3FN, indicando en cada paso qué dependencia eliminaron.

### 0FN
`estudios` guarda una lista, y cada elemento trae el estudio **y su costo** (`Radiografía ($25000)`).

### 1FN — una fila por estudio

PK `(nro_internación, estudio)`. De 5 filas pasamos a 8.

| nro_intern. (PK) | estudio (PK) | costo | ingreso | dni_paciente | paciente | hab. | piso | jefa_enf. | matrícula | médico |
|---|---|---|---|---|---|---|---|---|---|---|
| I-300 | Radiografía | 25000 | 01/10/2026 | 30555111 | Domínguez, Luis | 201 | 2 | Medina | 6120 | Paredes |
| I-300 | Análisis de sangre | 12000 | 01/10/2026 | 30555111 | Domínguez, Luis | 201 | 2 | Medina | 6120 | Paredes |
| I-301 | Ecografía | 40000 | 02/10/2026 | 28777222 | Ponce, Marta | 305 | 3 | Castro | 6345 | Correa |
| I-302 | Análisis de sangre | 12000 | 02/10/2026 | 35111999 | Gallo, Pía | 202 | 2 | Medina | 6120 | Paredes |
| I-303 | Radiografía | 25000 | 04/10/2026 | 40888111 | Figueroa, Juan | 306 | 3 | Castro | 7011 | Villalba |
| I-303 | Ecografía | 40000 | 04/10/2026 | 40888111 | Figueroa, Juan | 306 | 3 | Castro | 7011 | Villalba |
| I-303 | Análisis de sangre | 12000 | 04/10/2026 | 40888111 | Figueroa, Juan | 306 | 3 | Castro | 7011 | Villalba |
| I-304 | Ecografía | 40000 | 05/10/2026 | 33777444 | Escobar, Inés | 201 | 2 | Medina | 6345 | Correa |

### 2FN — tres grupos

- `costo` depende solo de `estudio`
- todo el resto depende solo de `nro_internación`
- ninguna columna depende de la clave completa

`estudio(estudio PK, costo)`

| estudio (PK) | costo |
|---|---|
| Radiografía | 25000 |
| Ecografía | 40000 |
| Análisis de sangre | 12000 |

`internacion(nro_internación PK, ingreso, dni_paciente, paciente, habitación, piso, jefa_enfermería, matrícula, médico)`

| nro_intern. (PK) | ingreso | dni_paciente | paciente | hab. | piso | jefa_enf. | matrícula | médico |
|---|---|---|---|---|---|---|---|---|
| I-300 | 01/10/2026 | 30555111 | Domínguez, Luis | 201 | 2 | Medina | 6120 | Paredes |
| I-301 | 02/10/2026 | 28777222 | Ponce, Marta | 305 | 3 | Castro | 6345 | Correa |
| I-302 | 02/10/2026 | 35111999 | Gallo, Pía | 202 | 2 | Medina | 6120 | Paredes |
| I-303 | 04/10/2026 | 40888111 | Figueroa, Juan | 306 | 3 | Castro | 7011 | Villalba |
| I-304 | 05/10/2026 | 33777444 | Escobar, Inés | 201 | 2 | Medina | 6345 | Correa |

`estudio_realizado(nro_internación PK FK, estudio PK FK)` — las 8 filas, solo las dos claves.

### 3FN — tres cadenas

- `dni_paciente → paciente`
- `habitación → piso → jefa_enfermería` *(dos niveles)*
- `matrícula → médico`

`paciente(dni_paciente PK, paciente)` · `medico(matrícula PK, médico)`

| dni_paciente (PK) | paciente | | matrícula (PK) | médico |
|---|---|---|---|---|
| 30555111 | Domínguez, Luis | | 6120 | Paredes |
| 28777222 | Ponce, Marta | | 6345 | Correa |
| 35111999 | Gallo, Pía | | 7011 | Villalba |
| 40888111 | Figueroa, Juan | | | |
| 33777444 | Escobar, Inés | | | |

`piso(piso PK, jefa_enfermería)` · `habitacion(habitación PK, piso FK)`

| piso (PK) | jefa_enfermería | | habitación (PK) | piso (FK) |
|---|---|---|---|---|
| 2 | Medina | | 201 | 2 |
| 3 | Castro | | 202 | 2 |
| | | | 305 | 3 |
| | | | 306 | 3 |

`internacion(nro_internación PK, ingreso, dni_paciente FK, habitación FK, matrícula FK)`

| nro_intern. (PK) | ingreso | dni_paciente (FK) | habitación (FK) | matrícula (FK) |
|---|---|---|---|---|
| I-300 | 01/10/2026 | 30555111 | 201 | 6120 |
| I-301 | 02/10/2026 | 28777222 | 305 | 6345 |
| I-302 | 02/10/2026 | 35111999 | 202 | 6120 |
| I-303 | 04/10/2026 | 40888111 | 306 | 7011 |
| I-304 | 05/10/2026 | 33777444 | 201 | 6345 |

### Modelo final

| Tabla | PK | FK | Otras columnas |
|---|---|---|---|
| `paciente` | dni_paciente | — | paciente |
| `medico` | matrícula | — | médico |
| `piso` | piso | — | jefa_enfermería |
| `habitacion` | habitación | piso | — |
| `internacion` | nro_internación | dni_paciente, habitación, matrícula | ingreso |
| `estudio` | estudio | — | costo |
| `estudio_realizado` | (nro_internación, estudio) | nro_internación, estudio | — |

**Error común:** dejar `jefa_enfermería` en `habitacion`. La jefa es del piso: las habitaciones 201 y 202 están las dos en el piso 2 y repetirían Medina.

---

## Ejercicio 7 — La empresa de mudanzas

### Enunciado

Una empresa de mudanzas quiere normalizar los datos con los que trabaja. Del relevamiento surge lo siguiente:

Cada vez que un cliente contrata el servicio se registran los **puntos de traslado** (origen y destino) y la **fecha y hora estimada de inicio**. Del cliente se guardan nombre completo, DNI, **teléfonos (puede tener uno o más de uno)** y correo electrónico. También se registra una **persona de contacto**, de la que se guardan nombre completo, teléfonos (uno o más) y correo electrónico.

Para cada mudanza se asignan **operarios** — como mínimo uno — y un **vehículo**.

La empresa tiene un libro con los datos de sus **choferes y operarios**: nombre completo, DNI, teléfonos (puede no tener ninguno), correo, edad, dirección (calle, número, ciudad) y el **valor de la hora** que se le paga. Ese valor está tabulado por puesto:

- Chofer: $9000 / h
- Operario de mudanza: $7000 / h

Para controlar los sueldos registra en un cuaderno: nombre completo, DNI, mes, cantidad de horas trabajadas y **sueldo total**.

De cada **vehículo** registra patente, marca, modelo, kilómetros realizados, volumen y peso que soporta.

**Se pide:** llevar el modelo a 3FN. Justificar qué dependencia se elimina en cada paso.

**Pistas de lo que hay que mirar:** los teléfonos, el valor de la hora, el sueldo total y el parecido entre *cliente* y *persona de contacto*.

El enunciado no trae planilla. **Los datos de las tablas que siguen son inventados**, para ver cómo queda la forma en cada paso.

### 0FN — los tres registros que lleva la empresa

**Planilla de mudanzas**

| nro_mudanza | fecha_hora | origen | destino | cliente | dni_cliente | tel_cliente | contacto | tel_contacto | operarios | patente |
|---|---|---|---|---|---|---|---|---|---|---|
| M-001 | 05/11/2026 09:00 | Colón 1200, Córdoba | San Martín 450, Villa Allende | Acosta, Raúl | 31222333 | 3514445566; 3517778899 | Acosta, Elena | 3512223344 | Quiroga; Sosa | AB123CD |
| M-002 | 06/11/2026 14:00 | Rivadavia 80, Córdoba | Belgrano 900, Río Cuarto | Bianchi, Laura | 29555666 | 3516667788 | Paz, Mario | 3519990011 | Sosa | AC456EF |

**Libro de choferes y operarios**

| nombre | dni | telefonos | email | edad | direccion | puesto | valor_hora |
|---|---|---|---|---|---|---|---|
| Quiroga, Nahuel | 30111222 | 3511112233 | nquiroga@mail.com | 38 | Sarmiento 120, Córdoba | Operario de mudanza | 7000 |
| Sosa, Daniel | 28444555 | *(sin teléfono)* | dsosa@mail.com | 45 | Vélez 77, Córdoba | Chofer | 9000 |

**Cuaderno de sueldos**

| nombre | dni | mes | horas | sueldo_total |
|---|---|---|---|---|
| Quiroga, Nahuel | 30111222 | 10/2026 | 120 | 840000 |
| Sosa, Daniel | 28444555 | 10/2026 | 100 | 900000 |

Cuatro problemas a la vista: los **teléfonos** son listas, las **direcciones** son valores compuestos, los **operarios asignados** son otra lista, y el **nombre** está repetido entre el libro y el cuaderno.

### 1FN — se sacan las listas y se parten los compuestos

Cada teléfono a su propia fila:

`telefono_empleado(dni PK FK, telefono PK)`

| dni (PK, FK) | telefono (PK) |
|---|---|
| 30111222 | 3511112233 |

Sosa no tiene ninguna fila acá: **no tener teléfono deja de ser una celda vacía y pasa a ser la ausencia de filas.**

Cada operario asignado a su propia fila:

`mudanza_operario(nro_mudanza PK FK, dni PK FK)`

| nro_mudanza (PK, FK) | dni (PK, FK) |
|---|---|
| M-001 | 30111222 |
| M-001 | 28444555 |
| M-002 | 28444555 |

Y la dirección se parte en columnas:

`empleado(dni PK, nombre, edad, calle, numero, ciudad, email, puesto, valor_hora)`

| dni (PK) | nombre | edad | calle | numero | ciudad | puesto | valor_hora |
|---|---|---|---|---|---|---|---|
| 30111222 | Quiroga, Nahuel | 38 | Sarmiento | 120 | Córdoba | Operario de mudanza | 7000 |
| 28444555 | Sosa, Daniel | 45 | Vélez | 77 | Córdoba | Chofer | 9000 |

### 2FN — el cuaderno de sueldos

Su clave es `(dni, mes)`: un empleado tiene un registro por mes. `nombre` depende **solo de `dni`**, que es una parte de la clave: dependencia parcial. Se va a `empleado`, donde ya estaba.

`horas_mes(dni PK FK, mes PK, horas_trabajadas, sueldo_total)`

| dni (PK, FK) | mes (PK) | horas_trabajadas | sueldo_total |
|---|---|---|---|
| 30111222 | 10/2026 | 120 | 840000 |
| 28444555 | 10/2026 | 100 | 900000 |

### 3FN — el valor de la hora y el sueldo

Dos cosas:

- **`valor_hora` depende del puesto, no de la persona**: `dni → puesto → valor_hora` es transitiva. Todos los choferes cobran lo mismo, y hoy el 9000 se repite en cada chofer.
- **`sueldo_total` es un campo calculado**: `horas_trabajadas × valor_hora`. Se elimina.

`puesto(puesto PK, valor_hora)`

| puesto (PK) | valor_hora |
|---|---|
| Chofer | 9000 |
| Operario de mudanza | 7000 |

`empleado(dni PK, nombre, edad, calle, numero, ciudad, email, puesto FK)`

| dni (PK) | nombre | edad | calle | numero | ciudad | puesto (FK) |
|---|---|---|---|---|---|---|
| 30111222 | Quiroga, Nahuel | 38 | Sarmiento | 120 | Córdoba | Operario de mudanza |
| 28444555 | Sosa, Daniel | 45 | Vélez | 77 | Córdoba | Chofer |

`horas_mes(dni PK FK, mes PK, horas_trabajadas)` — sin `sueldo_total`.

| dni (PK, FK) | mes (PK) | horas_trabajadas |
|---|---|---|
| 30111222 | 10/2026 | 120 |
| 28444555 | 10/2026 | 100 |

Y la mudanza, con el cliente y el contacto apuntando los dos a `persona`:

`mudanza(nro_mudanza PK, fecha_hora_estimada, origen, destino, id_cliente FK, id_contacto FK, patente FK)`

| nro_mudanza (PK) | fecha_hora | origen | destino | id_cliente (FK) | id_contacto (FK) | patente (FK) |
|---|---|---|---|---|---|---|
| M-001 | 05/11/2026 09:00 | Colón 1200, Córdoba | San Martín 450, Villa Allende | 1 | 2 | AB123CD |
| M-002 | 06/11/2026 14:00 | Rivadavia 80, Córdoba | Belgrano 900, Río Cuarto | 3 | 4 | AC456EF |

`persona(id_persona PK, nombre, dni, email)`

| id_persona (PK) | nombre | dni | email |
|---|---|---|---|
| 1 | Acosta, Raúl | 31222333 | racosta@mail.com |
| 2 | Acosta, Elena | — | eacosta@mail.com |
| 3 | Bianchi, Laura | 29555666 | lbianchi@mail.com |
| 4 | Paz, Mario | — | mpaz@mail.com |

### Modelo final

| Tabla | PK | FK | Otras columnas |
|---|---|---|---|
| `persona` | id_persona | — | nombre, dni, email |
| `telefono_persona` | (id_persona, telefono) | id_persona | — |
| `puesto` | puesto | — | valor_hora |
| `empleado` | dni | puesto | nombre, edad, calle, numero, ciudad, email |
| `telefono_empleado` | (dni, telefono) | dni | — |
| `vehiculo` | patente | — | marca, modelo, km_realizados, volumen, peso_soportado |
| `mudanza` | nro_mudanza | id_cliente, id_contacto, patente | fecha_hora_estimada, origen, destino |
| `mudanza_operario` | (nro_mudanza, dni) | nro_mudanza, dni | — |
| `horas_mes` | (dni, mes) | dni | horas_trabajadas |

### Las dos decisiones que se discuten

**El sueldo total no se guarda.** Sale de `horas_trabajadas × valor_hora`. Guardarlo es el caso del campo calculado: si cambia el valor de la hora, el sueldo guardado queda mintiendo.

**Cliente y contacto en una sola tabla `persona`.** Tienen los mismos datos, así que `mudanza` apunta dos veces a la misma tabla. También es defendible hacer dos tablas separadas; lo que no se puede es repetir las columnas dentro de `mudanza`.

**Error común:** poner `valor_hora` como columna de `empleado`. El enunciado dice que está tabulado por puesto: todos los choferes cobran lo mismo, y repetir 9000 en cada chofer es exactamente la redundancia que 3FN elimina.

---

## Ejercicio 8 — El sistema heredado de búsqueda laboral

### Enunciado

Una empresa de servicios de capital humano quiere reemplazar sus sistemas. Hoy funciona con dos archivos binarios.

**`personas.dat`**

| DNI | Contraseña | Nombre y Apellido | descripción | Fecha de nacimiento | Estudios formales | Idiomas |
|---|---|---|---|---|---|---|
| long int | string[8] | string[50] | string[300] | string[10] | string[300] | string[300] |

Sobre esa estructura, el análisis reveló que:

- El campo **`descripción`** se agregó después y se usa para guardar datos que no se habían contemplado. Adentro se almacenan, separados por `|` (pipe): la dirección de email, los **teléfonos** (nunca más de dos: uno fijo y uno móvil, separados entre sí por `;`) y la dirección de residencia (calle, número, código postal, ciudad y provincia, separados por `,`).
- En **`Fecha de nacimiento`** conviven los formatos `dd/mm/aaaa` y `dd-mm-aaaa`, y en algunos registros se guardó directamente la edad.
- **`Estudios formales`** e **`Idiomas`** guardan, para cada uno: nombre del título, si está completo (`si` / `no`), cantidad de años y entidad emisora, separados por `|`. Si la persona tiene más de un estudio, se separan entre sí con `;`.

**`empresas.dat`**

| Nombre | Razón social | CUIT | descripción | Rubro | Cantidad de empleados | Aviso |
|---|---|---|---|---|---|---|

Cada empresa publica avisos de trabajo, y el campo `Aviso` guarda todos los avisos publicados por esa empresa.

**Se pide:** llevar el modelo a 3FN. Para cada campo problemático, indicar qué regla de qué forma normal se está violando.

**Pista:** acá el trabajo más grande es de 1FN, y hay más de un motivo distinto por los que se viola.

El enunciado da la estructura de los archivos, no sus datos. **Los registros que siguen son inventados**, para ver qué hay realmente adentro de cada campo.

### 0FN — `personas.dat` tal como está hoy

| DNI | Contraseña | Nombre y Apellido | descripción | Fecha de nacimiento | Estudios formales | Idiomas |
|---|---|---|---|---|---|---|
| 30111222 | abc12345 | Marta Acuña | `macuna@mail.com\|3514445566;3517778899\|Colón,1200,5000,Córdoba,Córdoba` | 14/03/1983 | `Analista de Sistemas\|si\|3\|UTN; Ingeniería\|no\|2\|UNC` | `Inglés\|si\|5\|Cultural` |
| 28444555 | xyz99887 | Iván Bustos | `ibustos@mail.com\|3516667788\|Vélez,77,5000,Córdoba,Córdoba` | 02-11-1979 | `Técnico en Programación\|si\|3\|ISET` | `Inglés\|no\|2\|Particular` |
| 35777888 | qwe55443 | Rocío Cáceres | `rcaceres@mail.com\|\|Duarte,310,5800,Río Cuarto,Córdoba` | 41 | *(vacío)* | `Inglés\|si\|4\|Cultural` |

### Las violaciones de 1FN, por tipo

| # | Tipo | Dónde | Se ve en |
|---|---|---|---|
| a | **Campo multipropósito** | `descripción` guarda email, teléfonos y dirección separados por pipes | las tres filas |
| b | **Valor multivaluado** | teléfonos (hasta dos), estudios formales e idiomas | Acuña: dos teléfonos y dos estudios |
| c | **Valor compuesto** | la dirección (calle, número, CP, ciudad, provincia) y cada estudio (título, completo, años, entidad) | todas |
| d | **Dominio inconsistente** | `fecha de nacimiento` con tres formatos distintos | Acuña `14/03/1983`, Bustos `02-11-1979`, Cáceres `41` |

En (a) el problema no es que el valor no sea atómico: es que **la columna no tiene un significado único**. Es el único de los cuatro que no se arregla separando: hay que decidir qué datos eran y darle una columna a cada uno.

### 1FN — se abre `descripción` y se sacan las listas

`persona(dni PK, contraseña, nombre, apellido, email, fecha_nac, calle, numero, cp)`

| dni (PK) | nombre | apellido | email | fecha_nac | calle | numero | cp |
|---|---|---|---|---|---|---|---|
| 30111222 | Marta | Acuña | macuna@mail.com | 1983-03-14 | Colón | 1200 | 5000 |
| 28444555 | Iván | Bustos | ibustos@mail.com | 1979-11-02 | Vélez | 77 | 5000 |
| 35777888 | Rocío | Cáceres | rcaceres@mail.com | *(nulo)* | Duarte | 310 | 5800 |

Las fechas quedan en un **único formato**. La de Cáceres se pierde: de `41` no se puede reconstruir el día ni el mes, así que se migra nula.

`telefono_persona(dni PK FK, telefono PK, tipo)`

| dni (PK, FK) | telefono (PK) | tipo |
|---|---|---|
| 30111222 | 3514445566 | fijo |
| 30111222 | 3517778899 | móvil |
| 28444555 | 3516667788 | móvil |

Cáceres no tiene ninguna fila: su campo de teléfonos venía vacío.

`estudio(id_estudio PK, dni FK, titulo, tipo, completo, anios, entidad)`

| id_estudio (PK) | dni (FK) | titulo | tipo | completo | anios | entidad |
|---|---|---|---|---|---|---|
| 1 | 30111222 | Analista de Sistemas | formal | si | 3 | UTN |
| 2 | 30111222 | Ingeniería | formal | no | 2 | UNC |
| 3 | 30111222 | Inglés | idioma | si | 5 | Cultural |
| 4 | 28444555 | Técnico en Programación | formal | si | 3 | ISET |
| 5 | 28444555 | Inglés | idioma | no | 2 | Particular |
| 6 | 35777888 | Inglés | idioma | si | 4 | Cultural |

La columna `tipo` reemplaza a las tres columnas originales (formales, informales, idiomas): tenían la misma estructura, así que van a la misma tabla.

### 2FN
`persona` y `estudio` tienen PK de una sola columna, así que ya están en 2FN. `telefono_persona` tiene PK compuesta, pero `tipo` depende de las dos columnas: se queda.

### 3FN — la entidad y la ubicación

Dos cadenas:

- `id_estudio → entidad` repite "UTN", "Cultural" en cada fila → sale `entidad`
- `cp → ciudad → provincia` → salen `codigo_postal` y `ciudad`

`entidad(id_entidad PK, nombre)`

| id_entidad (PK) | nombre |
|---|---|
| 1 | UTN |
| 2 | UNC |
| 3 | Cultural |
| 4 | ISET |
| 5 | Particular |

`ciudad(ciudad PK, provincia)` · `codigo_postal(cp PK, ciudad FK)`

| ciudad (PK) | provincia | | cp (PK) | ciudad (FK) |
|---|---|---|---|---|
| Córdoba | Córdoba | | 5000 | Córdoba |
| Río Cuarto | Córdoba | | 5800 | Río Cuarto |

### Modelo final

| Tabla | PK | FK | Otras columnas |
|---|---|---|---|
| `persona` | dni | cp | contraseña, nombre, apellido, email, fecha_nac, calle, numero |
| `telefono_persona` | (dni, telefono) | dni | tipo |
| `codigo_postal` | cp | ciudad | — |
| `ciudad` | ciudad | — | provincia |
| `entidad` | id_entidad | — | nombre |
| `estudio` | id_estudio | dni, id_entidad | titulo, tipo, completo, anios |
| `empresa` | cuit | — | nombre, razon_social, rubro, cantidad_empleados, descripcion |
| `aviso` | id_aviso | cuit | titulo, texto, fecha |

### Observaciones

**La edad no se guarda.** Es un campo derivado de `fecha_nac`. Donde hoy hay una edad, al migrar hay que reconstruir la fecha o dejarla nula.

**`tipo` en `estudio`** distingue formal / informal / idioma. Así las tres columnas originales se unifican en una tabla, en vez de repetir la misma estructura tres veces.

**Error común:** crear `telefono_fijo` y `telefono_movil` como dos columnas. Funciona porque el enunciado dice "nunca más de dos", pero es un grupo de columnas repetidas: el mismo problema que `producto_1` y `producto_2`.

---

## Ejercicio 9 — Los equipos y el software instalado

### Enunciado

Una empresa quiere regularizar el software instalado en las PC de sus empleados. Hoy lleva todo en una única tabla:

| id_equipo | marca | modelo | ram_gb | dni_usuario | usuario | sector | software_instalado |
|---|---|---|---|---|---|---|---|
| EQ-01 | Dell | OptiPlex 3080 | 8 | 30111222 | Acuña, Marta | Administración | Windows 10; Office 2019; Chrome |
| EQ-02 | HP | ProDesk 400 | 16 | 28444555 | Bustos, Iván | Sistemas | Windows 11; Chrome; Visual Studio Code |
| EQ-03 | Dell | OptiPlex 3080 | 8 | 35777888 | Cáceres, Rocío | Administración | Windows 10; Office 2019 |
| EQ-04 | Lenovo | ThinkCentre M70 | 16 | 28444555 | Bustos, Iván | Sistemas | Windows 11; Visual Studio Code; Docker |
| EQ-05 | HP | ProDesk 400 | 16 | 41222333 | Duarte, Nahuel | Depósito | Windows 10; Chrome |

**Supuestos**

- Un equipo tiene **más de un software instalado**.
- Los **modelos de PC no se repiten entre marcas**: si dos equipos son del mismo modelo, son de la misma marca.
- La memoria RAM depende del modelo.
- Un usuario puede tener asignado más de un equipo, pero cada equipo tiene un solo usuario.
- Cada usuario pertenece a un solo sector.

**Se pide:** llevar el modelo a 3FN, reduciendo la redundancia. Indicar en cada paso qué dependencia se elimina.

### 0FN
`software_instalado` guarda una lista.

### 1FN — una fila por software de cada equipo

PK `(id_equipo, software)`. De 5 filas pasamos a 13.

| id_equipo (PK) | software (PK) | marca | modelo | ram_gb | dni_usuario | usuario | sector |
|---|---|---|---|---|---|---|---|
| EQ-01 | Windows 10 | Dell | OptiPlex 3080 | 8 | 30111222 | Acuña, Marta | Administración |
| EQ-01 | Office 2019 | Dell | OptiPlex 3080 | 8 | 30111222 | Acuña, Marta | Administración |
| EQ-01 | Chrome | Dell | OptiPlex 3080 | 8 | 30111222 | Acuña, Marta | Administración |
| EQ-02 | Windows 11 | HP | ProDesk 400 | 16 | 28444555 | Bustos, Iván | Sistemas |
| EQ-02 | Chrome | HP | ProDesk 400 | 16 | 28444555 | Bustos, Iván | Sistemas |
| EQ-02 | Visual Studio Code | HP | ProDesk 400 | 16 | 28444555 | Bustos, Iván | Sistemas |
| EQ-03 | Windows 10 | Dell | OptiPlex 3080 | 8 | 35777888 | Cáceres, Rocío | Administración |
| EQ-03 | Office 2019 | Dell | OptiPlex 3080 | 8 | 35777888 | Cáceres, Rocío | Administración |
| EQ-04 | Windows 11 | Lenovo | ThinkCentre M70 | 16 | 28444555 | Bustos, Iván | Sistemas |
| EQ-04 | Visual Studio Code | Lenovo | ThinkCentre M70 | 16 | 28444555 | Bustos, Iván | Sistemas |
| EQ-04 | Docker | Lenovo | ThinkCentre M70 | 16 | 28444555 | Bustos, Iván | Sistemas |
| EQ-05 | Windows 10 | HP | ProDesk 400 | 16 | 41222333 | Duarte, Nahuel | Depósito |
| EQ-05 | Chrome | HP | ProDesk 400 | 16 | 41222333 | Duarte, Nahuel | Depósito |

### 2FN — sale EQUIPO

`equipo(id_equipo PK, marca, modelo, ram_gb, dni_usuario, usuario, sector)`

| id_equipo (PK) | marca | modelo | ram_gb | dni_usuario | usuario | sector |
|---|---|---|---|---|---|---|
| EQ-01 | Dell | OptiPlex 3080 | 8 | 30111222 | Acuña, Marta | Administración |
| EQ-02 | HP | ProDesk 400 | 16 | 28444555 | Bustos, Iván | Sistemas |
| EQ-03 | Dell | OptiPlex 3080 | 8 | 35777888 | Cáceres, Rocío | Administración |
| EQ-04 | Lenovo | ThinkCentre M70 | 16 | 28444555 | Bustos, Iván | Sistemas |
| EQ-05 | HP | ProDesk 400 | 16 | 41222333 | Duarte, Nahuel | Depósito |

`software(software PK)` — seis filas: Windows 10, Windows 11, Office 2019, Chrome, Visual Studio Code, Docker.

`equipo_software(id_equipo PK FK, software PK FK)` — las 13 filas.

### 3FN — dos cadenas

- `id_equipo → modelo → marca, ram_gb` — el enunciado aclara que **los modelos no se repiten entre marcas**
- `id_equipo → dni_usuario → usuario, sector`

`modelo(modelo PK, marca, ram_gb)`

| modelo (PK) | marca | ram_gb |
|---|---|---|
| OptiPlex 3080 | Dell | 8 |
| ProDesk 400 | HP | 16 |
| ThinkCentre M70 | Lenovo | 16 |

`usuario(dni_usuario PK, usuario, sector)`

| dni_usuario (PK) | usuario | sector |
|---|---|---|
| 30111222 | Acuña, Marta | Administración |
| 28444555 | Bustos, Iván | Sistemas |
| 35777888 | Cáceres, Rocío | Administración |
| 41222333 | Duarte, Nahuel | Depósito |

`equipo(id_equipo PK, modelo FK, dni_usuario FK)`

| id_equipo (PK) | modelo (FK) | dni_usuario (FK) |
|---|---|---|
| EQ-01 | OptiPlex 3080 | 30111222 |
| EQ-02 | ProDesk 400 | 28444555 |
| EQ-03 | OptiPlex 3080 | 35777888 |
| EQ-04 | ThinkCentre M70 | 28444555 |
| EQ-05 | ProDesk 400 | 41222333 |

### Modelo final

| Tabla | PK | FK | Otras columnas |
|---|---|---|---|
| `modelo` | modelo | — | marca, ram_gb |
| `usuario` | dni_usuario | — | usuario, sector |
| `equipo` | id_equipo | modelo, dni_usuario | — |
| `software` | software | — | — |
| `equipo_software` | (id_equipo, software) | id_equipo, software | — |

**Error común:** no ver que `marca` depende de `modelo`. La pista está puesta a propósito en el enunciado. Sin esa aclaración, `(marca, modelo)` sería la clave y no habría transitiva.

---

## Ejercicio 10 — La planilla de pruebas de aplicaciones

### Enunciado

Una empresa prueba aplicaciones en distintos teléfonos y redes, y lleva el registro en una sola hoja de cálculo. Éstas son sus columnas:

| Columna | Qué guarda |
|---|---|
| `cliente` | Nombre y número de cliente juntos, así: `Juan Perez; 115632` |
| `cliente_empresa` | Razón social del cliente |
| `carrier` | Compañía de telefonía donde se probó |
| `aplicación` | Nombre de la app probada |
| `descripción` | Descripción de la app |
| `foto_1`, `foto_2`, `foto_3` | Hasta tres fotos de la app |
| `prueba_1`, `descripción_1` | Nombre y descripción de la primera prueba |
| `prueba_2`, `descripción_2` | Nombre y descripción de la segunda prueba |
| `tipo_red` | Tipo de red: aparece cargado como `WAP`, `WEP` y también `wep` |
| `fecha` | Fecha de la corrida |
| `resultado_1`, `observaciones_1` | Resultado y observaciones de la primera prueba |
| `resultado_2`, `observaciones_2` | Resultado y observaciones de la segunda prueba |
| `foto_resultado_1`, `foto_resultado_2` | Foto del resultado de cada prueba |

Algunas filas de ejemplo:

| cliente | carrier | aplicación | prueba_1 | prueba_2 | tipo_red | resultado_1 | resultado_2 |
|---|---|---|---|---|---|---|---|
| Juan Perez; 115632 | Claro | Disney_Princesas | Login | Seleccionar personaje | WAP | Ok | Ok |
| Juan Perez; 115632 | Claro | Disney_Princesas | Login | Seleccionar personaje | WEP | Ok | Error |
| Juan Perez; 115632 | Movistar | Disney_Princesas | Login | Seleccionar personaje | WAP | Ok | Ok |
| Juan Perez; 115632 | Movistar | Linterna | Prender | Apagar | wep | Ok | Ok |

**Supuestos**

- Una aplicación es de un solo cliente, y su descripción no cambia entre corridas.
- Una prueba tiene siempre la misma descripción, sin importar en qué corrida se use.
- Una corrida es la combinación de una app, un carrier, un tipo de red y una fecha.
- Una app puede tener más de dos pruebas: la planilla se quedó corta.

**Se pide:**

1. Señalar **todas** las violaciones de 1FN que encuentres: son de tres tipos distintos.
2. Llevar el modelo a 3FN.
3. Indicar qué pasa con `tipo_red` cargado como `WEP` y como `wep`, y si eso lo resuelve la normalización o es otro problema.

### 0FN — la planilla

La misma muestra del enunciado, ahora con las columnas que allá quedaron afuera: la razón social, la fecha y las descripciones de cada prueba. Son las que hacen falta para ver qué se mueve en cada paso.

| cliente | cliente_empresa | aplicación | carrier | tipo_red | fecha | prueba_1 | descripción_1 | resultado_1 | prueba_2 | descripción_2 | resultado_2 |
|---|---|---|---|---|---|---|---|---|---|---|---|
| Juan Perez; 115632 | Juan Perez SA | Disney_Princesas | Claro | WAP | 01/05/2018 | Login | Cargar usuario y clave | Ok | Seleccionar personaje | Desplegar menú principal | Ok |
| Juan Perez; 115632 | Juan Perez SA | Disney_Princesas | Claro | WEP | 01/05/2018 | Login | Cargar usuario y clave | Ok | Seleccionar personaje | Desplegar menú principal | Error |
| Juan Perez; 115632 | Juan Perez SA | Disney_Princesas | Movistar | WAP | 01/05/2018 | Login | Cargar usuario y clave | Ok | Seleccionar personaje | Desplegar menú principal | Ok |
| Juan Perez; 115632 | Juan Perez SA | Linterna | Movistar | wep | 01/05/2018 | Prender | Prender la linterna | Ok | Apagar | Apagar la linterna | Ok |

*(La hoja real tiene además `foto_1/2/3`, `observaciones_N` y `foto_resultado_N`.)*

### Las tres violaciones de 1FN

| # | Tipo | Dónde |
|---|---|---|
| a | **Valor compuesto** | `cliente` guarda `Juan Perez; 115632`: nombre y número juntos |
| b | **Grupos de columnas repetidas** | tres grupos distintos: `foto_1/2/3`, `prueba_N` + `descripción_N`, y `resultado_N` + `observaciones_N` + `foto_resultado_N` |
| c | **Límite artificial** | una app puede tener más de dos pruebas, y la planilla no crece sin agregar columnas |

### 1FN — una fila por prueba de cada corrida

Se parte `cliente` en dos columnas y cada prueba pasa a su propia fila. La clave queda enorme: `(aplicación, carrier, tipo_red, fecha, prueba)`.

| aplicación (PK) | carrier (PK) | tipo_red (PK) | fecha (PK) | prueba (PK) | descripción_prueba | resultado | nro_cliente | nombre_cliente |
|---|---|---|---|---|---|---|---|---|
| Disney_Princesas | Claro | WAP | 01/05/2018 | Login | Cargar usuario y clave | Ok | 115632 | Juan Perez |
| Disney_Princesas | Claro | WAP | 01/05/2018 | Seleccionar personaje | Desplegar menú principal | Ok | 115632 | Juan Perez |
| Disney_Princesas | Claro | WEP | 01/05/2018 | Login | Cargar usuario y clave | Ok | 115632 | Juan Perez |
| Disney_Princesas | Claro | WEP | 01/05/2018 | Seleccionar personaje | Desplegar menú principal | Error | 115632 | Juan Perez |
| Disney_Princesas | Movistar | WAP | 01/05/2018 | Login | Cargar usuario y clave | Ok | 115632 | Juan Perez |
| Disney_Princesas | Movistar | WAP | 01/05/2018 | Seleccionar personaje | Desplegar menú principal | Ok | 115632 | Juan Perez |
| Linterna | Movistar | wep | 01/05/2018 | Prender | Prender la linterna | Ok | 115632 | Juan Perez |
| Linterna | Movistar | wep | 01/05/2018 | Apagar | Apagar la linterna | Ok | 115632 | Juan Perez |

Ya se puede agregar una tercera prueba sin tocar la estructura. Pero *"Cargar usuario y clave"* quedó escrito tres veces.

### 2FN — qué depende de qué parte de esa clave

| Columnas | Dependen de | Van a |
|---|---|---|
| `descripción_app, nro_cliente, nombre_cliente, razon_social` | solo `aplicación` | tabla APLICACION |
| `descripción_prueba` | solo `prueba` | tabla PRUEBA |
| `resultado, observaciones, foto_resultado` | la clave completa | se quedan |

Las cuatro columnas de la corrida (`aplicación, carrier, tipo_red, fecha`) se reemplazan por un `id_corrida`, para no arrastrarlas en todas las FK.

`corrida(id_corrida PK, aplicación, carrier, tipo_red, fecha)`

| id_corrida (PK) | aplicación | carrier | tipo_red | fecha |
|---|---|---|---|---|
| 1 | Disney_Princesas | Claro | WAP | 01/05/2018 |
| 2 | Disney_Princesas | Claro | WEP | 01/05/2018 |
| 3 | Disney_Princesas | Movistar | WAP | 01/05/2018 |
| 4 | Linterna | Movistar | wep | 01/05/2018 |

`prueba(id_prueba PK, id_app FK, nombre, descripcion)`

| id_prueba (PK) | id_app (FK) | nombre | descripcion |
|---|---|---|---|
| 1 | 1 | Login | Cargar usuario y clave |
| 2 | 1 | Seleccionar personaje | Desplegar menú principal |
| 3 | 2 | Prender | Prender la linterna |
| 4 | 2 | Apagar | Apagar la linterna |

### 3FN — sale el cliente, y los catálogos

En `aplicacion`, `nro_cliente → nombre_cliente, razon_social` es transitiva.

`cliente(nro_cliente PK, nombre, razon_social)` · `aplicacion(id_app PK, nombre, descripcion, nro_cliente FK)`

| nro_cliente (PK) | nombre | razon_social | | id_app (PK) | nombre | nro_cliente (FK) |
|---|---|---|---|---|---|---|
| 115632 | Juan Perez | Juan Perez SA | | 1 | Disney_Princesas | 115632 |
| | | | | 2 | Linterna | 115632 |

Y `carrier` y `tipo_red` pasan a ser catálogos, con una FK desde `corrida`.

### Modelo final

| Tabla | PK | FK | Otras columnas |
|---|---|---|---|
| `cliente` | nro_cliente | — | nombre, razon_social |
| `aplicacion` | id_app | nro_cliente | nombre, descripcion |
| `foto_app` | (id_app, nro_foto) | id_app | archivo |
| `prueba` | id_prueba | id_app | nombre, descripcion |
| `carrier` | carrier | — | — |
| `tipo_red` | tipo_red | — | — |
| `corrida` | id_corrida | id_app, carrier, tipo_red | fecha |
| `resultado` | (id_corrida, id_prueba) | id_corrida, id_prueba | resultado, observaciones, foto_resultado |

Así quedan los datos del ejemplo:

`cliente`

| nro_cliente (PK) | nombre | razon_social |
|---|---|---|
| 115632 | Juan Perez | Juan Perez SA |

`aplicacion` · `prueba`

| id_app (PK) | nombre | nro_cliente (FK) | | id_prueba (PK) | id_app (FK) | nombre |
|---|---|---|---|---|---|---|
| 1 | Disney_Princesas | 115632 | | 1 | 1 | Login |
| 2 | Linterna | 115632 | | 2 | 1 | Seleccionar personaje |
| | | | | 3 | 2 | Prender |
| | | | | 4 | 2 | Apagar |

`corrida`

| id_corrida (PK) | id_app (FK) | carrier (FK) | tipo_red (FK) | fecha |
|---|---|---|---|---|
| 1 | 1 | Claro | WAP | 01/05/2018 |
| 2 | 1 | Claro | WEP | 01/05/2018 |
| 3 | 1 | Movistar | WAP | 01/05/2018 |
| 4 | 2 | Movistar | WEP | 01/05/2018 |

`resultado`

| id_corrida (PK, FK) | id_prueba (PK, FK) | resultado | observaciones |
|---|---|---|---|
| 1 | 1 | Ok | — |
| 1 | 2 | Ok | — |
| 2 | 1 | Ok | — |
| 2 | 2 | Error | No se pudo seleccionar |
| 3 | 1 | Ok | — |
| 3 | 2 | Ok | — |
| 4 | 3 | Ok | — |
| 4 | 4 | Ok | — |

`foto_app` es otra **entidad débil**, como los bultos del ejercicio 5: las fotos no tienen identificador propio, se numeran dentro de su aplicación.

### `WEP` y `wep`: la pregunta 3

**No lo resuelve la normalización.** Se puede tener un modelo impecable en 3FN y seguir cargando `WEP`, `wep` y `Wep` como tres valores distintos. Las formas normales hablan de **dónde** vive cada dato, no de **qué valores** puede tomar.

Lo que sí lo resuelve:

- una tabla `tipo_red` como catálogo, con una FK desde `corrida`: entonces solo se pueden usar los valores que existan en el catálogo;
- o un dominio o un `CHECK` que limite los valores aceptados.

Es la distinción de **DKNF**: una restricción sobre los valores no es una cuestión de descomposición, es una cuestión de dominio.

**Error común:** armar una sola tabla `prueba` con `id_app`, `carrier`, `tipo_red` y `fecha` adentro. La prueba (`Login`, `Apagar`) existe con independencia de la corrida: la misma prueba se ejecuta en Claro y en Movistar. Mezclarlas obliga a repetir su descripción en cada corrida.
