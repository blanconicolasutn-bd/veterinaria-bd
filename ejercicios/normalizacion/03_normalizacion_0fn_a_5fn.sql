-- ============================================================
-- Normalización paso a paso — de 0FN a 5FN (Unidad V)
--
-- Todo con el mismo ejemplo: la veterinaria.
--
-- REGLA DE NOMBRES: el prefijo dice en qué forma normal ESTÁ
-- la tabla. Contando prefijos sabés cuántas tablas hay en cada
-- etapa, y una descomposición siempre va de un prefijo al
-- siguiente.
--
--   fn0_   0FN   1 tabla    la planilla cruda
--   fn1_   1FN   1 tabla    sin listas en las celdas
--   fn2_   2FN   2 tablas   sin dependencias parciales
--   fn3_   3FN   7 tablas   sin dependencias transitivas
--   fn3b_  BCNF  3 tablas   (3b = "3 y medio": BCNF es 3FN estricta)
--   fn4_   4FN   3 tablas   sin dependencias multivaluadas
--   fn5_   5FN   3 tablas   sin dependencias de join
--   fn6_   DKNF  1 tabla    restricción movida al dominio
--
-- Las descomposiciones, leídas por los nombres:
--   fn0_planilla   →  fn1_planilla                      (1 → 1)
--   fn1_planilla   →  fn2_consulta + fn2_receta         (1 → 2)
--   fn2_consulta   →  fn3_dueno, fn3_mascota,
--                     fn3_veterinario, fn3_consulta      (1 → 4)
--   fn3_atencion   →  fn3b_veterinario + fn3b_atencion  (1 → 2)
--   fn3b_agenda    →  fn4_vet_especialidad + fn4_vet_dia (1 → 2)
--   fn4_receta_lab →  fn5_receta + fn5_trabaja_con
--                     + fn5_fabrica                      (1 → 3)
--
-- Corré este script entero en el SQL Editor de Supabase.
-- Es idempotente. Después usá 04_normalizacion_consultas_clase.sql
-- ============================================================

drop table if exists fn6_turno            cascade;
drop domain if exists estado_turno        cascade;
drop table if exists fn5_turno            cascade;
drop table if exists fn5_fabrica          cascade;
drop table if exists fn5_trabaja_con      cascade;
drop table if exists fn5_receta           cascade;
drop table if exists fn4_receta_lab       cascade;
drop table if exists fn4_vet_dia          cascade;
drop table if exists fn4_vet_especialidad cascade;
drop table if exists fn3b_agenda          cascade;
drop table if exists fn3b_atencion        cascade;
drop table if exists fn3b_veterinario     cascade;
drop table if exists fn3_atencion         cascade;
drop table if exists fn3_receta           cascade;
drop table if exists fn3_consulta         cascade;
drop table if exists fn3_mascota          cascade;
drop table if exists fn3_medicamento      cascade;
drop table if exists fn3_veterinario      cascade;
drop table if exists fn3_dueno            cascade;
drop table if exists fn2_receta           cascade;
drop table if exists fn2_consulta         cascade;
drop table if exists fn1_planilla         cascade;
drop table if exists fn0_planilla         cascade;

-- nombres viejos, por si alguien corrió una versión anterior
drop table if exists n0_planilla          cascade;
drop table if exists n1_planilla          cascade;
drop table if exists n2_consulta          cascade;
drop table if exists n2_receta            cascade;
drop table if exists n3_dueno             cascade;
drop table if exists n3_mascota           cascade;
drop table if exists n3_veterinario       cascade;
drop table if exists n3_medicamento       cascade;
drop table if exists n3_consulta          cascade;
drop table if exists n3_receta            cascade;
drop table if exists bcnf_atencion_3fn    cascade;
drop table if exists bcnf_veterinario     cascade;
drop table if exists bcnf_atencion        cascade;
drop table if exists n4_agenda            cascade;
drop table if exists n4_vet_especialidad  cascade;
drop table if exists n4_vet_dia           cascade;
drop table if exists n5_receta_lab        cascade;
drop table if exists n5_receta            cascade;
drop table if exists n5_trabaja_con       cascade;
drop table if exists n5_fabrica           cascade;


