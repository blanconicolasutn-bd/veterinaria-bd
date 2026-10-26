# Diseño y Administración de Base de Datos

## Guía de ejercicios — Normalización hasta 3FN (Unidad V)

Diez ejercicios para llevar un modelo de datos hasta la **tercera forma normal (3FN)**.

En todos se pide lo mismo: **llevar el modelo a 3FN**, indicando en cada paso qué dependencia se elimina y cómo quedan las tablas. En los primeros seis los datos están en una planilla; en los últimos cuatro hay que deducir las dependencias a partir de la descripción del sistema.

Notación para las respuestas: `tabla(columna PK, columna, columna FK → otra_tabla)`.

La resolución paso a paso, con cómo quedan los datos en cada forma normal, está en [`resoluciones/`](resoluciones/Normalizaci%C3%B3n%20-%2010%20ejercicios%20hasta%203FN%20-%20Resoluciones.md).

---

### Repaso rápido

- **Dependencia funcional (X → Y):** cada valor de X determina un único valor de Y. Si conozco X, conozco Y.
- **1FN:** cada celda guarda un único valor (atómico), no hay grupos de columnas repetidas y cada fila se identifica por una clave primaria.
- **2FN:** está en 1FN y ninguna columna que no es clave depende de *solo una parte* de la clave primaria. Si la PK es de una sola columna, la tabla ya está en 2FN.
- **3FN:** está en 2FN y ninguna columna que no es clave depende de *otra columna que tampoco es clave* (no hay cadenas `clave → A → B`).

Para recordar: cada columna depende **de la clave** (1FN), **de toda la clave** (2FN) y **de nada más que la clave** (3FN).

---

### Ejercicio 1 — El taller mecánico

Planilla de órdenes de reparación. En cada orden se anotan los repuestos usados con su cantidad.

| nro_orden | fecha | patente | modelo | marca | dni_dueño | dueño | repuestos |
|---|---|---|---|---|---|---|---|
| 1001 | 02/09/2026 | AB123CD | Corolla | Toyota | 31222333 | Acosta, Raúl | Filtro de aceite x1, Bujía x4 |
| 1002 | 02/09/2026 | AC456EF | Gol | Volkswagen | 29555666 | Bianchi, Laura | Pastillas de freno x2 |
| 1003 | 03/09/2026 | AB123CD | Corolla | Toyota | 31222333 | Acosta, Raúl | Correa x1, Bujía x4 |
| 1004 | 04/09/2026 | AD789GH | Hilux | Toyota | 36777888 | Cabrera, Nora | Filtro de aceite x1, Filtro de aire x1, Bujía x4 |
| 1005 | 05/09/2026 | AE321IJ | Gol | Volkswagen | 31222333 | Acosta, Raúl | Pastillas de freno x2, Correa x1 |
| 1006 | 06/09/2026 | AC456EF | Gol | Volkswagen | 29555666 | Bianchi, Laura | Filtro de aire x1 |

**Supuestos**

- Cada orden es de un solo vehículo.
- Cada vehículo (patente) tiene un solo dueño y es de un solo modelo.
- Cada modelo es de una sola marca.
- Los repuestos se identifican por su nombre.

**Se pide:** llevarla a 3FN, indicando en cada paso qué dependencia eliminaron.

---

### Ejercicio 2 — El cine

Planilla de entradas vendidas. En cada ticket se anotan las butacas compradas.

| nro_ticket | id_función | fecha | hora | sala | capacidad | película | duración_min | butacas |
|---|---|---|---|---|---|---|---|---|
| T-01 | F10 | 15/11/2026 | 18:00 | Sala 1 | 120 | El último faro | 118 | F5, F6 |
| T-02 | F10 | 15/11/2026 | 18:00 | Sala 1 | 120 | El último faro | 118 | G1 |
| T-03 | F11 | 15/11/2026 | 20:30 | Sala 2 | 80 | Pequeños gigantes | 95 | C3, C4, C5 |
| T-04 | F12 | 16/11/2026 | 18:00 | Sala 1 | 120 | Pequeños gigantes | 95 | A1 |
| T-05 | F11 | 15/11/2026 | 20:30 | Sala 2 | 80 | Pequeños gigantes | 95 | D7, D8 |
| T-06 | F13 | 16/11/2026 | 21:00 | Sala 3 | 60 | Noche en Tilcara | 132 | H2 |

**Supuestos**

- Cada función es de una película, en una sala, en una fecha y hora.
- Cada sala tiene una capacidad fija y cada película una duración fija.
- Un ticket es para una sola función.

