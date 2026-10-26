-- ============================================================
-- Normalización 0FN → 5FN — consultas para seguir en clase
--
-- Requiere haber corrido antes 03_normalizacion_0fn_a_5fn.sql
--
-- CÓMO USARLO: no corras todo el archivo de una. En el SQL Editor
-- de Supabase, SELECCIONÁ con el mouse solo el bloque que querés
-- ver y apretá Ctrl+Enter (Cmd+Enter en Mac): corre nada más que
-- lo seleccionado. Si corrés todo junto, Supabase muestra
-- únicamente el resultado del último SELECT.
-- ============================================================


-- ════════════════════════════════════════════════════════════
-- 0FN — LA PLANILLA
-- ════════════════════════════════════════════════════════════

-- [0.1] Así arranca todo: una sola tabla.
--       Mirá la última columna: tiene una lista adentro.
select * from fn0_planilla;

-- [0.2] El problema práctico: ¿qué consultas recetaron Prednisolona?
--       Hay que salir a buscar texto adentro de la celda. Es frágil:
--       se rompe con una mayúscula, un espacio o una abreviatura.
select consulta, mascota, medicamentos
from fn0_planilla
where medicamentos like '%Prednisolona%';

-- [0.3] Y esto directamente no se puede: ¿cuántas veces se recetó
--       cada medicamento? No hay forma de contar lo que está
--       escondido adentro de un texto.


-- ════════════════════════════════════════════════════════════
-- 1FN — UNA FILA POR MEDICAMENTO
-- ════════════════════════════════════════════════════════════

-- [1.1] Se deshizo la lista. Ahora la PK es (consulta, medicamento).
select * from fn1_planilla;

-- [1.2] Lo que antes era imposible, ahora es una línea:
select medicamento, count(*) as veces_recetado
from fn1_planilla
group by medicamento
order by veces_recetado desc, medicamento;

-- [1.3] PERO la redundancia empeoró. El teléfono de Pérez está
--       escrito tres veces. Si cambia, hay que acordarse de las tres.
select dueno, telefono, count(*) as filas_donde_se_repite
from fn1_planilla
group by dueno, telefono
order by filas_donde_se_repite desc;


-- ════════════════════════════════════════════════════════════
-- 2FN — SIN DEPENDENCIAS PARCIALES
-- ════════════════════════════════════════════════════════════

-- [2.1] Lo que dependía solo de "consulta" se fue a su tabla.
select * from fn2_consulta;

-- [2.2] La dosis necesita las dos columnas de la clave: se queda.
select * from fn2_receta;

-- [2.3] De 6 filas con todo repetido pasamos a 4 + 6, pero cada
--       dato de la consulta se guarda una sola vez.
select 'fn1_planilla' as tabla, count(*) as filas from fn1_planilla
union all
select 'fn2_consulta', count(*) from fn2_consulta
union all
select 'fn2_receta',   count(*) from fn2_receta;

-- [2.4] Todavía falta: en fn2_consulta, "Díaz / Dermatología"
--       sigue repetido, y el teléfono sigue pegado al dueño.
select distinct veterinario, especialidad from fn2_consulta;


-- ════════════════════════════════════════════════════════════
-- 3FN — SIN DEPENDENCIAS TRANSITIVAS
-- ════════════════════════════════════════════════════════════

-- [3.1] Las seis tablas finales, una por una.
select * from fn3_dueno;
select * from fn3_mascota;
select * from fn3_veterinario;
select * from fn3_medicamento;
select * from fn3_consulta;
select * from fn3_receta;

-- [3.2] Los dos Rocky: por esto el nombre no servía como clave.
select m.id_mascota, m.nombre, d.apellido as dueno
from fn3_mascota m
join fn3_dueno d on d.id_dueno = m.id_dueno
order by m.nombre, d.apellido;

