# Resolución — 10 ejercicios de funciones y PL/pgSQL

Resolución de [`Funciones - 10 ejercicios en PL-pgSQL.md`](Funciones%20-%2010%20ejercicios%20en%20PL-pgSQL.md). Conviene intentarlos antes de mirarla.

Todas las funciones están escritas con `create or replace`, así que se pueden volver a correr las veces que haga falta.

Al final de cada ejercicio hay un **Error común**: casi siempre es más útil que la solución.

---

## Ejercicio 1 — Cuántas mascotas tiene un dueño

### Enunciado

Escribir la función `cantidad_mascotas(p_dueno int)` que devuelva cuántas mascotas tiene ese dueño.

- El cuerpo es **una sola consulta**: elegir el `language` que corresponde.
- Prestar atención al tipo que se declara en el `returns`.

### Solución

```sql
create or replace function cantidad_mascotas(p_dueno int)
returns bigint as $$
  select count(*) from mascota
  where id_dueno = p_dueno;
$$ language sql;
```

El cuerpo es una sola consulta, así que va `language sql`: no hace falta `begin`, ni `end`, ni `return`. La última consulta del cuerpo **es** lo que devuelve.

### Resultado

| llamada | devuelve |
|---|---|
| `cantidad_mascotas(1)` | 2 |
| `cantidad_mascotas(3)` | 3 |
| `cantidad_mascotas(5)` | 0 |

El dueño 5 (Alvarez, Rocío) no tiene ninguna mascota cargada, y la función devuelve `0`, no `null`: `count(*)` sobre cero filas devuelve cero.

### Error común

Declarar `returns int`. `count(*)` devuelve **`bigint`**, y Postgres corta con *return type mismatch*. Hay dos salidas, las dos válidas:

```sql
returns bigint          -- declarar el tipo que realmente devuelve
-- o bien
select count(*)::int    -- convertirlo en el cuerpo
```

---

## Ejercicio 2 — El dueño de una mascota

### Enunciado

Escribir `dueno_de(p_mascota int)` que, dado el id de una mascota, devuelva el texto `'Apellido, Nombre'` de su dueño.

- Resolverlo en **plpgsql**, con `declare` y `select ... into`.
- Declarar las variables con `%type`, sin escribir `varchar(60)` a mano.

### Solución

```sql
create or replace function dueno_de(p_mascota int)
returns text as $$
declare
  v_apellido dueno.apellido%type;
  v_nombre   dueno.nombre%type;
begin
  select d.apellido, d.nombre
    into v_apellido, v_nombre
  from mascota m
  join dueno d on d.id_dueno = m.id_dueno
  where m.id_mascota = p_mascota;

  return v_apellido || ', ' || v_nombre;
end $$ language plpgsql;
```

`select ... into` carga **varias variables de una sola vez**, en el mismo orden en que están las columnas del `select`.

`%type` dice "el tipo que tenga esa columna". Si mañana `apellido` pasa de `varchar(60)` a `varchar(100)`, la función no hay que tocarla.

### Resultado

| llamada | devuelve |
|---|---|
| `dueno_de(1)` | `Gómez, María` |
| `dueno_de(9)` | `Sosa, Diego` |

### Error común

Poner las variables del `into` en otro orden que las columnas del `select`. Postgres **no avisa** si los tipos son compatibles: devuelve `María, Gómez` y queda así. El `into` empareja por **posición**, no por nombre.

---

## Ejercicio 3 — Clasificar por peso

### Enunciado

Escribir `categoria_peso(p_peso decimal)` que devuelva `'grande'` si el peso es mayor a 20 kg, `'mediano'` si es mayor a 5 kg, y `'chico'` en cualquier otro caso. No consulta la base.

### Solución

```sql
create or replace function categoria_peso(p_peso decimal)
returns text as $$
begin
  if p_peso > 20 then
    return 'grande';
  elsif p_peso > 5 then
    return 'mediano';
  else
    return 'chico';
  end if;
end $$ language plpgsql;
```

No hay `declare` porque no hace falta ninguna variable: el parámetro alcanza. Tampoco toca ninguna tabla — es una función de cálculo puro.

Se escribe **`elsif`**, en una sola palabra.

### Resultado

```sql
select nombre, peso_kg, categoria_peso(peso_kg) as categoria
from mascota
order by peso_kg desc;
```

| nombre | peso_kg | categoria |
|---|---|---|
| Rocky | 35.00 | grande |
| Rocky | 28.50 | grande |
| Bruno | 15.00 | mediano |
| Nina | 12.00 | mediano |
| Toby | 6.00 | mediano |
| Michi | 4.50 | chico |
| Michi | 4.20 | chico |
| Luna | 3.80 | chico |
| Coco | 1.80 | chico |
| Pipo | 0.30 | chico |