**Se pide:** llevarla a 3FN, indicando en cada paso qué dependencia eliminaron.

---

### Ejercicio 3 — El gimnasio

Planilla de asistencias. Cada fila es la asistencia de un socio a una clase en una fecha.

| dni_socio | fecha | cod_clase | socio | plan | precio_plan | clase | instructor | sala |
|---|---|---|---|---|---|---|---|---|
| 33222111 | 01/09/2026 | YOG | Ledesma, Mateo | Libre | 30000 | Yoga | Ramos | Sala A |
| 33222111 | 01/09/2026 | SPN | Ledesma, Mateo | Libre | 30000 | Spinning | Ortiz | Sala B |
| 30999888 | 01/09/2026 | YOG | Moreno, Sofía | 3 veces | 22000 | Yoga | Ramos | Sala A |
| 33222111 | 03/09/2026 | YOG | Ledesma, Mateo | Libre | 30000 | Yoga | Ramos | Sala A |
| 37555444 | 03/09/2026 | FUN | Navarro, Iván | 2 veces | 16000 | Funcional | Ortiz | Sala C |
| 30999888 | 03/09/2026 | SPN | Moreno, Sofía | 3 veces | 22000 | Spinning | Ortiz | Sala B |
| 37555444 | 05/09/2026 | YOG | Navarro, Iván | 2 veces | 16000 | Yoga | Ramos | Sala A |

**Supuestos**

- Un socio no asiste dos veces a la misma clase el mismo día.
- Cada socio tiene un solo plan, y el precio depende del plan.
- Cada clase tiene un instructor y una sala fijos.

**Se pide:**

1. Identificar la clave primaria de la planilla. **Ojo: no es de una sola columna.**
2. Indicar en qué forma normal está, y por qué.
3. Llevarla a 3FN, indicando en cada paso qué dependencia eliminaron.

---

### Ejercicio 4 — Las horas por proyecto

Planilla mensual de horas. Cada elemento de la lista tiene la forma `código-nombre: horas`.

| legajo | empleado | departamento | jefe_depto | proyectos_y_horas |
|---|---|---|---|---|
| L-10 | Ojeda, Paula | Sistemas | Quiroga | P1-Portal web: 20; P3-App móvil: 10 |
| L-11 | Peralta, Julián | Sistemas | Quiroga | P1-Portal web: 35 |
| L-12 | Rojas, Lucía | Marketing | Suárez | P2-Campaña verano: 25; P1-Portal web: 5 |
| L-13 | Toledo, Bruno | Marketing | Suárez | P2-Campaña verano: 30 |
| L-14 | Vázquez, Elena | Sistemas | Quiroga | P3-App móvil: 40; P2-Campaña verano: 8 |

**Supuestos**

- Cada empleado pertenece a un solo departamento, y cada departamento tiene un solo jefe.
- El código identifica al proyecto.
- Las horas son las que cada empleado trabajó en cada proyecto durante el mes.

**Se pide:** llevarla a 3FN. **Atención:** cada elemento de la lista guarda tres datos distintos, no uno.

---

### Ejercicio 5 — La empresa de transporte

Planilla de envíos. En cada envío se anota el peso de cada bulto.

| nro_envío | fecha | cuit_remitente | remitente | cp_destino | localidad | provincia | pesos_bultos_kg |
|---|---|---|---|---|---|---|---|
| E-100 | 05/10/2026 | 30-70111222-5 | Distribuidora Norte | 5000 | Córdoba | Córdoba | 10; 5; 5 |
| E-101 | 05/10/2026 | 30-70999888-2 | Agro Sur SA | 2000 | Rosario | Santa Fe | 3.5 |
| E-102 | 06/10/2026 | 30-70111222-5 | Distribuidora Norte | 5800 | Río Cuarto | Córdoba | 12; 8 |
| E-103 | 06/10/2026 | 20-25333444-1 | Benítez, Omar | 5000 | Córdoba | Córdoba | 2; 2; 2; 1 |
| E-104 | 07/10/2026 | 30-70999888-2 | Agro Sur SA | 3000 | Santa Fe | Santa Fe | 20 |

**Supuestos**

- Cada código postal corresponde a una localidad, y cada localidad a una provincia.
- El remitente se identifica por su CUIT.
- **Los bultos no tienen código: de cada uno solo se conoce su peso**, y dos bultos del mismo envío pueden pesar lo mismo.

**Se pide:** llevarla a 3FN. **Atención:** pensá bien cómo identificar cada bulto. El envío E-103 tiene tres bultos de 2 kg.

---

