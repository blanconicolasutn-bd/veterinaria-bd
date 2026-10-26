-- ============================================================
-- Auto-chequeo de los ejercicios de transacciones y funciones
--
-- ESTE ARCHIVO NO TRAE LAS SOLUCIONES. Trae las verificaciones:
-- vos escribís tu respuesta, corrés el chequeo que corresponde,
-- y el script te dice si quedó bien.
--
-- CÓMO USARLO: un bloque por vez. Seleccionalo con el mouse y
-- apretá Ctrl+Enter (Cmd+Enter en Mac). No corras el archivo
-- entero: Supabase muestra solo el resultado del último select.
--
-- Casi todos los chequeos devuelven una columna que dice OK o
-- MAL. Si dice MAL, volvé al ejercicio: no hace falta adivinar
-- qué se rompió.
--
-- Requiere 01_esquema.sql + 02_datos.sql.
-- ============================================================


-- ════════════════════════════════════════════════════════════
-- [0] ANTES DE EMPEZAR: ¿este editor respeta el rollback?
--     Si esto no dice OK, nada de lo demás va a funcionar.
-- ════════════════════════════════════════════════════════════
begin;
insert into dueno (dni, apellido, nombre)
values ('99999999', 'Prueba', 'Editor');
rollback;

select case when count(*) = 0 then 'OK' else 'MAL' end as rollback_funciona
from dueno where dni = '99999999';


-- ============================================================
--                  PARTE T — TRANSACCIONES
--
--  Cada chequeo se corre DESPUÉS de tu propia respuesta.
-- ============================================================


-- ════════════════════════════════════════════════════════════
-- [T.1] Alta de dueño y mascota
--       Corré esto después de tu transacción con commit.
-- ════════════════════════════════════════════════════════════
select case
         when count(*) = 1 then 'OK — quedaron el dueño y su mascota'
         else 'MAL — esperaba 1 fila y hay ' || count(*)
       end as resultado
from dueno d
join mascota m on m.id_dueno = d.id_dueno
where d.dni = '27888999' and m.nombre = 'Duque';


-- ════════════════════════════════════════════════════════════
-- [T.1b] Y ahora dejá la base como estaba (corré esto siempre)
-- ════════════════════════════════════════════════════════════
delete from mascota
where id_dueno = (select id_dueno from dueno where dni = '27888999');

delete from dueno where dni = '27888999';


-- ════════════════════════════════════════════════════════════
-- [T.2] El alta que se deshace
--       Tu primera ejecución tiene que haber devuelto 1.
--       Corré esto como segunda ejecución.
-- ════════════════════════════════════════════════════════════
select case when count(*) = 0 then 'OK — el rollback deshizo el insert'
            else 'MAL — la fila quedó: ¿pusiste commit en vez de rollback?'
       end as resultado
from dueno where dni = '27888999';


-- ════════════════════════════════════════════════════════════
-- [T.3] La transacción que se aborta
--       Tu bloque tenía que cortar con el error de FK.
--       Esto verifica que NO quedó ninguna de las dos mascotas.
-- ════════════════════════════════════════════════════════════


select case
         when count(*) = 0 then 'OK — no quedó ninguna de las dos'
         else 'MAL — quedaron ' || count(*) || ': ¿pusiste commit en vez '
              || 'de dejar que el error cortara?'
       end as resultado
from mascota where nombre in ('Fantasma', 'Lola');

-- Ojo: tenés que haber visto UN SOLO error, no dos. El segundo insert
-- nunca llegó a ejecutarse.


-- ════════════════════════════════════════════════════════════
-- [T.4] Borrar la consulta 4 con sus recetas
--       Tu transacción termina en rollback, así que esto
--       verifica que NO se perdió nada.
-- ════════════════════════════════════════════════════════════
select case
         when (select count(*) from consulta where id_consulta = 4) = 1
          and (select count(*) from receta   where id_consulta = 4) = 2
         then 'OK — el rollback dejó la consulta 4 con sus 2 recetas'
         else 'MAL — faltan filas: ¿te quedó un commit?'
       end as resultado;


-- ════════════════════════════════════════════════════════════
-- [T.5] La mascota cambia de dueño
--       Tu primera ejecución tiene que haber mostrado 1 y 3.
--       Corré esto como segunda ejecución.
-- ════════════════════════════════════════════════════════════
select case
         when (select count(*) from mascota where id_dueno = 1) = 2
          and (select count(*) from mascota where id_dueno = 2) = 2
         then 'OK — volvió todo atrás'
         else 'MAL — Michi quedó cambiada de dueño'
       end as resultado;