La función se llama **una vez por fila**, como si fuera una columna calculada.

### Error común

Escribir las condiciones de menor a mayor:

```sql
if p_peso > 5 then
  return 'mediano';
elsif p_peso > 20 then     -- nunca se llega acá
  return 'grande';
```

Rocky pesa 28.50, entra por la primera condición y sale `mediano`. En una cadena de `if`, **gana la primera condición que se cumple**, así que las condiciones van de la más exigente a la menos exigente.

El segundo error, más silencioso: si `peso_kg` fuera `null`, todas las comparaciones dan `null` (ni verdadero ni falso), se cae en el `else` y devuelve `chico`. Una mascota sin peso cargado quedaría clasificada como chica.

---

## Ejercicio 4 — Lo mismo, sin función

### Enunciado

Resolver la misma clasificación con una sola consulta con `case`, sin crear nada. Después explicar cuándo conviene `case` y cuándo la función con `if`.

### Solución

```sql
select nombre, peso_kg,
       case when peso_kg > 20 then 'grande'
            when peso_kg >  5 then 'mediano'
            else 'chico'
       end as categoria
from mascota
order by peso_kg desc;
```

El resultado es **idéntico** al del ejercicio 3.

### La respuesta

| | `case` | la función |
|---|---|---|
| Dónde vive la regla | Adentro de esa consulta | Guardada en la base, una sola vez |
| Si cambia el límite de 20 kg | Hay que buscar y corregir cada consulta | Se corrige la función y listo |
| Reusar en otro lado | Copiar y pegar | `categoria_peso(...)` |
| Para escribirla | Más rápido, no crea nada | Hay que crearla primero |

**La regla práctica:** si la clasificación es de esa consulta y nada más, `case`. Si es una **regla del negocio** que va a aparecer en varias consultas —y alguien la va a querer cambiar—, función.

Y hay una diferencia de fondo: `case` **devuelve un valor** adentro de un `select`. `if` **decide qué sentencias se ejecutan**, y por eso solo existe adentro de un bloque de código. No se puede escribir `select if ...`.

---

## Ejercicio 5 — La edad, y qué pasa si la mascota no existe

### Enunciado

Escribir `edad_mascota(p_id int)` que devuelva la edad en años cumplidos. Si no existe una mascota con ese id, cortar con el error `No existe la mascota <id>`.

### Solución

```sql
create or replace function edad_mascota(p_id int)
returns int as $$
declare
  v_nac mascota.fecha_nac%type;
begin
  select fecha_nac into v_nac
  from mascota where id_mascota = p_id;

  if not found then
    raise exception 'No existe la mascota %', p_id;
  end if;

  return extract(year from age(v_nac));
end $$ language plpgsql;
```

`found` queda en `false` cuando el `select ... into` anterior **no trajo ninguna fila**. Se consulta inmediatamente después: cualquier otra sentencia lo pisa.

El `%` del `raise` es el lugar donde se mete el valor que va después de la coma.

### Resultado

| llamada | devuelve |
|---|---|
| `edad_mascota(1)` | 7 |
| `edad_mascota(99)` | `ERROR: No existe la mascota 99` |

### Error común

Preguntar por el valor en lugar de preguntar por la fila:

```sql
if v_nac is null then
  raise exception 'No existe la mascota %', p_id;
end if;
```

Parece lo mismo y no lo es. Son **dos situaciones distintas**: que la mascota no exista, y que exista pero no tenga la fecha de nacimiento cargada. Con `is null` las dos dan el mismo error, y el mensaje miente en el segundo caso.

`found` responde *"¿vino una fila?"*. `is null` responde *"¿el dato está vacío?"*.

---

## Ejercicio 6 — La ficha de la mascota

### Enunciado

Escribir `ficha_mascota(p_id int)` que devuelva `Rocky (Perro, Labrador) — 28.50 kg`, usando `%rowtype`. Las mascotas sin raza tienen que salir como `sin raza`.

### Solución

```sql
create or replace function ficha_mascota(p_id int)
returns text as $$
declare
  v_fila mascota%rowtype;
begin
  select * into v_fila
  from mascota where id_mascota = p_id;

  if not found then
    raise exception 'No existe la mascota %', p_id;
  end if;

  return v_fila.nombre
      || ' (' || v_fila.especie || ', '
      || coalesce(v_fila.raza, 'sin raza') || ') — '
      || v_fila.peso_kg || ' kg';
end $$ language plpgsql;
```

`mascota%rowtype` declara una variable con **la misma forma que una fila de `mascota`**: una sola variable en lugar de cinco, y después se accede con punto. Si mañana se le agrega una columna a `mascota`, la variable la tiene sin tocar nada.