-- ############################################################
-- 0FN  —  1 TABLA
-- La planilla, como la llevaría la veterinaria en Excel.
-- Sin clave primaria, y con una lista adentro de una celda.
-- ############################################################
create table fn0_planilla (
  consulta      int,
  fecha         date,
  mascota       varchar(40),
  dueno         varchar(60),
  telefono      varchar(30),
  matricula     int,
  veterinario   varchar(60),
  especialidad  varchar(60),
  medicamentos  varchar(200)   -- ← la lista: acá está el problema
);

insert into fn0_planilla values
  ( 4, '2023-05-20', 'Toby',  'Pérez',     '1145552222', 1003, 'Díaz',    'Dermatología',
    'Prednisolona 5mg cada 12hs, Cefalexina 250mg cada 8hs'),
  ( 5, '2023-11-02', 'Toby',  'Pérez',     '1145552222', 1003, 'Díaz',    'Dermatología',
    'Prednisolona 2.5mg cada 24hs'),
  ( 7, '2023-07-01', 'Rocky', 'Fernández', '1145553333', 1002, 'Torres',  'Cirugía',
    'Amoxicilina 500mg cada 12hs, Meloxicam 0.1mg/kg cada 24hs'),
  (14, '2024-02-20', 'Rocky', 'Gómez',     '1145551111', 1001, 'Ramírez', 'Clínica general',
    'Ranitidina 2mg/kg cada 12hs');


-- ############################################################
-- 1FN  —  1 TABLA     (fn0_planilla → fn1_planilla)
-- Se deshace la lista: una fila por medicamento recetado.
-- Recién ahora hay clave primaria, y queda compuesta.
-- Ojo: la redundancia AUMENTA. 1FN ordena, no limpia.
-- ############################################################
create table fn1_planilla (
  consulta      int,
  medicamento   varchar(40),
  dosis         varchar(40),
  fecha         date,
  mascota       varchar(40),
  dueno         varchar(60),
  telefono      varchar(30),
  matricula     int,
  veterinario   varchar(60),
  especialidad  varchar(60),
  primary key (consulta, medicamento)
);

insert into fn1_planilla values
  ( 4, 'Prednisolona', '5mg cada 12hs',     '2023-05-20', 'Toby',  'Pérez',     '1145552222', 1003, 'Díaz',    'Dermatología'),
  ( 4, 'Cefalexina',   '250mg cada 8hs',    '2023-05-20', 'Toby',  'Pérez',     '1145552222', 1003, 'Díaz',    'Dermatología'),
  ( 5, 'Prednisolona', '2.5mg cada 24hs',   '2023-11-02', 'Toby',  'Pérez',     '1145552222', 1003, 'Díaz',    'Dermatología'),
  ( 7, 'Amoxicilina',  '500mg cada 12hs',   '2023-07-01', 'Rocky', 'Fernández', '1145553333', 1002, 'Torres',  'Cirugía'),
  ( 7, 'Meloxicam',    '0.1mg/kg cada 24hs','2023-07-01', 'Rocky', 'Fernández', '1145553333', 1002, 'Torres',  'Cirugía'),
  (14, 'Ranitidina',   '2mg/kg cada 12hs',  '2024-02-20', 'Rocky', 'Gómez',     '1145551111', 1001, 'Ramírez', 'Clínica general');


-- ############################################################
-- 2FN  —  2 TABLAS    (fn1_planilla → fn2_consulta + fn2_receta)
-- Lo que depende solo de "consulta" se va a su tabla.
-- La dosis necesita las dos columnas: se queda en el cruce.
-- ############################################################
create table fn2_consulta (
  consulta      int primary key,
  fecha         date,
  mascota       varchar(40),
  dueno         varchar(60),
  telefono      varchar(30),
  matricula     int,
  veterinario   varchar(60),
  especialidad  varchar(60)
);

insert into fn2_consulta values
  ( 4, '2023-05-20', 'Toby',  'Pérez',     '1145552222', 1003, 'Díaz',    'Dermatología'),
  ( 5, '2023-11-02', 'Toby',  'Pérez',     '1145552222', 1003, 'Díaz',    'Dermatología'),
  ( 7, '2023-07-01', 'Rocky', 'Fernández', '1145553333', 1002, 'Torres',  'Cirugía'),
  (14, '2024-02-20', 'Rocky', 'Gómez',     '1145551111', 1001, 'Ramírez', 'Clínica general');