-- [3.3] LA PRUEBA DE QUE NO PERDIMOS NADA:
--       reconstruimos la planilla de 1FN desde las seis tablas.
--       Tiene que dar exactamente las mismas 6 filas.
select c.id_consulta as consulta,
       me.nombre     as medicamento,
       r.dosis,
       c.fecha,
       ma.nombre     as mascota,
       d.apellido    as dueno,
       d.telefono,
       v.matricula,
       v.apellido    as veterinario,
       v.especialidad
from fn3_receta r
join fn3_consulta    c  on c.id_consulta    = r.id_consulta
join fn3_medicamento me on me.id_medicamento = r.id_medicamento
join fn3_mascota     ma on ma.id_mascota    = c.id_mascota
join fn3_dueno       d  on d.id_dueno       = ma.id_dueno
join fn3_veterinario v  on v.matricula      = c.matricula
order by consulta, medicamento;

-- [3.4] El teléfono de Pérez, ahora: una sola fila.
select * from fn3_dueno where apellido = 'Pérez';


-- ════════════════════════════════════════════════════════════
-- BCNF — EL DETERMINANTE QUE NO ES CLAVE
-- ════════════════════════════════════════════════════════════

-- [B.1] La tabla problemática. Está en 3FN: todas sus columnas
--       son parte de alguna clave candidata, así que no hay
--       ninguna columna no clave de la que preocuparse.
select * from fn3_atencion;

-- [B.2] Y sin embargo "Díaz / Dermatología" está dos veces, y
--       "Ramírez / Clínica general" también. Eso lo causa
--       veterinario → especialidad, cuyo lado izquierdo NO es clave.
select veterinario, especialidad, count(*) as veces
from fn3_atencion
group by veterinario, especialidad
order by veces desc;

-- [B.3] LA ANOMALÍA DE INSERCIÓN:
--       la veterinaria contrata a Molina, oftalmólogo, que todavía
--       no atendió a nadie. ¿Dónde lo guardo?
--       En fn3_atencion no hay lugar: la PK exige una mascota.
--       Descomentá para ver el error que da:
-- insert into fn3_atencion (mascota, especialidad, veterinario)
--   values (null, 'Oftalmología', 'Molina');

-- [B.4] Después de descomponer, sí entra:
insert into fn3b_veterinario values ('Molina', 'Oftalmología')
  on conflict do nothing;

select * from fn3b_veterinario order by veterinario;

-- [B.5] Y la asignación queda aparte, sin repetir la especialidad.
select * from fn3b_atencion order by mascota, veterinario;


-- ════════════════════════════════════════════════════════════
-- 4FN — DOS HECHOS INDEPENDIENTES
-- ════════════════════════════════════════════════════════════

-- [4.1] La agenda mal armada. Ramírez (1001) tiene 2 especialidades
--       y atiende 2 días: la tabla guarda las 4 combinaciones.
select * from fn3b_agenda order by matricula, especialidad, dia;

-- [4.2] El síntoma, en números: las filas son el producto de dos listas.
select matricula,
       count(distinct especialidad) as especialidades,
       count(distinct dia)          as dias,
       count(*)                     as filas_guardadas
from fn3b_agenda
group by matricula
order by matricula;

-- [4.3] Descompuesta: un hecho por tabla. 3 filas + 3 filas.
select * from fn4_vet_especialidad order by matricula, especialidad;
select * from fn4_vet_dia          order by matricula, dia;

-- [4.4] LA PRUEBA: al unirlas volvemos a las 5 filas exactas.
select e.matricula, e.especialidad, d.dia
from fn4_vet_especialidad e
join fn4_vet_dia d on d.matricula = e.matricula
order by 1, 2, 3;

-- [4.5] Verificación formal: la diferencia entre las dos es vacía
--       en los dos sentidos. No sobra ni falta ninguna fila.
(select matricula, especialidad, dia from fn3b_agenda
 except
 select e.matricula, e.especialidad, d.dia
 from fn4_vet_especialidad e join fn4_vet_dia d on d.matricula = e.matricula)
