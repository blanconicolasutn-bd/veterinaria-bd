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
--
-- MEDIDO EN SUPABASE EL 29/10:
--   Seq Scan on ix_consulta (cost=0.00..4332.00 rows=1 width=42)
--   Rows Removed by Filter: 199999
--   Planning Time:    0.284 ms
--   Execution Time: 505.359 ms   <-- el número a retener


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
-- MEDIDO EN SUPABASE EL 29/10:
--   Index Scan using idx_cons_id (cost=0.42..2.64 rows=1 width=42)
--   Index Cond: (id_consulta = 150000)
--   Planning Time:  1.792 ms
--   Execution Time: 2.812 ms
--
--   505,359 ms  ->  2,812 ms  =  180 VECES MÁS RÁPIDO.
--   Y mirá el costo estimado: de 4332 bajo a 2,64. Por eso el
--   motor cambió de plan: no es magia, es que ahora hay uno
--   mucho más barato.
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
--
-- MEDIDO EL 29/10: Index Scan using idx_cons_diag
--   (cost=0.29..447.98 rows=1040)
--   Index Cond: ((diagnostico)::text = 'Insuficiencia cardíaca'::text)
--   Execution Time: 1.759 ms
-- Estimó 1040 filas y hay 1011: las estadísticas del ANALYZE
-- están bien, y por eso acertó el plan.


-- [2.4] Buscamos el diagnóstico COMÚN: ~170.000 filas de 200.000.
explain analyze
select * from ix_consulta
where diagnostico = 'Sano';
-- ESPERADO: Seq Scan, a pesar de que el índice existe.
--
-- No es un error del motor: si vas a devolver el 85% de la tabla,
-- ir al índice y después a la tabla por cada fila sale MÁS caro
-- que leer todo de corrido. Es el "70%" del apunte, en vivo.
--
-- MEDIDO EL 29/10: Seq Scan on ix_consulta
--   (cost=0.00..4332.00 rows=169660 width=42)
--   Rows Removed by Filter: 30026
--   Execution Time: 30.240 ms
--
-- DOS COSAS PARA MOSTRAR ACÁ:
--   1) Es el MISMO índice de [2.3], que recién usó y ahora ignora.
--      Lo único que cambió es cuántas filas devuelve la consulta.
--   2) Ahora "Rows Removed by Filter" es 30.026 y no 199.999: las
--      filas que leyó de más son pocas, porque casi todas sirven.


-- ════════════════════════════════════════════════════════════
-- 3 · LA FUNCIÓN QUE TAPA EL ÍNDICE
-- ════════════════════════════════════════════════════════════

-- [3.0] PRIMERO: buscá un nombre que exista de verdad.
-- Los nombres se generaron al azar, así que 'Rocky 1234' puede
-- no existir en tu base. Copiá el que te devuelva esto y usalo
-- en los bloques que siguen, en lugar de 'Rocky 1234'.
select nombre from ix_mascota where id_mascota = 1234;

-- El plan es el mismo exista o no la fila — lo que estamos
-- mirando es cómo BUSCA, no qué encuentra —, pero queda mejor
-- si además devuelve algo.


-- [3.1] Índice sobre el nombre de la mascota.
create index idx_mas_nombre on ix_mascota (nombre);

explain analyze
select * from ix_mascota
where nombre = 'Rocky 1234';
-- ESPERADO: Index Scan. Hasta acá, todo bien.
--
-- MEDIDO EL 29/10: Index Scan using idx_mas_nombre
--   (cost=0.29..2.51 rows=1 width=25)
--   Index Cond: ((nombre)::text = 'Rocky 1234'::text)
--   Execution Time: 0.778 ms


-- [3.2] Ahora buscamos sin importar mayúsculas y minúsculas.
explain analyze
select * from ix_mascota
where lower(nombre) = 'rocky 1234';
-- ESPERADO: Seq Scan.
--
-- El índice está sobre nombre, no sobre lower(nombre). Para el
-- motor son dos cosas distintas y no lo puede usar. Es el error
-- más común: "creé el índice y no lo usa".
--
-- MEDIDO EL 29/10: Seq Scan on ix_mascota
--   (cost=0.00..447.00 rows=100 width=25)
--   Filter: (lower((nombre)::text) = 'rocky 1234'::text)
--   Rows Removed by Filter: 20000
--   Execution Time: 12.134 ms
--
-- Leyó las 20.000 filas. Y fijate el contraste con [3.1]: misma
-- tabla, misma columna, mismo índice — lo único que cambió es
-- que la condición le aplica una función a la columna.


