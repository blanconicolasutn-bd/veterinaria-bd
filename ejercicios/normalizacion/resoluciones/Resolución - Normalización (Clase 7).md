# Resolución — Ejercicios de normalización

Resolución de los ejercicios de [`Normalización - 3 ejercicios (Clase 7).md`](../Normalizaci%C3%B3n%20-%203%20ejercicios%20(Clase%207).md). Conviene intentar resolverlos antes de mirarla.

Cada ejercicio sigue el mismo esquema que vimos en la Clase 7:

1. **0FN:** qué problema tiene la planilla.
2. **1FN:** se sacan las listas y las columnas repetidas, y se elige la PK.
3. **2FN:** se revisa de qué parte de la PK depende cada columna y se separan las dependencias parciales.
4. **3FN:** se buscan las cadenas `clave → A → B` y se separan las dependencias transitivas.
5. **Modelo final** y errores comunes.

Notación: `tabla(columna PK, columna, columna FK → otra_tabla)`.

---

## Ejercicio 1 — El corralón

### 0FN: el problema

La planilla tiene un **grupo de columnas repetidas**: `producto_1, precio_1, cant_1` y `producto_2, precio_2, cant_2`. Además limita la factura a dos productos y deja celdas vacías (A-0002, A-0006).

### 1FN: una fila por producto de cada factura

Se pasa cada grupo repetido a su propia fila. Ninguna columna sola identifica la fila: la factura A-0001 tiene dos filas y Cemento aparece en varias facturas. La PK es compuesta.

`linea(nro_factura PK, producto PK, fecha, cuit, cliente, domicilio, precio, cantidad)`

| nro_factura (PK) | producto (PK) | fecha | cuit | cliente | domicilio | precio | cantidad |
|---|---|---|---|---|---|---|---|
| A-0001 | Cemento | 01/10/2026 | 20-30111222-3 | Pérez Hnos. | Colón 1200 | 9500 | 10 |
| A-0001 | Arena | 01/10/2026 | 20-30111222-3 | Pérez Hnos. | Colón 1200 | 32000 | 2 |
| A-0002 | Cal | 01/10/2026 | 27-28444555-1 | López, Marta | Vélez 450 | 6200 | 5 |
| A-0003 | Arena | 02/10/2026 | 20-30111222-3 | Pérez Hnos. | Colón 1200 | 32000 | 1 |
| A-0003 | Cemento | 02/10/2026 | 20-30111222-3 | Pérez Hnos. | Colón 1200 | 9500 | 4 |
| A-0004 | Hierro 8 | 02/10/2026 | 30-71555666-9 | Constr. Sur | San Juan 88 | 14800 | 20 |
| A-0004 | Cemento | 02/10/2026 | 30-71555666-9 | Constr. Sur | San Juan 88 | 9500 | 15 |
| A-0005 | Ladrillo | 03/10/2026 | 27-28444555-1 | López, Marta | Vélez 450 | 450 | 500 |
| A-0005 | Cal | 03/10/2026 | 27-28444555-1 | López, Marta | Vélez 450 | 6200 | 2 |
| A-0006 | Arena | 03/10/2026 | 20-33777888-4 | Ríos, Pablo | Duarte 310 | 32000 | 3 |
| A-0007 | Hierro 8 | 04/10/2026 | 30-71555666-9 | Constr. Sur | San Juan 88 | 14800 | 10 |
| A-0007 | Ladrillo | 04/10/2026 | 30-71555666-9 | Constr. Sur | San Juan 88 | 450 | 1200 |

Se eliminó: el grupo de columnas repetidas. Quedan 12 filas.

### 2FN: separar lo que depende de una parte de la PK

La PK es `(nro_factura, producto)`. De qué depende cada columna:

| Columnas | ¿Qué las determina? | Resultado |
|---|---|---|
| fecha, cuit, cliente, domicilio | solo `nro_factura` (parte de la PK) | dependencia parcial → tabla `factura` |
| precio | solo `producto` (parte de la PK; supuesto: precio de lista) | dependencia parcial → tabla `producto` |
| cantidad | `nro_factura` + `producto` (toda la PK) | se queda → tabla `detalle` |

Hay dos dependencias parciales, una por cada parte de la PK. Se separan en dos iteraciones (el orden no importa: empezando por `nro_factura` se llega a las mismas tablas).

