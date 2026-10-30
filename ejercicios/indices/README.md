# Índices y optimización de consultas (Unidad VII)

Dos scripts para ver, en tu propia base, cuándo el motor usa un índice y cuándo no.

## Por qué no se usa la veterinaria

La veterinaria tiene 10 mascotas y 16 consultas. Con tablas así, PostgreSQL **nunca** va a usar un índice, y hace bien: leer 16 filas de corrido es más rápido que ir al índice y volver a buscar cada fila.

O sea que una demo sobre la veterinaria mostraría justo lo contrario de lo que queremos aprender. Por eso el primer script genera dos tablas grandes del mismo dominio: **20.000 mascotas y 200.000 consultas**.

## Los scripts

| Script | Qué hace |
|---|---|
| `01_datos_demo.sql` | Crea `ix_mascota` e `ix_consulta` con datos generados. Se corre **entero**, tarda unos segundos, y termina con un control que tiene que dar 20000 / 200000 / ~170000 / ~1000 / **0 índices** |
| `02_indices_en_vivo.sql` | 24 bloques numerados para ir viendo cada caso. Se corre **de a un bloque por vez** |

Para el segundo: seleccioná el bloque con el mouse y apretá `Ctrl+Enter` (`Cmd+Enter` en Mac). Supabase ejecuta solo lo seleccionado. Si corrés el archivo entero, muestra únicamente el resultado del último `SELECT`.

## Dos cosas del primer script que parecen errores y no lo son

**Las tablas no tienen `primary key`.** Una PK crea su propio índice, y entonces no habría forma de ver qué pasa *sin* índice. Los índices los vamos creando durante el recorrido.

**Los datos están desbalanceados a propósito.** El 85% de las consultas tiene diagnóstico `'Sano'` y solo el 0,5% tiene `'Insuficiencia cardíaca'`. Eso permite ver lo más interesante de todo el tema: **el mismo índice se usa o no según cuántas filas devuelva la consulta**.

## Qué vas a ver

| Bloques | Qué muestra |
|---|---|
| `[1.x]` | La misma consulta sin índice (`Seq Scan`) y con índice (`Index Scan`) |
| `[2.x]` | Por qué el mismo índice se usa para el diagnóstico raro y se ignora para el común |
| `[3.x]` | Cómo una función sobre la columna tapa el índice, y cómo se arregla |
| `[4.x]` | Por qué en un índice multicolumna el orden importa |
| `[5.x]` | Índices parciales: ocupan menos, pero solo se usan si la consulta repite su condición |
| `[6.x]` | Hash Join, Nested Loop, y cómo cambia el plan al agregar un índice |
| `[7.x]` | Lo que cuesta: cuánto tarda insertar 20.000 filas con y sin índices |
| `[8.x]` | Cuáles de tus índices se usaron realmente, y cuáles son solo costo |

## Cómo leer un plan

Los números —`cost`, tiempos— van a dar distinto en cada máquina. Lo que importa es:

- **El nombre del nodo**: `Seq Scan` lee la tabla entera; `Index Scan` va por el índice.
- **Dónde aparece la condición**: `Filter` significa que leyó la fila y después la descartó; `Index Cond` significa que ni la leyó.
- **`Rows Removed by Filter`**: cuántas filas leyó al pedo. Si es un número grande, ahí hay algo para mejorar.

## Volver a correr la demo

Los `create index` del segundo script no dicen `if not exists`: si el índice ya existe, dan error. Para repetir el recorrido está el bloque **`[9.1]`**, que borra los siete índices y deja las tablas intactas — no hace falta regenerar las 220.000 filas. Como son índices nuevos, los contadores de `[8.1]` también arrancan de cero.

Para empezar de cero del todo, volvé a correr `01_datos_demo.sql`: arranca borrando las dos tablas, así que no hay que borrarlas antes.

## Al terminar

El bloque `[9.3]` del segundo script, comentado, borra las dos tablas. Ocupan unos 25 MB más los índices.