-- ════════════════════════════════════════════════════════════
-- [T.6] Una consulta con su receta
--       Tu transacción termina en rollback: no tiene que haber
--       quedado ninguna consulta nueva.
-- ════════════════════════════════════════════════════════════
select case
         when count(*) = 0 then 'OK — no quedó nada, como corresponde'
         else 'MAL — quedaron ' || count(*) || ' consultas sin deshacer'
       end as resultado
from consulta where motivo = 'Control de peso';

-- NOTA: si tu transacción te devolvió un id_consulta más alto del
-- que esperabas, está bien. Las secuencias no vuelven atrás con el
-- rollback — mirá el "Error común" del ejercicio 2.


-- ════════════════════════════════════════════════════════════
-- [T.7] El update sin where
--       Tu bloque tiene que haber mostrado 10, y terminar en
--       rollback. Esto verifica que los pesos siguen intactos.
-- ════════════════════════════════════════════════════════════
select case
         when count(*) = 0 then 'OK — ninguna mascota quedó en 10 kg'
         else 'MAL — ' || count(*) || ' mascotas quedaron en 10 kg'
       end as resultado
from mascota where peso_kg = 10;


-- ════════════════════════════════════════════════════════════
-- [T.8] Subirle 1 kg a los perros del dueño 3
--       Antes del rollback, tu select tenía que mostrar a Rocky
--       en 36.00 y a Michi y Pipo intactos. Acá se verifica que
--       el rollback dejó todo como estaba.
-- ════════════════════════════════════════════════════════════
select case
         when (select peso_kg from mascota where id_mascota = 5) = 35.00
          and (select peso_kg from mascota where id_mascota = 6) = 4.50
          and (select peso_kg from mascota where id_mascota = 7) = 0.30
         then 'OK'
         else 'MAL — revisá el rollback, o el where del update'
       end as resultado;


-- ════════════════════════════════════════════════════════════
-- [T.9] Tres recetas y una repetida
--       Corré esto DESPUÉS de tu bloque do con el exception.
-- ════════════════════════════════════════════════════════════


select case
         when count(*) = 2 then 'OK — el repetido falló y los otros dos quedaron'
         when count(*) = 0 then 'MAL — se perdieron los tres: el bloque interno '
              || 'con exception tiene que envolver SOLO al insert repetido'
         else 'MAL — quedaron ' || count(*)
       end as resultado
from receta where id_consulta = 1;


-- ════════════════════════════════════════════════════════════
-- [T.9b] Dejá la base como estaba
-- ════════════════════════════════════════════════════════════
delete from receta where id_consulta = 1;


-- ════════════════════════════════════════════════════════════
-- [T.10] savepoint: Nina sí, Pipo no
--        Éste SÍ termina en commit. Corré el chequeo después.
-- ════════════════════════════════════════════════════════════
select case
         when (select peso_kg from mascota where id_mascota = 8) = 14.00
          and (select peso_kg from mascota where id_mascota = 7) = 0.30
         then 'OK — quedó el aumento de Nina y no el de Pipo'
         when (select peso_kg from mascota where id_mascota = 7) > 0.30
         then 'MAL — a Pipo le quedaron los 20 kg: revisá el rollback to'
         else 'MAL — a Nina no le quedó el aumento'
       end as resultado;


-- ════════════════════════════════════════════════════════════
-- [T.10b] Dejá la base como estaba
-- ════════════════════════════════════════════════════════════
update mascota set peso_kg = 12.00 where id_mascota = 8;



-- ============================================================
--            PARTE F — INTEGRADORES DE FUNCIONES
--
--  Acá los chequeos LLAMAN a tus funciones, así que tienen que
--  llamarse exactamente como dice el enunciado y recibir los
--  mismos parámetros. Si te dice "function ... does not exist",
--  revisá el nombre o los tipos.
-- ============================================================


-- ════════════════════════════════════════════════════════════
-- [F.0] ¿Están las seis funciones creadas?
-- ════════════════════════════════════════════════════════════
select p.proname as funcion,
       pg_get_function_arguments(p.oid) as parametros
from pg_proc p
join pg_namespace n on n.oid = p.pronamespace
where n.nspname = 'public'
  and p.proname in ('registrar_peso', 'riesgo_mascota', 'recetar',
                    'nueva_consulta', 'control_peso', 'cerrar_tratamiento')
