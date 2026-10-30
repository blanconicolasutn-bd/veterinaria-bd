# Resolución — 10 ejercicios de transacciones

Resolución de [`Transacciones - 10 ejercicios con la veterinaria.md`](Transacciones%20-%2010%20ejercicios%20con%20la%20veterinaria.md). Conviene intentarlos antes de mirarla.

Cada bloque de código se corre **entero, de una sola vez**. Donde dice *segunda ejecución*, es un bloque aparte.

Al final de cada ejercicio hay un **Error común**: casi siempre es más útil que la solución.

---

## Ejercicio 1 — Un dueño nuevo con su mascota

### Enunciado

Dar de alta al dueño **Quiroga, Ernesto** (DNI 27888999, teléfono 1145559999, domicilio Sarmiento 1500) y a su perro **Duque** (ovejero alemán, nacido el 12/03/2022, 32 kg), en una sola transacción. El `id_dueno` lo genera la base.

### Solución

```sql
begin;

insert into dueno (dni, apellido, nombre, telefono, domicilio)
values ('27888999', 'Quiroga', 'Ernesto', '1145559999', 'Sarmiento 1500');

insert into mascota (id_dueno, nombre, especie, raza, fecha_nac, peso_kg)
values ((select id_dueno from dueno where dni = '27888999'),
        'Duque', 'Perro', 'Ovejero Alemán', '2022-03-12', 32.00);

commit;

select d.apellido, d.nombre, m.nombre as mascota, m.peso_kg
from dueno d
join mascota m on m.id_dueno = d.id_dueno
where d.dni = '27888999';
```

El segundo `insert` busca el `id_dueno` con una subconsulta sobre el DNI, que es `unique`. Funciona porque **adentro de la transacción la fila del primer `insert` ya existe**: la transacción se ve a sí misma, aunque nadie más la vea todavía.

### Resultado

| apellido | nombre | mascota | peso_kg |
|---|---|---|---|
| Quiroga | Ernesto | Duque | 32.00 |

### Dejar la base como estaba

```sql
delete from mascota
where id_dueno = (select id_dueno from dueno where dni = '27888999');

delete from dueno where dni = '27888999';
```

El orden importa: primero la mascota, después el dueño. Al revés, la FK no lo permite.

### Error común

Escribir el `id_dueno` a mano:

```sql
insert into mascota (id_dueno, ...) values (6, ...);   -- ✗
```

Hay cinco dueños, así que "el que sigue es el 6" parece razonable, y hoy hasta puede funcionar. Pero `id_dueno` es `generated always as identity`: el número lo decide una secuencia, y **la secuencia avanza aunque el `insert` falle o se deshaga**. Después de unos cuantos intentos fallidos, el próximo id puede ser el 9 y no el 6. La fila queda colgada del dueño equivocado, sin ningún error.

La otra forma de tomarlo, si no hay una columna `unique` a mano:

```sql
values (currval(pg_get_serial_sequence('dueno', 'id_dueno')), ...)
```

---

## Ejercicio 2 — El alta de la que uno se arrepiente

### Enunciado

Repetir el alta del ejercicio 1 terminándola con `rollback`. Mostrar que adentro de la transacción la fila se ve, y que después no está.

### Solución

Primera ejecución:

```sql
begin;

insert into dueno (dni, apellido, nombre)
values ('27888999', 'Quiroga', 'Ernesto');

select count(*) as adentro from dueno where dni = '27888999';

rollback;
```

| adentro |
|---|
| 1 |

Segunda ejecución:

```sql
select count(*) as despues from dueno where dni = '27888999';
```

| despues |
|---|
| 0 |

### La respuesta

La fila estaba **escrita en la base**, no en algún borrador aparte. Postgres la guardó de verdad, pero marcada como perteneciente a una transacción sin confirmar: la ve quien la escribió y nadie más. El `rollback` no "borra" la fila, la deja marcada como descartada.

Por eso el `select` de adentro la encuentra y el de afuera no: no son dos lugares distintos, es la misma fila vista desde dos transacciones distintas.

### Error común

Suponer que el `rollback` deja la base **exactamente** como estaba. Los datos sí vuelven atrás; **la secuencia del `id_dueno` no**. Ese número se consumió y no se devuelve. Es a propósito: si la secuencia se deshiciera, dos transacciones simultáneas podrían pedir el mismo id.