create table fn2_receta (
  consulta     int references fn2_consulta(consulta),
  medicamento  varchar(40),
  dosis        varchar(40),
  primary key (consulta, medicamento)
);

insert into fn2_receta values
  ( 4, 'Prednisolona', '5mg cada 12hs'),
  ( 4, 'Cefalexina',   '250mg cada 8hs'),
  ( 5, 'Prednisolona', '2.5mg cada 24hs'),
  ( 7, 'Amoxicilina',  '500mg cada 12hs'),
  ( 7, 'Meloxicam',    '0.1mg/kg cada 24hs'),
  (14, 'Ranitidina',   '2mg/kg cada 12hs');


-- ############################################################
-- 3FN  —  7 TABLAS
-- fn2_consulta se parte en 4: DUENO, MASCOTA, VETERINARIO y
-- CONSULTA. fn2_receta se renombra y suma MEDICAMENTO.
--
-- Las cadenas transitivas que había:
--   consulta → matricula → veterinario, especialidad
--   consulta → mascota   → dueno → telefono
--
-- Hay dos Rocky de dueños distintos: el nombre no sirve como
-- clave, hacen falta id_mascota e id_dueno.
-- ############################################################
create table fn3_dueno (
  id_dueno  int primary key,
  apellido  varchar(60) not null,
  telefono  varchar(30)
);
insert into fn3_dueno values
  (1, 'Pérez',     '1145552222'),
  (2, 'Fernández', '1145553333'),
  (3, 'Gómez',     '1145551111');

create table fn3_mascota (
  id_mascota  int primary key,
  nombre      varchar(40) not null,
  id_dueno    int not null references fn3_dueno(id_dueno)
);
insert into fn3_mascota values
  (1, 'Toby',  1),
  (2, 'Rocky', 2),   -- el Rocky de Fernández
  (3, 'Rocky', 3);   -- el otro Rocky, de Gómez

create table fn3_veterinario (
  matricula     int primary key,   -- clave que ya venía dada
  apellido      varchar(60) not null,
  especialidad  varchar(60)
);
insert into fn3_veterinario values
  (1001, 'Ramírez', 'Clínica general'),
  (1002, 'Torres',  'Cirugía'),
  (1003, 'Díaz',    'Dermatología');

create table fn3_medicamento (
  id_medicamento  int primary key,
  nombre          varchar(40) not null
);
insert into fn3_medicamento values
  (1, 'Prednisolona'),
  (2, 'Cefalexina'),
  (3, 'Amoxicilina'),
  (4, 'Meloxicam'),
  (5, 'Ranitidina');

create table fn3_consulta (
  id_consulta  int primary key,
  fecha        date not null,
  id_mascota   int not null references fn3_mascota(id_mascota),
  matricula    int not null references fn3_veterinario(matricula)
);
insert into fn3_consulta values
  ( 4, '2023-05-20', 1, 1003),
  ( 5, '2023-11-02', 1, 1003),
  ( 7, '2023-07-01', 2, 1002),
  (14, '2024-02-20', 3, 1001);

create table fn3_receta (
  id_consulta     int references fn3_consulta(id_consulta),
  id_medicamento  int references fn3_medicamento(id_medicamento),
  dosis           varchar(40) not null,
  primary key (id_consulta, id_medicamento)
);
insert into fn3_receta values
  ( 4, 1, '5mg cada 12hs'),
  ( 4, 2, '250mg cada 8hs'),
  ( 5, 1, '2.5mg cada 24hs'),
  ( 7, 3, '500mg cada 12hs'),
  ( 7, 4, '0.1mg/kg cada 24hs'),
  (14, 5, '2mg/kg cada 12hs');