-- [3.3] Se arregla con un índice por expresión.
create index idx_mas_nombre_lower on ix_mascota (lower(nombre));

explain analyze
select * from ix_mascota
where lower(nombre) = 'rocky 1234';
-- ESPERADO: usa idx_mas_nombre_lower.
--
-- MEDIDO EL 29/10: Bitmap Heap Scan on ix_mascota
--   Recheck Cond: (lower((nombre)::text) = 'rocky 1234'::text)
--   -> Bitmap Index Scan on idx_mas_nombre_lower
--      (cost=0.00..2.14 rows=100)
--   Execution Time: 0.059 ms
--
--   12,134 ms  ->  0,059 ms  =  unas 200 veces más rápido.
--
-- NO es un "Index Scan" a secas: el motor eligió un Bitmap Scan,
-- que es una variante. Primero arma en memoria un mapa de qué
-- páginas del disco tienen filas que sirven (Bitmap Index Scan)
-- y después las lee de una (Bitmap Heap Scan). Lo elige cuando
-- espera varias filas dispersas. Para lo que estamos viendo es
-- lo mismo: usó el índice.


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
--
-- MEDIDO EL 29/10: Index Scan using idx_cons_vet_fecha
--   (cost=0.29..33.68 rows=3 width=42)
--   Index Cond: ((matricula = 1003) AND (fecha = '2024-06-15'::date))
--   Execution Time: 0.292 ms
--
-- Mirá que las DOS condiciones están en Index Cond, y no hay
-- ningún Filter: el motor no leyó una sola fila de más. El índice
-- resolvió la búsqueda completa.


-- [4.3] Filtrando por la SEGUNDA sola: no le sirve igual.
explain analyze
select * from ix_consulta
where fecha = date '2024-06-15';
-- MEDIDO EL 29/10: Index Scan using idx_cons_vet_fecha
--   (cost=0.29..1805.24 rows=92 width=42)
--   Index Cond: (fecha = '2024-06-15'::date)
--   Execution Time: 6.124 ms
--
-- OJO ACÁ, QUE ES EL PUNTO DEL BLOQUE: dice "Index Scan", así que
-- a primera vista parecería que el índice sí le sirve. Compará los
-- costos con el bloque anterior:
--
--     [4.2] por matrícula y fecha   cost 0.29..33.68     0,292 ms
--     [4.3] por fecha sola          cost 0.29..1805.24   6,124 ms
--
-- Cincuenta veces más caro con el MISMO índice. En [4.2] el motor
-- salta directo al lugar donde empiezan las consultas de esa
-- matrícula. En [4.3] no tiene por dónde entrar, así que recorre
-- el índice ENTERO mirando la fecha de cada entrada.
--
-- Un índice (a, b) sirve para buscar por a, o por a y b, pero no
-- para buscar solo por b: es como el índice de un libro ordenado
-- por apellido y nombre. Buscar un nombre suelto se puede, pero
-- leyendo el índice de punta a punta.
--
-- (Si en tu base da Seq Scan en vez de Index Scan, también está
-- bien: son las dos formas caras de hacer lo mismo, y el motor
-- elige según cuántas filas estime.)


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
--
-- MEDIDO EL 29/10: Index Scan using idx_cons_caras
--   (cost=0.29..14.80 rows=12 width=42)
--   Index Cond: (fecha = '2024-06-15'::date)
--   Execution Time: 0.205 ms
--
-- Un índice que pesa una fracción del completo, resolviendo la
-- consulta en 0,2 ms.

explain analyze
select * from ix_consulta
where fecha = date '2024-06-15';
-- ESPERADO: NO usa idx_cons_caras — sin la condición del importe,
-- el motor no puede saber que ese índice alcanza.
--
-- MEDIDO EL 29/10: Index Scan using idx_cons_vet_fecha
--   (cost=0.29..1805.24 rows=92 width=42)
--   Index Cond: (fecha = '2024-06-15'::date)
--   Execution Time: 27.274 ms
--
-- Efectivamente lo ignoró. Y fijate QUÉ usó en su lugar: el
-- idx_cons_vet_fecha de [4.1], o sea el plan caro del bloque
-- [4.3], recorriendo el índice entero.
--
--     con la condición del importe   idx_cons_caras     0,205 ms
--     sin la condición del importe   idx_cons_vet_fecha  27,274 ms
--
-- Misma fecha, mismas filas, 130 veces más lento. El índice
-- parcial estaba ahí y habría servido: el motor no lo puede usar
-- porque no tiene cómo garantizar que las filas que busca estén
-- adentro del pedazo que ese índice cubre.
--
-- La moraleja del bloque: un índice parcial es barato, pero solo
-- aparece si la consulta repite su where. Si tus consultas no lo
-- repiten, es un índice que pagás y no usas.


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
--
-- MEDIDO EL 29/10: Hash Join (cost=597.00..7179.00 rows=200000)
--   Hash Cond: (c.id_mascota = m.id_mascota)
--   -> Seq Scan on ix_consulta c   (200000 filas)
--   -> Hash  (20000 filas)  Buckets: 32768  Memory Usage: 1194kB
--   Execution Time: 719.744 ms
--
-- Se ve el método completo: arma la tabla hash con ix_mascota
-- (1,2 MB en memoria) y después pasa ix_consulta por arriba.
-- Es lo correcto cuando el join devuelve TODO: 200.000 filas.