#### Iteración 1: lo que depende solo de `producto`

```
producto(producto PK, precio)
linea(nro_factura PK, producto PK FK → producto, fecha, cuit, cliente, domicilio, cantidad)
```

**producto**

| producto (PK) | precio |
|---|---|
| Cemento | 9500 |
| Arena | 32000 |
| Cal | 6200 |
| Hierro 8 | 14800 |
| Ladrillo | 450 |

**linea** (tabla intermedia, todavía no está en 2FN)

| nro_factura (PK) | producto (PK, FK) | fecha | cuit | cliente | domicilio | cantidad |
|---|---|---|---|---|---|---|
| A-0001 | Cemento | 01/10/2026 | 20-30111222-3 | Pérez Hnos. | Colón 1200 | 10 |
| A-0001 | Arena | 01/10/2026 | 20-30111222-3 | Pérez Hnos. | Colón 1200 | 2 |
| A-0002 | Cal | 01/10/2026 | 27-28444555-1 | López, Marta | Vélez 450 | 5 |
| A-0003 | Arena | 02/10/2026 | 20-30111222-3 | Pérez Hnos. | Colón 1200 | 1 |
| A-0003 | Cemento | 02/10/2026 | 20-30111222-3 | Pérez Hnos. | Colón 1200 | 4 |
| A-0004 | Hierro 8 | 02/10/2026 | 30-71555666-9 | Constr. Sur | San Juan 88 | 20 |
| A-0004 | Cemento | 02/10/2026 | 30-71555666-9 | Constr. Sur | San Juan 88 | 15 |
| A-0005 | Ladrillo | 03/10/2026 | 27-28444555-1 | López, Marta | Vélez 450 | 500 |
| A-0005 | Cal | 03/10/2026 | 27-28444555-1 | López, Marta | Vélez 450 | 2 |
| A-0006 | Arena | 03/10/2026 | 20-33777888-4 | Ríos, Pablo | Duarte 310 | 3 |
| A-0007 | Hierro 8 | 04/10/2026 | 30-71555666-9 | Constr. Sur | San Juan 88 | 10 |
| A-0007 | Ladrillo | 04/10/2026 | 30-71555666-9 | Constr. Sur | San Juan 88 | 1200 |

Se eliminó: `producto → precio`. `linea` sigue con PK compuesta y `fecha, cuit, cliente, domicilio` dependen solo de `nro_factura`: falta otra iteración.

#### Iteración 2: lo que depende solo de `nro_factura`

```
factura(nro_factura PK, fecha, cuit, cliente, domicilio)
detalle(nro_factura PK FK → factura, producto PK FK → producto, cantidad)
```

`cantidad` no va a `factura`: depende de las dos columnas de la PK (A-0001 tiene 10 de Cemento y 2 de Arena). Queda en la tabla que conserva la PK compuesta, que pasa a llamarse `detalle`.

**factura**

| nro_factura (PK) | fecha | cuit | cliente | domicilio |
|---|---|---|---|---|
| A-0001 | 01/10/2026 | 20-30111222-3 | Pérez Hnos. | Colón 1200 |
| A-0002 | 01/10/2026 | 27-28444555-1 | López, Marta | Vélez 450 |
| A-0003 | 02/10/2026 | 20-30111222-3 | Pérez Hnos. | Colón 1200 |
| A-0004 | 02/10/2026 | 30-71555666-9 | Constr. Sur | San Juan 88 |
| A-0005 | 03/10/2026 | 27-28444555-1 | López, Marta | Vélez 450 |
| A-0006 | 03/10/2026 | 20-33777888-4 | Ríos, Pablo | Duarte 310 |
| A-0007 | 04/10/2026 | 30-71555666-9 | Constr. Sur | San Juan 88 |

**detalle**

| nro_factura (PK, FK) | producto (PK, FK) | cantidad |
|---|---|---|
| A-0001 | Cemento | 10 |
| A-0001 | Arena | 2 |
| A-0002 | Cal | 5 |
| A-0003 | Arena | 1 |
| A-0003 | Cemento | 4 |
| A-0004 | Hierro 8 | 20 |
| A-0004 | Cemento | 15 |
| A-0005 | Ladrillo | 500 |
| A-0005 | Cal | 2 |
| A-0006 | Arena | 3 |
| A-0007 | Hierro 8 | 10 |
| A-0007 | Ladrillo | 1200 |

