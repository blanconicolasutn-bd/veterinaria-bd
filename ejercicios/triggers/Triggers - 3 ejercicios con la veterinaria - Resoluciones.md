# Resolución — 3 ejercicios de triggers

Resolución de [`Triggers - 3 ejercicios con la veterinaria.md`](Triggers%20-%203%20ejercicios%20con%20la%20veterinaria.md). Conviene intentarlos antes de mirarla.

Al final de cada ejercicio hay un **Error común**: casi siempre es más útil que la solución.

---

## Ejercicio 1 — El nombre bien escrito

### Enunciado

Que los nombres de las mascotas queden siempre guardados con la primera letra de cada palabra en mayúscula y sin espacios de más, tanto al insertar como al modificar.

### Solución

```sql
create or replace function fn_nombre_prolijo()
returns trigger as $$
begin
  new.nombre := initcap(trim(new.nombre));
  return new;
end $$ language plpgsql;

create trigger tr_nombre_prolijo
before insert or update of nombre on mascota
for each row
execute function fn_nombre_prolijo();
```

### Resultado

```sql
insert into mascota (id_dueno, nombre, especie)
values (1, '   rocKY junior  ', 'Perro');
```

| id_mascota | nombre |
|---|---|
| 11 | Rocky Junior |

### Lo que hay que ver acá

Un trigger `before` **no sirve solo para validar**: puede cambiar la fila. Lo que se guarda no es lo que vino en el `insert`, es lo que devuelve la función en `new`.

Por eso `new.nombre := ...` y después `return new`. Las dos cosas hacen falta: si asignás y no devolvés `new`, no se guarda nada.

El `update of nombre` evita que el trigger corra cuando alguien actualiza el peso o el domicilio. No es obligatorio, pero es gratis y ahorra llamadas.

### Error común

Escribirlo como `after`:

```sql
create trigger tr_nombre_prolijo
after insert or update on mascota   -- ✗
```

No da error. Simplemente **no hace nada**: en un `after` la fila ya está escrita y el valor devuelto se ignora. El nombre queda como vino, y el trigger parece estar funcionando porque nadie se queja.

El segundo, más silencioso todavía: olvidarse el `return new` y terminar la función con `return null`. En un `before`, eso **cancela el insert**: la mascota no se guarda, y tampoco hay error.

---

## Ejercicio 2 — No recetar dos veces lo mismo

### Enunciado

Un trigger que impida recetar dos veces el mismo medicamento en una consulta, venga de donde venga el `insert`, con el mensaje `El medicamento <id> ya está recetado en la consulta <id>`.

### Solución

```sql
create or replace function fn_no_duplicar_receta()
returns trigger as $$
declare
  v_existe int;
begin
  select 1 into v_existe
  from receta
  where id_consulta    = new.id_consulta
    and id_medicamento = new.id_medicamento;

  if found then
    raise exception 'El medicamento % ya está recetado en la consulta %',
                    new.id_medicamento, new.id_consulta;
  end if;

  return new;
end $$ language plpgsql;

create trigger tr_no_duplicar_receta
before insert on receta
for each row
execute function fn_no_duplicar_receta();
```

### Resultado

| | Devuelve |
|---|---|
| Primer `insert` de `(1, 3)` | Se guarda |
| Segundo `insert` de `(1, 3)` | `ERROR: El medicamento 3 ya está recetado en la consulta 1` |

### La respuesta: ¿para qué sirve, si la PK ya lo impide?

Para que el mensaje se entienda.

Sin el trigger, el segundo `insert` también falla — pero con esto:

```
ERROR: duplicate key value violates unique constraint "receta_pkey"
DETAIL: Key (id_consulta, id_medicamento)=(1, 3) already exists.
```

Eso no le dice nada a quien está cargando una receta. La restricción garantiza que **el dato no se rompa**; el trigger garantiza que **el error se entienda**. Las dos cosas van juntas: ninguna reemplaza a la otra.

Y funciona porque un trigger `before insert` corre **antes** de que se verifique la clave primaria. Si fuera `after`, la PK cortaría primero y el trigger no llegaría a hablar.

### Error común

Ponerlo como `after insert`. Nunca se llega a ejecutar: la violación de clave primaria ocurre antes, y el error que ve el usuario sigue siendo el de `receta_pkey`.