### Ejercicio 6 — El hospital

Planilla de internaciones. En cada una se anotan los estudios realizados con su costo.

| nro_internación | ingreso | dni_paciente | paciente | habitación | piso | jefa_enfermería | matrícula | médico | estudios |
|---|---|---|---|---|---|---|---|---|---|
| I-300 | 01/10/2026 | 30555111 | Domínguez, Luis | 201 | 2 | Medina | 6120 | Paredes | Radiografía ($25000), Análisis de sangre ($12000) |
| I-301 | 02/10/2026 | 28777222 | Ponce, Marta | 305 | 3 | Castro | 6345 | Correa | Ecografía ($40000) |
| I-302 | 02/10/2026 | 35111999 | Gallo, Pía | 202 | 2 | Medina | 6120 | Paredes | Análisis de sangre ($12000) |
| I-303 | 04/10/2026 | 40888111 | Figueroa, Juan | 306 | 3 | Castro | 7011 | Villalba | Radiografía ($25000), Ecografía ($40000), Análisis de sangre ($12000) |
| I-304 | 05/10/2026 | 33777444 | Escobar, Inés | 201 | 2 | Medina | 6345 | Correa | Ecografía ($40000) |

**Supuestos**

- Cada internación es de un paciente, en una habitación, con un médico a cargo.
- Cada habitación está en un piso, y cada piso tiene una jefa de enfermería.
- El costo depende solo del estudio.
- Un estudio no se repite dentro de la misma internación.

**Se pide:** llevarla a 3FN, indicando en cada paso qué dependencia eliminaron.

---

### Ejercicio 7 — La empresa de mudanzas

Una empresa de mudanzas quiere normalizar los datos con los que trabaja. Del relevamiento surge lo siguiente:

Cada vez que un cliente contrata el servicio se registran los **puntos de traslado** (origen y destino) y la **fecha y hora estimada de inicio**. Del cliente se guardan nombre completo, DNI, **teléfonos (puede tener uno o más de uno)** y correo electrónico. También se registra una **persona de contacto**, de la que se guardan nombre completo, teléfonos (uno o más) y correo electrónico.

Para cada mudanza se asignan **operarios** — como mínimo uno — y un **vehículo**.

La empresa tiene un libro con los datos de sus **choferes y operarios**: nombre completo, DNI, teléfonos (puede no tener ninguno), correo, edad, dirección (calle, número, ciudad) y el **valor de la hora** que se le paga. Ese valor está tabulado por puesto:

- Chofer: $9000 / h
- Operario de mudanza: $7000 / h

Para controlar los sueldos registra en un cuaderno: nombre completo, DNI, mes, cantidad de horas trabajadas y **sueldo total**.

De cada **vehículo** registra patente, marca, modelo, kilómetros realizados, volumen y peso que soporta.

**Se pide:** llevar el modelo a 3FN. Justificar qué dependencia se elimina en cada paso.

**Pistas de lo que hay que mirar:** los teléfonos, el valor de la hora, el sueldo total y el parecido entre *cliente* y *persona de contacto*.

---

### Ejercicio 8 — El sistema heredado de búsqueda laboral

Una empresa de servicios de capital humano quiere reemplazar sus sistemas. Hoy funciona con dos archivos binarios.

**`personas.dat`**

| DNI | Contraseña | Nombre y Apellido | descripción | Fecha de nacimiento | Estudios formales | Idiomas |
|---|---|---|---|---|---|---|
| long int | string[8] | string[50] | string[300] | string[10] | string[300] | string[300] |

Sobre esa estructura, el análisis reveló que:

- El campo **`descripción`** se agregó después y se usa para guardar datos que no se habían contemplado. Adentro se almacenan, separados por `|` (pipe): la dirección de email, los **teléfonos** (nunca más de dos: uno fijo y uno móvil, separados entre sí por `;`) y la dirección de residencia (calle, número, código postal, ciudad y provincia, separados por `,`).
- En **`Fecha de nacimiento`** conviven los formatos `dd/mm/aaaa` y `dd-mm-aaaa`, y en algunos registros se guardó directamente la edad.
- **`Estudios formales`** e **`Idiomas`** guardan, para cada uno: nombre del título, si está completo (`si` / `no`), cantidad de años y entidad emisora, separados por `|`. Si la persona tiene más de un estudio, se separan entre sí con `;`.

**`empresas.dat`**

| Nombre | Razón social | CUIT | descripción | Rubro | Cantidad de empleados | Aviso |
|---|---|---|---|---|---|---|