Conclusión para la clase: los `id` tienen huecos, y eso **no es un error**. Un `id` es un identificador, no un contador.

---

## Ejercicio 3 — La transacción que se aborta

### Enunciado

En una sola ejecución y dentro de una misma transacción, insertar una mascota con `id_dueno = 99` (que no existe) y a continuación una mascota válida del dueño 1 llamada `Lola`, y cerrar con `commit`. Después verificar qué quedó y explicar por qué.

### Solución

```sql
begin;

insert into mascota (id_dueno, nombre, especie)
values (99, 'Fantasma', 'Perro');

insert into mascota (id_dueno, nombre, especie)
values (1, 'Lola', 'Perro');

commit;
```

```
ERROR: insert or update on table "mascota" violates foreign key
       constraint "mascota_id_dueno_fkey"
DETAIL: Key (id_dueno)=(99) is not present in table "dueno".
```

Y en otra ejecución:

```sql
select count(*) as cuantas
from mascota where nombre in ('Fantasma', 'Lola');
```

| cuantas |
|---|
| 0 |

### La respuesta

**Un solo error.** Eso es lo que hay que notar: hubo dos `insert` y apareció un único mensaje. El segundo **no falló**: no llegó a ejecutarse nunca.

Cuando una sentencia da error, Postgres **descarta todo lo que viene después** en esa ejecución. No sigue probando a ver si lo demás anda. Y la transacción queda *abortada*: ya no acepta nada hasta que se cierre. Ni siquiera el `commit` final confirma algo — termina haciendo un `rollback`.

Por eso el control devuelve `0`: no quedó `Fantasma`, obviamente, y tampoco `Lola`, que era perfecta.

Y ésa es exactamente la pregunta que abre el ejercicio 9: *¿y si quiero conservar lo que ya hice bien?*

### Si alguna vez usan un cliente de escritorio

En `psql`, pgAdmin o DBeaver se escribe una sentencia por vez, así que ahí sí se llega a mandar el segundo `insert`. La respuesta no es que funcione: es un segundo error distinto.

```
ERROR: current transaction is aborted,
       commands ignored until end of transaction block
```

Dice lo mismo con otras palabras — la transacción está rota y hay que cerrarla —, pero conviene conocerlo porque es uno de los mensajes más desconcertantes de Postgres la primera vez que aparece.

### Error común

Creer que el error "se saltea" y que el resto de la transacción sigue. Es la causa de un bug clásico: un proceso que inserta mil filas, falla en la número tres, y termina con cero filas cargadas mientras el log dice que todo salió bien.

---

## Ejercicio 4 — Borrar una consulta que tiene recetas

### Enunciado

Borrar la consulta 4 con todo lo que recetó. Primero intentar borrar solo la consulta y copiar el error; después resolverlo en una transacción, en el orden correcto, y terminar con `rollback`.

### Solución

Primero, el intento que falla, en una ejecución aparte:

```sql
delete from consulta where id_consulta = 4;
```

```
ERROR: update or delete on table "consulta" violates foreign key
       constraint "receta_id_consulta_fkey" on table "receta"
DETAIL: Key (id_consulta)=(4) is still referenced from table "receta".
```

Y después, la transacción:

```sql
begin;

delete from receta   where id_consulta = 4;
delete from consulta where id_consulta = 4;

select count(*) as recetas_que_quedan
from receta where id_consulta = 4;

rollback;
```

| recetas_que_quedan |
|---|
| 0 |

### Por qué va en una transacción

Las dos sentencias son **una sola operación del negocio**: "dar de baja la consulta 4". Si se borran las recetas y el borrado de la consulta falla, queda una consulta sin sus recetas — peor que no haber empezado, porque se perdió información y no se avisó.

El orden es siempre **de la hija a la madre**: primero lo que referencia, después lo referenciado.

### Error común

Resolverlo poniéndole `on delete cascade` a la FK. Funciona, y es un desastre cuando se usa sin pensar: a partir de ahí, un `delete` distraído sobre `consulta` se lleva las recetas **en silencio**, sin error y sin aviso. El error de FK no es un obstáculo, es una red de seguridad: te obliga a decir en voz alta que querés borrar también lo de abajo.