order by p.proname;

-- Tienen que aparecer las seis. Las que falten, no están creadas.


-- ════════════════════════════════════════════════════════════
-- [F.1] El do que valida el peso
--       Tu bloque tiene que haber cortado con un error.
--       Esto verifica que el update se deshizo solo.
-- ════════════════════════════════════════════════════════════
select case when peso_kg = 28.50 then 'OK — el error deshizo el update'
            else 'MAL — Rocky quedó en ' || peso_kg || ': la validación '
                 || 'tiene que estar DENTRO del mismo bloque'
       end as resultado
from mascota where id_mascota = 1;


-- ════════════════════════════════════════════════════════════
-- [F.2] registrar_peso: el camino que funciona
-- ════════════════════════════════════════════════════════════
-- se la llama UNA sola vez: la función modifica el peso, así que
-- llamarla de nuevo para el mensaje de error daría un texto falso
with r as (select registrar_peso(1, 30.00) as devuelto)
select case when devuelto = 'Rocky: 28.50 kg → 30.00 kg'
            then 'OK'
            else 'MAL — devolvió: ' || devuelto
       end as resultado
from r;

-- Ojo: esto deja a Rocky en 30.00. Lo arregla el bloque [F.2d].


-- ════════════════════════════════════════════════════════════
-- [F.2b] Y los dos caminos que tienen que cortar
-- ════════════════════════════════════════════════════════════
select registrar_peso(1, 150);
-- TIENE QUE DAR ERROR: "Peso fuera de rango: 150 kg"
-- Si devuelve un texto, te falta la validación del rango.


-- ════════════════════════════════════════════════════════════
-- [F.2c]
-- ════════════════════════════════════════════════════════════
select registrar_peso(99, 30);
-- TIENE QUE DAR ERROR: "No existe la mascota 99"
-- Si devuelve null o un texto raro, te falta el if not found.


-- ════════════════════════════════════════════════════════════
-- [F.2d] Dejá a Rocky como estaba
-- ════════════════════════════════════════════════════════════
update mascota set peso_kg = 28.50 where id_mascota = 1;


-- ════════════════════════════════════════════════════════════
-- [F.3] riesgo_mascota: las tres categorías
-- ════════════════════════════════════════════════════════════
select case
         when riesgo_mascota(5) = 'alto'      -- 8 años y 35 kg
          and riesgo_mascota(8) = 'medio'     -- 9 años, 12 kg
          and riesgo_mascota(1) = 'medio'     -- 7 años, 28.50 kg
          and riesgo_mascota(4) = 'bajo'      -- 4 años, 3.80 kg
         then 'OK — las tres categorías andan'
         when riesgo_mascota(5) <> 'alto'
         then 'MAL — Rocky (id 5) cumple las dos condiciones y tiene '
              || 'que dar alto: revisá el ORDEN de las ramas del if'
         else 'MAL — revisá el caso "una sola condición"'
       end as resultado;


-- ════════════════════════════════════════════════════════════
-- [F.3b] Mascota inexistente
-- ════════════════════════════════════════════════════════════
select riesgo_mascota(99);
-- TIENE QUE DAR ERROR: "No existe la mascota 99"


-- ════════════════════════════════════════════════════════════
-- [F.4] recetar: el alta que funciona
-- ════════════════════════════════════════════════════════════
select case when recetar(1, 3, '1 ampolla', 5) = 'Recetado: Ivermectina por 5 días'
            then 'OK'
            else 'MAL — revisá el texto que devolvés'
       end as resultado;


-- ════════════════════════════════════════════════════════════
-- [F.4b] El duplicado
-- ════════════════════════════════════════════════════════════
select recetar(1, 3, '1 ampolla', 5);
-- TIENE QUE DAR ERROR: "El medicamento 3 ya está recetado en la consulta 1"
-- Si el error habla de "duplicate key" o "receta_pkey", el que cortó
-- fue la clave primaria y no tu validación: te falta el if found.


-- ════════════════════════════════════════════════════════════
-- [F.4c] Duración inválida
-- ════════════════════════════════════════════════════════════
select recetar(1, 7, '100mg cada 12hs', 0);
-- TIENE QUE DAR ERROR: "La duración tiene que ser mayor a cero"


-- ════════════════════════════════════════════════════════════
-- [F.4d] Consulta inexistente
-- ════════════════════════════════════════════════════════════
select recetar(99, 7, '100mg', 5);
-- TIENE QUE DAR ERROR: "No existe la consulta 99"