Cada empresa publica avisos de trabajo, y el campo `Aviso` guarda todos los avisos publicados por esa empresa.

**Se pide:** llevar el modelo a 3FN. Para cada campo problemático, indicar qué regla de qué forma normal se está violando.

**Pista:** acá el trabajo más grande es de 1FN, y hay más de un motivo distinto por los que se viola.

---

### Ejercicio 9 — Los equipos y el software instalado

Una empresa quiere regularizar el software instalado en las PC de sus empleados. Hoy lleva todo en una única tabla:

| id_equipo | marca | modelo | ram_gb | dni_usuario | usuario | sector | software_instalado |
|---|---|---|---|---|---|---|---|
| EQ-01 | Dell | OptiPlex 3080 | 8 | 30111222 | Acuña, Marta | Administración | Windows 10; Office 2019; Chrome |
| EQ-02 | HP | ProDesk 400 | 16 | 28444555 | Bustos, Iván | Sistemas | Windows 11; Chrome; Visual Studio Code |
| EQ-03 | Dell | OptiPlex 3080 | 8 | 35777888 | Cáceres, Rocío | Administración | Windows 10; Office 2019 |
| EQ-04 | Lenovo | ThinkCentre M70 | 16 | 28444555 | Bustos, Iván | Sistemas | Windows 11; Visual Studio Code; Docker |
| EQ-05 | HP | ProDesk 400 | 16 | 41222333 | Duarte, Nahuel | Depósito | Windows 10; Chrome |

**Supuestos**

- Un equipo tiene **más de un software instalado**.
- Los **modelos de PC no se repiten entre marcas**: si dos equipos son del mismo modelo, son de la misma marca.
- La memoria RAM depende del modelo.
- Un usuario puede tener asignado más de un equipo, pero cada equipo tiene un solo usuario.
- Cada usuario pertenece a un solo sector.

**Se pide:** llevar el modelo a 3FN, reduciendo la redundancia. Indicar en cada paso qué dependencia se elimina.

---

### Ejercicio 10 — La planilla de pruebas de aplicaciones

Una empresa prueba aplicaciones en distintos teléfonos y redes, y lleva el registro en una sola hoja de cálculo. Éstas son sus columnas:

| Columna | Qué guarda |
|---|---|
| `cliente` | Nombre y número de cliente juntos, así: `Juan Perez; 115632` |
| `cliente_empresa` | Razón social del cliente |
| `carrier` | Compañía de telefonía donde se probó |
| `aplicación` | Nombre de la app probada |
| `descripción` | Descripción de la app |
| `foto_1`, `foto_2`, `foto_3` | Hasta tres fotos de la app |
| `prueba_1`, `descripción_1` | Nombre y descripción de la primera prueba |
| `prueba_2`, `descripción_2` | Nombre y descripción de la segunda prueba |
| `tipo_red` | Tipo de red: aparece cargado como `WAP`, `WEP` y también `wep` |
| `fecha` | Fecha de la corrida |
| `resultado_1`, `observaciones_1` | Resultado y observaciones de la primera prueba |
| `resultado_2`, `observaciones_2` | Resultado y observaciones de la segunda prueba |
| `foto_resultado_1`, `foto_resultado_2` | Foto del resultado de cada prueba |

Algunas filas de ejemplo:

| cliente | carrier | aplicación | prueba_1 | prueba_2 | tipo_red | resultado_1 | resultado_2 |
|---|---|---|---|---|---|---|---|
| Juan Perez; 115632 | Claro | Disney_Princesas | Login | Seleccionar personaje | WAP | Ok | Ok |
| Juan Perez; 115632 | Claro | Disney_Princesas | Login | Seleccionar personaje | WEP | Ok | Error |
| Juan Perez; 115632 | Movistar | Disney_Princesas | Login | Seleccionar personaje | WAP | Ok | Ok |
| Juan Perez; 115632 | Movistar | Linterna | Prender | Apagar | wep | Ok | Ok |

**Supuestos**

- Una aplicación es de un solo cliente, y su descripción no cambia entre corridas.
- Una prueba tiene siempre la misma descripción, sin importar en qué corrida se use.
- Una corrida es la combinación de una app, un carrier, un tipo de red y una fecha.
- Una app puede tener más de dos pruebas: la planilla se quedó corta.

**Se pide:**

1. Señalar **todas** las violaciones de 1FN que encuentres: son de tres tipos distintos.
2. Llevar el modelo a 3FN.
3. Indicar qué pasa con `tipo_red` cargado como `WEP` y como `wep`, y si eso lo resuelve la normalización o es otro problema.
