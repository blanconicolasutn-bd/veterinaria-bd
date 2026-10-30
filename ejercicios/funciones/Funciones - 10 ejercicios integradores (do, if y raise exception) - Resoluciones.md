# Resolución — 10 ejercicios integradores de funciones

Resolución de [`Funciones - 10 ejercicios integradores (do, if y raise exception).md`](Funciones%20-%2010%20ejercicios%20integradores%20(do,%20if%20y%20raise%20exception).md). Conviene intentarlos antes de mirarla.

Todas las funciones están escritas con `create or replace`, así que se pueden volver a correr las veces que haga falta.

Al final de cada ejercicio hay un **Error común**: casi siempre es más útil que la solución.

---

## Ejercicio 1 — El peso que no puede ser

### Enunciado

Un bloque `do` que le cargue a Rocky (`id_mascota = 1`) un peso de 150 kg y que, si el peso queda fuera del rango 0.05 – 100, corte con `Peso fuera de rango: <valor> kg`. Verificar después qué quedó guardado y explicar por qué.

### Solución

```sql
do $$
declare
  v_peso mascota.peso_kg%type := 150;
begin
  update mascota set peso_kg = v_peso where id_mascota = 1;

  if v_peso < 0.05 or v_peso > 100 then
    raise exception 'Peso fuera de rango: % kg', v_peso;
  end if;
end $$;
```

```
ERROR: Peso fuera de rango: 150.00 kg
```

Y en otra ejecución:

```sql
select id_mascota, nombre, peso_kg from mascota where id_mascota = 1;
```

| id_mascota | nombre | peso_kg |
|---|---|---|
| 1 | Rocky | 28.50 |

### La respuesta

El `update` **se ejecutó**: durante un instante Rocky pesó 150 kg. Pero el `update` y el `raise exception` están en el mismo bloque, o sea en la misma transacción, y cuando el bloque corta con un error Postgres deshace todo lo que esa transacción hizo.

Es un `rollback` que nadie escribió: **lo disparó el error**.

### Error común

Poner la validación **después** del `end` del bloque, en otra sentencia. Ahí el `do` termina bien, el `update` queda confirmado, y la validación llega tarde: Rocky ya pesa 150 kg y no hay nada que deshacer.

Lo que protege el dato no es la validación, es que la validación esté **adentro de la misma transacción** que la modificación.

---

## Ejercicio 2 — La misma validación, pero reutilizable

### Enunciado

Convertir el ejercicio 1 en `registrar_peso(p_id int, p_peso decimal)`, que corte si la mascota no existe o si el peso está fuera de rango, y que si está todo bien actualice y devuelva `Rocky: 28.50 kg → 30.00 kg`.

### Solución

```sql
create or replace function registrar_peso(p_id int, p_peso decimal)
returns text as $$
declare
  v_nombre  mascota.nombre%type;
  v_anterior mascota.peso_kg%type;
begin
  select nombre, peso_kg into v_nombre, v_anterior
  from mascota where id_mascota = p_id;

  if not found then
    raise exception 'No existe la mascota %', p_id;
  end if;

  if p_peso < 0.05 or p_peso > 100 then
    raise exception 'Peso fuera de rango: % kg', p_peso;
  end if;

  update mascota set peso_kg = p_peso where id_mascota = p_id;

  return v_nombre || ': ' || v_anterior || ' kg → ' || p_peso || ' kg';
end $$ language plpgsql;
```

### Resultado

| llamada | devuelve |
|---|---|
| `registrar_peso(1, 30.00)` | `Rocky: 28.50 kg → 30.00 kg` |
| `registrar_peso(1, 150)` | `ERROR: Peso fuera de rango: 150 kg` |
| `registrar_peso(99, 30)` | `ERROR: No existe la mascota 99` |

### El orden de los controles

Los dos `if` van **antes** del `update`, y en ese orden. Primero se pregunta si la mascota existe, porque si no existe no tiene sentido validar nada más; después se valida el dato que viene de afuera; y recién al final se modifica.

Acá, a diferencia del ejercicio 1, la validación **sí** se puede hacer antes, porque no depende del resultado del `update`. Cuando se puede, se hace antes: es más barato y el mensaje de error es más claro.

### Error común

Devolver el peso anterior leyéndolo **después** del `update`:

```sql
update mascota set peso_kg = p_peso where id_mascota = p_id;
select peso_kg into v_anterior from mascota where id_mascota = p_id;   -- ✗
```