-- [6.2] Join filtrando fuerte de un lado.
explain analyze
select c.id_consulta, m.nombre
from ix_consulta c
join ix_mascota m on m.id_mascota = c.id_mascota
where c.diagnostico = 'Insuficiencia cardíaca';
-- ESPERADO: Hash Join otra vez, pero mucho más barato.
--
-- MEDIDO EL 29/10: Hash Join (cost=597.30..1059.28 rows=1040)
--   -> Index Scan using idx_cons_diag on ix_consulta c
--      Index Cond: (diagnostico = 'Insuficiencia cardíaca')
--   -> Hash -> Seq Scan on ix_mascota m  (20000 filas)
--   Execution Time: 9.368 ms
--
-- 719 ms -> 9 ms: el filtro redujo el lado izquierdo de 200.000
-- filas a 1.040, usando el índice de [2.2].
--
-- PERO el método de join NO cambió, y la razón es el punto del
-- bloque: para ir fila por fila a ix_mascota el motor necesitaría
-- un índice por id_mascota, y ix_mascota no tiene ninguno (las
-- tablas se crearon sin primary key a propósito). Sin ese índice,
-- buscar 1.040 veces en una tabla de 20.000 filas significaría
-- 1.040 recorridos completos. Le sigue conviniendo armar el hash
-- una sola vez.


-- [6.3] Démosle ese índice y comparemos.
create index idx_mas_id on ix_mascota (id_mascota);

explain analyze
select c.id_consulta, m.nombre
from ix_consulta c
join ix_mascota m on m.id_mascota = c.id_mascota
where c.diagnostico = 'Insuficiencia cardíaca';
-- ESPERADO: Nested Loop con Index Scan adentro, y bastante más
-- rápido que [6.2].
--
-- MEDIDO EL 29/10: Nested Loop (cost=0.58..999.98 rows=1040)
--   -> Index Scan using idx_cons_diag on ix_consulta c
--   -> Index Scan using idx_mas_id on ix_mascota m
--      Index Cond: (id_mascota = c.id_mascota)
--   Execution Time: 4.583 ms
--
-- ACÁ ESTÁ LO IMPORTANTE DE LA SECCIÓN 6: no tocamos la consulta,
-- es letra por letra la misma que [6.2]. Creamos un índice en la
-- OTRA tabla y el motor cambió de estrategia solo: dejó el hash y
-- pasó a buscar fila por fila, 9,368 ms -> 4,583 ms.
--
-- Un índice no acelera una consulta solamente haciendo más rápido
-- un paso: a veces le habilita al motor un plan entero que antes
-- no le convenía.


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
--
-- MEDIDO EL 29/10:
--     idx_cons_id            4408 kB
--     idx_cons_vet_fecha     1536 kB
--     idx_cons_diag          1368 kB
--     idx_mas_nombre          632 kB
--     idx_mas_nombre_lower    632 kB
--     idx_mas_id              456 kB
--     idx_cons_caras          256 kB
--                            -------
--                           ~9,1 MB
--
-- Dos cosas para mirar:
--   1) Los de ix_consulta solos suman 7,4 MB sobre una tabla de
--      ~25 MB: casi un 30% más de disco.
--   2) idx_cons_caras pesa 256 kB contra los 1536 kB de
--      idx_cons_vet_fecha, que indexa la MISMA columna fecha.
--      Seis veces menos, porque solo guarda las filas caras.
--      Es lo que prometía el bloque [5.1], ahora con el número.


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
--
-- MEDIDO EL 29/10: Insert on ix_consulta
--   Execution Time: 114.635 ms
--
-- SI SUPABASE NO TE MUESTRA EL PLAN: el bloque termina en
-- rollback, que no devuelve filas, y el editor muestra el
-- resultado de la ÚLTIMA sentencia. Si te pasa eso, corré el
-- explain solo, sin el begin ni el rollback, y después borra lo
-- insertado a mano:
--
--     delete from ix_consulta where id_consulta > 900000;


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
-- MEDIDO EL 29/10: Insert on ix_consulta
--   Execution Time: 39.255 ms
--
--     con los 4 índices    114,635 ms
--     sin índices           39,255 ms
--
-- Casi TRES VECES más lento por tener índices. Los mismos 20.000
-- insert, la misma tabla: la diferencia son los 75 ms que el
-- motor gastó en actualizar los cuatro índices, uno por fila.
--
-- Ésa es la contra, y es la única parte del tema donde un índice
-- JUEGA EN CONTRA: cada uno hay que mantenerlo en cada alta, baja
-- y modificación. Un índice que nadie usa no es neutro, es costo
-- puro: ocupa disco y hace más lenta cada escritura.


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
-- ESPERADO, Y ACÁ HAY UNA TRAMPA: los índices de ix_mascota van a
-- tener idx_scan > 0, pero los CUATRO de ix_consulta van a estar
-- en 0, aunque los usamos durante toda la clase.
--
-- No es un error: en [7.3] los borramos y en [7.4] los volvimos a
-- crear. Para PostgreSQL son índices nuevos, recién nacidos, y el
-- contador arranca de cero con cada uno.
--
-- Vale la pena mostrarlo: la estadística cuenta desde que existe
-- el índice, no desde que existe la tabla. En un sistema real, un
-- idx_scan en 0 significa "no se usó" solo si el índice lleva
-- tiempo ahi.
--
-- Para verlo moverse, volvé a correr [2.3] y después este bloque:
-- idx_cons_diag pasa a 1.

