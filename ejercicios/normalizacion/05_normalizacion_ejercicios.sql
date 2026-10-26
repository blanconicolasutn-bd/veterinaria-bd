-- ============================================================
-- Normalización — tablas de los ejercicios (Unidad V)
--
-- Parte A: los tres ejercicios que se hacen en clase.
--          Va SOLO el enunciado: la descomposición la arman
--          ustedes con sus propios CREATE TABLE.
--
-- Parte B: los cuatro ejercicios de la casa, con enunciado Y
--          solución, para que cada uno verifique lo que hizo.
--
-- Prefijos:  ej_   ejercicios en vivo
--            ex1_  inscripciones      ex2_  corralón
--            ex3_  club               ex4_  turnos
--
-- Corré este script entero en el SQL Editor de Supabase.
-- Es idempotente. Después usá 06_normalizacion_ejercicios_consultas.sql
-- ============================================================

drop table if exists ex4_turno            cascade;
drop table if exists ex4_medico           cascade;
drop table if exists ex4_paciente         cascade;
drop table if exists ex4_planilla         cascade;
drop table if exists ex3_socio_actividad  cascade;
drop table if exists ex3_socio            cascade;
drop table if exists ex3_categoria        cascade;
drop table if exists ex3_planilla         cascade;
drop table if exists ex2_detalle          cascade;
drop table if exists ex2_producto         cascade;
drop table if exists ex2_factura          cascade;
drop table if exists ex2_cliente          cascade;
drop table if exists ex2_planilla         cascade;
drop table if exists ex1_inscripcion      cascade;
drop table if exists ex1_materia          cascade;
drop table if exists ex1_profesor         cascade;
drop table if exists ex1_alumno           cascade;
drop table if exists ex1_planilla         cascade;
drop table if exists ej_vet_servicio       cascade;
drop table if exists ej_dueno_contacto     cascade;
drop table if exists ej_consultorio        cascade;


-- ############################################################
-- PARTE A — LOS TRES EJERCICIOS EN VIVO (solo enunciado)
-- Los tres son de la veterinaria, igual que los ejemplos de la
-- clase: lo único que cambia es qué parte del negocio miran.
-- ############################################################

-- ------------------------------------------------------------
-- BCNF — los consultorios
-- Cada veterinario atiende siempre en el mismo consultorio.
-- En una franja horaria, un consultorio tiene un solo veterinario.
-- Se pide: dependencias funcionales, claves candidatas,
--          ¿está en 3FN? ¿y en BCNF? Si no, descomponerla.
-- ------------------------------------------------------------
create table ej_consultorio (
  consultorio  varchar(10),
  franja       varchar(20),
  veterinario  varchar(40),
  primary key (consultorio, franja)
);

insert into ej_consultorio values
  ('C1', 'Lunes 09-13',     'Díaz'),
  ('C1', 'Miércoles 09-13', 'Díaz'),
  ('C2', 'Lunes 09-13',     'Ramírez'),
  ('C2', 'Martes 09-13',    'Torres');


-- ------------------------------------------------------------
-- 4FN — los contactos del dueño
-- Un dueño puede tener varios teléfonos y varias mascotas, y
-- ningún teléfono está atado a ninguna mascota en particular.
-- Se pide: las dos dependencias multivaluadas, por qué está en
--          BCNF pero no en 4FN, y la descomposición.
-- ------------------------------------------------------------
create table ej_dueno_contacto (
  id_dueno   int,
  telefono   varchar(20),
  mascota    varchar(40),
  primary key (id_dueno, telefono, mascota)
);

insert into ej_dueno_contacto values
  (1, '1145551111', 'Toby'),
  (1, '1145551111', 'Mía'),
  (1, '1166662222', 'Toby'),
  (1, '1166662222', 'Mía'),
  (2, '1145553333', 'Rocky');


-- ------------------------------------------------------------
-- 5FN — veterinario, especie y servicio
-- Regla: si el veterinario atiende esa especie, y el servicio se
-- presta para esa especie, y el veterinario presta ese servicio,
-- entonces presta ese servicio para esa especie.
-- Se pide: (a) ¿está en 4FN?  (b) ¿por qué con dos proyecciones
--          no alcanza?  (c) escribir las tres y unirlas.
-- ------------------------------------------------------------
create table ej_vet_servicio (
  veterinario  varchar(40),
  especie      varchar(20),
  servicio     varchar(30),
  primary key (veterinario, especie, servicio)
);