Ya es tarde: el valor viejo lo acaba de pisar el `update`, y la función devuelve `30.00 kg → 30.00 kg`. El estado anterior hay que guardarlo **antes** de modificarlo.

---

## Ejercicio 3 — El nivel de riesgo

### Enunciado

`riesgo_mascota(p_id int)` que devuelva `'alto'` si la mascota tiene 8 años o más **y** pesa más de 20 kg, `'medio'` si cumple una sola condición, y `'bajo'` si no cumple ninguna. Si no existe, cortar.

### Solución

```sql
create or replace function riesgo_mascota(p_id int)
returns text as $$
declare
  v_fila    mascota%rowtype;
  v_mayor   boolean;
  v_pesada  boolean;
begin
  select * into v_fila from mascota where id_mascota = p_id;

  if not found then
    raise exception 'No existe la mascota %', p_id;
  end if;

  v_mayor  := extract(year from age(v_fila.fecha_nac)) >= 8;
  v_pesada := v_fila.peso_kg > 20;

  if v_mayor and v_pesada then
    return 'alto';
  elsif v_mayor or v_pesada then
    return 'medio';
  else
    return 'bajo';
  end if;
end $$ language plpgsql;
```

Las dos variables booleanas hacen el trabajo: se calcula **una vez** cada condición y el `if` queda en tres líneas legibles. Sin ellas, la primera rama repite las dos comparaciones y la segunda las repite otra vez.

### Resultado

| nombre | peso_kg | edad | riesgo |
|---|---|---|---|
| Rocky | 35.00 | 8 | alto |
| Bruno | 15.00 | 2 | bajo |
| Coco | 1.80 | 3 | bajo |
| Luna | 3.80 | 4 | bajo |
| Michi | 4.20 | 5 | bajo |
| Michi | 4.50 | 5 | bajo |
| Pipo | 0.30 | 5 | bajo |
| Toby | 6.00 | 6 | bajo |
| Nina | 12.00 | 9 | medio |
| Rocky | 28.50 | 7 | medio |

El `order by riesgo` los ordena alfabéticamente —`alto`, `bajo`, `medio`—, no por gravedad.

Los dos `medio` llegan por caminos distintos: **Nina** por la edad y **Rocky** (el de 28.50) por el peso. Que la misma categoría se alcance de dos formas es justamente lo que hace falta el `or`.

### Error común

Escribir el `if` con las condiciones sueltas y en el orden natural de lectura:

```sql
if v_mayor then
  return 'medio';
elsif v_pesada then
  return 'medio';
elsif v_mayor and v_pesada then     -- ✗ nunca se llega
  return 'alto';
```

Rocky (el de 35 kg y 8 años) entra por la primera rama y sale `medio`. En una cadena de `if` **gana la primera condición que se cumple**, así que la más exigente va primero. Es el mismo error que clasificar por peso de menor a mayor.

---

## Ejercicio 4 — Recetar sin repetir

### Enunciado

`recetar(p_consulta int, p_medicamento int, p_dosis varchar, p_dias int)` con tres controles: consulta inexistente, medicamento ya recetado en esa consulta, y duración menor o igual a cero. Si está todo bien, insertar y devolver `Recetado: <nombre> por <n> días`.

### Solución

```sql
create or replace function recetar(p_consulta int, p_medicamento int,
                                   p_dosis varchar, p_dias int)
returns text as $$
declare
  v_nombre medicamento.nombre%type;
  v_existe int;
begin
  select 1 into v_existe
  from consulta where id_consulta = p_consulta;

  if not found then
    raise exception 'No existe la consulta %', p_consulta;
  end if;

  select 1 into v_existe
  from receta
  where id_consulta = p_consulta
    and id_medicamento = p_medicamento;

  if found then
    raise exception 'El medicamento % ya está recetado en la consulta %',
                    p_medicamento, p_consulta;
  end if;

  if p_dias <= 0 then
    raise exception 'La duración tiene que ser mayor a cero';
  end if;

  select nombre into v_nombre
  from medicamento where id_medicamento = p_medicamento;

  insert into receta (id_consulta, id_medicamento, dosis, duracion_dias)
  values (p_consulta, p_medicamento, p_dosis, p_dias);

  return 'Recetado: ' || v_nombre || ' por ' || p_dias || ' días';
end $$ language plpgsql;
```

Notar los dos usos opuestos de `found`: el primero pregunta `if not found` (la consulta **tiene** que existir) y el segundo `if found` (la receta **no** tiene que existir). Es la misma herramienta para dos preguntas contrarias.