-- ════════════════════════════════════════════════════════════
-- [F.4e] Dejá la base como estaba
-- ════════════════════════════════════════════════════════════
delete from receta where id_consulta = 1;


-- ════════════════════════════════════════════════════════════
-- [F.5] nueva_consulta: tiene que devolver un número
-- ════════════════════════════════════════════════════════════
select case when nueva_consulta(1, 1001, 'Control de peso') > 0
            then 'OK — devolvió el id de la consulta nueva'
            else 'MAL'
       end as resultado;

-- El número NO tiene por qué ser 17. Cada insert anterior sobre
-- consulta, aunque se haya deshecho, se llevó su número.


-- ════════════════════════════════════════════════════════════
-- [F.5b] Veterinario inexistente
-- ════════════════════════════════════════════════════════════
select nueva_consulta(1, 9999, 'Control de peso');
-- TIENE QUE DAR ERROR: "No existe el veterinario 9999"


-- ════════════════════════════════════════════════════════════
-- [F.5c] Motivo con solo espacios — el que más se cuela
-- ════════════════════════════════════════════════════════════
select nueva_consulta(1, 1001, '   ');
-- TIENE QUE DAR ERROR: "El motivo no puede estar vacío"
-- Si lo inserta, tu validación mira p_motivo = '' y tres espacios
-- no son lo mismo que vacío. Mirá trim().


-- ════════════════════════════════════════════════════════════
-- [F.5d] Motivo en null — el otro caso
-- ════════════════════════════════════════════════════════════
select nueva_consulta(1, 1001, null);
-- TIENE QUE DAR ERROR: "El motivo no puede estar vacío"
-- Si lo inserta, te falta coalesce(): comparar algo con null no da
-- falso, da null, y el if se va por el else.


-- ════════════════════════════════════════════════════════════
-- [F.5e] Dejá la base como estaba
-- ════════════════════════════════════════════════════════════
delete from consulta where motivo = 'Control de peso' or motivo is null;


-- ════════════════════════════════════════════════════════════
-- [F.6] El do que cierra consultas
--       Corrido tal cual, tiene que cortar con el error.
--       Después dejá una consulta abierta y volvé a correrlo:
--       ahí no tiene que cortar.
-- ════════════════════════════════════════════════════════════
update consulta set diagnostico = null where id_consulta = 1;

-- (ahora corré tu bloque: NO tiene que dar error)


-- ════════════════════════════════════════════════════════════
-- [F.6b] ¿Cerró la que estaba abierta?
-- ════════════════════════════════════════════════════════════
select case when diagnostico = 'Cerrado por control' then 'OK'
            when diagnostico is null then 'MAL — no modificó la consulta'
            else 'MAL — quedó: ' || diagnostico
       end as resultado
from consulta where id_consulta = 1;


-- ════════════════════════════════════════════════════════════
-- [F.6c] Dejá la base como estaba
-- ════════════════════════════════════════════════════════════
update consulta set diagnostico = 'Sano' where id_consulta = 1;


-- ════════════════════════════════════════════════════════════
-- [F.7] control_peso
-- ════════════════════════════════════════════════════════════
select case when control_peso(1) = 'Rocky (Perro) — 28.50 kg — riesgo medio'
            then 'OK'
            else 'MAL — devolvió: ' || control_peso(1)
       end as resultado;


-- ════════════════════════════════════════════════════════════
-- [F.7b] Los dos errores tienen que ser DISTINTOS
-- ════════════════════════════════════════════════════════════
select control_peso(99);
-- TIENE QUE DAR ERROR: "No existe la mascota 99"


-- ════════════════════════════════════════════════════════════
-- [F.7c] Existe pero sin peso cargado: otro error, con el nombre
-- ════════════════════════════════════════════════════════════
update mascota set peso_kg = null where id_mascota = 9;
select control_peso(9);
-- TIENE QUE DAR ERROR: "La mascota Coco no tiene peso cargado"
-- Si dice "No existe la mascota 9", estás usando un solo control
-- para dos problemas distintos, y el mensaje miente.
--
-- El update de arriba se deshace junto con el error, así que Coco
-- vuelve solo a 1.80. Verificalo en el bloque que sigue.


-- ════════════════════════════════════════════════════════════
-- [F.7d]
-- ════════════════════════════════════════════════════════════
select case when peso_kg = 1.80 then 'OK — Coco volvió solo'
            else 'MAL — Coco quedó sin peso'
       end as resultado