insert into ej_vet_servicio values
  ('Díaz',   'Perro', 'Vacunación'),
  ('Díaz',   'Perro', 'Ecografía'),
  ('Díaz',   'Gato',  'Vacunación'),
  ('Torres', 'Perro', 'Vacunación');
-- Falta "Díaz / Gato / Ecografía": la ecografía solo se presta
-- para perros. Esa ausencia es la pista.


-- ############################################################
-- PARTE B — LOS CUATRO DE LA CASA (enunciado + solución)
-- ############################################################

-- ============================================================
-- EJERCICIO 1 — INSCRIPCIONES
-- PK: (legajo, cod_materia). Cada materia tiene un único profesor.
-- ============================================================
create table ex1_planilla (
  legajo       int,
  alumno       varchar(40),
  carrera      varchar(40),
  cod_materia  varchar(8),
  materia      varchar(60),
  profesor     varchar(40),
  oficina      varchar(10),
  nota         int,
  primary key (legajo, cod_materia)
);

insert into ex1_planilla values
  (24815, 'Gómez', 'Sistemas',   'BD', 'Bases de Datos', 'Méndez', '204', 8),
  (24815, 'Gómez', 'Sistemas',   'AL', 'Álgebra',        'Sosa',   '110', 6),
  (24816, 'Paz',   'Industrial', 'BD', 'Bases de Datos', 'Méndez', '204', 9),
  (24817, 'Ruiz',  'Sistemas',   'AL', 'Álgebra',        'Sosa',   '110', 7);

-- --- solución en 3FN ---
create table ex1_alumno (
  legajo   int primary key,
  alumno   varchar(40) not null,
  carrera  varchar(40)
);
insert into ex1_alumno values
  (24815, 'Gómez', 'Sistemas'),
  (24816, 'Paz',   'Industrial'),
  (24817, 'Ruiz',  'Sistemas');

create table ex1_profesor (
  id_profesor  int primary key,
  nombre       varchar(40) not null,
  oficina      varchar(10)
);
insert into ex1_profesor values
  (1, 'Méndez', '204'),
  (2, 'Sosa',   '110');

create table ex1_materia (
  cod_materia  varchar(8) primary key,
  materia      varchar(60) not null,
  id_profesor  int not null references ex1_profesor(id_profesor)
);
insert into ex1_materia values
  ('BD', 'Bases de Datos', 1),
  ('AL', 'Álgebra',        2);

create table ex1_inscripcion (
  legajo       int references ex1_alumno(legajo),
  cod_materia  varchar(8) references ex1_materia(cod_materia),
  nota         int,
  primary key (legajo, cod_materia)
);
insert into ex1_inscripcion values
  (24815, 'BD', 8),
  (24815, 'AL', 6),
  (24816, 'BD', 9),
  (24817, 'AL', 7);


-- ============================================================
-- EJERCICIO 2 — EL CORRALÓN
-- Columnas numeradas: producto_1 / producto_2 son un grupo repetido.
-- El precio es de lista: no cambia de una factura a otra.
-- ============================================================
create table ex2_planilla (
  nro_factura  varchar(10) primary key,
  fecha        date,
  cuit         varchar(15),
  cliente      varchar(40),
  domicilio    varchar(60),
  producto_1   varchar(30),
  precio_1     numeric(10,2),
  cant_1       int,
  producto_2   varchar(30),
  precio_2     numeric(10,2),
  cant_2       int
);

insert into ex2_planilla values
  ('A-0001', '2026-10-01', '20-30111222-3', 'Pérez Hnos.',  'Colón 1200',  'Cemento',  9500,   10, 'Arena',    32000,    2),
  ('A-0002', '2026-10-01', '27-28444555-1', 'López, Marta', 'Vélez 450',   'Cal',      6200,    5,  null,       null, null),
  ('A-0003', '2026-10-02', '20-30111222-3', 'Pérez Hnos.',  'Colón 1200',  'Arena',   32000,    1, 'Cemento',   9500,    4),
  ('A-0004', '2026-10-02', '30-71555666-9', 'Constr. Sur',  'San Juan 88', 'Hierro 8',14800,   20, 'Cemento',   9500,   15),
  ('A-0005', '2026-10-03', '27-28444555-1', 'López, Marta', 'Vélez 450',   'Ladrillo',  450,  500, 'Cal',       6200,    2),
  ('A-0006', '2026-10-03', '20-33777888-4', 'Ríos, Pablo',  'Duarte 310',  'Arena',   32000,    3,  null,       null, null),
  ('A-0007', '2026-10-04', '30-71555666-9', 'Constr. Sur',  'San Juan 88', 'Hierro 8',14800,   10, 'Ladrillo',   450, 1200);