### Resultado

| llamada | devuelve |
|---|---|
| `recetar(1, 3, '1 ampolla', 5)` | `Recetado: Ivermectina por 5 días` |
| `recetar(1, 3, '1 ampolla', 5)` | `ERROR: El medicamento 3 ya está recetado en la consulta 1` |
| `recetar(1, 7, '100mg cada 12hs', 0)` | `ERROR: La duración tiene que ser mayor a cero` |
| `recetar(99, 7, '100mg', 5)` | `ERROR: No existe la consulta 99` |

### Error común

Confiar en que la clave primaria ya protege del duplicado y no escribir el segundo control. Es cierto que protege —el `insert` va a fallar igual—, pero el error que recibe el usuario es:

```
ERROR: duplicate key value violates unique constraint "receta_pkey"
```

Eso no le dice nada a nadie que no conozca la base. La restricción garantiza que **el dato no se rompa**; la validación explícita garantiza que **el mensaje se entienda**. Las dos cosas van juntas: la primera no reemplaza a la segunda.

---

## Ejercicio 5 — Una consulta nueva, validada

### Enunciado

`nueva_consulta(p_mascota int, p_matricula int, p_motivo varchar)` que registre una consulta con la fecha de hoy y devuelva el `id_consulta` generado, validando mascota, veterinario y motivo no vacío.

### Solución

```sql
create or replace function nueva_consulta(p_mascota int, p_matricula int,
                                          p_motivo varchar)
returns int as $$
declare
  v_id    consulta.id_consulta%type;
  v_dummy int;
begin
  select 1 into v_dummy from mascota where id_mascota = p_mascota;
  if not found then
    raise exception 'No existe la mascota %', p_mascota;
  end if;

  select 1 into v_dummy from veterinario where matricula = p_matricula;
  if not found then
    raise exception 'No existe el veterinario %', p_matricula;
  end if;

  if trim(coalesce(p_motivo, '')) = '' then
    raise exception 'El motivo no puede estar vacío';
  end if;

  insert into consulta (id_mascota, matricula, fecha, motivo)
  values (p_mascota, p_matricula, current_date, p_motivo)
  returning id_consulta into v_id;

  return v_id;
end $$ language plpgsql;
```

La pieza nueva es **`returning ... into`**: el `insert` devuelve el `id_consulta` que acaba de generar la base y lo deja en la variable, sin tener que ir a buscarlo con otra consulta.

### Resultado

| llamada | devuelve |
|---|---|
| `nueva_consulta(1, 1001, 'Control de peso')` | un número: `17`, `18`… |
| `nueva_consulta(1, 9999, 'Control de peso')` | `ERROR: No existe el veterinario 9999` |
| `nueva_consulta(1, 1001, '   ')` | `ERROR: El motivo no puede estar vacío` |

**El número no es predecible, y eso está bien.** Hay 16 consultas cargadas, así que uno esperaría un 17 — pero puede salir 18, 19 o 23. Cada `insert` que se intentó antes sobre `consulta`, **aunque haya fallado o se haya deshecho con un `rollback`**, se llevó su número: las secuencias no vuelven atrás.

Es a propósito. Si una secuencia se deshiciera junto con la transacción, dos personas insertando al mismo tiempo podrían recibir el mismo id. El precio de evitarlo son los huecos, y conviene asumirlos desde el principio: **un `id` es un identificador, no un contador**. Si alguien necesita "la consulta número 5 del mes", eso es una columna aparte, calculada, no la clave primaria.

### Por qué `trim(coalesce(...))`

Son dos problemas distintos y hay que cubrir los dos:

| El motivo viene así | `p_motivo = ''` | `trim(coalesce(p_motivo,'')) = ''` |
|---|---|---|
| `null` | `null` — ni verdadero ni falso | `true` ✓ |
| `'   '` | `false` — "no está vacío" | `true` ✓ |
| `'Control'` | `false` | `false` ✓ |

`coalesce` convierte el `null` en texto vacío, porque en SQL **comparar algo con `null` no da falso, da `null`**, y un `if` con condición `null` se va por el `else`. Y `trim` saca los espacios, porque tres espacios no son un motivo.

### Error común

Validar el motivo con `if p_motivo is null or p_motivo = ''`. Cubre el `null` pero deja pasar `'   '`, que es el caso que más se cuela en un formulario real.

---

## Ejercicio 6 — Cerrar las consultas de una mascota

### Enunciado

