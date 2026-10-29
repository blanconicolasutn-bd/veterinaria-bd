# Diseño y Administración de Base de Datos

## Guía de ejercicios — Triggers (Unidad VI)

Tres ejercicios sobre la base de **la veterinaria**, para hacer en clase. Antes de empezar hay que tener corridos, en este orden, `sql/01_esquema.sql` y `sql/02_datos.sql`.

Los tres se resuelven en el SQL Editor de Supabase. Cada uno trae el `select` con el que se prueba y el resultado que tiene que dar.

---

### Lo que hace falta de antes

Un trigger son siempre **dos cosas**: una función que devuelve `trigger` y no recibe parámetros, y el `create trigger` que la conecta con la tabla.

```sql
create function <nombre>()
returns trigger as $$
begin
  -- acá se usan new y old
  return new;
end $$ language plpgsql;

create trigger <nombre>
{ before | after } { insert | update | delete }
on <tabla>
for each row
execute function <funcion>();
```

Las cuatro decisiones que hay que tomar cada vez:

| | Opciones | Cómo se elige |
|---|---|---|
| ¿Cuándo? | `before` / `after` | `before` si querés cambiar o impedir la fila; `after` si querés reaccionar a algo ya hecho |
| ¿Cada cuánto? | `for each row` / `for each statement` | `row` si necesitás mirar la fila. **No es el default**: hay que escribirlo |
| ¿Qué datos? | `new` / `old` | `insert` trae `new`; `delete` trae `old`; `update` trae las dos |
| ¿Qué devuelve? | `new` / `old` / `null` | En un `before`, `null` **cancela la operación en silencio**. En un `after` da igual: se ignora |

---

## Ejercicio 1 — El nombre bien escrito

Los nombres de las mascotas se cargan como sale: `rocky`, `ROCKY`, `  Rocky  `. Queremos que **siempre** queden guardados con la primera letra de cada palabra en mayúscula y sin espacios de más, sin pedirle nada a quien carga.

**Se pide:**

1. La función y el trigger que lo resuelvan.
2. Tiene que funcionar tanto al insertar como al modificar el nombre.
3. Verificar con el ejemplo de abajo y dejar la base como estaba.

**Pistas:** `initcap()` pone en mayúscula la primera letra de cada palabra; `trim()` saca los espacios de los extremos. Y acordate de que un `before` puede **devolver un `new` distinto del que vino**.

**Probalo con**

```sql
insert into mascota (id_dueno, nombre, especie)
values (1, '   rocKY junior  ', 'Perro');

select id_mascota, nombre from mascota
where especie = 'Perro' and id_dueno = 1
order by id_mascota desc limit 1;
```

**Tiene que devolver** `Rocky Junior`, sin espacios adelante ni atrás.

**Para dejar la base como estaba**

```sql
delete from mascota where nombre = 'Rocky Junior';
```

---

## Ejercicio 2 — No recetar dos veces lo mismo

En el ejercicio 4 de la guía de funciones integradoras escribieron `recetar()`, que impedía recetar dos veces el mismo medicamento en una consulta. El problema es que esa validación **solo corre si alguien llama a la función**: un `insert` directo sobre `receta` se la saltea.

**Se pide:**

1. Un trigger que haga esa validación **siempre**, venga de donde venga el `insert`.
2. El mensaje tiene que ser `El medicamento <id> ya está recetado en la consulta <id>`.
3. Verificar y dejar la base como estaba.

**Para pensar antes de escribir nada:** la clave primaria de `receta` ya impide el duplicado. ¿Para qué sirve entonces el trigger? Escribilo en un renglón.

**Probalo con**

```sql
insert into receta (id_consulta, id_medicamento, dosis, duracion_dias)
values (1, 3, '1 ampolla', 5);

insert into receta (id_consulta, id_medicamento, dosis, duracion_dias)
values (1, 3, '1 ampolla', 5);
```

**Tiene que** aceptar el primero y cortar el segundo con **tu** mensaje, no con el de la clave primaria.

**Para dejar la base como estaba**

```sql
delete from receta where id_consulta = 1;
```

---

## Ejercicio 3 — El historial de pesos

La veterinaria quiere poder revisar cómo fue cambiando el peso de cada mascota. Hay que registrar **cada cambio** en una tabla aparte, guardando el valor anterior y el nuevo.

**Se pide:**

1. Crear la tabla `peso_historial` con: un id propio, el `id_mascota`, el peso anterior, el peso nuevo y la fecha y hora del cambio.
2. La función y el trigger que la llenen solos.
3. Tiene que registrar **solo cuando el peso cambia de verdad**: si alguien actualiza el domicilio, o vuelve a guardar el mismo peso, no se registra nada.
4. Verificar y dejar la base como estaba.

**Pistas:** éste es el único de los tres que necesita `old`. Para comparar valores que pueden ser `null`, `=` no sirve: mirá `is distinct from`.

**Probalo con**

```sql
update mascota set peso_kg = 30.00 where id_mascota = 1;
update mascota set peso_kg = 30.00 where id_mascota = 1;   -- mismo valor
update mascota set raza = 'Labrador' where id_mascota = 1; -- otra columna

select id_mascota, peso_anterior, peso_nuevo
from peso_historial;
```

**Tiene que devolver una sola fila**: `1 | 28.50 | 30.00`. Los otros dos `update` no tienen que dejar rastro.

**Para dejar la base como estaba**

```sql
update mascota set peso_kg = 28.50 where id_mascota = 1;
delete from peso_historial;
```

---

## Si querés seguir

Cuando los tres anden, probá esto y explicá qué pasó:

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

select count(*) from mascota where nombre = 'Fantasma';

drop trigger tr_rara on mascota;
drop function fn_rara();
```

El `insert` no da error. El `select` devuelve `0`. **¿Por qué?**