from mascota where id_mascota = 9;


-- ════════════════════════════════════════════════════════════
-- [F.8] cerrar_tratamiento: plural y singular
-- ════════════════════════════════════════════════════════════
select case
         when cerrar_tratamiento(4) = 'Consulta 4: 2 medicamentos, 17 días en total'
          and cerrar_tratamiento(2) = 'Consulta 2: 1 medicamento, 5 días en total'
         then 'OK — anda el plural y el singular'
         when cerrar_tratamiento(2) like '%1 medicamentos%'
         then 'MAL — falta resolver el singular'
         else 'MAL — devolvió: ' || cerrar_tratamiento(4)
       end as resultado;


-- ════════════════════════════════════════════════════════════
-- [F.8b] Existe pero no recetó nada
-- ════════════════════════════════════════════════════════════
select cerrar_tratamiento(1);
-- TIENE QUE DAR ERROR: "La consulta 1 no tiene recetas"
-- Si devuelve "Consulta 1: 0 medicamentos, 0 días", resolviste la
-- verificación con found — y found siempre da true cuando la
-- consulta es un count(). Mirá el valor, no si vino una fila.


-- ════════════════════════════════════════════════════════════
-- [F.8c] No existe
-- ════════════════════════════════════════════════════════════
select cerrar_tratamiento(99);
-- TIENE QUE DAR ERROR: "No existe la consulta 99"


-- ════════════════════════════════════════════════════════════
-- [F.9] El aumento de 5 kg: tu bloque NO tiene que cortar
-- ════════════════════════════════════════════════════════════
select case
         when (select peso_kg from mascota where id_mascota = 8)  = 17.00
          and (select peso_kg from mascota where id_mascota = 9)  = 6.80
          and (select peso_kg from mascota where id_mascota = 10) = 20.00
         then 'OK — los tres subieron 5 kg'
         else 'MAL — revisá el where del update'
       end as resultado;


-- ════════════════════════════════════════════════════════════
-- [F.9b] Ahora el mismo bloque con 100 en lugar de 5:
--        tiene que cortar. Corré el chequeo después.
-- ════════════════════════════════════════════════════════════
select case
         when (select peso_kg from mascota where id_mascota = 8)  = 17.00
          and (select peso_kg from mascota where id_mascota = 9)  = 6.80
          and (select peso_kg from mascota where id_mascota = 10) = 20.00
         then 'OK — el error deshizo el aumento'
         else 'MAL — los pesos cambiaron: tu bloque no cortó'
       end as resultado;


-- ════════════════════════════════════════════════════════════
-- [F.9c] Dejá la base como estaba
-- ════════════════════════════════════════════════════════════
update mascota set peso_kg = 12.00 where id_mascota = 8;
update mascota set peso_kg = 1.80  where id_mascota = 9;
update mascota set peso_kg = 15.00 where id_mascota = 10;


-- ════════════════════════════════════════════════════════════
-- [F.10] El error que viaja hacia arriba
--        Tu bloque tiene que haber cortado con
--        "Peso fuera de rango: 150 kg".
-- ════════════════════════════════════════════════════════════
select case when diagnostico = 'Sano'
            then 'OK — el error de la función deshizo el update del bloque'
            when diagnostico = 'En revisión'
            then 'MAL — el update quedó: ¿tu bloque llamó de verdad a '
                 || 'registrar_peso, o le pasaste un peso válido?'
            else 'MAL — quedó: ' || diagnostico
       end as resultado
from consulta where id_consulta = 1;


-- ════════════════════════════════════════════════════════════
-- CONTROL FINAL: ¿quedó la base como al principio?
--
-- Si algo dice MAL, volvé a correr 01_esquema.sql y 02_datos.sql:
-- es más rápido que buscar qué quedó cambiado.
-- ════════════════════════════════════════════════════════════
select case
         when (select count(*) from dueno)    = 5
          and (select count(*) from mascota)  = 10
          and (select count(*) from consulta) = 16
          and (select count(*) from receta)   = 11
          and (select peso_kg from mascota where id_mascota = 1) = 28.50
          and (select peso_kg from mascota where id_mascota = 8) = 12.00
          and (select diagnostico from consulta where id_consulta = 1) = 'Sano'
         then 'OK — la base quedó como al principio'
         else 'MAL — algo quedó cambiado'
       end as resultado;