Un bloque `do` que le ponga el diagnóstico `'Cerrado por control'` a todas las consultas sin diagnóstico de la mascota 1 y que, si no modificó ninguna fila, corte con `La mascota 1 no tiene consultas abiertas`. Correrlo dos veces y explicar qué cambia.

### Solución

```sql
do $$
begin
  update consulta
  set diagnostico = 'Cerrado por control'
  where id_mascota = 1
    and diagnostico is null;

  if not found then
    raise exception 'La mascota 1 no tiene consultas abiertas';
  end if;
end $$;
```

Con los datos tal como vienen, la primera corrida ya da:

```
ERROR: La mascota 1 no tiene consultas abiertas
```

Las tres consultas de la mascota 1 (las número 1, 2 y 14) tienen diagnóstico cargado, así que el `update` no toca ninguna fila.

### Para probar el camino que sí funciona

```sql
-- dejamos una consulta abierta
update consulta set diagnostico = null where id_consulta = 1;
```

Corriendo ahora el bloque, **no da error**. Y si se lo corre una segunda vez, vuelve a dar el error: ya no queda ninguna abierta.

```sql
-- dejar la base como estaba
update consulta set diagnostico = 'Sano' where id_consulta = 1;
```

### La respuesta

Entre la primera corrida y la segunda cambia el **estado de la base**, no el código. La primera vez el `update` encuentra una fila y `found` queda en `true`; la segunda ya no queda nada que cerrar, `found` queda en `false` y salta el error.

Es la diferencia entre *"la sentencia se ejecutó"* y *"la sentencia hizo algo"*. Un `update` que no toca ninguna fila **no es un error** para Postgres: es una operación exitosa sobre cero filas. Si para el negocio sí es un problema, hay que preguntarlo con `found`.

### Error común

Usar este bloque como si fuera idempotente —"lo corro de nuevo por las dudas"— y que la segunda corrida rompa un proceso entero por un error que, en realidad, significa "ya estaba hecho".

Cuando volver a ejecutar algo es legítimo, el `raise exception` sobra: ahí conviene no cortar, o cortar solo si el estado es **de verdad** inconsistente.

---

## Ejercicio 7 — La ficha que exige el peso cargado

### Enunciado

`control_peso(p_id int)` que devuelva `Rocky (Perro) — 28.50 kg — riesgo medio`, usando `%rowtype`, con un error si la mascota no existe y otro distinto si existe pero no tiene el peso cargado, y tomando el riesgo de la función del ejercicio 3.

### Solución

```sql
create or replace function control_peso(p_id int)
returns text as $$
declare
  v_fila mascota%rowtype;
begin
  select * into v_fila from mascota where id_mascota = p_id;

  if not found then
    raise exception 'No existe la mascota %', p_id;
  end if;

  if v_fila.peso_kg is null then
    raise exception 'La mascota % no tiene peso cargado', v_fila.nombre;
  end if;

  return v_fila.nombre || ' (' || v_fila.especie || ') — '
      || v_fila.peso_kg || ' kg — riesgo '
      || riesgo_mascota(p_id);
end $$ language plpgsql;
```

Una función puede llamar a otra igual que lo haría un `select`: `riesgo_mascota(p_id)` se usa directamente adentro de la concatenación.

### Resultado

| llamada | devuelve |
|---|---|
| `control_peso(1)` | `Rocky (Perro) — 28.50 kg — riesgo medio` |
| `control_peso(99)` | `ERROR: No existe la mascota 99` |
| `control_peso(9)` con el peso en `null` | `ERROR: La mascota Coco no tiene peso cargado` |

### La respuesta: por qué dos errores

Porque son **dos problemas con dos responsables distintos**:

- *No existe la mascota 99* → el que llamó se equivocó de id. Se arregla corrigiendo la llamada.
- *Coco no tiene peso cargado* → el id está bien, la mascota existe; lo que falta es un dato. Se arregla cargando el peso.

Si los dos casos dieran el mismo mensaje, el que lo recibe no sabría cuál de las dos cosas hacer. Y fijate que el segundo mensaje puede decir **el nombre** de la mascota, justamente porque la fila existe: eso es imposible en el primero.

Es, otra vez, la diferencia entre `found` (¿vino una fila?) y `is null` (¿el dato está vacío?) — pero acá las dos preguntas conviven en la misma función.

### Error común

Resolver los dos casos con un solo control sobre el peso:

```sql
if v_fila.peso_kg is null then
  raise exception 'No existe la mascota %', p_id;   -- ✗
end if;
```