---

## Ejercicio 5 — La mascota cambia de dueño

### Enunciado

Michi (`id_mascota = 2`) pasa a estar a nombre de Pérez, Juan (`id_dueno = 2`). Hacerlo en una transacción que muestre cuántas mascotas tiene cada dueño, y comprobar en una segunda ejecución que el `rollback` volvió todo atrás.

### Solución

Primera ejecución:

```sql
begin;

update mascota set id_dueno = 2 where id_mascota = 2;

select id_dueno, count(*) as mascotas
from mascota
where id_dueno in (1, 2)
group by id_dueno
order by id_dueno;

rollback;
```

| id_dueno | mascotas |
|---|---|
| 1 | 1 |
| 2 | 3 |

Segunda ejecución:

```sql
select id_dueno, count(*) as mascotas
from mascota
where id_dueno in (1, 2)
group by id_dueno
order by id_dueno;
```

| id_dueno | mascotas |
|---|---|
| 1 | 2 |
| 2 | 2 |

### Error común

Olvidarse el `where` del `update` y pasar **todas** las mascotas al dueño 2. Dentro de una transacción el `rollback` te salva; sin `begin`, no hay nada que hacer.

Es el mismo tema del ejercicio 7, y la razón por la que conviene abrir la transacción **antes** de escribir el `update`, no después de leerlo dos veces.

---

## Ejercicio 6 — Una consulta con su receta

### Enunciado

Registrar una consulta nueva para Rocky (`id_mascota = 1`) con la matrícula 1001, fecha de hoy, motivo *"Control de peso"*, y recetarle Meloxicam (`id_medicamento = 2`), dosis *"0.1mg/kg cada 24hs"*, 5 días. Todo en una transacción, tomando el `id_consulta` que genera la base.

### Solución

```sql
begin;

insert into consulta (id_mascota, matricula, fecha, motivo)
values (1, 1001, current_date, 'Control de peso');

insert into receta (id_consulta, id_medicamento, dosis, frecuencia, duracion_dias)
values (currval(pg_get_serial_sequence('consulta', 'id_consulta')),
        2, '0.1mg/kg cada 24hs', '1 vez al día', 5);

select c.id_consulta, c.motivo, m.nombre as medicamento, r.duracion_dias
from consulta c
join receta r      on r.id_consulta = c.id_consulta
join medicamento m on m.id_medicamento = r.id_medicamento
where c.motivo = 'Control de peso';

rollback;
```

| id_consulta | motivo | medicamento | duracion_dias |
|---|---|---|---|
| 17 | Control de peso | Meloxicam | 5 |

El `id_consulta` puede no ser 17: depende de cuántas veces se haya corrido el bloque.

### Por qué `currval` y no `max`

Acá no hay una columna `unique` para buscar la consulta recién insertada, así que no sirve el truco del ejercicio 1. Hay dos caminos:

```sql
(select max(id_consulta) from consulta)   -- anda, pero es frágil
currval(pg_get_serial_sequence(...))      -- correcto
```

`max` devuelve el id más alto **de la tabla**, no el que insertó esta transacción. Con un solo usuario da lo mismo; con dos personas cargando consultas al mismo tiempo, una se puede llevar el id de la otra. `currval` devuelve el último valor que **esta sesión** pidió a la secuencia, y por eso es seguro siempre.

### Error común

Partirlo en dos ejecuciones: la consulta en una y la receta en otra. Ahí la transacción se pierde en el medio, y si la receta falla queda **una consulta sin receta** confirmada. Es justo lo que la transacción venía a evitar.

---

## Ejercicio 7 — El `update` sin `where`

### Enunciado

Correr dentro de una transacción un `update` que le ponga `peso_kg = 10` a `mascota` sin cláusula `where`. Consultar cuántas filas quedaron así, decidir `commit` o `rollback`, y explicar qué habría pasado sin `begin`.

### Solución

```sql
begin;

update mascota set peso_kg = 10;

select count(*) as mascotas_en_10_kg
from mascota where peso_kg = 10;

rollback;
```

| mascotas_en_10_kg |
|---|
| 10 |

### La respuesta

Diez: **todas**. La decisión es `rollback`, y no hay nada que discutir.

