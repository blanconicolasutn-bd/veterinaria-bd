-- ============================================================
-- Ejercicios de normalización — consultas de verificación
--
-- Requiere haber corrido antes 05_normalizacion_ejercicios.sql
--
-- Igual que en el 04: seleccioná un bloque con el mouse y
-- Ctrl+Enter (Cmd+Enter en Mac). Si corrés todo junto, Supabase
-- muestra únicamente el último resultado.
--
-- La idea de los bloques [V.x]: reconstruir la planilla original
-- desde las tablas de la solución. Si la reconstrucción coincide
-- exactamente con la planilla, la descomposición no perdió nada.
-- Si da alguna fila, algo quedó mal.
-- ============================================================


-- ════════════════════════════════════════════════════════════
-- A · LOS TRES EJERCICIOS EN VIVO  (sin solución: la arman ustedes)
-- ════════════════════════════════════════════════════════════

-- [A.1] BCNF — los consultorios.
select * from ej_consultorio order by consultorio, franja;

-- [A.2] Pista: ¿se repite algún par de valores que no debería?
select veterinario, consultorio, count(*) as veces
from ej_consultorio
group by veterinario, consultorio
order by veces desc, veterinario;

-- [A.3] 4FN — los contactos del dueño. Contá las filas por dueño.
select * from ej_dueno_contacto order by id_dueno, telefono, mascota;

select id_dueno,
       count(distinct telefono) as telefonos,
       count(distinct mascota)  as mascotas,
       count(*)                 as filas_guardadas
from ej_dueno_contacto
group by id_dueno
order by id_dueno;

-- [A.4] 5FN — veterinario, especie y servicio.
select * from ej_vet_servicio order by 1, 2, 3;

-- [A.5] Pista para el de 5FN: uní dos proyecciones y contá.
--       Da 5 filas, y la tabla original tiene 4. ¿Cuál sobra?
select a.veterinario, a.especie, p.servicio
from (select distinct veterinario, especie  from ej_vet_servicio) a
join (select distinct veterinario, servicio from ej_vet_servicio) p
  on p.veterinario = a.veterinario
except
select veterinario, especie, servicio from ej_vet_servicio;

-- [A.6] Para cuando armen su descomposición: así se comprueba.
--       Creen sus tablas y reemplacen el segundo SELECT por el
--       join de las suyas. Tiene que dar CERO filas.
-- select veterinario, especie, servicio from ej_vet_servicio
-- except
-- select ... ;


-- ════════════════════════════════════════════════════════════
-- B · EJERCICIO 1 — INSCRIPCIONES
-- ════════════════════════════════════════════════════════════

-- [1.0] La planilla original.
select * from ex1_planilla order by legajo, cod_materia;

-- [1.1] La solución, tabla por tabla.
select * from ex1_alumno      order by legajo;
select * from ex1_profesor    order by id_profesor;
select * from ex1_materia     order by cod_materia;
select * from ex1_inscripcion order by legajo, cod_materia;

-- [1.2] La transitiva que había que ver: la oficina es del
--       profesor, no de la materia. Antes se repetía; ahora no.
select p.nombre as profesor, p.oficina, count(m.cod_materia) as materias_que_dicta
from ex1_profesor p
left join ex1_materia m on m.id_profesor = p.id_profesor
group by p.nombre, p.oficina
order by p.nombre;

-- [V.1] VERIFICACIÓN: reconstruyo la planilla desde las 4 tablas.
--       Tiene que dar CERO filas en los dos sentidos.
(select legajo, alumno, carrera, cod_materia, materia, profesor, oficina, nota
 from ex1_planilla
 except
 select a.legajo, a.alumno, a.carrera, m.cod_materia, m.materia, p.nombre, p.oficina, i.nota
 from ex1_inscripcion i
 join ex1_alumno   a on a.legajo      = i.legajo
 join ex1_materia  m on m.cod_materia = i.cod_materia
 join ex1_profesor p on p.id_profesor = m.id_profesor)
union all
(select a.legajo, a.alumno, a.carrera, m.cod_materia, m.materia, p.nombre, p.oficina, i.nota
 from ex1_inscripcion i
 join ex1_alumno   a on a.legajo      = i.legajo
 join ex1_materia  m on m.cod_materia = i.cod_materia
 join ex1_profesor p on p.id_profesor = m.id_profesor
 except
 select legajo, alumno, carrera, cod_materia, materia, profesor, oficina, nota
 from ex1_planilla);


-- ════════════════════════════════════════════════════════════
-- C · EJERCICIO 2 — EL CORRALÓN
-- ════════════════════════════════════════════════════════════

-- [2.0] La planilla original, con las columnas numeradas.
select * from ex2_planilla order by nro_factura;

-- [2.1] La solución.
select * from ex2_cliente  order by cuit;
select * from ex2_factura  order by nro_factura;
select * from ex2_producto order by producto;
select * from ex2_detalle  order by nro_factura, producto;

-- [2.2] El precio del cemento estaba escrito 4 veces en la planilla.
--       Ahora está una sola vez:
select * from ex2_producto where producto = 'Cemento';

-- [V.2] VERIFICACIÓN: deshago el grupo repetido de la planilla
--       con un UNION ALL y lo comparo contra ex2_detalle.
--       Tiene que dar CERO filas en los dos sentidos.
with planilla_1fn as (
  select nro_factura, producto_1 as producto, cant_1 as cantidad
  from ex2_planilla where producto_1 is not null
  union all
  select nro_factura, producto_2, cant_2
  from ex2_planilla where producto_2 is not null
)
(select nro_factura, producto, cantidad from planilla_1fn
 except
 select nro_factura, producto, cantidad from ex2_detalle)