Con la mascota 99 funciona de casualidad: no vino ninguna fila, `v_fila.peso_kg` queda en `null` y el mensaje sale correcto. Pero con Coco **miente**: dice que no existe una mascota que existe. Es el peor tipo de error, porque manda a buscar el problema al lugar equivocado.

---

## Ejercicio 8 — El tratamiento completo

### Enunciado

`cerrar_tratamiento(p_consulta int)` que devuelva `Consulta 4: 2 medicamentos, 17 días en total`, con un error si la consulta no existe y otro si existe pero no recetó nada, y con el singular resuelto.

### Solución

```sql
create or replace function cerrar_tratamiento(p_consulta int)
returns text as $$
declare
  v_dummy int;
  v_cuantos int;
  v_dias    int;
begin
  select 1 into v_dummy
  from consulta where id_consulta = p_consulta;

  if not found then
    raise exception 'No existe la consulta %', p_consulta;
  end if;

  select count(*), coalesce(sum(duracion_dias), 0)
    into v_cuantos, v_dias
  from receta where id_consulta = p_consulta;

  if v_cuantos = 0 then
    raise exception 'La consulta % no tiene recetas', p_consulta;
  end if;

  return 'Consulta ' || p_consulta || ': ' || v_cuantos
      || case when v_cuantos = 1 then ' medicamento, ' else ' medicamentos, ' end
      || v_dias || ' días en total';
end $$ language plpgsql;
```

### Resultado

| llamada | devuelve |
|---|---|
| `cerrar_tratamiento(4)` | `Consulta 4: 2 medicamentos, 17 días en total` |
| `cerrar_tratamiento(2)` | `Consulta 2: 1 medicamento, 5 días en total` |
| `cerrar_tratamiento(1)` | `ERROR: La consulta 1 no tiene recetas` |
| `cerrar_tratamiento(99)` | `ERROR: No existe la consulta 99` |

### La trampa de `found`

La primera verificación **sí** se hace con `found`: el `select 1 from consulta` o trae una fila o no trae ninguna.

La segunda **no se puede hacer con `found`**, y por eso se pregunta `if v_cuantos = 0`. La razón: `count(*)` es una función de agregación, y **una agregación sin `group by` siempre devuelve exactamente una fila**, aunque no haya ni una receta. Devuelve un `0`, pero devuelve una fila — así que `found` queda en `true` siempre.

La regla que queda: `found` sirve para saber si **vino una fila**. Cuando la consulta es una agregación, siempre viene una, y hay que mirar **el valor**.

### El `case` adentro del `return`

El singular se resuelve con un `case`, no con un `if`. Es el tema de la clase puesto en práctica: el `case` **devuelve un valor** y por eso puede ir en el medio de una concatenación; un `if` no podría, porque decide sentencias, no produce valores.

### Error común

Escribir el `coalesce` solo sobre el `sum` y olvidarse de que `count` ya devuelve 0 por su cuenta — o al revés, ponerle `coalesce` al `count`, que nunca devuelve `null`. `count(*)` cuenta filas y sobre cero filas cuenta cero; `sum()` sobre cero filas devuelve `null`. Son dos agregaciones que se comportan distinto con el conjunto vacío, y conviene tenerlo claro.

---

## Ejercicio 9 — El control que mira el conjunto

### Enunciado

Un bloque `do` que les sume 5 kg a todas las mascotas del dueño 4 y que, si después del aumento alguna queda por encima de 100 kg, corte con `El aumento deja a <nombre> en <valor> kg`.

### Solución

```sql
do $$
declare
  v_aumento  decimal(5,2) := 5;
  v_nombre   mascota.nombre%type;
  v_peso     mascota.peso_kg%type;
begin
  update mascota
  set peso_kg = peso_kg + v_aumento
  where id_dueno = 4;

  select nombre, peso_kg into v_nombre, v_peso
  from mascota
  where id_dueno = 4 and peso_kg > 100
  order by peso_kg desc
  limit 1;

  if found then
    raise exception 'El aumento deja a % en % kg', v_nombre, v_peso;
  end if;
end $$;
```

Con `v_aumento := 5` no da error. Verificando después:

```sql
select id_mascota, nombre, peso_kg
from mascota where id_dueno = 4 order by id_mascota;
```

| id_mascota | nombre | peso_kg |
|---|---|---|
| 8 | Nina | 17.00 |
| 9 | Coco | 6.80 |
| 10 | Bruno | 20.00 |