union all
(select e.matricula, e.especialidad, d.dia
 from fn4_vet_especialidad e join fn4_vet_dia d on d.matricula = e.matricula
 except
 select matricula, especialidad, dia from fn3b_agenda);


-- ════════════════════════════════════════════════════════════
-- 5FN — HACEN FALTA TRES, NO DOS
-- ════════════════════════════════════════════════════════════

-- [5.1] La tabla original: 4 filas.
--       Falta "Díaz / Amoxicilina / Brouwer" porque Brouwer no
--       fabrica amoxicilina. Esa ausencia es toda la gracia.
select * from fn4_receta_lab order by 1, 2, 3;

-- [5.2] Las tres proyecciones, un hecho suelto cada una.
select * from fn5_receta      order by 1, 2;
select * from fn5_trabaja_con order by 1, 2;
select * from fn5_fabrica     order by 1, 2;

-- [5.3] UNIMOS SOLO DOS → salen 5 filas. Una no existía.
select r.veterinario, r.droga, t.laboratorio
from fn5_receta r
join fn5_trabaja_con t on t.veterinario = r.veterinario
order by 1, 2, 3;

-- [5.4] ¿Cuál es la fila de más? Acá está, en una sola consulta:
select r.veterinario, r.droga, t.laboratorio
from fn5_receta r
join fn5_trabaja_con t on t.veterinario = r.veterinario
except
select veterinario, droga, laboratorio from fn4_receta_lab;
--   → Díaz / Amoxicilina / Brouwer    (fila espuria)

-- [5.5] UNIMOS LAS TRES → vuelven las 4 filas exactas.
--       La tercera proyección es la que descarta la combinación
--       imposible: fabrica no tiene el par (Brouwer, Amoxicilina).
select r.veterinario, r.droga, t.laboratorio
from fn5_receta r
join fn5_trabaja_con t on t.veterinario = r.veterinario
join fn5_fabrica     f on f.laboratorio = t.laboratorio
                     and f.droga       = r.droga
order by 1, 2, 3;

-- [5.6] Verificación formal: diferencia vacía en los dos sentidos.
(select veterinario, droga, laboratorio from fn4_receta_lab
 except
 select r.veterinario, r.droga, t.laboratorio
 from fn5_receta r
 join fn5_trabaja_con t on t.veterinario = r.veterinario
 join fn5_fabrica f on f.laboratorio = t.laboratorio and f.droga = r.droga)
union all
(select r.veterinario, r.droga, t.laboratorio
 from fn5_receta r
 join fn5_trabaja_con t on t.veterinario = r.veterinario
 join fn5_fabrica f on f.laboratorio = t.laboratorio and f.droga = r.droga
 except
 select veterinario, droga, laboratorio from fn4_receta_lab);


-- ════════════════════════════════════════════════════════════
-- 6FN / DKNF — LA RESTRICCIÓN QUE SE MUEVE AL DOMINIO
-- ════════════════════════════════════════════════════════════

-- [6.1] Dos tablas que guardan lo mismo. La diferencia no está
--       en los datos: está en DÓNDE vive la regla del estado.
select * from fn5_turno order by id_turno;
select * from fn6_turno order by id_turno;

-- [6.2] fn5_turno necesita un CHECK propio. Acá está, escrito
--       aparte de los dominios y de la clave: por eso NO está
--       en DKNF.
select conname as restriccion, pg_get_constraintdef(oid) as definicion
from pg_constraint
where conrelid = 'fn5_turno'::regclass
order by conname;

-- [6.3] fn6_turno no tiene ningún CHECK propio: solo la PK.
--       La regla del estado se mudó al dominio.
select conname as restriccion, pg_get_constraintdef(oid) as definicion
from pg_constraint
where conrelid = 'fn6_turno'::regclass
order by conname;

-- [6.4] Y acá está la regla, viviendo en el dominio:
select t.typname as dominio, pg_get_constraintdef(c.oid) as definicion
from pg_type t
join pg_constraint c on c.contypid = t.oid
where t.typname = 'estado_turno';