-- --- solución en 3FN ---
create table ex2_cliente (
  cuit       varchar(15) primary key,
  cliente    varchar(40) not null,
  domicilio  varchar(60)
);
insert into ex2_cliente values
  ('20-30111222-3', 'Pérez Hnos.',  'Colón 1200'),
  ('27-28444555-1', 'López, Marta', 'Vélez 450'),
  ('30-71555666-9', 'Constr. Sur',  'San Juan 88'),
  ('20-33777888-4', 'Ríos, Pablo',  'Duarte 310');

create table ex2_factura (
  nro_factura  varchar(10) primary key,
  fecha        date not null,
  cuit         varchar(15) not null references ex2_cliente(cuit)
);
insert into ex2_factura values
  ('A-0001', '2026-10-01', '20-30111222-3'),
  ('A-0002', '2026-10-01', '27-28444555-1'),
  ('A-0003', '2026-10-02', '20-30111222-3'),
  ('A-0004', '2026-10-02', '30-71555666-9'),
  ('A-0005', '2026-10-03', '27-28444555-1'),
  ('A-0006', '2026-10-03', '20-33777888-4'),
  ('A-0007', '2026-10-04', '30-71555666-9');

create table ex2_producto (
  producto  varchar(30) primary key,
  precio    numeric(10,2) not null
);
insert into ex2_producto values
  ('Cemento',   9500),
  ('Arena',    32000),
  ('Cal',       6200),
  ('Hierro 8', 14800),
  ('Ladrillo',   450);

create table ex2_detalle (
  nro_factura  varchar(10) references ex2_factura(nro_factura),
  producto     varchar(30) references ex2_producto(producto),
  cantidad     int not null,
  primary key (nro_factura, producto)
);
insert into ex2_detalle values
  ('A-0001', 'Cemento',   10),
  ('A-0001', 'Arena',      2),
  ('A-0002', 'Cal',        5),
  ('A-0003', 'Arena',      1),
  ('A-0003', 'Cemento',    4),
  ('A-0004', 'Hierro 8',  20),
  ('A-0004', 'Cemento',   15),
  ('A-0005', 'Ladrillo', 500),
  ('A-0005', 'Cal',        2),
  ('A-0006', 'Arena',      3),
  ('A-0007', 'Hierro 8',  10),
  ('A-0007', 'Ladrillo', 1200);


-- ============================================================
-- EJERCICIO 3 — EL CLUB
-- Lista de actividades en una celda. La cuota depende de la categoría.
-- ============================================================
create table ex3_planilla (
  nro_socio    int primary key,
  socio        varchar(40),
  barrio       varchar(30),
  categoria    varchar(20),
  cuota        numeric(10,2),
  actividades  varchar(100)
);

insert into ex3_planilla values
  (101, 'Gómez, Ana',   'Centro',  'Mayor',     25000, 'Natación, Fútbol'),
  (102, 'Paz, Luis',    'Alberdi', 'Menor',     15000, 'Fútbol'),
  (103, 'Ruiz, Sol',    'Centro',  'Mayor',     25000, 'Natación, Vóley, Fútbol'),
  (104, 'Díaz, Leo',    'Güemes',  'Vitalicio',     0, 'Ajedrez'),
  (105, 'Sosa, Eva',    'Alberdi', 'Menor',     15000, 'Vóley, Natación'),
  (106, 'Vera, Tomás',  'Cofico',  'Mayor',     25000, 'Ajedrez, Fútbol'),
  (107, 'Luna, Mía',    'Güemes',  'Menor',     15000, 'Natación');

-- --- solución en 3FN ---
create table ex3_categoria (
  categoria  varchar(20) primary key,
  cuota      numeric(10,2) not null
);
insert into ex3_categoria values
  ('Mayor',     25000),
  ('Menor',     15000),
  ('Vitalicio',     0);

create table ex3_socio (
  nro_socio  int primary key,
  socio      varchar(40) not null,
  barrio     varchar(30),
  categoria  varchar(20) not null references ex3_categoria(categoria)
);
insert into ex3_socio values
  (101, 'Gómez, Ana',  'Centro',  'Mayor'),
  (102, 'Paz, Luis',   'Alberdi', 'Menor'),
  (103, 'Ruiz, Sol',   'Centro',  'Mayor'),
  (104, 'Díaz, Leo',   'Güemes',  'Vitalicio'),
  (105, 'Sosa, Eva',   'Alberdi', 'Menor'),
  (106, 'Vera, Tomás', 'Cofico',  'Mayor'),
  (107, 'Luna, Mía',   'Güemes',  'Menor');