-- ------------------------------------------------------------
-- La veterinaria crece (regla 1): "para cada especialidad, una
-- mascota es atendida siempre por el mismo veterinario", y cada
-- veterinario tiene una sola especialidad.
--
-- Esta tabla ESTÁ EN 3FN (todas sus columnas son parte de alguna
-- clave candidata, así que no hay ninguna columna no clave), y
-- por eso lleva prefijo fn3_. Igual está mal: viola BCNF.
-- ------------------------------------------------------------
create table fn3_atencion (
  mascota       varchar(40),
  especialidad  varchar(60),
  veterinario   varchar(60) not null,
  primary key (mascota, especialidad)
);
insert into fn3_atencion values
  ('Toby',  'Dermatología',    'Díaz'),
  ('Toby',  'Clínica general', 'Ramírez'),
  ('Rocky', 'Dermatología',    'Díaz'),
  ('Rocky', 'Cirugía',         'Torres'),
  ('Luna',  'Clínica general', 'Ramírez');


-- ############################################################
-- BCNF  —  3 TABLAS   (fn3_atencion → fn3b_veterinario + fn3b_atencion)
-- El determinante que no era clave candidata (veterinario) se
-- va a una tabla propia, con lo que determina.
-- ############################################################
create table fn3b_veterinario (
  veterinario   varchar(60) primary key,
  especialidad  varchar(60) not null
);
insert into fn3b_veterinario values
  ('Díaz',    'Dermatología'),
  ('Ramírez', 'Clínica general'),
  ('Torres',  'Cirugía');

create table fn3b_atencion (
  mascota      varchar(40),
  veterinario  varchar(60) references fn3b_veterinario(veterinario),
  primary key (mascota, veterinario)
);
insert into fn3b_atencion values
  ('Toby',  'Díaz'),
  ('Toby',  'Ramírez'),
  ('Rocky', 'Díaz'),
  ('Rocky', 'Torres'),
  ('Luna',  'Ramírez');

-- ------------------------------------------------------------
-- La veterinaria crece (regla 2): de cada veterinario
-- registramos sus especialidades y los días que atiende.
--
-- Esta tabla ESTÁ EN BCNF (las tres columnas son la clave, no
-- hay ninguna dependencia funcional no trivial), y por eso
-- lleva prefijo fn3b_. Igual está mal: viola 4FN.
-- ------------------------------------------------------------
create table fn3b_agenda (
  matricula     int,
  especialidad  varchar(60),
  dia           varchar(15),
  primary key (matricula, especialidad, dia)
);
insert into fn3b_agenda values
  (1001, 'Clínica general', 'Lunes'),
  (1001, 'Clínica general', 'Miércoles'),
  (1001, 'Ecografía',       'Lunes'),
  (1001, 'Ecografía',       'Miércoles'),
  (1002, 'Cirugía',         'Martes');


-- ############################################################
-- 4FN  —  3 TABLAS   (fn3b_agenda → fn4_vet_especialidad + fn4_vet_dia)
-- Un hecho independiente por tabla.
-- ############################################################
create table fn4_vet_especialidad (
  matricula     int,
  especialidad  varchar(60),
  primary key (matricula, especialidad)
);
insert into fn4_vet_especialidad values
  (1001, 'Clínica general'),
  (1001, 'Ecografía'),
  (1002, 'Cirugía');

create table fn4_vet_dia (
  matricula  int,
  dia        varchar(15),
  primary key (matricula, dia)
);
insert into fn4_vet_dia values
  (1001, 'Lunes'),
  (1001, 'Miércoles'),
  (1002, 'Martes');

-- ------------------------------------------------------------
-- La veterinaria crece (regla 3): si un veterinario receta una
-- droga, y un laboratorio la fabrica, y el veterinario trabaja
-- con ese laboratorio, entonces receta esa droga de ese
-- laboratorio.
--
-- Esta tabla ESTÁ EN 4FN (no hay multivaluadas independientes:
-- las tres columnas están ligadas por la regla), y por eso
-- lleva prefijo fn4_. Igual está mal: viola 5FN.
--
-- Fijate que falta "Díaz / Amoxicilina / Brouwer": Brouwer no
-- fabrica amoxicilina. Esa ausencia es la pista.
-- ------------------------------------------------------------
create table fn4_receta_lab (
  veterinario  varchar(60),
  droga        varchar(40),
  laboratorio  varchar(40),
  primary key (veterinario, droga, laboratorio)
);
insert into fn4_receta_lab values
  ('Díaz',   'Meloxicam',   'Holliday'),
  ('Díaz',   'Meloxicam',   'Brouwer'),
  ('Díaz',   'Amoxicilina', 'Holliday'),
  ('Torres', 'Meloxicam',   'Holliday');


