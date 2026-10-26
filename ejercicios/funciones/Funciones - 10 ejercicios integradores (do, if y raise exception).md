# Diseño y Administración de Base de Datos

## Guía de ejercicios — Integradores de funciones (Unidad VI)

Diez ejercicios sobre la base de **la veterinaria**, donde cada uno combina **varias** de las herramientas de la clase: bloques `do`, funciones, variables, `if`, `found` y `raise exception`.

Son distintos de los de [`Funciones - 10 ejercicios en PL-pgSQL.md`](Funciones%20-%2010%20ejercicios%20en%20PL-pgSQL.md), donde cada ejercicio practica **una** pieza por vez. Acá hay que usarlas juntas, que es como aparecen en un sistema real.

Antes de empezar hay que tener corridos, en este orden, `01_esquema.sql` y `02_datos.sql`.

---

### Antes de empezar

**Todos corren en el SQL Editor de Supabase.** Pero hay dos reglas que conviene tener a mano:

1. **Los `raise notice` no se ven.** Por eso ningún ejercicio los pide para mostrar un resultado: cuando hay que ver un valor, la función lo **devuelve** con `return` y se le hace `select`.
2. **Cada ejecución del editor es una transacción.** Esto juega a favor: si una función modifica datos y después lanza un `raise exception`, **la modificación se deshace sola**. Varios ejercicios dependen de eso.

Cada ejercicio trae el `select` con el que se prueba y lo que tiene que devolver, incluido el texto exacto de los errores.

**Varios ejercicios modifican datos.** Los que lo hacen traen al final la sentencia para dejar la base como estaba.

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

## Ejercicio 1 — El peso que no puede ser

Escribir un bloque `do` que le cargue a Rocky (`id_mascota = 1`) un peso de **150 kg** y que, si el peso que se está por guardar queda **fuera del rango 0.05 – 100**, corte con el error `Peso fuera de rango: <valor> kg`.

**Se pide:**

1. El bloque, usando una variable para el peso nuevo.
2. Después, **en otra ejecución**, verificar qué quedó guardado.
3. Explicar en dos renglones por qué quedó así, **si no se escribió ningún `rollback`**.

**Tiene que devolver** el error primero, y `28.50` después.

---

## Ejercicio 2 — La misma validación, pero reutilizable

Convertir el ejercicio 1 en la función `registrar_peso(p_id int, p_peso decimal)`, que:

- corte con `No existe la mascota <id>` si la mascota no existe;
- corte con `Peso fuera de rango: <valor> kg` si el peso no está entre 0.05 y 100;
- si está todo bien, **actualice** el peso y devuelva el texto `Rocky: 28.50 kg → 30.00 kg`.

**Probala con**

```sql
select registrar_peso(1, 30.00);
select registrar_peso(1, 150);
select registrar_peso(99, 30);
```

**Tiene que devolver** el texto del cambio, y después los dos errores.

**Para dejar la base como estaba**

```sql
update mascota set peso_kg = 28.50 where id_mascota = 1;
```

---

## Ejercicio 3 — El nivel de riesgo

Escribir `riesgo_mascota(p_id int)` que devuelva el nivel de riesgo de una mascota combinando **edad y peso**:

- `'alto'` si tiene 8 años o más **y** pesa más de 20 kg;
- `'medio'` si cumple **una sola** de las dos condiciones;
- `'bajo'` si no cumple ninguna.

Si la mascota no existe, cortar con `No existe la mascota <id>`.

**Probala con**

```sql
select nombre, peso_kg,
       extract(year from age(fecha_nac)) as edad,
       riesgo_mascota(id_mascota) as riesgo
from mascota
order by riesgo, nombre;
```

**Pista:** se puede resolver con un `if` de tres ramas, o con dos variables booleanas y un `if` mucho más corto. Las dos valen; la segunda se lee mejor.

---

## Ejercicio 4 — Recetar sin repetir

Escribir `recetar(p_consulta int, p_medicamento int, p_dosis varchar, p_dias int)` que agregue un medicamento a una consulta, con estos controles:

- si la consulta no existe → `No existe la consulta <id>`;
- si ese medicamento **ya está recetado** en esa consulta → `El medicamento <id> ya está recetado en la consulta <id>`;
- si los días son cero o negativos → `La duración tiene que ser mayor a cero`;
- si está todo bien, insertar y devolver `Recetado: <nombre del medicamento> por <n> días`.

**Probala con**

```sql
select recetar(1, 3, '1 ampolla', 5);
select recetar(1, 3, '1 ampolla', 5);
select recetar(1, 7, '100mg cada 12hs', 0);
select recetar(99, 7, '100mg', 5);
```

**Tiene que devolver** la confirmación la primera vez y los tres errores después.

**Para dejar la base como estaba**

```sql
delete from receta where id_consulta = 1;
```

---

## Ejercicio 5 — Una consulta nueva, validada