Sin el `begin`, cada sentencia es su propia transacción y se confirma sola al terminar. O sea: el `update` ya habría quedado confirmado, los diez pesos reales estarían perdidos, y la única salida sería un backup.

Postgres **no pregunta**. No hay "¿está seguro?". La red de seguridad es `begin`, y hay que ponerla antes, no después.

### Error común

Pensar que el `select` de control se puede correr *después* del `commit` "para ver cómo quedó". Después del `commit` ya no hay marcha atrás: el control sirve **mientras la transacción sigue abierta**, que es el único momento en que todavía se puede decidir.

---

## Ejercicio 8 — Confirmar solo si tocó lo que tenía que tocar

### Enunciado

Subirle 1 kg el peso a todos los perros del dueño 3, que tiene tres mascotas pero no todas son perros. Mostrar qué filas quedaron modificadas y deshacer si son más de las esperadas.

### Solución

```sql
begin;

update mascota
set peso_kg = peso_kg + 1
where id_dueno = 3
  and especie = 'Perro';

select id_mascota, nombre, especie, peso_kg
from mascota
where id_dueno = 3
order by id_mascota;

rollback;
```

| id_mascota | nombre | especie | peso_kg |
|---|---|---|---|
| 5 | Rocky | Perro | 36.00 |
| 6 | Michi | Gato | 4.50 |
| 7 | Pipo | Ave | 0.30 |

### La respuesta

Esperaba **una** fila modificada y fue **una**: el dueño 3 tiene un perro, un gato y un ave. Rocky pasó de 35.00 a 36.00; Michi y Pipo quedaron intactos. El `update` estuvo bien, así que acá correspondería `commit` — pero la guía pide `rollback` para no ensuciar la base.

El `select` muestra **las tres** mascotas del dueño a propósito, no solo la modificada: lo que hay que verificar no es que haya cambiado lo que queríamos, sino que **no haya cambiado lo que no queríamos**.

### Error común

Filtrar solo por dueño y olvidarse la especie:

```sql
where id_dueno = 3   -- ✗ le suma un kilo al ave también
```

Pipo pasaría de 0.30 a 1.30 kg. El `update` no da ningún error: hace exactamente lo que le pidieron. Por eso el control va antes del `commit` y no después.

---

## Ejercicio 9 — Tres recetas y una repetida (`savepoint`)

### Enunciado

Agregarle a la consulta 1 los medicamentos 3, 7 y 3 otra vez. El tercero viola la clave primaria `(id_consulta, id_medicamento)`. Primero ver que el error se lleva puestos los dos primeros; después lograr que el repetido falle pero los otros dos queden.

### Primera parte — el problema

```sql
begin;

insert into receta (id_consulta, id_medicamento, dosis, frecuencia, duracion_dias)
values (1, 3, '1 ampolla', 'única', 1);

insert into receta (id_consulta, id_medicamento, dosis, frecuencia, duracion_dias)
values (1, 7, '100mg cada 12hs', '2 veces al día', 10);

insert into receta (id_consulta, id_medicamento, dosis, frecuencia, duracion_dias)
values (1, 3, '1 ampolla', 'única', 1);

commit;
```

```
ERROR: duplicate key value violates unique constraint "receta_pkey"
DETAIL: Key (id_consulta, id_medicamento)=(1, 3) already exists.
```

Y el control:

```sql
select count(*) as recetas_de_la_1 from receta where id_consulta = 1;
```

| recetas_de_la_1 |
|---|
| 0 |

Los dos primeros `insert` se habían ejecutado bien, y se perdieron igual. Es el ejercicio 3 otra vez, ahora costando trabajo.

### Segunda parte — la solución

```sql
do $$
begin
  insert into receta (id_consulta, id_medicamento, dosis, frecuencia, duracion_dias)
  values (1, 3, '1 ampolla', 'única', 1);

  insert into receta (id_consulta, id_medicamento, dosis, frecuencia, duracion_dias)
  values (1, 7, '100mg cada 12hs', '2 veces al día', 10);

  begin
    insert into receta (id_consulta, id_medicamento, dosis, frecuencia, duracion_dias)
    values (1, 3, '1 ampolla', 'única', 1);
  exception when unique_violation then
    null;          -- ya estaba recetado: lo descartamos y seguimos
  end;
end $$;
```

