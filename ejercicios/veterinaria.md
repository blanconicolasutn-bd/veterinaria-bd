# Diseño y Administración de Base de Datos

## Guía de ejercicios — La veterinaria

Modelo basado en `veterinariaresolucion.md`. Usá el esquema y los datos de
`Veterinaria - 01 esquema (Supabase-PostgreSQL).sql` y
`Veterinaria - 02 datos de ejemplo.sql`.

Tablas: `dueno`, `mascota`, `veterinario`, `consulta`, `medicamento`, `receta`
(la tabla intermedia, cruce de `consulta` y `medicamento`).

---

### Consultas sobre una tabla

1. Listar todos los dueños ordenados por apellido.
2. Listar el nombre y la especie de todas las mascotas.
3. Listar las mascotas cuyo peso sea mayor a 10 kg.
4. Listar los veterinarios cuya especialidad sea "Clínica general".
5. Listar las consultas realizadas durante el año 2024, ordenadas por fecha.
6. Listar el nombre y la presentación de los medicamentos que vengan en comprimidos.
7. Listar las mascotas nacidas antes del año 2020.
8. Mostrar, en una sola columna con el alias `nombre_completo`, el nombre y apellido de cada dueño. (concatenación de campos en select con `||`)
9. Listar las consultas cuyo motivo contenga la palabra "control" (sin importar mayúsculas/minúsculas).
10. Listar las mascotas cuya especie sea "Perro" o "Gato".
11. Listar los dueños que no tengan un teléfono cargado.

### Consultas multitabla

1. Listar el nombre de cada mascota junto con el apellido de su dueño.
2. Listar fecha, motivo y diagnóstico de cada consulta, junto con el nombre de la mascota y el apellido del veterinario que la atendió.
3. Listar el nombre de la mascota y el apellido del veterinario, sólo para las consultas realizadas en 2023.
4. Listar todos los dueños junto con los datos de sus mascotas, **incluyendo a los dueños que no tengan ninguna**.
5. Listar todos los veterinarios junto con los datos de las consultas que atendieron, **incluyendo a los que no atendieron ninguna**.
6. Listar el nombre del medicamento, la dosis y la fecha de la consulta en la que fue recetado.
7. Listar las mascotas que nunca tuvieron ninguna consulta.
8. Listar los medicamentos que nunca fueron recetados.


### Consultas estadísticas (resumen)

1. Calcular la cantidad total de consultas registradas.
2. Calcular la cantidad de mascotas por especie.
3. Calcular el peso promedio de las mascotas, agrupado por especie.
4. Listar la cantidad de consultas atendidas por cada veterinario. Mostrar apellido, nombre y cantidad — incluyendo los veterinarios con 0 consultas.
5. Listar la cantidad de consultas realizadas por mes y año.
6. Calcular cuántas mascotas tiene cada dueño, incluyendo los que tienen 0.
7. Listar los medicamentos que fueron recetados más de una vez.
8. Calcular la duración promedio (en días) de los tratamientos recetados.
9. Listar el apellido del dueño con más mascotas registradas.
10. Para cada consulta que haya recetado más de un medicamento, listar la fecha de la consulta y el nombre de la mascota (sin repetir la fila por cada medicamento).
11. Listar las mascotas que nunca tuvieron ninguna consulta. (otra forma para el punto 7)

### Subconsultas

1. Listar las mascotas cuyo peso sea mayor al peso promedio de todas las mascotas.
2. Listar los dueños que no tienen ninguna mascota registrada (resolverlo con `NOT EXISTS` o `NOT IN`).
3. Listar los veterinarios que nunca atendieron ninguna consulta.
4. Listar el nombre de la mascota con la mayor cantidad de consultas registradas.
5. Listar las consultas en las que se recetaron más medicamentos que el promedio de medicamentos por consulta.
6. Listar los medicamentos cuya cantidad de veces recetado sea igual al máximo de recetas entre todos los medicamentos.

### Para pensar (sin SQL)

1. ¿Por qué `dosis` no puede ser un atributo de `medicamento`? ¿Y por qué tampoco de `consulta`?
2. `mascota.nombre` no es una buena clave primaria. Buscá en los datos de ejemplo dos filas que lo demuestren.
3. Si se implementara la variante de `consulta` como entidad débil (PK = `id_mascota` + `fecha`), ¿qué problema aparecería con las mascotas que van dos veces el mismo día? ¿Y qué le pasaría a la clave primaria de `receta`?
