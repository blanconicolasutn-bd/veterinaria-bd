# Diseño y Administración de Base de Datos — Unidad IV: la veterinaria

Material de práctica del ejercicio de la veterinaria (Unidad IV — DDL/DML/consultas).

## Contenido

- **`sql/01_esquema.sql`** — creación de las 6 tablas (`dueno`, `mascota`, `veterinario`, `consulta`, `medicamento`, `receta`) para Supabase/PostgreSQL. Es idempotente, se puede correr las veces que haga falta.
- **`sql/02_datos.sql`** — datos de ejemplo para practicar. Se corre después del esquema.
- **`sql/03_normalizacion_0fn_a_5fn.sql`** — la misma veterinaria en **cada etapa de normalización**: 22 tablas donde **el prefijo dice en qué forma normal está la tabla** (`fn0_` 1 tabla, `fn1_` 1, `fn2_` 2, `fn3_` 7, `fn3b_` 3 para BCNF, `fn4_` 3, `fn5_` 4, `fn6_` 1 para DKNF). Así, contar prefijos te dice cuántas tablas hay en cada etapa, y cada descomposición va de un prefijo al siguiente. Independiente de los scripts 01 y 02, también idempotente.
- **`sql/04_normalizacion_consultas_clase.sql`** — un `SELECT` por etapa para recorrer la normalización en vivo. Incluye las verificaciones que importan: reconstruir la planilla desde las seis tablas de 3FN, y el caso de 5FN donde unir dos proyecciones produce una fila que no existe y unir tres la descarta.
- **`sql/05_normalizacion_ejercicios.sql`** — las tablas de los ejercicios de la Unidad V: los tres que se hacen en clase (solo el enunciado, la descomposición la arman ustedes) y los cuatro de la casa (enunciado **y** solución). Todos sobre la veterinaria.
- **`sql/06_normalizacion_ejercicios_consultas.sql`** — consultas de verificación: reconstruyen cada planilla original desde las tablas de la solución. Si la descomposición está bien, devuelven cero filas.
- **`ejercicios/veterinaria.md`** — guía de ejercicios de consultas sobre este modelo.
- **`ejercicios/normalizacion.md`** — ejercicios de normalización de la **Clase 7**: tres planillas para llevar a 3FN, con el formato de entrega por Pull Request.
- **`ejercicios/Normalización - 10 ejercicios hasta 3FN.md`** — los **diez** ejercicios que se corrigen en la **Clase 9**. En los primeros seis los datos vienen en una planilla; en los últimos cuatro hay que deducir las dependencias a partir de la descripción del sistema.
- **`ejercicios/resoluciones normalizacion/`** — las resoluciones paso a paso (1FN, 2FN y 3FN) de las dos guías: la de la Clase 7 y la de los diez ejercicios de la Clase 9. Esta última muestra además **cómo quedan los datos** en cada forma normal, no solo el esquema.
- **`ejercicios/transacciones/`** — diez ejercicios de transacciones sobre la veterinaria: `begin`, `commit`, `rollback` y, los dos últimos, `savepoint`. Ocho se resuelven en Supabase; los otros dos necesitan un cliente que mantenga la sesión abierta, y la guía explica por qué.
- **`ejercicios/funciones/`** — dos guías de diez ejercicios cada una (Unidad VI). La primera practica **una pieza por ejercicio** —`language sql`, `declare`, `if`, `found`, `%rowtype`, `returns table`, `create procedure`—; la segunda las combina: bloques `do`, funciones que validan y cortan con `raise exception`, y el error que deshace lo que hizo quien lo llamó.
- **`autochequeo/`** — un script para **verificar tus propias respuestas** de esos dos últimos conjuntos. No trae las soluciones: trae las verificaciones, y cuando algo está mal te dice qué mirar.
- **`ejercicios repaso primera parte/`** — ejercicios integradores de repaso (Unidad I a IV bis): teoría, DER, DDL, consultas, subconsultas y transacciones, con sus resoluciones. Incluye ejercicios extra de subconsultas en SELECT, FROM y WHERE sobre la veterinaria.
- **`practica/`** — espacio opcional para practicar el flujo de Pull Request (ver abajo).

## Cómo usar la base

1. Creá tu propio proyecto gratis en [supabase.com](https://supabase.com).
2. Abrí el **SQL Editor** del proyecto.
3. Pegá y corré `sql/01_esquema.sql`.
4. Pegá y corré `sql/02_datos.sql`.
5. Ya podés resolver los ejercicios de `ejercicios/veterinaria.md` contra tu propia base.

## Seguir la normalización paso a paso (Unidad V)

1. Corré `sql/03_normalizacion_0fn_a_5fn.sql`. Te deja 22 tablas nuevas, ordenadas de `fn0_` a `fn6_`. El prefijo de cada una dice en qué forma normal está.
2. Abrí `sql/04_normalizacion_consultas_clase.sql` y **corré un bloque por vez**: seleccionalo con el mouse y apretá `Ctrl+Enter` (`Cmd+Enter` en Mac). Supabase ejecuta solo lo seleccionado.
3. Mirá cómo el mismo dato de la veterinaria va cambiando de lugar en cada forma normal.
4. El bloque `[6.1]` en adelante usa `CREATE DOMAIN` para mostrar DKNF: la misma regla escrita como `CHECK` suelto (`fn5_turno`) o metida en el dominio (`fn6_turno`).
5. Para los ejercicios, corré `sql/05_normalizacion_ejercicios.sql` y verificá tus respuestas con los bloques `[V.x]` de `sql/06_normalizacion_ejercicios_consultas.sql`: si tu descomposición es correcta, devuelven **cero filas**.

> Si corrés el archivo entero de una, Supabase muestra únicamente el resultado del último `SELECT`. Por eso conviene ir de a bloques.

## Transacciones y funciones (Unidades IV bis y VI)

1. Resolvé las guías de `ejercicios/transacciones/` y `ejercicios/funciones/` en tu propio proyecto de Supabase, con las tablas de `sql/01_esquema.sql` y `sql/02_datos.sql` cargadas.
2. Verificá tus respuestas con `autochequeo/09_autochequeo_ejercicios.sql`, de a un bloque por vez. La mayoría de los chequeos responden `OK` o `MAL`, y cuando dicen `MAL` indican qué revisar.
3. Algunos bloques **tienen que dar error**: están marcados, y ahí el ERROR rojo es la respuesta correcta.

> Los ejercicios 3 y 9 de transacciones no se pueden hacer en el SQL Editor: los dos necesitan ver fallar una sentencia y seguir en la misma transacción, y el editor manda el bloque entero de una vez. Se hacen en `psql`, pgAdmin o DBeaver, o se ven en clase. Está explicado en `autochequeo/README.md`.

## Practicar el flujo de Fork + Pull Request

Esto **no es una entrega ni se corrige** — es una forma de practicar cómo se usa git y GitHub en un caso real, sin que nadie tenga que pedir acceso a nadie:

1. **Fork** este repositorio (botón arriba a la derecha en GitHub) → te queda una copia en tu cuenta.
2. En tu copia, agregá tu archivo (por ejemplo, alguna consulta resuelta) dentro de `practica/apellido-nombre/`.
3. Abrí un **Pull Request** desde tu copia hacia este repositorio.
4. Si querés, el profesor puede revisarlo y dejar comentarios directamente sobre el código.

### Ejemplo de estructura

```
practica/
  gomez-maria/
    consultas-tabla.sql
    consultas-multitabla.sql
```
