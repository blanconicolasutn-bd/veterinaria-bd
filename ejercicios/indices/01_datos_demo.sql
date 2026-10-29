-- ============================================================
-- Índices — la base de prueba (Unidad VII)
--
-- POR QUÉ HACE FALTA ESTO
-- La veterinaria tiene 10 mascotas y 16 consultas. Con tablas
-- así, PostgreSQL nunca va a usar un índice —y hace bien: leer
-- 16 filas de corrido  es más rápido que ir al índice y volver—.
-- O sea que una demo sobre la veterinaria mostraría justo lo
-- contrario de lo que queremos enseñar.
--
-- Por eso generamos dos tablas grandes del mismo dominio:
-- 20.000 mascotas y 200.000 consultas.
--
-- DOS DECISIONES QUE PARECEN ERRORES Y NO LO SON
--   1) Las tablas NO tienen primary key. Una PK crea su propio
--      índice, y entonces no habría forma de ver qué pasa SIN
--      índice. Los índices los vamos creando en clase.
--   2) Los datos están desbalanceados a propósito: el 85% de
--      las consultas tiene diagnóstico 'Sano'. Eso permite ver
--      que el motor usa o no usa el mismo índice según cuántas
--      filas devuelva la consulta.
--
-- CÓMO CORRERLO: este archivo entero, de una vez. Tarda unos
-- segundos. Es idempotente: se puede volver a correr.
--
-- Después usá 02_indices_en_vivo.sql, de a un bloque por vez.
-- Al final de este archivo está el bloque para borrar todo.
-- ============================================================

drop table if exists ix_consulta;
drop table if exists ix_mascota;


-- ------------------------------------------------------------
-- IX_MASCOTA — 20.000 filas
--
-- El nombre se guarda con mayúsculas y minúsculas mezcladas a
-- propósito: así tiene sentido el índice por expresión sobre
-- lower(nombre).
-- ------------------------------------------------------------
create table ix_mascota (
  id_mascota int,
  nombre     varchar(40),
  especie    varchar(20),
  peso_kg    numeric(5,2)
);

-- Ojo con un detalle: cada llamada a random() devuelve un valor
-- distinto. Encadenarlas en un case haría que las proporciones no
-- sean las que uno escribe, así que se saca UN valor por fila en
-- la subconsulta y el case compara siempre contra ése.
insert into ix_mascota (id_mascota, nombre, especie, peso_kg)
select
  g,
  case when r_may < 0.5 then upper(nom) else nom end || ' ' || g,
  case
    when r_esp < 0.60 then 'Perro'
    when r_esp < 0.85 then 'Gato'
    when r_esp < 0.95 then 'Ave'
    else                   'Conejo'
  end,
  round((r_peso * 45 + 0.5)::numeric, 2)
from (
  select g,
         random() as r_may,
         random() as r_esp,
         random() as r_peso,
         (array['Rocky','Michi','Luna','Toby','Nina',
                'Pipo','Coco','Bruno'])[(random()*7)::int + 1] as nom
  from generate_series(1, 20000) g
) t;


-- ------------------------------------------------------------
-- IX_CONSULTA — 200.000 filas
--
-- diagnostico está desbalanceado: 'Sano' se lleva el 85%, y
-- 'Insuficiencia cardíaca' aparece en menos del 1%. Son los dos
-- extremos que necesitamos para la demo de selectividad.
-- ------------------------------------------------------------
create table ix_consulta (
  id_consulta int,
  id_mascota  int,
  matricula   int,
  fecha       date,
  motivo      varchar(60),
  diagnostico varchar(40),
  importe     numeric(10,2)
);

insert into ix_consulta
  (id_consulta, id_mascota, matricula, fecha, motivo, diagnostico, importe)
select
  g,
  (r_mas * 19999)::int + 1,
  1001 + (r_vet * 3)::int,
  date '2020-01-01' + (r_fec * 2200)::int,
  (array['Control anual','Vacunación','Herida en pata','Picazón',
         'Chequeo general','Cojera','Vómitos','Control post-operatorio'
         ])[(r_mot * 7)::int + 1],
  case
    when r_dia < 0.850 then 'Sano'
    when r_dia < 0.900 then 'Dermatitis leve'
    when r_dia < 0.940 then 'Esguince leve'
    when r_dia < 0.970 then 'Gastritis'
    when r_dia < 0.995 then 'Sutura realizada'
    else                    'Insuficiencia cardíaca'
  end,
  round((r_imp * 50000 + 2000)::numeric, 2)
from (
  select g,
         random() as r_mas, random() as r_vet, random() as r_fec,
         random() as r_mot, random() as r_dia, random() as r_imp
  from generate_series(1, 200000) g
) t;


-- ------------------------------------------------------------
-- ANALYZE — recolecta las estadísticas
--
-- Sin esto el motor no sabe cómo están distribuidos los datos y
-- puede elegir planes malos. Es el comando del final de la
-- unidad, puesto en práctica desde el minuto cero.
-- ------------------------------------------------------------
analyze ix_mascota;
analyze ix_consulta;


-- ------------------------------------------------------------
-- CONTROL — tiene que devolver una fila con estos valores
-- ------------------------------------------------------------
select
  (select count(*) from ix_mascota)   as mascotas,      -- 20000
  (select count(*) from ix_consulta)  as consultas,     -- 200000
  (select count(*) from ix_consulta
    where diagnostico = 'Sano')       as sanas,         -- ~170000
  (select count(*) from ix_consulta
    where diagnostico = 'Insuficiencia cardíaca')
                                      as cardiacas,     -- ~1000
  (select count(*) from pg_indexes
    where tablename in ('ix_mascota','ix_consulta'))
                                      as indices;       -- 0

-- CORRIDO EN SUPABASE EL 2026-10-29:
--   20000 | 200000 | 169974 | 1011 | 0
-- O sea 85,0% de 'Sano' y 0,51% de 'Insuficiencia cardíaca',
-- que es exactamente el desbalance que necesita la demo de
-- selectividad del bloque 2 de 02_indices_en_vivo.sql.
-- Los números de sanas y cardiacas varían un poco en cada
-- corrida: son aleatorios.


-- ============================================================
-- Si algo sale mal, o al terminar la unidad: borrar todo
-- ============================================================
-- drop table if exists ix_consulta;
-- drop table if exists ix_mascota;
