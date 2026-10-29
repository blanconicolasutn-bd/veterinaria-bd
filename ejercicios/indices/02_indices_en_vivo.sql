-- ============================================================
-- Índices y EXPLAIN — para seguir en clase (Unidad VII)
--
-- Requiere haber corrido antes 01_datos_demo.sql
--
-- CÓMO USARLO: no corras el archivo entero. Seleccioná con el
-- mouse el bloque que querés ver y apretá Ctrl+Enter (Cmd+Enter
-- en Mac): Supabase ejecuta solo lo seleccionado. Si corrés todo
-- junto, muestra únicamente el resultado del último SELECT.
--
-- Cada bloque dice abajo qué tiene que pasar. Los tiempos y los
-- costos van a dar distinto en cada máquina: lo que importa es
-- el NOMBRE DEL NODO (Seq Scan o Index Scan) y si la condición
-- aparece como Filter o como Index Cond.
-- ============================================================


-- ════════════════════════════════════════════════════════════
-- 1 · SIN ÍNDICE, Y CON ÍNDICE
-- ════════════════════════════════════════════════════════════

-- [1.1] El punto de partida: dos tablas grandes y cero índices.
select tablename, indexname
from pg_indexes
where tablename in ('ix_mascota', 'ix_consulta');
-- ESPERADO: ninguna fila. Todavía no hay un solo índice.


-- [1.2] Buscar UNA consulta entre doscientas mil, sin índice.
explain analyze
select * from ix_consulta
where id_consulta = 150000;
-- ESPERADO: Seq Scan on ix_consulta
--           Filter: (id_consulta = 150000)
--           Rows Removed by Filter: 199999
-- Leyó las 200.000 filas para quedarse con una.
-- ANOTÁ el Execution Time: lo vamos a comparar en [1.4].


-- [1.3] Creamos el índice.
create index idx_cons_id on ix_consulta (id_consulta);
-- ESPERADO: Success. Tarda un poco: tiene que leer la tabla entera.


-- [1.4] La MISMA consulta, sin cambiarle una letra.
explain analyze
select * from ix_consulta
where id_consulta = 150000;
-- ESPERADO: Index Scan using idx_cons_id
--           Index Cond: (id_consulta = 150000)
-- Desapareció el Rows Removed by Filter: ya no lee filas de más.
-- Comparar el Execution Time con el de [1.2].
--
-- LO IMPORTANTE: nadie le pidió que usara el índice. Lo eligió
-- solo, porque ahora es el plan más barato. SQL es declarativo.


-- ════════════════════════════════════════════════════════════
-- 2 · EL MISMO ÍNDICE SE USA O NO SEGÚN CUÁNTAS FILAS DEVUELVA
-- ════════════════════════════════════════════════════════════

-- [2.1] Cómo están repartidos los diagnósticos.
select diagnostico, count(*) as filas,
       round(100.0 * count(*) / sum(count(*)) over (), 2) as porcentaje
from ix_consulta
group by diagnostico
order by filas desc;
-- ESPERADO: 'Sano' se lleva el 85%; 'Insuficiencia cardíaca' el 0,5%.


-- [2.2] Un índice sobre diagnostico.
create index idx_cons_diag on ix_consulta (diagnostico);


-- [2.3] Buscamos el diagnóstico RARO: ~1.000 filas de 200.000.
explain analyze
select * from ix_consulta
where diagnostico = 'Insuficiencia cardíaca';
-- ESPERADO: usa el índice — Bitmap Index Scan o Index Scan.
-- Devuelve poquitas filas, así que ir al índice conviene.


-- [2.4] Buscamos el diagnóstico COMÚN: ~170.000 filas de 200.000.
explain analyze
select * from ix_consulta
where diagnostico = 'Sano';
-- ESPERADO: Seq Scan, a pesar de que el índice existe.
--
-- No es un error del motor: si vas a devolver el 85% de la tabla,
-- ir al índice y después a la tabla por cada fila sale MÁS caro
-- que leer todo de corrido. Es el "70%" del apunte, en vivo.