-- [6.5] Las dos rechazan el valor inválido, pero por motivos
--       distintos. Descomentá de a una para ver los mensajes:
-- insert into fn5_turno values (9, 'pendiente');   -- viola el CHECK de la tabla
-- insert into fn6_turno values (9, 'pendiente');   -- viola el DOMINIO

-- [6.6] El límite de DKNF: una restricción que relaciona dos
--       columnas no entra en ningún dominio, porque un dominio
--       mira un valor por vez.
--         check (fecha_devolucion >= fecha_retiro)
--       Eso siempre va a ser un CHECK de tabla. Por eso casi
--       ninguna tabla real está en DKNF, y está bien que así sea.


-- ════════════════════════════════════════════════════════════
-- CIERRE — EL RECORRIDO EN NÚMEROS
-- ════════════════════════════════════════════════════════════

-- [C.0] CUÁNTAS TABLAS HAY EN CADA ETAPA, leído del catálogo
--       de PostgreSQL. El prefijo de cada tabla dice en qué
--       forma normal está, así que esto se cuenta solo.
select case
         when table_name like 'fn0!_%'  escape '!' then '0FN'
         when table_name like 'fn1!_%'  escape '!' then '1FN'
         when table_name like 'fn2!_%'  escape '!' then '2FN'
         when table_name like 'fn3b!_%' escape '!' then 'BCNF'
         when table_name like 'fn3!_%'  escape '!' then '3FN'
         when table_name like 'fn4!_%'  escape '!' then '4FN'
         when table_name like 'fn5!_%'  escape '!' then '5FN'
       end as etapa,
       count(*)                      as cuantas_tablas,
       string_agg(table_name, ', ' order by table_name) as tablas
from information_schema.tables
where table_schema = 'public'
  and table_name like 'fn%'
group by 1
order by min(table_name);

-- [C.1] La cadena principal: cuántas tablas y cuántas filas en
--       cada etapa. Es el recorrido de la planilla de consultas,
--       sin contar las tres tablas que trajeron las reglas nuevas.
select '0FN' as etapa, 1 as tablas, (select count(*) from fn0_planilla) as filas
union all
select '1FN', 1, (select count(*) from fn1_planilla)
union all
select '2FN', 2, (select count(*) from fn2_consulta) + (select count(*) from fn2_receta)
union all
select '3FN', 6, (select count(*) from fn3_dueno)
                + (select count(*) from fn3_mascota)
                + (select count(*) from fn3_veterinario)
                + (select count(*) from fn3_medicamento)
                + (select count(*) from fn3_consulta)
                + (select count(*) from fn3_receta)
order by etapa;

-- [C.1b] Las tres descomposiciones de la segunda mitad, leídas
--        por los nombres: una tabla de un prefijo se convierte
--        en varias del prefijo siguiente.
select 'fn3_atencion → BCNF'   as descomposicion,
       (select count(*) from fn3_atencion)   as filas_antes,
       (select count(*) from fn3b_veterinario) + (select count(*) from fn3b_atencion) as filas_despues,
       '1 tabla → 2 tablas'    as tablas
union all
select 'fn3b_agenda → 4FN',
       (select count(*) from fn3b_agenda),
       (select count(*) from fn4_vet_especialidad) + (select count(*) from fn4_vet_dia),
       '1 tabla → 2 tablas'
union all
select 'fn4_receta_lab → 5FN',
       (select count(*) from fn4_receta_lab),
       (select count(*) from fn5_receta) + (select count(*) from fn5_trabaja_con)
         + (select count(*) from fn5_fabrica),
       '1 tabla → 3 tablas';

-- [C.2] Para pensar: en 3FN hay más filas en total que en 1FN.
--       ¿Entonces normalizar no ahorra espacio?
--       Ahorra REPETICIÓN, que es otra cosa: ningún dato está
--       escrito dos veces, y por eso ninguno puede quedar
--       desactualizado respecto de su copia.