### Resultado

| llamada | devuelve |
|---|---|
| `ficha_mascota(1)` | `Rocky (Perro, Labrador) — 28.50 kg` |
| `ficha_mascota(7)` | `Pipo (Ave, sin raza) — 0.30 kg` |

### Error común

Olvidarse el `coalesce`. Pipo no tiene raza cargada, y en SQL **cualquier cosa concatenada con `null` da `null`**: no se pierde la raza sola, se pierde la ficha entera.

Lo peor es que **no da error**: la celda sale vacía y hay que darse cuenta mirando. Es la clase de bug que llega a producción.

---

## Ejercicio 7 — Los medicamentos de una consulta

### Enunciado

Escribir `recetas_de(p_consulta int)` que devuelva varias filas con el nombre del medicamento, la dosis y la duración en días de todo lo recetado en esa consulta, y que pueda usarse en el `from`.

### Solución

```sql
create or replace function recetas_de(p_consulta int)
returns table(medicamento varchar, dosis varchar, dias int) as $$
  select m.nombre, r.dosis, r.duracion_dias
  from receta r
  join medicamento m on m.id_medicamento = r.id_medicamento
  where r.id_consulta = p_consulta
  order by m.nombre;
$$ language sql;
```

`returns table(...)` hace que la función devuelva **un conjunto de filas**, así que se usa en el `from` y no en la lista del `select`:

```sql
select * from recetas_de(4);
```

Es, en los hechos, **una vista con parámetros**.

### Resultado

| medicamento | dosis | dias |
|---|---|---|
| Cefalexina | 250mg cada 8hs | 7 |
| Prednisolona | 5mg cada 12hs | 10 |

Sin el `order by`, Postgres no garantiza ningún orden en particular.

### Error común

Declarar las columnas con el tipo que suena bien en vez del que tiene la tabla:

```sql
returns table(medicamento text, dosis text, dias int)   -- ✗
```

`medicamento.nombre` es `varchar(80)` y `receta.dosis` es `varchar(60)`. Postgres corta con *return type mismatch*. La regla: **el tipo del `returns table` tiene que coincidir con el de la columna que se devuelve**. Si hay dudas, mirar el `create table`.

Un segundo detalle, para cuando la escriban en `plpgsql` con `return query`: los nombres del `returns table` se comportan como variables, así que una columna de salida llamada `nombre` choca con la columna `nombre` de la tabla y Postgres avisa de la ambigüedad. Por eso acá la columna de salida se llama `medicamento` y no `nombre`.

---

## Ejercicio 8 — Días de tratamiento

### Enunciado

Escribir `dias_tratamiento(p_consulta int)` que devuelva la suma de `duracion_dias` de la consulta. Si no recetó nada, devolver `0` y no `null`, resolviéndolo con un `if` y una asignación con `:=`.

### Solución

```sql
create or replace function dias_tratamiento(p_consulta int)
returns int as $$
declare
  v_total int;
begin
  select sum(duracion_dias) into v_total
  from receta where id_consulta = p_consulta;

  if v_total is null then
    v_total := 0;
  end if;

  return v_total;
end $$ language plpgsql;
```

`:=` asigna un valor **sin ir a la base**. Es la diferencia con `select ... into`, que va a buscarlo.

### Resultado

| llamada | devuelve | por qué |
|---|---|---|
| `dias_tratamiento(7)` | 10 | 7 días de Amoxicilina + 3 de Meloxicam |
| `dias_tratamiento(4)` | 17 | 10 de Prednisolona + 7 de Cefalexina |
| `dias_tratamiento(1)` | 0 | la consulta 1 no recetó nada |

### Error común

Resolverlo con `found`, como en el ejercicio 5:

```sql
if not found then      -- ✗ nunca se cumple
  v_total := 0;
end if;
```

Acá `found` **siempre vale `true`**, aunque no haya ninguna receta. La razón: `sum()` es una función de agregación, y una agregación sin `group by` **siempre devuelve exactamente una fila** — con `null` adentro, pero una fila. Vino una fila, así que `found` es verdadero.

Es el contraste exacto con el ejercicio 5: ahí no venía ninguna fila; acá viene una fila vacía. Por eso ahí se pregunta por `found` y acá por `is null`.

La versión corta, para el que la vio venir:

```sql
create or replace function dias_tratamiento(p_consulta int)
returns int as $$
  select coalesce(sum(duracion_dias), 0)::int
  from receta where id_consulta = p_consulta;
$$ language sql;
```

---

## Ejercicio 9 — Un peso imposible

### Enunciado

Escribir un bloque `do` que le ponga `0` al peso de la mascota 3 y, si el peso que se está por guardar es menor o igual a cero, corte con el error `Peso inválido: <valor>`. Después verificar, en una ejecución aparte, qué quedó guardado, y explicar por qué.

