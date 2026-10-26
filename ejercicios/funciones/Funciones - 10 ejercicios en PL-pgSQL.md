# Diseño y Administración de Base de Datos

## Guía de ejercicios — Funciones y PL/pgSQL (Unidad VI)

Diez ejercicios sobre la base de **la veterinaria**. Antes de empezar hay que tener corridos, en este orden, `01_esquema.sql` y `02_datos.sql`.

Cada ejercicio trae el `select` con el que se prueba y el resultado que tiene que dar, así cada uno verifica lo suyo sin esperar la corrección.

---

### Antes de empezar: dos cosas del editor de Supabase

1. **Los `raise notice` no se ven.** El bloque corre y el editor dice *"Success. No rows returned"*, pero el mensaje no aparece en ningún lado. Por eso casi todos los ejercicios piden funciones que **devuelvan** un valor: lo que se devuelve sí se ve en la grilla.
2. **Un `commit` adentro de un procedimiento falla** con `ERROR 2D000: invalid transaction termination`. No es un error del código: está explicado en el ejercicio 10.

---

### Las tablas

| Tabla | Clave | Columnas |
|---|---|---|
| `dueno` | `id_dueno` | `dni`, `apellido`, `nombre`, `telefono`, `domicilio` |
| `veterinario` | `matricula` | `apellido`, `nombre`, `especialidad` |
| `medicamento` | `id_medicamento` | `nombre`, `droga`, `presentacion` |
| `mascota` | `id_mascota` | `id_dueno` → dueno, `nombre`, `especie`, `raza`, `fecha_nac`, `peso_kg` |
| `consulta` | `id_consulta` | `id_mascota` → mascota, `matricula` → veterinario, `fecha`, `motivo`, `diagnostico` |
| `receta` | `id_consulta` + `id_medicamento` | `dosis`, `frecuencia`, `duracion_dias` |

---

### Repaso rápido

| Pieza | Para qué |
|---|---|
| `$$ ... $$` | Delimita el cuerpo, que se le pasa a Postgres como un texto |
| `create function <nombre>(<params>) returns <tipo>` | Guarda la función en la base |
| `language sql` / `language plpgsql` | `sql` si el cuerpo es una sola consulta; `plpgsql` si hay que decidir, guardar en variables o lanzar errores |
| `declare` ... `select ... into` | Declara variables y les carga un valor desde la base |
| `:=` | Asigna un valor sin ir a la base |
| `tabla.columna%type` / `tabla%rowtype` | Toma el tipo de una columna, o guarda una fila entera |
| `if ... elsif ... else ... end if` | Decide qué sentencias se ejecutan |
| `found` | Vale `true` o `false` según si la sentencia anterior tocó filas |
| `raise exception` | Lanza un error, corta el bloque y deshace lo que el bloque hizo |
| `returns table(...)` | La función devuelve varias filas y se usa en el `from` |
| `create procedure` + `call` | No devuelve valor, pero puede hacer `commit` y `rollback` |

---

## Ejercicio 1 — Cuántas mascotas tiene un dueño

Escribir la función `cantidad_mascotas(p_dueno int)` que devuelva cuántas mascotas tiene ese dueño.

- El cuerpo es **una sola consulta**: elegir el `language` que corresponde.
- Prestar atención al tipo que se declara en el `returns`.

**Probala con**

```sql
select cantidad_mascotas(1);
select cantidad_mascotas(3);
select cantidad_mascotas(5);
```

**Tiene que devolver** `2`, `3` y `0`.

---

## Ejercicio 2 — El dueño de una mascota

Escribir `dueno_de(p_mascota int)` que, dado el id de una mascota, devuelva el texto `'Apellido, Nombre'` de su dueño.

- Resolverlo en **plpgsql**, con `declare` y `select ... into`.
- Declarar las variables con `%type`, sin escribir `varchar(60)` a mano.

**Probala con**

```sql
select dueno_de(1);
select dueno_de(9);
```

**Tiene que devolver** `Gómez, María` y `Sosa, Diego`.

---

## Ejercicio 3 — Clasificar por peso

Escribir `categoria_peso(p_peso decimal)` que devuelva:

- `'grande'` si el peso es mayor a 20 kg
- `'mediano'` si es mayor a 5 kg
- `'chico'` en cualquier otro caso