Cambiando el aumento a 100, y partiendo de los pesos que quedaron recién:

```
ERROR: El aumento deja a Bruno en 120.00 kg
```

Y verificando otra vez, los pesos **siguen en 17.00, 6.80 y 20.00**: el segundo `update` no dejó rastro.

### Dejar la base como estaba

```sql
update mascota set peso_kg = 12.00 where id_mascota = 8;
update mascota set peso_kg = 1.80  where id_mascota = 9;
update mascota set peso_kg = 15.00 where id_mascota = 10;
```

### Lo que hay que entender acá

La validación **no se puede hacer antes**: depende del resultado del `update`, porque cada mascota parte de un peso distinto. Habría que calcular a mano, mascota por mascota, lo que el `update` va a hacer — y eso es escribir dos veces la misma lógica, que es la forma más confiable de que las dos versiones se contradigan.

Modificar primero y controlar después es más simple y más seguro, **pero solo porque el error deshace todo**. Fuera de una transacción, este mismo orden sería un desastre.

Notar también que el control mira **el conjunto**, no el valor que entró por parámetro: busca si *alguna* fila quedó mal. Por eso el `select ... limit 1` con `order by peso_kg desc`, que trae la peor, y el `if found`, que pregunta si apareció alguna.

### Error común

Validar solo el parámetro:

```sql
if v_aumento > 50 then
  raise exception 'Aumento demasiado grande';   -- ✗
end if;
```

No alcanza. Un aumento de 5 kg es razonable para Bruno y un disparate para Pipo, que pesa 0.30. El límite no está en cuánto se suma, está en **dónde queda cada fila** — y eso solo se sabe después de sumar.

---

## Ejercicio 10 — El error que viaja hacia arriba

### Enunciado

Un bloque `do` que le ponga el diagnóstico `'En revisión'` a la consulta 1 y después llame a `registrar_peso(1, 150)`, que corta con un error. Verificar qué quedó del diagnóstico y explicar qué pasó.

### Solución

```sql
do $$
declare
  v_resultado text;
begin
  update consulta
  set diagnostico = 'En revisión'
  where id_consulta = 1;

  v_resultado := registrar_peso(1, 150);
end $$;
```

```
ERROR: Peso fuera de rango: 150 kg
CONTEXT: PL/pgSQL function registrar_peso(integer,numeric) ... at RAISE
         SQL statement "SELECT registrar_peso(1, 150)"
         PL/pgSQL function inline_code_block ... at assignment
```

Vale la pena leer el `CONTEXT`: dice de abajo hacia arriba por dónde pasó el error. Nació en `registrar_peso`, salió por el `select` que la llamó, y terminó en el bloque `do` —que Postgres llama `inline_code_block`—.

Y en otra ejecución:

```sql
select id_consulta, diagnostico from consulta where id_consulta = 1;
```

| id_consulta | diagnostico |
|---|---|
| 1 | Sano |

### La respuesta

**Quién lo lanzó:** la función `registrar_peso`, en su `raise exception`. Ella recibió un peso de 150 y se negó.

**Quién lo recibió:** nadie. El bloque `do` no tiene ningún manejo de excepciones, así que el error lo atraviesa y sigue subiendo hasta el editor, que es el que lo muestra.

**Por qué se deshizo el `update`:** porque la función y el bloque que la llamó **corren en la misma transacción**. Una función no abre una transacción propia: se ejecuta dentro de la de quien la llamó. Entonces, cuando el error aborta esa transacción, se va todo lo que hubiera adentro — incluido un `update` sobre `consulta`, una tabla que `registrar_peso` ni siquiera menciona.

Ése es el punto del ejercicio: **el alcance del `rollback` no es la función, es la transacción**.

Leído al derecho, es una muy buena noticia: alcanza con que la función valide bien su parte para que todo lo que la rodea quede protegido. Y leído al revés, es la advertencia: una función que lanza un error puede tirar abajo trabajo que no es suyo, así que el `raise exception` se usa cuando de verdad hay que cortar, no para avisar.

### Error común

Esperar que el `update` de la consulta sobreviva *"porque la función falló después"*. El orden no importa: no hay un punto de confirmación entre una cosa y la otra. Lo que confirma es el final del bloque, y ese final no llegó.

Para que el `update` sobreviviera habría que confirmarlo **antes** de llamar a la función, y eso una función no lo puede hacer: necesita un procedimiento con su `commit`. Que es exactamente la diferencia entre función y procedimiento.
