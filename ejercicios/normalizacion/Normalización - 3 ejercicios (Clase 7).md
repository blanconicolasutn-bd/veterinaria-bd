# Diseño y Administración de Base de Datos

## Guía de ejercicios — Normalización (Unidad V)

Tres planillas para llevar hasta la **tercera forma normal (3FN)**. Son los ejercicios para la casa de la Clase 7: se entregan por Pull Request y se revisan en la Clase 8.

La resolución paso a paso está en [`resoluciones/`](resoluciones/Resoluci%C3%B3n%20-%20Normalizaci%C3%B3n%20(Clase%207).md).

---

### Repaso rápido

- **Dependencia funcional (X → Y):** cada valor de X determina un único valor de Y. Si conozco X, conozco Y.
- **1FN:** cada celda guarda un único valor (atómico), no hay grupos de columnas repetidas y cada fila se identifica por una clave primaria.
- **2FN:** está en 1FN y ninguna columna que no es clave depende de *solo una parte* de la clave primaria (no hay dependencias parciales). Si la PK es de una sola columna, la tabla ya está en 2FN.
- **3FN:** está en 2FN y ninguna columna que no es clave depende de *otra columna que tampoco es clave* (no hay dependencias transitivas: clave → A → B).

Para recordar: cada columna depende **de la clave** (1FN), **de toda la clave** (2FN) y **de nada más que la clave** (3FN).

---

### Ejercicio 1 — El corralón (columnas repetidas)

Planilla de facturas de un corralón de materiales. Cada factura tiene a lo sumo dos productos.

| nro_factura | fecha | cuit | cliente | domicilio | producto_1 | precio_1 | cant_1 | producto_2 | precio_2 | cant_2 |
|---|---|---|---|---|---|---|---|---|---|---|
| A-0001 | 01/10/2026 | 20-30111222-3 | Pérez Hnos. | Colón 1200 | Cemento | 9500 | 10 | Arena | 32000 | 2 |
| A-0002 | 01/10/2026 | 27-28444555-1 | López, Marta | Vélez 450 | Cal | 6200 | 5 | | | |
| A-0003 | 02/10/2026 | 20-30111222-3 | Pérez Hnos. | Colón 1200 | Arena | 32000 | 1 | Cemento | 9500 | 4 |
| A-0004 | 02/10/2026 | 30-71555666-9 | Constr. Sur | San Juan 88 | Hierro 8 | 14800 | 20 | Cemento | 9500 | 15 |
| A-0005 | 03/10/2026 | 27-28444555-1 | López, Marta | Vélez 450 | Ladrillo | 450 | 500 | Cal | 6200 | 2 |
| A-0006 | 03/10/2026 | 20-33777888-4 | Ríos, Pablo | Duarte 310 | Arena | 32000 | 3 | | | |
| A-0007 | 04/10/2026 | 30-71555666-9 | Constr. Sur | San Juan 88 | Hierro 8 | 14800 | 10 | Ladrillo | 450 | 1200 |

**Supuestos**

- El precio es el precio de lista del producto: no cambia de una factura a otra.
- Cada producto se identifica por su nombre.
- Cada factura es de un solo cliente, que se identifica por su CUIT.

**Se pide:** llevar la planilla a 1FN, 2FN y 3FN. En cada paso, indicar qué dependencia eliminaron y cómo quedan las tablas (PK y FK).

---

### Ejercicio 2 — El club (listas en una celda)

Planilla de socios de un club. La cuota depende de la categoría del socio.

| nro_socio | socio | barrio | categoría | cuota | actividades |
|---|---|---|---|---|---|
| 101 | Gómez, Ana | Centro | Mayor | 25000 | Natación, Fútbol |
| 102 | Paz, Luis | Alberdi | Menor | 15000 | Fútbol |
| 103 | Ruiz, Sol | Centro | Mayor | 25000 | Natación, Vóley, Fútbol |
| 104 | Díaz, Leo | Güemes | Vitalicio | 0 | Ajedrez |
| 105 | Sosa, Eva | Alberdi | Menor | 15000 | Vóley, Natación |
| 106 | Vera, Tomás | Cofico | Mayor | 25000 | Ajedrez, Fútbol |
| 107 | Luna, Mía | Güemes | Menor | 15000 | Natación |

**Supuestos**

- Cada socio tiene una sola categoría.
- Todos los socios de una misma categoría pagan la misma cuota.
- Cada actividad se identifica por su nombre.

**Se pide:** llevar la planilla a 1FN, 2FN y 3FN. En cada paso, indicar qué dependencia eliminaron y cómo quedan las tablas (PK y FK).

---

### Ejercicio 3 — Los turnos (PK simple)

Planilla de turnos de un centro médico. Cada turno tiene un número único.

| nro_turno | fecha | hora | dni_paciente | paciente | obra_social | matrícula | médico | especialidad |
|---|---|---|---|---|---|---|---|---|
| 5001 | 06/10/2026 | 09:00 | 30111222 | Sosa, Juan | OSDE | 4521 | Méndez | Cardiología |
| 5002 | 06/10/2026 | 09:30 | 28444555 | Vera, Ana | PAMI | 4521 | Méndez | Cardiología |
| 5003 | 06/10/2026 | 10:00 | 30111222 | Sosa, Juan | OSDE | 3870 | Ríos | Clínica médica |
| 5004 | 07/10/2026 | 09:00 | 35666777 | Luna, Ema | Particular | 3870 | Ríos | Clínica médica |
| 5005 | 07/10/2026 | 09:30 | 40222333 | Paz, Lucas | Swiss Medical | 5102 | Herrera | Traumatología |
| 5006 | 07/10/2026 | 10:00 | 28444555 | Vera, Ana | PAMI | 3870 | Ríos | Clínica médica |
| 5007 | 08/10/2026 | 11:00 | 40222333 | Paz, Lucas | Swiss Medical | 5102 | Herrera | Traumatología |
| 5008 | 08/10/2026 | 11:30 | 33555999 | Gil, Marta | OSDE | 4521 | Méndez | Cardiología |

**Supuestos**

- Cada paciente tiene una sola obra social.
- Cada médico tiene una sola especialidad.
- El paciente se identifica por su DNI y el médico por su matrícula.

**Se pide:**

1. Indicar en qué forma normal está la planilla, y por qué.
2. Llevarla a 3FN, indicando qué dependencias eliminaron (PK y FK).

---

### Cómo entregarlo

1. Hacer **Fork** de este repositorio (botón arriba a la derecha en GitHub).
2. En tu fork, crear el archivo `practica/apellido-nombre/normalizacion.md`.
3. Escribir los tres ejercicios con el formato de abajo: una sección por paso (1FN, 2FN, 3FN).
4. Abrir el **Pull Request** hacia este repositorio, igual que en la Clase 4.

Las tablas se escriben como `tabla(columna PK, columna, columna FK → otra_tabla, ...)`.

```md
# Ejercicio 1: el corralón

## 1FN
linea(nro_factura PK, producto PK, ...)
Se eliminó: ...

## 2FN
factura(nro_factura PK, ...)
producto(producto PK, ...)
Se eliminó: ...

## 3FN
...

# Ejercicio 2: el club
...
```