Es el mismo criterio del ejercicio 1 por otro camino: **si querés impedir algo, `before`**.

---

## Ejercicio 3 — El historial de pesos

### Enunciado

Registrar cada cambio de peso en una tabla `peso_historial`, con el valor anterior y el nuevo, y solo cuando el peso cambia de verdad.

### Solución

```sql
create table if not exists peso_historial (
  id             int generated always as identity primary key,
  id_mascota     int not null,
  peso_anterior  decimal(5,2),
  peso_nuevo     decimal(5,2),
  cuando         timestamp default now()
);

create or replace function fn_log_peso()
returns trigger as $$
begin
  insert into peso_historial (id_mascota, peso_anterior, peso_nuevo)
  values (old.id_mascota, old.peso_kg, new.peso_kg);

  return null;   -- after: el valor devuelto se ignora
end $$ language plpgsql;

create trigger tr_log_peso
after update of peso_kg on mascota
for each row
when (new.peso_kg is distinct from old.peso_kg)
execute function fn_log_peso();
```

### Resultado

```sql
update mascota set peso_kg = 30.00 where id_mascota = 1;
update mascota set peso_kg = 30.00 where id_mascota = 1;
update mascota set raza = 'Labrador' where id_mascota = 1;

select id_mascota, peso_anterior, peso_nuevo from peso_historial;
```

| id_mascota | peso_anterior | peso_nuevo |
|---|---|---|
| 1 | 28.50 | 30.00 |

**Una sola fila.** El segundo `update` guardaba el mismo valor y el tercero ni tocó la columna.

### Las tres piezas que lo filtran

Hay **tres** filtros distintos trabajando juntos, y conviene no confundirlos:

| Pieza | Qué filtra |
|---|---|
| `after update of peso_kg` | Que el `update` **mencione** la columna `peso_kg` — por eso el cambio de raza no dispara nada |
| `when (... is distinct from ...)` | Que el valor haya cambiado **de verdad** — por eso el segundo update no registra |
| `for each row` | Que se ejecute una vez por cada mascota afectada, y que existan `new` y `old` |

### Por qué `is distinct from` y no `<>`

Porque `<>` con `null` no da falso: da `null`, y un `when` con condición `null` no dispara.

Si una mascota no tiene el peso cargado y alguien se lo pone, `new.peso_kg <> old.peso_kg` sería `30.00 <> null` = `null`, y el cambio **no quedaría registrado**. `is distinct from` trata al `null` como un valor más y devuelve `true`.

### Para dejar la base como estaba

```sql
update mascota set peso_kg = 28.50 where id_mascota = 1;
delete from peso_historial;
```

### Error común

Usar `new` para el `id_mascota` y el peso anterior:

```sql
values (new.id_mascota, new.peso_kg, new.peso_kg);   -- ✗
```

Las dos columnas quedan con el mismo valor y el historial no sirve para nada. El valor viejo **solo existe en `old`**, y `old` solo existe en triggers `update` y `delete` por fila.

---

## El de yapa: el trigger que no hace nada

```sql
create function fn_rara()
returns trigger as $$
begin
  return null;
end $$ language plpgsql;

create trigger tr_rara
before insert on mascota
for each row execute function fn_rara();

insert into mascota (id_dueno, nombre, especie)
values (1, 'Fantasma', 'Perro');
-- INSERT 0 0   ← no da error

select count(*) from mascota where nombre = 'Fantasma';
-- 0
```

### Por qué

Devolver `null` en un trigger `before ... for each row` **cancela la operación para esa fila**. No es un error: es la forma que tiene PostgreSQL de decir "esta fila no va".

El `insert` termina bien, nadie se queja, y la fila no está. Fijate que la respuesta dice `INSERT 0 0`: el segundo número es cuántas filas se insertaron.

**Ojo con el apunte de la Unidad VI**, que dice que devolver `null` *"hace que el registro posea todos sus campos en NULL, lo que generará un error"*. No es así, y la diferencia importa: un error avisa, y esto no avisa nada.

La conclusión práctica: para **rechazar** algo, `raise exception`. `return null` solo cuando de verdad querés descartar en silencio, que es muy raro.