-- ════════════════════════════════════════════════════════════
-- 3 · LA FUNCIÓN QUE TAPA EL ÍNDICE
-- ════════════════════════════════════════════════════════════

-- [3.1] Índice sobre el nombre de la mascota.
create index idx_mas_nombre on ix_mascota (nombre);

explain analyze
select * from ix_mascota
where nombre = 'Rocky 1234';
-- ESPERADO: Index Scan. Hasta acá, todo bien.


-- [3.2] Ahora buscamos sin importar mayúsculas y minúsculas.
explain analyze
select * from ix_mascota
where lower(nombre) = 'rocky 1234';
-- ESPERADO: Seq Scan.
--
-- El índice está sobre nombre, no sobre lower(nombre). Para el
-- motor son dos cosas distintas y no lo puede usar. Es el error
-- más común: "creé el índice y no lo usa".


-- [3.3] Se arregla con un índice por expresión.
create index idx_mas_nombre_lower on ix_mascota (lower(nombre));

explain analyze
select * from ix_mascota
where lower(nombre) = 'rocky 1234';
-- ESPERADO: Index Scan using idx_mas_nombre_lower.


-- ════════════════════════════════════════════════════════════
-- 4 · EN UN ÍNDICE MULTICOLUMNA, EL ORDEN IMPORTA
-- ════════════════════════════════════════════════════════════

-- [4.1] Un índice sobre (matricula, fecha), en ese orden.
create index idx_cons_vet_fecha on ix_consulta (matricula, fecha);


-- [4.2] Filtrando por la PRIMERA columna: lo usa.
explain analyze
select * from ix_consulta
where matricula = 1003 and fecha = date '2024-06-15';
-- ESPERADO: Index Scan using idx_cons_vet_fecha.


-- [4.3] Filtrando por la SEGUNDA sola: no le sirve igual.
explain analyze
select * from ix_consulta
where fecha = date '2024-06-15';
-- ESPERADO: Seq Scan, o a lo sumo un recorrido completo del
-- índice. Un índice (a, b) sirve para buscar por a, o por a y b,
-- pero no para buscar solo por b: es como el índice de un libro
-- ordenado por apellido y nombre, que no sirve para buscar por
-- nombre.


-- ════════════════════════════════════════════════════════════
-- 5 · ÍNDICE PARCIAL
-- ════════════════════════════════════════════════════════════

-- [5.1] Solo nos interesan las consultas caras: indexamos esas.
create index idx_cons_caras on ix_consulta (fecha)
where importe > 45000;

select pg_size_pretty(pg_relation_size('idx_cons_vet_fecha')) as completo,
       pg_size_pretty(pg_relation_size('idx_cons_caras'))     as parcial;
-- ESPERADO: el parcial pesa muchísimo menos.


-- [5.2] Lo usa solo si la consulta repite la condición del índice.
explain analyze
select * from ix_consulta
where importe > 45000 and fecha = date '2024-06-15';
-- ESPERADO: usa idx_cons_caras.

explain analyze
select * from ix_consulta
where fecha = date '2024-06-15';
-- ESPERADO: NO usa idx_cons_caras — sin la condición del importe,
-- el motor no puede saber que ese índice alcanza.


-- ════════════════════════════════════════════════════════════
-- 6 · LOS JOIN METHODS
-- ════════════════════════════════════════════════════════════

-- [6.1] Join grande contra grande.
explain analyze
select c.id_consulta, m.nombre
from ix_consulta c
join ix_mascota m on m.id_mascota = c.id_mascota;
-- ESPERADO: Hash Join. Arma una tabla hash con la más chica
-- (ix_mascota) y recorre la otra comparando contra ella.