create table ex3_socio_actividad (
  nro_socio  int references ex3_socio(nro_socio),
  actividad  varchar(30),
  primary key (nro_socio, actividad)
);
insert into ex3_socio_actividad values
  (101, 'Natación'), (101, 'Fútbol'),
  (102, 'Fútbol'),
  (103, 'Natación'), (103, 'Vóley'), (103, 'Fútbol'),
  (104, 'Ajedrez'),
  (105, 'Vóley'),    (105, 'Natación'),
  (106, 'Ajedrez'),  (106, 'Fútbol'),
  (107, 'Natación');


-- ============================================================
-- EJERCICIO 4 — LOS TURNOS
-- PK simple (nro_turno): por eso ya está en 2FN sin hacer nada.
-- ============================================================
create table ex4_planilla (
  nro_turno     int primary key,
  fecha         date,
  hora          time,
  dni_paciente  varchar(10),
  paciente      varchar(40),
  obra_social   varchar(30),
  matricula     int,
  medico        varchar(40),
  especialidad  varchar(40)
);

insert into ex4_planilla values
  (5001, '2026-10-06', '09:00', '30111222', 'Sosa, Juan',  'OSDE',          4521, 'Méndez',  'Cardiología'),
  (5002, '2026-10-06', '09:30', '28444555', 'Vera, Ana',   'PAMI',          4521, 'Méndez',  'Cardiología'),
  (5003, '2026-10-06', '10:00', '30111222', 'Sosa, Juan',  'OSDE',          3870, 'Ríos',    'Clínica médica'),
  (5004, '2026-10-07', '09:00', '35666777', 'Luna, Ema',   'Particular',    3870, 'Ríos',    'Clínica médica'),
  (5005, '2026-10-07', '09:30', '40222333', 'Paz, Lucas',  'Swiss Medical', 5102, 'Herrera', 'Traumatología'),
  (5006, '2026-10-07', '10:00', '28444555', 'Vera, Ana',   'PAMI',          3870, 'Ríos',    'Clínica médica'),
  (5007, '2026-10-08', '11:00', '40222333', 'Paz, Lucas',  'Swiss Medical', 5102, 'Herrera', 'Traumatología'),
  (5008, '2026-10-08', '11:30', '33555999', 'Gil, Marta',  'OSDE',          4521, 'Méndez',  'Cardiología');

-- --- solución en 3FN ---
create table ex4_paciente (
  dni_paciente  varchar(10) primary key,
  paciente      varchar(40) not null,
  obra_social   varchar(30)
);
insert into ex4_paciente values
  ('30111222', 'Sosa, Juan', 'OSDE'),
  ('28444555', 'Vera, Ana',  'PAMI'),
  ('35666777', 'Luna, Ema',  'Particular'),
  ('40222333', 'Paz, Lucas', 'Swiss Medical'),
  ('33555999', 'Gil, Marta', 'OSDE');

create table ex4_medico (
  matricula     int primary key,
  medico        varchar(40) not null,
  especialidad  varchar(40)
);
insert into ex4_medico values
  (4521, 'Méndez',  'Cardiología'),
  (3870, 'Ríos',    'Clínica médica'),
  (5102, 'Herrera', 'Traumatología');

create table ex4_turno (
  nro_turno     int primary key,
  fecha         date not null,
  hora          time not null,
  dni_paciente  varchar(10) not null references ex4_paciente(dni_paciente),
  matricula     int not null references ex4_medico(matricula)
);
insert into ex4_turno values
  (5001, '2026-10-06', '09:00', '30111222', 4521),
  (5002, '2026-10-06', '09:30', '28444555', 4521),
  (5003, '2026-10-06', '10:00', '30111222', 3870),
  (5004, '2026-10-07', '09:00', '35666777', 3870),
  (5005, '2026-10-07', '09:30', '40222333', 5102),
  (5006, '2026-10-07', '10:00', '28444555', 3870),
  (5007, '2026-10-08', '11:00', '40222333', 5102),
  (5008, '2026-10-08', '11:30', '33555999', 4521);


select 'Ejercicios cargados: 3 en vivo (solo enunciado) + 4 de la casa (con solución).' as resultado;
