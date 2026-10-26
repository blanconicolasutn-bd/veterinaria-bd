# Diseño y Administración de Base de Datos

## Guía de ejercicios — Transacciones (Unidad IV bis)

Diez ejercicios sobre la base de **la veterinaria**. Antes de empezar hay que tener corridos, en este orden, `01_esquema.sql` y `02_datos.sql`.

Ocho se resuelven con `begin`, `commit` y `rollback`. Los **dos últimos** necesitan `savepoint`.

---

### Cómo correrlos, que acá importa

**Cada ejercicio se corre como un solo bloque**: se selecciona entero con el mouse y se ejecuta con `Ctrl+Enter` (`Cmd+Enter` en Mac).

No se puede partir una transacción en dos ejecuciones —correr el `begin` por un lado y el `commit` por otro— porque **cada ejecución del editor es independiente**: la transacción que abriste en la primera no sigue abierta en la segunda.

En el ejercicio 1 hay una verificación para confirmar que tu editor se comporta así. Conviene hacerla antes que nada.

**Cuando algo falla, lo que sigue no se ejecuta.** El editor manda el bloque entero de una sola vez, así que la primera sentencia que da error corta ahí: las que venían después ni se intentan. No es un problema, es parte de lo que vamos a estudiar — los ejercicios **3** y **9** son justamente sobre eso.

**Supabase muestra solo el último `select` de cada ejecución.** Por eso la guía usa siempre el mismo esquema: **un solo `select` adentro de la transacción** —el que muestra lo que la transacción hizo— y, cuando hace falta comprobar que el `rollback` funcionó, **otra ejecución aparte** con el `select` de control. Nunca dos `select` en el mismo bloque esperando ver los dos.

**La base queda como estaba.** Casi todos los ejercicios terminan en `rollback`, justamente para no ensuciar los datos. Los que confirman con `commit` traen al final las sentencias para dejar todo como estaba.

---

### Las tablas

| Tabla | Clave | Columnas |
|---|---|---|
| `dueno` | `id_dueno` | `dni`, `apellido`, `nombre`, `telefono`, `domicilio` |
| `veterinario` | `matricula` | `apellido`, `nombre`, `especialidad` |
| `medicamento` | `id_medicamento` | `nombre`, `droga`, `presentacion` |
| `mascota` | `id_mascota` | `id_dueno` → dueno, `nombre`, `especie`, `raza`, `fecha_nac`, `peso_kg` |
| `consulta` | `id_consulta` | `id_mascota` → mascota, `matricula` → veterinario, `fecha`, `motivo`, `diagnostico` |
| `receta` | `id_consulta` + `id_medicamento` | `dosis`, `frecuencia`, `duracion_dias` |

---

### Repaso rápido

| Sentencia | Qué hace |
|---|---|
| `begin;` | Abre una transacción |
| `commit;` | Confirma todo lo que la transacción hizo |
| `rollback;` | Deshace todo lo que la transacción hizo |
| `savepoint <nombre>;` | Marca un punto intermedio adentro de la transacción |
| `rollback to <nombre>;` | Vuelve a ese punto **sin cerrar** la transacción |
| `release savepoint <nombre>;` | Descarta la marca, sin deshacer nada |

Lo que define una transacción: **o pasa todo, o no pasa nada**.

---

## Ejercicio 1 — Un dueño nuevo con su mascota

Dar de alta al dueño **Quiroga, Ernesto** (DNI 27888999, teléfono 1145559999, domicilio Sarmiento 1500) **y** a su perro **Duque** (ovejero alemán, nacido el 12/03/2022, 32 kg), en una sola transacción.

**Se pide:**

1. Escribir la transacción completa, con `begin` y `commit`.
2. El `id_dueno` lo genera la base, así que la mascota tiene que tomarlo sin escribirlo a mano.
3. Verificar que quedaron los dos.
4. Dejar la base como estaba.

**La verificación del editor:** antes de hacer el ejercicio, correr este bloque solo. Si al final `Duque` **no** aparece, tu editor respeta el `rollback` y todo lo demás de la guía va a funcionar.

```sql
begin;
insert into dueno (dni, apellido, nombre)
values ('99999999', 'Prueba', 'Editor');
rollback;

select count(*) from dueno where dni = '99999999';
```

**Tiene que devolver** `0`.

---

## Ejercicio 2 — El alta de la que uno se arrepiente

Repetir el alta del ejercicio 1, pero **terminarla con `rollback`** en lugar de `commit`.

**Se pide:**

1. En la **primera ejecución**: el `begin`, el `insert`, un `select` que cuente al dueño nuevo, y el `rollback`.
2. En una **segunda ejecución**: el mismo `select`.

**Tiene que devolver** `1` la primera vez y `0` la segunda.

**Para explicar en dos renglones:** si el `select` de adentro lo encontró, ¿dónde estaba esa fila?

---

## Ejercicio 3 — La transacción que se aborta

En una sola ejecución, y dentro de una misma transacción:

1. Insertar una mascota con `id_dueno = 99`, que **no existe**.
2. A continuación, insertar una mascota **válida**, del dueño 1, llamada `Lola`.
3. Cerrar con `commit`.

Después, **en otra ejecución**, verificar qué quedó:

```sql
select count(*) as cuantas
from mascota where nombre in ('Fantasma', 'Lola');
```

**Se pide:**