-- MEDIDO EL 29/10:
--     idx_cons_id             0     4408 kB
--     idx_cons_diag           0     1368 kB
--     idx_cons_vet_fecha      0     1536 kB
--     idx_cons_caras          0      256 kB
--     idx_mas_nombre          1      632 kB
--     idx_mas_nombre_lower    1      632 kB
--     idx_mas_id           1013      456 kB
--
-- Los cuatro ceros son los recién creados en [7.4]. Los otros
-- tres vienen contando desde [3.1], [3.3] y [6.3].
--
-- Y MIRÁ EL 1013, que es el mejor número del script: idx_mas_id
-- se usó MIL TRECE VECES en una sola consulta. Es el Nested Loop
-- de [6.3]: por cada una de las ~1.040 consultas que quedaron del
-- lado izquierdo, el motor fue al índice a buscar esa mascota.
-- Ahí se ve, contado, que "por cada fila de una tabla busca en la
-- otra" es literal.
--
-- Compará con idx_mas_nombre, que dice 1: una consulta, una
-- búsqueda. El contador no cuenta consultas, cuenta búsquedas.

-- [8.2] Los de ix_mascota, que no tocamos, conservan la cuenta.
-- Mirá idx_mas_nombre, idx_mas_nombre_lower e idx_mas_id: esos
-- vienen contando desde [3.1], [3.3] y [6.3].


-- ════════════════════════════════════════════════════════════
-- 9 · VOLVER A EMPEZAR, Y LIMPIEZA
-- ════════════════════════════════════════════════════════════

-- [9.1] REINICIAR LA DEMO sin regenerar los datos.
--
-- Hace falta porque los create index de arriba no dicen
-- "if not exists": si el índice ya está, dan error. Esto los
-- borra todos y deja las tablas intactas, así que podés volver
-- a correr el archivo desde [1.1] y da exactamente lo mismo.
--
-- Como además son índices nuevos, los contadores de [8.1]
-- arrancan otra vez de cero.

drop index if exists idx_cons_id;
drop index if exists idx_cons_diag;
drop index if exists idx_cons_vet_fecha;
drop index if exists idx_cons_caras;
drop index if exists idx_mas_nombre;
drop index if exists idx_mas_nombre_lower;
drop index if exists idx_mas_id;

-- Por las dudas, si alguna vez corriste el insert de [7.2] sin
-- el begin/rollback, esto saca las filas de prueba:
delete from ix_consulta where id_consulta > 900000;

analyze ix_consulta;
analyze ix_mascota;


-- [9.2] EMPEZAR DE CERO DE VERDAD: volvé a correr
-- 01_datos_demo.sql entero. Arranca borrando las dos tablas, así
-- que no hace falta borrarlas antes. Tarda unos segundos.


-- [9.3] LIMPIEZA al terminar la unidad. Las dos tablas ocupan
-- unos 25 MB más los índices.
-- drop table if exists ix_consulta;
-- drop table if exists ix_mascota;