Escribir `nueva_consulta(p_mascota int, p_matricula int, p_motivo varchar)` que registre una consulta con la fecha de hoy y **devuelva el `id_consulta` generado**.

Controles:

- la mascota tiene que existir → `No existe la mascota <id>`;
- el veterinario tiene que existir → `No existe el veterinario <matrícula>`;
- el motivo no puede venir vacío ni en `null` → `El motivo no puede estar vacío`.

**Probala con**

```sql
select nueva_consulta(1, 1001, 'Control de peso');
select nueva_consulta(1, 9999, 'Control de peso');
select nueva_consulta(1, 1001, '   ');
```

**Pista:** para el motivo vacío, mirar `trim()` y `coalesce()`.

**Para dejar la base como estaba**

```sql
delete from consulta where motivo = 'Control de peso';
```

---

## Ejercicio 6 — Cerrar las consultas de una mascota

Escribir un bloque `do` que le ponga el diagnóstico `'Cerrado por control'` a **todas las consultas sin diagnóstico** de la mascota 1 y que, si **no modificó ninguna fila**, corte con el error `La mascota 1 no tiene consultas abiertas`.

**Se pide:**

1. El bloque, resolviendo la verificación con `found`.
2. Correrlo dos veces y explicar qué cambia entre la primera y la segunda.

**Pista:** en la base todas las consultas de la mascota 1 ya tienen diagnóstico, así que el error va a saltar en la primera corrida. Para probar el camino que sí funciona, antes hay que dejar una consulta sin diagnóstico.

---

## Ejercicio 7 — La ficha que exige el peso cargado

Escribir `control_peso(p_id int)` que devuelva un texto como:

```
Rocky (Perro) — 28.50 kg — riesgo medio
```

Condiciones:

- usar **`%rowtype`** para traer la fila entera;
- si la mascota no existe → `No existe la mascota <id>`;
- si la mascota **existe pero no tiene el peso cargado** → `La mascota <nombre> no tiene peso cargado`;
- el nivel de riesgo se obtiene **llamando a la función del ejercicio 3**.

**Probala con**

```sql
select control_peso(1);
select control_peso(99);
```

Y después, para probar el tercer error:

```sql
update mascota set peso_kg = null where id_mascota = 9;
select control_peso(9);
update mascota set peso_kg = 1.80 where id_mascota = 9;
```

**Para pensar:** ¿por qué hacen falta **dos** errores distintos y no alcanza con uno solo?

---

## Ejercicio 8 — El tratamiento completo

Escribir `cerrar_tratamiento(p_consulta int)` que devuelva un texto con el resumen del tratamiento de una consulta:

```
Consulta 4: 2 medicamentos, 17 días en total
```

Condiciones:

- si la consulta no existe → `No existe la consulta <id>`;
- si la consulta **existe pero no recetó nada** → `La consulta <id> no tiene recetas`;
- el texto tiene que decir `1 medicamento` en singular cuando corresponda.

**Probala con**

```sql
select cerrar_tratamiento(4);
select cerrar_tratamiento(2);
select cerrar_tratamiento(1);
select cerrar_tratamiento(99);
```

**Tiene que devolver** el resumen de la 4, el de la 2 en singular, y los dos errores.

**Ojo con `found`:** acá hay una trampa. Una de las dos verificaciones **no se puede hacer con `found`**. Averiguar cuál y por qué.

---

## Ejercicio 9 — El control que mira el conjunto

Escribir un bloque `do` que les sume 5 kg a **todas las mascotas del dueño 4** y que, si después del aumento **alguna** queda por encima de 100 kg, corte con el error `El aumento deja a <nombre> en <valor> kg`.

**Se pide:**

1. El bloque, con el control **después** del `update`.
2. Probarlo con 5 kg y verificar que los pesos cambiaron.
3. Probarlo con 100 kg y verificar que **no cambió ninguno**.
4. Dejar la base como estaba.

**Lo que hay que entender acá:** la validación no se puede hacer antes, porque depende del resultado del `update`. Eso obliga a modificar primero y controlar después — y es seguro **solo** porque el error deshace todo.

---

## Ejercicio 10 — El error que viaja hacia arriba

Escribir un bloque `do` que, en este orden:

1. le ponga el diagnóstico `'En revisión'` a la consulta 1;
2. llame a `registrar_peso(1, 150)`, la función del ejercicio 2, que va a cortar con un error.

**Se pide:**

1. El bloque.
2. Verificar, en otra ejecución, qué quedó del diagnóstico de la consulta 1.
3. Explicar en tres renglones qué pasó: quién lanzó el error, quién lo recibió, y por qué se deshizo algo que la función **ni siquiera tocó**.

**Tiene que devolver** el error `Peso fuera de rango: 150 kg`, y el diagnóstico de la consulta 1 tiene que seguir siendo `Sano`.