Se eliminó: `nro_factura → fecha, cuit, cliente, domicilio`. Con las dos iteraciones queda en 2FN: `factura`, `producto` y `detalle`. `producto` y `detalle` ya están en 3FN. En `factura` todavía se repiten "Pérez Hnos. · Colón 1200" y "Constr. Sur · San Juan 88".

### 3FN: separar las dependencias transitivas

En `factura`: `nro_factura → cuit → cliente, domicilio`. El cliente y el domicilio dependen del CUIT, que no es clave de `factura`.

```
cliente(cuit PK, cliente, domicilio)
factura(nro_factura PK, fecha, cuit FK → cliente)
```

**cliente**

| cuit (PK) | cliente | domicilio |
|---|---|---|
| 20-30111222-3 | Pérez Hnos. | Colón 1200 |
| 27-28444555-1 | López, Marta | Vélez 450 |
| 30-71555666-9 | Constr. Sur | San Juan 88 |
| 20-33777888-4 | Ríos, Pablo | Duarte 310 |

**factura**

| nro_factura (PK) | fecha | cuit (FK) |
|---|---|---|
| A-0001 | 01/10/2026 | 20-30111222-3 |
| A-0002 | 01/10/2026 | 27-28444555-1 |
| A-0003 | 02/10/2026 | 20-30111222-3 |
| A-0004 | 02/10/2026 | 30-71555666-9 |
| A-0005 | 03/10/2026 | 27-28444555-1 |
| A-0006 | 03/10/2026 | 20-33777888-4 |
| A-0007 | 04/10/2026 | 30-71555666-9 |

Se eliminó: la dependencia transitiva `cuit → cliente, domicilio`.

### Modelo final (4 tablas)

```
cliente(cuit PK, cliente, domicilio)
factura(nro_factura PK, fecha, cuit FK → cliente)
producto(producto PK, precio)
detalle(nro_factura PK FK → factura, producto PK FK → producto, cantidad)
```

1 tabla → 1FN: 1 tabla → 2FN: 3 tablas → 3FN: 4 tablas.

### Errores comunes

- Dejar `precio` en `detalle`. Con el supuesto del enunciado (precio de lista) depende solo del producto. Guardarlo en `detalle` tiene sentido solo si se quiere registrar el precio *al momento de la venta*, y eso es cambiar el supuesto.
- Usar `nro_factura` sola como PK en 1FN: no identifica la fila (A-0001 tiene dos).
- Hacer 2FN y 3FN de una sola vez sin decir qué dependencia es parcial y cuál transitiva.
- Separar `cliente` en 2FN diciendo que "depende de la factura": es una dependencia transitiva (pasa por el CUIT), se resuelve en 3FN.

---

## Ejercicio 2 — El club

### 0FN: el problema

La columna `actividades` tiene **listas separadas por coma** ("Natación, Fútbol"): una celda con varios valores.

### 1FN: una fila por socio y actividad

`socio_actividad(nro_socio PK, actividad PK, socio, barrio, categoría, cuota)`

| nro_socio (PK) | actividad (PK) | socio | barrio | categoría | cuota |
|---|---|---|---|---|---|
| 101 | Natación | Gómez, Ana | Centro | Mayor | 25000 |
| 101 | Fútbol | Gómez, Ana | Centro | Mayor | 25000 |
| 102 | Fútbol | Paz, Luis | Alberdi | Menor | 15000 |
| 103 | Natación | Ruiz, Sol | Centro | Mayor | 25000 |
| 103 | Vóley | Ruiz, Sol | Centro | Mayor | 25000 |
| 103 | Fútbol | Ruiz, Sol | Centro | Mayor | 25000 |
| 104 | Ajedrez | Díaz, Leo | Güemes | Vitalicio | 0 |
| 105 | Vóley | Sosa, Eva | Alberdi | Menor | 15000 |
| 105 | Natación | Sosa, Eva | Alberdi | Menor | 15000 |
| 106 | Ajedrez | Vera, Tomás | Cofico | Mayor | 25000 |
| 106 | Fútbol | Vera, Tomás | Cofico | Mayor | 25000 |
| 107 | Natación | Luna, Mía | Güemes | Menor | 15000 |

