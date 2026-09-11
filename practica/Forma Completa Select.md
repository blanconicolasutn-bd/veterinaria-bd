# SELECT — Guía completa con ejemplos

Basado en `https://www.postgresql.org/docs/current/sql-select.html`. Todos los ejemplos
usan el modelo de la veterinaria (`Veterinaria - 01 esquema (Supabase-PostgreSQL).sql`
y `Veterinaria - 02 datos de ejemplo.sql`), así que se pueden correr tal cual contra esa base.

Tablas: `dueno`, `mascota`, `veterinario`, `consulta`, `medicamento`, `receta`.

---

## Orden real de ejecución

Se lee `SELECT ... FROM ... WHERE ...` pero **no se ejecuta en ese orden**:

```
FROM / JOIN  →  WHERE  →  GROUP BY / HAVING  →  SELECT (expresiones)
→  DISTINCT  →  UNION/INTERSECT/EXCEPT  →  ORDER BY  →  LIMIT/OFFSET/FETCH  →  FOR UPDATE
```

Por eso un alias definido en el SELECT no se puede usar en el WHERE (el WHERE corre antes
de que el alias exista), pero sí se puede usar en el ORDER BY (que corre después).

---

# Parte 1 — Lo que ya vimos en clase

## 1. SELECT básico, alias y WHERE

```sql
select apellido, nombre as primer_nombre
from dueno
where telefono is not null;
```

## 2. ORDER BY

```sql
select nombre, peso_kg
from mascota
order by peso_kg desc, nombre asc;
```

`NULLS FIRST` / `NULLS LAST` controla dónde van los nulos (por defecto, `ASC` pone los
nulos al final y `DESC` al principio):

```sql
select apellido, telefono
from dueno
order by telefono nulls last;
```

## 3. JOINs

```sql
-- INNER JOIN: solo mascotas que tienen dueño (todas, en este modelo, porque id_dueno es NOT NULL)
select m.nombre as mascota, d.apellido as dueno
from mascota m
join dueno d on m.id_dueno = d.id_dueno;

-- LEFT JOIN: todos los dueños, tengan o no mascotas (Alvarez va a aparecer con NULL)
select d.apellido, m.nombre as mascota
from dueno d
left join mascota m on m.id_dueno = d.id_dueno;

-- FULL OUTER JOIN: veterinarios sin consultas Y consultas sin veterinario válido (no debería haber, pero lo muestra igual)
select v.apellido, c.id_consulta
from veterinario v
full join consulta c on c.matricula = v.matricula;

-- USING: forma corta cuando la columna se llama igual en ambas tablas
-- (no aplica directo a este modelo porque las FK no se llaman igual que la PK referenciada,
--  salvo id_mascota entre consulta y receta si la tuviéramos ahí — se deja como ejemplo conceptual)
```

## 4. GROUP BY y HAVING

```sql
-- Cantidad de mascotas por especie
select especie, count(*) as cantidad
from mascota
group by especie;

-- Solo las especies con más de 2 mascotas
select especie, count(*) as cantidad
from mascota
group by especie
having count(*) > 2;
```

## 5. Funciones de agregado

```sql
select
  count(*)          as total_consultas,
  count(distinct id_mascota) as mascotas_distintas,
  min(fecha)         as primera_consulta,
  max(fecha)         as ultima_consulta
from consulta;
```

## 6. Funciones de ventana

```sql
-- Numerar las consultas de cada mascota en orden cronológico
select
  id_mascota,
  fecha,
  row_number() over (partition by id_mascota order by fecha) as nro_visita
from consulta;

-- Comparar cada consulta con el promedio general, sin colapsar filas (a diferencia de GROUP BY)
select
  id_consulta,
  fecha,
  count(*) over () as total_consultas_global
from consulta;
```

---

# Parte 2 — Extra: lo que no vimos en clase

## 7. DISTINCT y DISTINCT ON

```sql
-- DISTINCT: valores únicos
select distinct especie from mascota;

-- DISTINCT ON: la fila "más reciente" de cada grupo (necesita ORDER BY que empiece igual)
select distinct on (id_mascota) id_mascota, fecha, motivo
from consulta
order by id_mascota, fecha desc;
```

`DISTINCT ON` es de las herramientas más útiles y menos conocidas: resuelve en una sola
consulta el clásico "traeme el último registro de cada X" sin subconsultas ni window functions.

## 8. UNION / INTERSECT / EXCEPT

```sql
-- UNION: junta los apellidos de dueños y veterinarios, sin duplicados
select apellido from dueno
union
select apellido from veterinario;

-- UNION ALL: igual, pero sin sacar duplicados (más rápido si sabés que no los necesitás sacar)
select apellido from dueno
union all
select apellido from veterinario;

-- Ojo con este "gotcha": Rocky y Michi son nombres repetidos en mascotas de dueños distintos.
-- UNION los deja como UNA sola fila, aunque son animales distintos:
select nombre from mascota where id_dueno = 1   -- Rocky, Michi
union
select nombre from mascota where id_dueno = 3;  -- Rocky, Michi, Pipo
-- resultado: Rocky, Michi, Pipo (¡no 5 filas, sino 3!)

-- INTERSECT: apellidos que aparecen en ambas tablas (con estos datos, vacío)
select apellido from dueno
intersect
select apellido from veterinario;

-- EXCEPT: apellidos de dueños que NO son también apellidos de veterinarios
select apellido from dueno
except
select apellido from veterinario;
```

