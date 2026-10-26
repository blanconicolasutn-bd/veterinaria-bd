# Normalización (Unidad V)

Todo el material de normalización está acá: las dos guías de ejercicios, sus resoluciones, y los scripts para seguir el camino completo en tu propia base.

## Las guías

| Archivo | Qué es |
|---|---|
| [`Normalización - 3 ejercicios (Clase 7).md`](Normalizaci%C3%B3n%20-%203%20ejercicios%20(Clase%207).md) | Tres planillas para llevar a 3FN. Se entregan por Pull Request. |
| [`Normalización - 10 ejercicios hasta 3FN.md`](Normalizaci%C3%B3n%20-%2010%20ejercicios%20hasta%203FN.md) | Diez ejercicios. En los primeros seis los datos vienen en una planilla; en los últimos cuatro hay que deducir las dependencias del relato del sistema. |

Las resoluciones paso a paso están en [`resoluciones/`](resoluciones). Muestran **cómo quedan los datos** en cada forma normal, no solo el esquema, y cada ejercicio cierra con el error más común.

## Los scripts

Se corren en el SQL Editor de tu propio proyecto de Supabase. Los cuatro son idempotentes: se pueden volver a correr las veces que haga falta.

| Script | Qué hace |
|---|---|
| `03_normalizacion_0fn_a_5fn.sql` | Crea la veterinaria **en todas las formas normales a la vez**: 22 tablas donde el prefijo dice en qué forma normal está cada una (`fn0_`, `fn1_`, `fn2_`, `fn3_`, `fn3b_` para BCNF, `fn4_`, `fn5_`, `fn6_`). Contar prefijos te dice cuántas tablas hay en cada etapa. |
| `04_normalizacion_consultas_clase.sql` | **El recorrido paso a paso**, en bloques numerados `[0.1]` → `[C.2]`. Cada bloque tiene arriba un comentario que dice qué mirar. |
| `05_normalizacion_ejercicios.sql` | Las tablas de los ejercicios: los **tres de clase** con enunciado solamente, y los **cuatro de la casa** con enunciado y solución. |
| `06_normalizacion_ejercicios_consultas.sql` | Las verificaciones de esos ejercicios: pistas para los de clase, y los bloques `[V.x]` que reconstruyen cada planilla original desde las tablas de la solución. |

El `03` y el `05` son independientes del esquema de la veterinaria: no hace falta haber corrido `sql/01_esquema.sql` ni `sql/02_datos.sql`.

## El orden

1. Corré `03_normalizacion_0fn_a_5fn.sql`. Te deja las 22 tablas.
2. Abrí `04_normalizacion_consultas_clase.sql` y **corré un bloque por vez**: seleccionalo con el mouse y apretá `Ctrl+Enter` (`Cmd+Enter` en Mac). Supabase ejecuta solo lo que esté seleccionado.
3. Para los ejercicios, corré `05_normalizacion_ejercicios.sql` y verificá con los bloques de `06_normalizacion_ejercicios_consultas.sql`.

> No corras un archivo entero de una: Supabase muestra únicamente el resultado del **último** `SELECT`, así que perderías todos los demás.

## Qué se ve en cada etapa

| Etapa | Prefijo | Tablas | Bloques del `04` | Qué vas a ver |
|---|---|---|---|---|
| 0FN | `fn0_` | 1 | `[0.1]` `[0.2]` | La planilla, con la lista adentro de una celda |
| 1FN | `fn1_` | 1 | `[1.1]` a `[1.3]` | Una fila por medicamento — y la redundancia que aumenta |
| 2FN | `fn2_` | 2 | `[2.1]` a `[2.4]` | Las dos tablas, y lo que todavía queda repetido |
| 3FN | `fn3_` | 7 | `[3.1]` a `[3.4]` | Las seis tablas, más la que trae la regla nueva |
| BCNF | `fn3b_` | 3 | `[B.1]` a `[B.5]` | La anomalía de inserción, probada en vivo |
| 4FN | `fn4_` | 3 | `[4.1]` a `[4.5]` | Las filas que se multiplican, y el join que las devuelve |
| 5FN | `fn5_` | 4 | `[5.1]` a `[5.6]` | La fila espuria al unir solo dos proyecciones |
| 6FN | `fn6_` | 1 | `[6.1]` a `[6.6]` | La restricción que se muda del `CHECK` al dominio |

Los bloques `[C.x]` del final cuentan las tablas y las filas de cada etapa, leyéndolas del catálogo del motor.