Se eliminó: la lista de actividades. Quedan 12 filas. `nro_socio` solo ya no alcanza como PK (el 101 tiene dos filas).

### 2FN: separar lo que depende de una parte de la PK

La PK es `(nro_socio, actividad)`.

| Columnas | ¿Qué las determina? | Resultado |
|---|---|---|
| socio, barrio, categoría, cuota | solo `nro_socio` (parte de la PK) | dependencia parcial → tabla `socio` |
| — | `nro_socio` + `actividad` | `socio_actividad` queda solo con la PK |

```
socio(nro_socio PK, socio, barrio, categoría, cuota)
socio_actividad(nro_socio PK FK → socio, actividad PK)
```

**socio**

| nro_socio (PK) | socio | barrio | categoría | cuota |
|---|---|---|---|---|
| 101 | Gómez, Ana | Centro | Mayor | 25000 |
| 102 | Paz, Luis | Alberdi | Menor | 15000 |
| 103 | Ruiz, Sol | Centro | Mayor | 25000 |
| 104 | Díaz, Leo | Güemes | Vitalicio | 0 |
| 105 | Sosa, Eva | Alberdi | Menor | 15000 |
| 106 | Vera, Tomás | Cofico | Mayor | 25000 |
| 107 | Luna, Mía | Güemes | Menor | 15000 |

**socio_actividad**

| nro_socio (PK, FK) | actividad (PK) |
|---|---|
| 101 | Natación |
| 101 | Fútbol |
| 102 | Fútbol |
| 103 | Natación |
| 103 | Vóley |
| 103 | Fútbol |
| 104 | Ajedrez |
| 105 | Vóley |
| 105 | Natación |
| 106 | Ajedrez |
| 106 | Fútbol |
| 107 | Natación |

A diferencia del corralón, acá hay **una sola iteración**: ninguna columna depende solo de `actividad`, porque la planilla no tiene datos propios de la actividad. Si los tuviera (por ejemplo `profesor` u `horario`), habría una segunda iteración que separaría la tabla `actividad`, igual que salió `producto` en el ejercicio 1.

Se eliminó: la dependencia parcial `nro_socio → socio, barrio, categoría, cuota`. `socio_actividad` es una tabla intermedia (la N:M socio–actividad): no tiene columnas propias y es correcto que quede solo con la PK.

### 3FN: separar las dependencias transitivas

En `socio`: `nro_socio → categoría → cuota`. La cuota depende de la categoría (supuesto), no del socio.

```
categoria(categoría PK, cuota)
socio(nro_socio PK, socio, barrio, categoría FK → categoria)
```

**categoria**

| categoría (PK) | cuota |
|---|---|
| Mayor | 25000 |
| Menor | 15000 |
| Vitalicio | 0 |

**socio**

| nro_socio (PK) | socio | barrio | categoría (FK) |
|---|---|---|---|
| 101 | Gómez, Ana | Centro | Mayor |
| 102 | Paz, Luis | Alberdi | Menor |
| 103 | Ruiz, Sol | Centro | Mayor |
| 104 | Díaz, Leo | Güemes | Vitalicio |
| 105 | Sosa, Eva | Alberdi | Menor |
| 106 | Vera, Tomás | Cofico | Mayor |
| 107 | Luna, Mía | Güemes | Menor |

Se eliminó: la dependencia transitiva `categoría → cuota`.

### Modelo final (3 tablas, o 4 con el catálogo de actividades)

```
categoria(categoría PK, cuota)
socio(nro_socio PK, socio, barrio, categoría FK → categoria)
socio_actividad(nro_socio PK FK → socio, actividad PK FK → actividad)
actividad(actividad PK)          -- opcional: catálogo
```

La tabla `actividad` no la exige la normalización: no hay ningún dato que dependa solo de la actividad. Agregarla como catálogo es una buena práctica: `socio_actividad.actividad` pasa a tener una FK y se evitan errores de tipeo ("Futbol" / "Fútbol").

1 tabla → 1FN: 1 tabla → 2FN: 2 tablas → 3FN: 3 tablas (4 con `actividad`).

### Errores comunes