- Copiar el error que devuelve el bloque.
- **¿Cuántos errores viste?** Son dos `insert` y uno de ellos es correcto: la respuesta a esa pregunta explica sola por qué `Lola` tampoco quedó.
- Decir cuánto devolvió el `select` de control, y por qué.

**Tiene que devolver** `0`.

---

## Ejercicio 4 — Borrar una consulta que tiene recetas

Borrar la consulta **4** con todo lo que recetó.

**Se pide:**

1. En una ejecución **aparte**, intentar borrar solo la consulta y copiar el error.
2. Después, resolverlo en una transacción, en el orden correcto.
3. Verificar, dentro de esa transacción, que no quedó ninguna receta de la consulta 4.
4. Terminar con `rollback`: la consulta 4 la necesitamos después.

---

## Ejercicio 5 — La mascota cambia de dueño

Michi (`id_mascota = 2`) pasa a estar a nombre de Pérez, Juan (`id_dueno = 2`).

**Se pide:**

1. En la **primera ejecución**: la transacción con el `update`, un `select` que cuente las mascotas de los dueños 1 y 2, y el `rollback`.
2. En una **segunda ejecución**: el mismo `select`, para comprobar que volvió todo atrás.

**Tiene que devolver** 1 y 3 la primera vez, y 2 y 2 la segunda.

---

## Ejercicio 6 — Una consulta con su receta

Registrar una consulta nueva para Rocky (`id_mascota = 1`) con la veterinaria Ramírez (`matricula = 1001`), fecha de hoy, motivo *"Control de peso"*, y recetarle **Meloxicam** (`id_medicamento = 2`), dosis *"0.1mg/kg cada 24hs"*, 5 días.

**Se pide:**

1. Hacerlo en una sola transacción: si la receta falla, la consulta tampoco tiene que quedar.
2. El `id_consulta` lo genera la base: la receta tiene que tomarlo sin escribirlo a mano.
3. Verificar que la consulta quedó con su receta, y terminar con `rollback`.

---

## Ejercicio 7 — El `update` sin `where`

Correr, dentro de una transacción, un `update` que le ponga `peso_kg = 10` a la tabla `mascota` **sin cláusula `where`**.

**Se pide:**

1. Antes del `commit`, consultar cuántas mascotas tienen ahora `peso_kg = 10`.
2. Con ese número a la vista, decidir: ¿`commit` o `rollback`?
3. Explicar en un renglón qué habría pasado si esto se corría sin `begin`.

---

## Ejercicio 8 — Confirmar solo si tocó lo que tenía que tocar

Hay que subirle 1 kg el peso a **todos los perros del dueño 3**. El dueño 3 tiene tres mascotas, pero **no todas son perros**.

**Se pide:**

1. Escribir la transacción con el `update`.
2. Antes de cerrarla, mostrar **qué filas quedaron modificadas**.
3. Si son más de las esperadas, deshacer. Dejar escrito en un comentario cuántas esperabas y cuántas fueron.
4. Terminar con `rollback` en cualquier caso.

---

## Ejercicio 9 — Tres recetas y una repetida (`savepoint`)

Hay que agregarle a la consulta **1** tres medicamentos:

| medicamento | dosis | frecuencia | días |
|---|---|---|---|
| 3 (Ivermectina) | 1 ampolla | única | 1 |
| 7 (Doxiciclina) | 100mg cada 12hs | 2 veces al día | 10 |
| 3 (Ivermectina) | 1 ampolla | única | 1 |

El tercero **está repetido**: `receta` tiene clave primaria `(id_consulta, id_medicamento)`.

**Primera parte — el problema.** Cargar los tres con tres `insert` sueltos, dentro de una transacción. Verificar después cuántas recetas quedó teniendo la consulta 1.

**Tiene que devolver** `0`: el error del tercero se llevó puestos los dos primeros.

**Segunda parte — la solución.** Lograr que **el repetido falle pero los otros dos queden**.

Para eso hace falta una pieza nueva. En un bloque `do`, un `begin ... end` interno puede llevar un `exception`:

```sql
begin
  <la sentencia riesgosa>;
exception when unique_violation then
  <qué hacer si falló>;
end;
```

Ese bloque interno **es un savepoint**: Postgres lo marca solo. Si la sentencia de adentro falla, se deshace lo que ese bloque hizo —nada más que eso— y la transacción sigue viva. Es la misma idea de `savepoint` + `rollback to`, escrita como código.

**Se pide:**

1. Escribir el bloque `do` con los tres `insert`, donde el tercero esté protegido.
2. Verificar que la consulta 1 terminó con exactamente **dos** recetas.
3. Dejar la base como estaba.

**Pista:** el nombre del error de clave duplicada es `unique_violation`. También sirve `others`, que atrapa cualquiera.

---

## Ejercicio 10 — El aumento del que uno se arrepiente a la mitad (`savepoint`)

En una sola transacción, y en este orden:

1. Subirle 2 kg el peso a Nina (`id_mascota = 8`).
2. Marcar un punto intermedio.
3. Subirle 20 kg el peso a Pipo (`id_mascota = 7`), que es un ave de 0.30 kg.
4. Darse cuenta del disparate: deshacer **solo el segundo cambio**, sin perder el primero.
5. Confirmar la transacción.

**Se pide:**

1. Escribir la transacción.
2. Verificar que Nina quedó en 14.00 y Pipo en 0.30.
3. Dejar la base como estaba.

**Para pensar:** ¿en qué se diferencia esto de haber hecho dos transacciones separadas?