## 9. LIMIT, OFFSET y FETCH

```sql
-- Las 5 consultas más recientes
select * from consulta
order by fecha desc
limit 5;

-- Paginación "clásica": página 2, de a 3 resultados
select * from mascota
order by nombre
limit 3 offset 3;

-- Sintaxis estándar SQL (equivalente a LIMIT/OFFSET, más explícita)
select * from medicamento
order by nombre
offset 0 rows
fetch first 3 rows only;

-- WITH TIES: si hay empate en el último puesto, lo incluye igual
select nombre, peso_kg from mascota
order by peso_kg desc
fetch first 3 rows with ties;
```

**Importante:** sin `ORDER BY`, `LIMIT`/`OFFSET` no garantizan qué filas van a volver —
el orden "natural" de una tabla no está definido en SQL.

## 10. WITH (CTEs — Common Table Expressions)

```sql
-- Le da nombre a una subconsulta para reutilizarla o para que la query sea más legible
with consultas_2024 as (
  select * from consulta where fecha >= '2024-01-01'
)
select m.nombre, count(*) as consultas_2024
from consultas_2024 c
join mascota m on c.id_mascota = m.id_mascota
group by m.nombre;

-- Varias CTEs encadenadas
with
  consultas_con_receta as (
    select distinct id_consulta from receta
  ),
  detalle as (
    select c.id_consulta, c.fecha, m.nombre as mascota
    from consulta c
    join mascota m on c.id_mascota = m.id_mascota
    where c.id_consulta in (select id_consulta from consultas_con_receta)
  )
select * from detalle order by fecha;
```

### WITH RECURSIVE

Este modelo no tiene una tabla jerárquica (como `empleado` con `legajo_jefe`), pero la
sintaxis general — muy usada para árboles y jerarquías — es:

```sql
with recursive contador as (
  select 1 as n                    -- caso base
  union all
  select n + 1 from contador where n < 5   -- caso recursivo
)
select * from contador;
-- devuelve 1, 2, 3, 4, 5
```

Si tuviéramos `empleado(legajo, legajo_jefe)`, el mismo patrón serviría para traer "todos
los subordinados, directos e indirectos, de un jefe dado".

## 11. GROUP BY avanzado: ROLLUP, CUBE, GROUPING SETS

```sql
-- ROLLUP: subtotal por veterinario + un total general al final
select v.apellido, count(*) as cantidad
from consulta c
join veterinario v on c.matricula = v.matricula
group by rollup (v.apellido);

-- CUBE: todas las combinaciones posibles (útil con 2+ columnas)
select v.apellido, extract(year from c.fecha) as anio, count(*)
from consulta c
join veterinario v on c.matricula = v.matricula
group by cube (v.apellido, anio);

-- GROUPING SETS: solo las combinaciones que a vos te interesan, ni más ni menos
select v.apellido, extract(year from c.fecha) as anio, count(*)
from consulta c
join veterinario v on c.matricula = v.matricula
group by grouping sets ((v.apellido), (anio), ());
```

## 12. LATERAL

```sql
-- Para cada dueño, la mascota con más peso (un JOIN correlacionado, fila por fila)
select d.apellido, top_mascota.nombre, top_mascota.peso_kg
from dueno d
left join lateral (
  select nombre, peso_kg
  from mascota
  where id_dueno = d.id_dueno
  order by peso_kg desc
  limit 1
) top_mascota on true;
```

`LATERAL` permite que la subconsulta del lado derecho "vea" columnas de la tabla del lado
izquierdo — algo que un JOIN normal no puede hacer.

## 13. TABLESAMPLE

```sql
-- Una muestra aleatoria del ~20% de las consultas (rápido, a nivel de bloque de disco)
select * from consulta tablesample system (20);

-- Muestreo fila por fila (más lento, más "aleatorio" de verdad) y reproducible
select * from consulta tablesample bernoulli (20) repeatable (42);
```

## 14. FOR UPDATE / FOR SHARE (locking)

```sql
-- Bloquea la fila para que nadie más la modifique hasta que termine tu transacción
begin;
select * from consulta where id_consulta = 5 for update;
-- ... hacer algo con esa fila ...
commit;

-- SKIP LOCKED: muy usado para colas de trabajo — si otro proceso ya la tomó, la salteo
select * from consulta
where motivo ilike '%control%'
order by fecha
limit 1
for update skip locked;
```

## 15. TABLE — atajo

```sql
table veterinario;
-- exactamente lo mismo que:
select * from veterinario;
```

---

## Resumen: qué usar según lo que necesitás

| Necesito... | Uso |
|---|---|
| El último registro de cada grupo | `DISTINCT ON` |
| Combinar resultados de 2 queries | `UNION` / `UNION ALL` |
| Paginar resultados | `LIMIT` / `OFFSET`, siempre con `ORDER BY` |
| Reusar una subconsulta varias veces / hacerla legible | `WITH` |
| Recorrer una jerarquía (árbol, organigrama) | `WITH RECURSIVE` |
| Subtotales + total general | `GROUP BY ROLLUP` |
| JOIN que necesita "ver" la fila de la izquierda | `LATERAL` |
| Traer una muestra al azar (no todo) | `TABLESAMPLE` |
| Evitar que otra transacción toque una fila mientras trabajo | `FOR UPDATE` |