- Resolver la lista con columnas `actividad_1`, `actividad_2`, `actividad_3`: sigue sin estar en 1FN (es otro grupo repetido).
- Dejar `cuota` en `socio`: es la transitiva del ejercicio.
- Pensar que `socio_actividad` "está vacía" o sobra porque no tiene columnas aparte de la PK: es la tabla que guarda qué socio hace qué actividad.
- Sacar `barrio` de `socio`: depende directamente del socio, así que se queda.

---

## Ejercicio 3 — Los turnos

### Forma normal de la planilla

- **1FN: sí.** No hay listas ni columnas repetidas, y `nro_turno` identifica cada fila.
- **2FN: sí.** La PK es de una sola columna (`nro_turno`), así que no puede haber dependencias parciales. Es el punto central del ejercicio: con PK simple, 1FN implica 2FN.
- **3FN: no.** Hay dos dependencias transitivas.

La planilla está en **2FN**.

### 1FN y 2FN: sin cambios

`turno(nro_turno PK, fecha, hora, dni_paciente, paciente, obra_social, matrícula, médico, especialidad)`

### 3FN: separar las dependencias transitivas

| Cadena | Dónde está la transitiva | Qué se hace |
|---|---|---|
| `nro_turno → dni_paciente → paciente, obra_social` | el paciente y la obra social dependen del DNI, no del turno | tabla `paciente` |
| `nro_turno → matrícula → médico, especialidad` | el médico y la especialidad dependen de la matrícula, no del turno | tabla `medico` |

```
paciente(dni_paciente PK, paciente, obra_social)
medico(matrícula PK, médico, especialidad)
turno(nro_turno PK, fecha, hora, dni_paciente FK → paciente, matrícula FK → medico)
```

**paciente**

| dni_paciente (PK) | paciente | obra_social |
|---|---|---|
| 30111222 | Sosa, Juan | OSDE |
| 28444555 | Vera, Ana | PAMI |
| 35666777 | Luna, Ema | Particular |
| 40222333 | Paz, Lucas | Swiss Medical |
| 33555999 | Gil, Marta | OSDE |

**medico**

| matrícula (PK) | médico | especialidad |
|---|---|---|
| 4521 | Méndez | Cardiología |
| 3870 | Ríos | Clínica médica |
| 5102 | Herrera | Traumatología |

**turno**

| nro_turno (PK) | fecha | hora | dni_paciente (FK) | matrícula (FK) |
|---|---|---|---|---|
| 5001 | 06/10/2026 | 09:00 | 30111222 | 4521 |
| 5002 | 06/10/2026 | 09:30 | 28444555 | 4521 |
| 5003 | 06/10/2026 | 10:00 | 30111222 | 3870 |
| 5004 | 07/10/2026 | 09:00 | 35666777 | 3870 |
| 5005 | 07/10/2026 | 09:30 | 40222333 | 5102 |
| 5006 | 07/10/2026 | 10:00 | 28444555 | 3870 |
| 5007 | 08/10/2026 | 11:00 | 40222333 | 5102 |
| 5008 | 08/10/2026 | 11:30 | 33555999 | 4521 |

Se eliminó: las dependencias transitivas `dni_paciente → paciente, obra_social` y `matrícula → médico, especialidad`.

### Modelo final (3 tablas)

```
paciente(dni_paciente PK, paciente, obra_social)
medico(matrícula PK, médico, especialidad)
turno(nro_turno PK, fecha, hora, dni_paciente FK → paciente, matrícula FK → medico)
```

1 tabla (ya en 2FN) → 3FN: 3 tablas.

### Errores comunes

- Decir que no está en 2FN "porque hay datos repetidos": la repetición es síntoma de la transitiva (3FN). Con PK simple no hay dependencias parciales.
- Creer que 3FN obliga a llevar `obra_social` o `especialidad` a tablas propias: no tienen datos propios, así que no hace falta. Se pueden agregar como catálogo, igual que `actividad` en el ejercicio 2.
- Dejar `especialidad` en `turno` porque "el turno es de esa especialidad": con el supuesto (un médico, una especialidad) depende de la matrícula.
- Detalle de diseño: "Particular" no es una obra social. En un sistema real se podría dejar `obra_social` en NULL para esos pacientes; no cambia la normalización.