```sql
select count(*) as recetas_de_la_1 from receta where id_consulta = 1;
```

| recetas_de_la_1 |
|---|
| 2 |

### Dejar la base como estaba

```sql
delete from receta where id_consulta = 1;
```

### Lo que hay que ver acá

El bloque interno —el `begin ... exception ... end` de adentro— **es un savepoint**. Postgres lo marca solo al entrar. Si la sentencia que está adentro falla, se deshace lo que ese bloque hizo, **nada más que eso**, y la transacción sigue viva y sana. Los dos `insert` de arriba quedan intactos porque pasaron **antes** de la marca.

Es exactamente lo que hacen `savepoint` y `rollback to`, escrito como código en lugar de como dos sentencias sueltas. La ventaja es que el bloque decide **solo** cuándo volver: no hay que mirar el error con los ojos y escribir el `rollback to` a mano.

Dicho corto: **`rollback` cierra la transacción, `rollback to` no**. Y un bloque con `exception` es un `rollback to` automático.

La marca va **antes** de la sentencia riesgosa: por eso el `begin` interno abre justo arriba del `insert` que puede fallar. Si lo pusieran después no serviría de nada — en una transacción ya abortada no se puede ejecutar nada.

### Error común

Proteger **todo** el bloque con un solo `exception` al final:

```sql
do $$
begin
  insert into receta ... (1, 3, ...);
  insert into receta ... (1, 7, ...);
  insert into receta ... (1, 3, ...);   -- el repetido
exception when unique_violation then
  null;                                 -- ✗ no salva nada
end $$;
```

Acá la marca quedó al principio, así que al volver a ella se pierden **los tres**. El resultado es el mismo que no haber hecho nada: cero recetas. Las marcas se ponen donde uno quiere poder volver, no al principio.

El otro error, más sutil: usar `exception when others` sin pensar. Atrapa cualquier error, incluidos los que uno **no** quería ignorar — un problema de permisos, una columna que no existe, un tipo mal puesto. Si se sabe qué puede fallar, conviene nombrarlo: `unique_violation`, `foreign_key_violation`, `not_null_violation`.

---

## Ejercicio 10 — El aumento del que uno se arrepiente a la mitad (`savepoint`)

### Enunciado

En una transacción: subirle 2 kg a Nina (`id_mascota = 8`), marcar un punto intermedio, subirle 20 kg a Pipo (`id_mascota = 7`, un ave de 0.30 kg), deshacer solo el segundo cambio y confirmar la transacción.

### Solución

```sql
begin;

update mascota set peso_kg = peso_kg + 2 where id_mascota = 8;

savepoint nina_lista;

update mascota set peso_kg = peso_kg + 20 where id_mascota = 7;

rollback to nina_lista;

commit;

select id_mascota, nombre, peso_kg
from mascota
where id_mascota in (7, 8)
order by id_mascota;
```

| id_mascota | nombre | peso_kg |
|---|---|---|
| 7 | Pipo | 0.30 |
| 8 | Nina | 14.00 |

### Dejar la base como estaba

```sql
update mascota set peso_kg = 12.00 where id_mascota = 8;
```

### La diferencia con dos transacciones separadas

Acá **no hubo ningún error**: el segundo `update` funcionó perfecto, y se deshizo igual porque el dato no tenía sentido. Es la otra cara del `savepoint` — no solo sirve para recuperarse de errores, también para probar algo y descartarlo.

¿Y por qué no dos transacciones? Porque hasta el `commit` final **nadie más vio nada**: ni el aumento de Nina, ni el disparate de Pipo, ni la corrección. Con dos transacciones, el aumento de Nina queda confirmado antes, y entre una y otra hay un momento en que otra persona puede leer la base a medio camino.

La transacción define **qué es "una sola operación"** de cara a los demás. Los `savepoint` organizan lo de adentro sin romper eso.

### Error común

Esperar que `rollback to` cierre la transacción. No la cierra: después de un `rollback to` la transacción **sigue abierta**, y si no se termina con `commit` o `rollback`, todo lo que quedó dentro no se confirma.

Y el otro, más silencioso: usar `release savepoint` creyendo que deshace. `release` solo descarta la marca —ya no se puede volver a ella— pero **no deshace nada**. Los cambios quedan.