### Solución

```sql
do $$
declare
  v_nuevo mascota.peso_kg%type := 0;
begin
  update mascota set peso_kg = v_nuevo where id_mascota = 3;

  if v_nuevo <= 0 then
    raise exception 'Peso inválido: %', v_nuevo;
  end if;
end $$;
```

Devuelve `ERROR: Peso inválido: 0`. Y después, **en otra ejecución**:

```sql
select id_mascota, nombre, peso_kg from mascota where id_mascota = 3;
```

| id_mascota | nombre | peso_kg |
|---|---|---|
| 3 | Toby | 6.00 |

Notar que el `declare` asigna el valor inicial con `:=` en la misma línea en que declara la variable.

### La respuesta

El peso quedó en 6.00 **aunque el `update` se ejecutó**.

El `update` y el `raise exception` están en el mismo bloque, y un bloque corre dentro de **una sola transacción**. Cuando el bloque corta con un error, Postgres deshace todo lo que esa transacción había hecho, incluido el `update` que ya había pasado.

Es exactamente un `rollback`, solo que no hubo que escribirlo: **lo disparó el error**. Esa es la forma de escribir "si pasa esto, rollback" adentro de un bloque de código.

### Error común

Partir el bloque en dos ejecuciones: primero el `update`, y en una segunda corrida la validación. Entonces **no hay nada que deshacer**: la primera ejecución ya terminó y confirmó, y Toby queda pesando 0 kg para siempre.

Lo que se deshace es lo que está en la **misma transacción** que el error. Por eso el `update` y su control van juntos.

---

## Ejercicio 10 — Lo que una función no puede hacer

### Enunciado

Escribir el procedimiento `limpiar_datos()` que ponga `duracion_dias = 1` a las recetas sin duración y deje en `null` el peso de las mascotas con peso `0`, confirmando cada tarea por separado. Después responder por qué no puede ser una función, cómo se invoca, y qué significa el error `2D000` de Supabase.

### Solución

```sql
create or replace procedure limpiar_datos()
language plpgsql as $$
begin
  update receta set duracion_dias = 1
  where duracion_dias is null;
  commit;

  update mascota set peso_kg = null
  where peso_kg = 0;
  commit;
end $$;

call limpiar_datos();
```

### a) ¿Por qué no puede ser una función?

Porque **una función corre adentro de la transacción de quien la llamó**. Si la llamás desde un `select`, la transacción es la de ese `select`: la función no la abrió, y no puede cerrarla. Un `commit` adentro de una función da error siempre.

Un procedimiento se invoca **solo**, con `call`, y no devuelve ningún valor que alguien esté esperando. Por eso sí puede abrir y cerrar sus propias transacciones. Existen desde **Postgres 11**.

Lo que sirve de acá: el procedimiento puede confirmar la primera tarea y seguir con la segunda. Si la segunda falla, lo que ya se confirmó **queda hecho**. Una función es todo o nada.

### b) ¿Cómo se invoca?

Con `call limpiar_datos();`.

Si se intenta con `select limpiar_datos();`, Postgres responde que eso es un procedimiento y sugiere usar `call`. No es un capricho de sintaxis: un `select` espera un valor de vuelta, y un procedimiento no devuelve ninguno.

### c) El error `2D000` de Supabase

```
ERROR: 2D000: invalid transaction termination
CONTEXT: PL/pgSQL function limpiar_datos() line N at COMMIT
```

El SQL Editor de Supabase **envuelve cada ejecución en una transacción propia**. Cuando el procedimiento llega al `commit`, se encuentra con una transacción que no abrió él, e intenta cerrarla: eso es lo que Postgres no permite, y es lo que dice el mensaje.

En `psql`, pgAdmin o DBeaver, el `call` se ejecuta en autocommit —sin ninguna transacción abierta por arriba— y el mismo código anda sin tocar una coma.

O sea: **no es un error del código ni una limitación de Postgres, es del editor**. Y leído al revés, es la mejor demostración de que un procedimiento maneja transacciones de verdad: si no las manejara, el editor no tendría de qué quejarse.

### Error común

Llamar "store procedure" a una función. Hasta Postgres 10 no había otra cosa, y por eso se usaban como sinónimos —el apunte de la Unidad VI todavía lo hace—. Desde la versión 11 son **dos objetos distintos**:

| | función | procedimiento |
|---|---|---|
| Se crea con | `create function` | `create procedure` |
| Devuelve valor | Sí | No |
| Se invoca | `select f(...)` | `call p(...)` |
| `commit` / `rollback` adentro | No puede | Sí puede |
| Se usa en una consulta | Sí | No |