-- ############################################################
-- 5FN  —  3 TABLAS
-- (fn4_receta_lab → fn5_receta + fn5_trabaja_con + fn5_fabrica)
-- Un hecho suelto por tabla. Hacen falta las TRES: uniendo solo
-- dos aparece una fila que no existe.
-- ############################################################
create table fn5_receta (
  veterinario  varchar(60),
  droga        varchar(40),
  primary key (veterinario, droga)
);
insert into fn5_receta values
  ('Díaz',   'Meloxicam'),
  ('Díaz',   'Amoxicilina'),
  ('Torres', 'Meloxicam');

create table fn5_trabaja_con (
  veterinario  varchar(60),
  laboratorio  varchar(40),
  primary key (veterinario, laboratorio)
);
insert into fn5_trabaja_con values
  ('Díaz',   'Holliday'),
  ('Díaz',   'Brouwer'),
  ('Torres', 'Holliday');

create table fn5_fabrica (
  laboratorio  varchar(40),
  droga        varchar(40),
  primary key (laboratorio, droga)
);
insert into fn5_fabrica values
  ('Holliday', 'Meloxicam'),
  ('Holliday', 'Amoxicilina'),
  ('Brouwer',  'Meloxicam');


-- ############################################################
-- 6FN / DKNF  —  2 TABLAS
--
-- DKNF no tiene procedimiento: no se puede "normalizar a DKNF".
-- Lo que sí se puede mostrar es la diferencia entre una
-- restricción que vive AFUERA (un CHECK suelto) y una que vive
-- EN EL DOMINIO, que es lo que la definición pide.
--
-- PostgreSQL tiene CREATE DOMAIN justamente para eso.
-- ############################################################

-- fn5_turno: está en 5FN, pero NO en DKNF. La regla "el estado
-- solo puede ser programado, atendido o cancelado" no se deduce
-- ni del dominio (es un varchar cualquiera) ni de la clave:
-- hay que escribirla aparte, en un CHECK.
create table fn5_turno (
  id_turno  int primary key,
  estado    varchar(20) not null,
  constraint ck_estado check (estado in ('programado', 'atendido', 'cancelado'))
);

insert into fn5_turno values
  (1, 'programado'),
  (2, 'atendido'),
  (3, 'cancelado');

-- fn6_turno: la misma regla, pero movida al dominio. Ahora la
-- restricción SÍ se deduce de la definición del tipo, y la tabla
-- no necesita ningún CHECK propio: está en DKNF.
create domain estado_turno as varchar(20)
  check (value in ('programado', 'atendido', 'cancelado'));

create table fn6_turno (
  id_turno  int primary key,
  estado    estado_turno not null
);

insert into fn6_turno values
  (1, 'programado'),
  (2, 'atendido'),
  (3, 'cancelado');

-- El límite, y por eso casi ninguna tabla real está en DKNF:
-- una restricción que relaciona DOS columnas no se puede meter
-- en ningún dominio, porque un dominio mira un valor por vez.
--   check (fecha_devolucion >= fecha_retiro)
-- Eso siempre va a ser un CHECK de tabla, y alcanza para que la
-- tabla quede fuera de DKNF.


-- ============================================================
-- Listo: 22 tablas. El prefijo de cada una dice en qué forma
-- normal está.
--
-- Nota sobre Supabase: estas tablas quedan sin RLS. Desde el
-- SQL Editor se consultan sin problema; el panel va a mostrar
-- un aviso de "RLS disabled", que para una base de práctica
-- no importa.
-- ============================================================
select etapa, tablas from (values
  ('0FN ', 1), ('1FN ', 1), ('2FN ', 2), ('3FN ', 7),
  ('BCNF', 3), ('4FN ', 3), ('5FN ', 4), ('DKNF', 1)
) as t(etapa, tablas) order by etapa;