-- [6.2] Join filtrando fuerte de un lado.
explain analyze
select c.id_consulta, m.nombre
from ix_consulta c
join ix_mascota m on m.id_mascota = c.id_mascota
where c.diagnostico = 'Insuficiencia cardíaca';
-- ESPERADO: Nested Loop. Como del lado izquierdo quedan pocas
-- filas, al motor le conviene buscar una por una en la otra tabla
-- — si tiene un índice para hacerlo.


-- [6.3] Démosle ese índice y comparemos.
create index idx_mas_id on ix_mascota (id_mascota);

explain analyze
select c.id_consulta, m.nombre
from ix_consulta c
join ix_mascota m on m.id_mascota = c.id_mascota
where c.diagnostico = 'Insuficiencia cardíaca';
-- ESPERADO: Nested Loop con Index Scan adentro, y bastante más
-- rápido que [6.2].


-- ════════════════════════════════════════════════════════════
-- 7 · LO QUE CUESTA TENER ÍNDICES
-- ════════════════════════════════════════════════════════════

-- [7.1] Cuánto ocupan los índices que creamos.
select indexrelname as indice,
       pg_size_pretty(pg_relation_size(indexrelid)) as tamano
from pg_stat_user_indexes
where relname in ('ix_consulta', 'ix_mascota')
order by pg_relation_size(indexrelid) desc;
-- ESPERADO: entre todos suman varios MB sobre una tabla de ~25 MB.


-- [7.2] Cuánto tarda insertar 20.000 filas CON todos esos índices.
-- La transacción se deshace sola: la tabla queda como estaba.
begin;
explain analyze
insert into ix_consulta
  (id_consulta, id_mascota, matricula, fecha, motivo, diagnostico, importe)
select 900000 + g, 1, 1001, current_date, 'Prueba', 'Sano', 1000
from generate_series(1, 20000) g;
rollback;
-- ESPERADO: anotá el Execution Time.


-- [7.3] Lo mismo, pero sin índices: los borramos, medimos y
-- después los volvemos a crear.
drop index if exists idx_cons_id;
drop index if exists idx_cons_diag;
drop index if exists idx_cons_vet_fecha;
drop index if exists idx_cons_caras;

begin;
explain analyze
insert into ix_consulta
  (id_consulta, id_mascota, matricula, fecha, motivo, diagnostico, importe)
select 900000 + g, 1, 1001, current_date, 'Prueba', 'Sano', 1000
from generate_series(1, 20000) g;
rollback;
-- ESPERADO: bastante más rápido que [7.2].
--
-- Ésa es la contra: cada índice hay que mantenerlo en cada alta,
-- baja y modificación. Un índice que nadie usa es solo costo.


-- [7.4] Los volvemos a crear.
create index idx_cons_id        on ix_consulta (id_consulta);
create index idx_cons_diag      on ix_consulta (diagnostico);
create index idx_cons_vet_fecha on ix_consulta (matricula, fecha);
create index idx_cons_caras     on ix_consulta (fecha) where importe > 45000;
analyze ix_consulta;


-- ════════════════════════════════════════════════════════════
-- 8 · ¿SE ESTÁN USANDO?
-- ════════════════════════════════════════════════════════════

-- [8.1] PostgreSQL lleva la cuenta de cuántas veces usó cada índice.
select indexrelname as indice,
       idx_scan     as veces_usado,
       pg_size_pretty(pg_relation_size(indexrelid)) as tamano
from pg_stat_user_indexes
where relname in ('ix_consulta', 'ix_mascota')
order by idx_scan;
-- ESPERADO: los que creamos y probamos tienen idx_scan > 0.
-- En un sistema real, los que quedan en 0 son candidatos a borrar.


-- ════════════════════════════════════════════════════════════
-- 9 · LIMPIEZA — al terminar la unidad
-- ════════════════════════════════════════════════════════════
-- drop table if exists ix_consulta;
-- drop table if exists ix_mascota;
