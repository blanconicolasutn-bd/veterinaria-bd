# Auto-chequeo de los ejercicios

Acá está `09_autochequeo_ejercicios.sql`: un script para **verificar tus propias respuestas** de los ejercicios de transacciones y de funciones.

**No trae las soluciones.** Trae las verificaciones. Vos escribís tu respuesta, corrés el chequeo que corresponde, y te dice si quedó bien — y si no, qué mirar.

Las resoluciones están en cada carpeta de ejercicios, al lado de su guía. Conviene usarlas después del chequeo y no antes: si el bloque dice `MAL`, el texto ya te apunta dónde mirar, y encontrarlo vos es la mitad del ejercicio.

## Antes de empezar

Tenés que tener corridos, en este orden, `sql/01_esquema.sql` y `sql/02_datos.sql` en tu propio proyecto de Supabase.

## Cómo usarlo

**Un bloque por vez.** Seleccionalo con el mouse y apretá `Ctrl+Enter` (`Cmd+Enter` en Mac). Supabase ejecuta solo lo que esté seleccionado.

No corras el archivo entero de una: Supabase muestra únicamente el resultado del **último** `select`, así que perderías todos los demás.

El orden es:

1. Corré el bloque `[0]`, que verifica que tu editor respeta el `rollback`. Si no dice `OK`, no sigas.
2. Resolvé el ejercicio en el editor, con tu propio código.
3. Corré el bloque de chequeo con el mismo número (`[T.4]` para el ejercicio 4 de transacciones, `[F.7]` para el 7 de funciones).

## Cómo se leen los resultados

La mayoría de los chequeos devuelven una columna que dice `OK` o `MAL`. Cuando dice `MAL`, el texto indica qué revisar — no hace falta adivinar.

**Algunos bloques tienen que dar error.** Están marcados con `TIENE QUE DAR ERROR` justo arriba, y abajo dice cuál es el mensaje esperado.

Son los que llaman a tu función con datos imposibles —por ejemplo, un peso de 150 kg— para comprobar que **se niegue**. Si Supabase te devuelve el mensaje de error que figura en el comentario, está bien: tu función hizo exactamente lo que tenía que hacer.

Lo que estaría mal es lo contrario: que en vez de cortar te devuelva un valor. Ahí falta la validación.

El bloque `[F.0]` es útil al principio: lista cuáles de las seis funciones tenés creadas.

## Los ejercicios 3 y 9 de transacciones

Son los dos que tratan sobre qué pasa cuando algo falla en el medio de una transacción, y los dos se resuelven **en Supabase**, como todos los demás.

El **3** se apoya en algo que conviene entender temprano: cuando una sentencia da error, lo que viene después en esa ejecución **ni siquiera se intenta**. Por eso ahí vas a ver un solo mensaje de error aunque haya dos `insert`.

El **9** necesita una pieza que no salió en la clase de transacciones: un `begin ... exception ... end` adentro de un bloque `do`. Ese bloque interno **es un savepoint** que Postgres marca solo. El enunciado lo explica y te muestra la forma; no hace falta saberlo de antes.

## Los triggers

Los bloques `[TR.x]` prueban tus triggers de verdad: insertan y modifican filas, miran qué quedó, y después limpian lo que ensuciaron. Arrancá por `[TR.0]`, que lista cuáles tenés creados.

El `[TR.2b]` es uno de los que **tiene que dar error**, y además importa CUÁL error: si el mensaje habla de `receta_pkey`, el que cortó fue la clave primaria y no tu trigger.

## Al final

El último bloque del script verifica que la base haya quedado como al principio: 5 dueños, 10 mascotas, 16 consultas y 11 recetas.

Si dice `MAL`, no te pongas a buscar qué quedó cambiado: volvé a correr `sql/01_esquema.sql` y `sql/02_datos.sql`, que es más rápido.