Esta función **no consulta la base**: trabaja solo con el parámetro que recibe.

**Probala con**

```sql
select nombre, peso_kg, categoria_peso(peso_kg) as categoria
from mascota
order by peso_kg desc;
```

**Tiene que devolver** las diez mascotas: dos `grande`, tres `mediano` y cinco `chico`.

---

## Ejercicio 4 — Lo mismo, sin función

Resolver la misma clasificación del ejercicio 3 **sin crear nada**: una sola consulta con `case`, que devuelva el mismo resultado.

Después, por escrito y en dos renglones: **¿cuándo conviene `case` y cuándo conviene la función con `if`?**

**Pista:** pensar qué pasa si mañana la veterinaria cambia los límites de peso, y esa clasificación está usada en seis consultas distintas.

---

## Ejercicio 5 — La edad, y qué pasa si la mascota no existe

Escribir `edad_mascota(p_id int)` que devuelva la edad en años cumplidos.

- Si **no existe** una mascota con ese id, tiene que cortar con el error `No existe la mascota <id>`, en lugar de devolver `null`.
- Para calcular la edad: `extract(year from age(<fecha>))`.

**Probala con**

```sql
select edad_mascota(1);
select edad_mascota(99);
```

**Tiene que devolver** `7` en el primer caso, y en el segundo cortar con el error.

---

## Ejercicio 6 — La ficha de la mascota

Escribir `ficha_mascota(p_id int)` que devuelva una línea con este formato:

```
Rocky (Perro, Labrador) — 28.50 kg
```

- Obligatorio usar **`%rowtype`**: una sola variable que guarde la fila entera.
- Hay mascotas **sin raza cargada**. En ese caso tiene que decir `sin raza`, y la línea tiene que salir completa igual.

**Probala con**

```sql
select ficha_mascota(1);
select ficha_mascota(7);
```

**Tiene que devolver**

```
Rocky (Perro, Labrador) — 28.50 kg
Pipo (Ave, sin raza) — 0.30 kg
```

---

## Ejercicio 7 — Los medicamentos de una consulta

Escribir `recetas_de(p_consulta int)` que devuelva **varias filas**: el nombre del medicamento, la dosis y la duración en días de todo lo recetado en esa consulta.

- Tiene que poder usarse en el `from`, como si fuera una tabla.

**Probala con**

```sql
select * from recetas_de(4);
```

**Tiene que devolver** dos filas: Prednisolona y Cefalexina.

---

## Ejercicio 8 — Días de tratamiento

Escribir `dias_tratamiento(p_consulta int)` que devuelva la **suma** de `duracion_dias` de todos los medicamentos recetados en esa consulta.

- Si la consulta **no recetó nada**, tiene que devolver `0`, no `null`.
- Resolver ese caso con un `if` y una asignación con `:=`.

**Probala con**

```sql
select dias_tratamiento(7);
select dias_tratamiento(4);
select dias_tratamiento(1);
```

**Tiene que devolver** `10`, `17` y `0`.

---

## Ejercicio 9 — Un peso imposible

Escribir un **bloque `do`** (no una función) que:

1. le ponga `0` al peso de la mascota 3 (Toby, que hoy pesa 6.00 kg);
2. si el peso que se está por guardar es menor o igual a cero, corte con el error `Peso inválido: <valor>`.

Después, **en una ejecución aparte**, verificar qué quedó guardado:

```sql
select id_mascota, nombre, peso_kg from mascota where id_mascota = 3;
```

**Se pide, además:** explicar en dos renglones por qué el peso quedó como quedó, **si en ningún momento se escribió `rollback`**.

---

## Ejercicio 10 — Lo que una función no puede hacer

Escribir el procedimiento `limpiar_datos()` que haga dos tareas, **confirmando cada una por separado**:

1. a las recetas sin duración cargada, ponerles `duracion_dias = 1`, y confirmar;
2. a las mascotas con peso `0`, dejarles el peso en `null`, y confirmar.

Después, responder:

- **a)** ¿Por qué esto no puede escribirse como una función?
- **b)** ¿Cómo se invoca? ¿Qué pasa si se intenta con `select`?
- **c)** Al correrlo en Supabase aparece `ERROR 2D000: invalid transaction termination`. ¿Qué dice ese error, y por qué el mismo código anda en pgAdmin o en DBeaver?