union all
(select nro_factura, producto, cantidad from ex2_detalle
 except
 select nro_factura, producto, cantidad from planilla_1fn);


-- ════════════════════════════════════════════════════════════
-- D · EJERCICIO 3 — EL CLUB
-- ════════════════════════════════════════════════════════════

-- [3.0] La planilla original, con la lista en la celda.
select * from ex3_planilla order by nro_socio;

-- [3.1] La solución.
select * from ex3_categoria       order by cuota desc;
select * from ex3_socio           order by nro_socio;
select * from ex3_socio_actividad order by nro_socio, actividad;

-- [3.2] La transitiva: la cuota era de la categoría, no del socio.
--       Antes "25000" estaba en tres filas; ahora, en una.
select categoria, cuota, (select count(*) from ex3_socio s where s.categoria = c.categoria) as socios
from ex3_categoria c
order by cuota desc;

-- [V.3] VERIFICACIÓN: para comparar hay que deshacer la lista de
--       la planilla. PostgreSQL puede hacerlo con string_to_array
--       + unnest... y que haga falta una función especial para
--       esto es exactamente el argumento a favor de 1FN.
--       Tiene que dar CERO filas en los dos sentidos.
with planilla_1fn as (
  select p.nro_socio, trim(a) as actividad
  from ex3_planilla p,
       unnest(string_to_array(p.actividades, ',')) as a
)
(select nro_socio, actividad from planilla_1fn
 except
 select nro_socio, actividad from ex3_socio_actividad)
union all
(select nro_socio, actividad from ex3_socio_actividad
 except
 select nro_socio, actividad from planilla_1fn);


-- ════════════════════════════════════════════════════════════
-- E · EJERCICIO 4 — LOS TURNOS
-- ════════════════════════════════════════════════════════════

-- [4.0] La planilla original. PK de una sola columna: ya está en 2FN.
select * from ex4_planilla order by nro_turno;

-- [4.1] La solución.
select * from ex4_paciente order by dni_paciente;
select * from ex4_medico   order by matricula;
select * from ex4_turno    order by nro_turno;

-- [4.2] Las dos transitivas que había que encontrar.
--       Vera, Ana aparecía 2 veces con su obra social; Ríos, 3
--       veces con su especialidad. Ahora, una sola vez cada uno.
select 'pacientes' as tabla, count(*) as filas from ex4_paciente
union all
select 'medicos',  count(*) from ex4_medico
union all
select 'turnos',   count(*) from ex4_turno
union all
select 'planilla original', count(*) from ex4_planilla;

-- [V.4] VERIFICACIÓN: reconstruyo la planilla desde las 3 tablas.
--       Tiene que dar CERO filas en los dos sentidos.
(select nro_turno, fecha, hora, dni_paciente, paciente, obra_social, matricula, medico, especialidad
 from ex4_planilla
 except
 select t.nro_turno, t.fecha, t.hora, p.dni_paciente, p.paciente, p.obra_social,
        m.matricula, m.medico, m.especialidad
 from ex4_turno t
 join ex4_paciente p on p.dni_paciente = t.dni_paciente
 join ex4_medico   m on m.matricula    = t.matricula)
union all
(select t.nro_turno, t.fecha, t.hora, p.dni_paciente, p.paciente, p.obra_social,
        m.matricula, m.medico, m.especialidad
 from ex4_turno t
 join ex4_paciente p on p.dni_paciente = t.dni_paciente
 join ex4_medico   m on m.matricula    = t.matricula
 except
 select nro_turno, fecha, hora, dni_paciente, paciente, obra_social, matricula, medico, especialidad
 from ex4_planilla);


-- ════════════════════════════════════════════════════════════
-- F · LAS CUATRO VERIFICACIONES DE UNA SOLA VEZ
-- ════════════════════════════════════════════════════════════

-- [F.1] Si las cuatro descomposiciones están bien, las cuatro
--       columnas dan 0. Es el cierre del bloque de correcciones.
select
  (select count(*) from (
     (select legajo, alumno, carrera, cod_materia, materia, profesor, oficina, nota from ex1_planilla
      except
      select a.legajo, a.alumno, a.carrera, m.cod_materia, m.materia, p.nombre, p.oficina, i.nota
      from ex1_inscripcion i
      join ex1_alumno a on a.legajo = i.legajo
      join ex1_materia m on m.cod_materia = i.cod_materia
      join ex1_profesor p on p.id_profesor = m.id_profesor)
   ) d1) as inscripciones,

  (select count(*) from (
     (select nro_factura, producto_1, cant_1 from ex2_planilla where producto_1 is not null
      union all
      select nro_factura, producto_2, cant_2 from ex2_planilla where producto_2 is not null
      except
      select nro_factura, producto, cantidad from ex2_detalle)
   ) d2) as corralon,

  (select count(*) from (
     (select p.nro_socio, trim(a) from ex3_planilla p,
             unnest(string_to_array(p.actividades, ',')) as a
      except
      select nro_socio, actividad from ex3_socio_actividad)
   ) d3) as club,

  (select count(*) from (
     (select nro_turno, dni_paciente, matricula from ex4_planilla
      except
      select nro_turno, dni_paciente, matricula from ex4_turno)
   ) d4) as turnos;
