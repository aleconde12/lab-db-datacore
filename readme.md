# Laboratorio DB Datacore

## Laboratorio para administracion de bases de datos 1

### 1. Requisitos
- Instalar SQL Server Express 2022 o equivalente
- Instalar SQL Server Management Studio (SSMS)
- Clonarse este repositorio para tener los mismos scripts
- Abrir el SSMS, usar `.\SQLEXPRESS` como host, `Windows Authentication` como credenciales, y tildar la opcion `Trust Server Certificate` y encrypt `optional`.
- Correr todos los scripts que comiencen con "create", empezando por el 01
- Finalizado el paso anterior, abrir una conexion nueva en el SSMS con las opciones:
 `localhost.\SQLEXPRESS` como host, 
 `SQL Server Authentication` como metodo de autenticacion, 
 tildar la opcion `Trust Server Certificate`, 
 y usar las credenciales `user name = datacore_app`, y `password = Datacore123!`
- Luego, correr con esta nueva conexion creada, el resto de los scripts, que comienzan con la letra "insert"


### 2. Estructura de modulos

Primero debemos comprender que modulos van a crearse, y que tablas contiene cada uno

| Módulo | Tema                         | Qué representa                                            |
| ------ | ---------------------------- | --------------------------------------------------------- |
| **M1** | Empleados y datos personales | Alta del empleado, datos sensibles, documentos, contactos |
| **M2** | Organización y cargos        | Departamentos, puestos, niveles, jerarquías               |
| **M3** | Nómina y compensación        | Sueldo, bonos, deducciones, cálculo de nómina             |
| **M4** | Asistencia y tiempo          | Entradas, salidas, vacaciones, horas extras               |
| **M5** | Desempeño y desarrollo       | Evaluaciones, objetivos, capacitaciones                   |


#### 2.1 Estudiante 1 — M1: Empleados y Datos Personales

Tablas:

~~~ sql
employees
personal_info
emergency_contacts
documents
employment_history
~~~

Debe implementar:

`vw_empleados_activos`

Y puede tener procedimiento:

`sp_registrar_empleado`

#### 2.2 Estudiante 2 — M2: Organización y Cargos

Tablas:

~~~ sql
departments
positions
job_levels
reporting_structure
~~~

Debe implementar:

`vw_organigrama`

Y podría sumar:

`vw_costo_personal_por_departamento`

Aunque esta última también toca M3, porque costo implica salario/nómina.

#### 2.3 Estudiante 3 — M3: Nómina y Compensación

Tablas:

~~~ sql
payroll
salary_components
deductions
bonuses
~~~

Debe implementar:

`sp_calcular_nomina`

Este módulo depende fuerte de:

~~~ sql
employees
positions
attendance
overtime
bonuses
deductions
~~~

#### 2.4 Estudiante 4 — M4: Asistencia y Tiempo

Tablas:

~~~ sql
attendance
work_schedules
overtime
leave_requests
~~~

Debe implementar un trigger tipo:

`trg_validar_saldo_vacaciones`

Tabla auxiliar (porque si el trigger tiene que validar saldo, ese saldo tiene que vivir en algún lado.):

`vacation_balances`


#### 2.5 Estudiante 5 — M5: Desempeño y Desarrollo

Tablas:

~~~ sql
performance_reviews
goals
competencies
training_records
~~~

Debe implementar:

`vw_empleados_alto_rendimiento`

Y alimenta bonos o promociones.


#### 2.6 Indice de modulos, visto desde scripts

Este es indice de modulos a utilizar, visto con los nombres de los scripts

~~~ bash
00_drop_database.sql
01_create_database.sql
02_create_schema.sql
03_create_tables_m2_organizacion.sql
04_create_tables_m1_empleados.sql
05_create_tables_m4_asistencia.sql
06_create_tables_m3_nomina.sql
07_create_tables_m5_desempeno.sql
08_insert_catalogos.sql
09_insert_demo_data.sql
10_views.sql
11_procedures.sql
12_triggers.sql
13_demo_flow.sql
~~~

### 3. Modulo 2 - Organizacion

Se empieza por M2 porque define la “estructura base” sobre la que después M1 engancha empleados. La decisión importante: en este se modela jerarquía por cargos/puestos, no por empleados, así no dependemos todavía de M1.

tablas del módulo:

>departments: áreas de la empresa, por ejemplo TI, RRHH, Finanzas.

>job_levels: niveles jerárquicos, por ejemplo Nivel 1, Nivel 2, Nivel 5.

>positions: cargos/puestos, por ejemplo Analista Senior, Gerente TI.

>reporting_structure: define qué puesto reporta a qué otro puesto.


#### 3.1 departments

Guarda las áreas de la empresa.

Ejemplos:
~~~sql
TI
Recursos Humanos
Finanzas
Administración
~~~
Tiene `is_active` para hacer baja lógica. En vez de borrar un departamento, se marca como inactivo.

#### 3.2 job_levels

Representa los niveles jerárquicos y sus rangos salariales.

Ejemplo:

>Nivel 1 - Junior       $800.000  a $1.500.000

>Nivel 3 - Semi Senior  $2.000.000 a $3.500.000

>Nivel 5 - Senior       $4.500.000 a $6.000.000

La constraint:

`CONSTRAINT ck_job_levels_salary_range CHECK (min_salary >= 0 AND max_salary >= min_salary)`

evita datos inválidos como:
~~~ sql
mínimo: 6.000.000
máximo: 4.500.000
~~~

#### 3.3 positions

Representa los cargos concretos dentro de un departamento.

Ejemplos:

>Analista Senior - TI - Nivel 5

>Gerente TI - TI - Nivel 6

>Analista RRHH - Recursos Humanos - Nivel 3

Tiene relación con:
~~~ sql
departments
job_levels
~~~

O sea, un puesto pertenece a un departamento y tiene un nivel jerárquico.

#### 3.4 reporting_structure

Esta tabla define la jerarquía.

Ejemplo:

>Analista Senior reporta a Gerente TI

>Gerente TI reporta a Director de Tecnología

Se usa:
~~~ sql
position_id
reports_to_position_id
~~~

En vez de:
~~~ sql
employee_id
reports_to_employee_id
~~~

Esto es intencional. Como todavía no creamos empleados, M2 puede existir solo. Después M1 registra empleados y los vincula a los puestos.

Importante para la demo

Con estas tablas, después podemos cargar datos así:

>Departamento: TI

>Nivel: 5 - Senior

>Cargo: Analista Senior

>Cargo superior: Gerente TI

Y más adelante, cuando venga M1, el empleado se engancha a positions.

Ejemplo conceptual:

>Juan Pérez -> Analista Senior -> TI -> reporta a Gerente TI

### 4. Modulo 1 - Empleados y datos personales

Este módulo administra la información principal de los empleados de la empresa.

Se apoya en el Módulo 2 - Organización, porque cada empleado se vincula a un cargo existente. Ese cargo, a su vez, ya pertenece a un departamento y tiene un nivel jerárquico definido.

La decisión importante es separar los datos laborales de los datos personales. La tabla `employees` guarda la información laboral principal, mientras que `personal_info` guarda datos complementarios de la persona.

Tablas del módulo:

> `employees`: empleados de la empresa, con legajo, nombre, apellido, DNI/CUIL, fecha de ingreso, estado y cargo asignado.

> `personal_info`: información personal adicional del empleado, como fecha de nacimiento, dirección, teléfono y correo electrónico.

> `documents`: documentación asociada al empleado, por ejemplo DNI, CUIL, contrato, certificado médico u otros documentos internos.

#### 4.1 employees

Guarda la información principal del empleado dentro de la empresa.

Ejemplos:

```sql
Juan Pérez - Legajo EMP001 - Analista Senior
María Gómez - Legajo EMP002 - Gerente RRHH
Carlos López - Legajo EMP003 - Administrativo
```

Campos principales:

```sql
employee_code
first_name
last_name
dni_cuil
hire_date
position_id
is_active
```

Tiene `is_active` para manejar baja lógica. En vez de borrar un empleado, se marca como inactivo.

Esto permite conservar el historial y evitar perder relaciones con otros registros del sistema.

La relación con `positions` permite saber qué cargo ocupa el empleado. Como el cargo ya pertenece a un departamento, no hace falta duplicar el departamento dentro de `employees`.

Ejemplo conceptual:

> Juan Pérez -> Analista Senior -> TI

#### 4.2 personal_info

Guarda datos personales complementarios del empleado.

Ejemplos de datos:

```sql
Fecha de nacimiento
Dirección
Teléfono
Email personal
Estado civil
Nacionalidad
```

Esta tabla se separa de `employees` para mantener más ordenado el modelo.

La tabla `employees` responde a la pregunta:

> ¿Quién trabaja en la empresa y qué cargo ocupa?

La tabla `personal_info` responde a la pregunta:

> ¿Cuáles son sus datos personales complementarios?

Tiene relación directa con:

```sql
employees
```

O sea, cada registro de `personal_info` pertenece a un empleado.

#### 4.3 documents

Guarda la documentación asociada a cada empleado.

Ejemplos:

> DNI

> Constancia de CUIL

> Contrato firmado

> Certificado médico

> Comprobante de domicilio

Campos posibles:

```sql
document_type
document_number
issue_date
expiration_date
document_status
employee_id
```

La idea es poder consultar qué documentación tiene cargada cada empleado y detectar documentación pendiente o vencida.

Ejemplo:

> Juan Pérez -> DNI -> Presentado

> Juan Pérez -> Contrato -> Presentado

> Juan Pérez -> Certificado médico -> Pendiente

#### 4.4 Vista de empleados activos

Se puede crear una vista llamada:

```sql
vw_empleados_activos
```

Esta vista muestra solamente los empleados activos, junto con su cargo y departamento.

Ejemplo de salida esperada:

> Juan Pérez - Analista Senior - TI

> María Gómez - Gerente RRHH - Recursos Humanos

> Carlos López - Administrativo - Administración

Esta vista sirve para la demo porque permite mostrar rápidamente el listado funcional de empleados vigentes.

Importante para la demo

Con estas tablas, el flujo funcional queda así:

> Crear departamento

> Crear nivel jerárquico

> Crear cargo

> Crear empleado

> Asociar empleado al cargo

> Cargar datos personales

> Cargar documentación

Ejemplo conceptual completo:

> Juan Pérez -> Analista Senior -> TI -> empleado activo -> documentación presentada

De esta manera, el Módulo 1 queda conectado con el Módulo 2 y se puede demostrar un circuito completo de alta de empleado dentro de la estructura organizacional.


### 5. Modulo 3 - Nómina y compensación

Este módulo administra la liquidación salarial de los empleados.

Se apoya en el Módulo 1 - Empleados, porque cada liquidación pertenece a un empleado existente. También se relaciona indirectamente con el Módulo 2 - Organización, ya que el empleado ocupa un cargo y ese cargo tiene un nivel jerárquico asociado.

La decisión importante es separar la cabecera de la liquidación del detalle de conceptos. De esta forma, una liquidación puede tener varios conceptos asociados, como sueldo básico, bonos, presentismo, jubilación u obra social.

Tablas del módulo:

> `payroll_periods`: períodos de liquidación, por ejemplo Junio 2026.

> `compensation_concepts`: conceptos salariales, como sueldo básico, bono, presentismo o descuentos.

> `employee_compensation`: compensaciones asignadas a cada empleado.

> `payroll_headers`: cabecera de liquidación por empleado y período.

> `payroll_details`: detalle de conceptos liquidados dentro de cada recibo.

### 6. Modulo 4 - Asistencia y tiempo

Este módulo se engancha directamente con:

~~~ yaml
M1 - Empleados
rrhh.employees
~~~

La idea funcional es registrar asistencia, jornadas, llegadas tarde, ausencias y horas trabajadas.

Tablas:

~~~ yaml
attendance_types
work_schedules
employee_schedules
attendance_records
~~~

Explicación rápida:


>`attendance_types` Tipos de asistencia o novedad. Ejemplo: PRESENTE, AUSENTE, LLEGADA_TARDE, LICENCIA, VACACIONES, HOME_OFFICE

>`work_schedules` Jornadas laborales esperadas. Ejemplo: Lunes a Viernes 09:00 a 18:00, Turno mañana 08:00 a 14:00, Turno tarde 14:00 a 20:00

>`employee_schedules` Asigna un horario a un empleado. Ejemplo: Juan Pérez -> Lunes a Viernes 09:00 a 18:00

>`attendance_records` Registra la asistencia diaria del empleado. Ejemplo: Juan Pérez - 2026-06-10 - Presente - Entrada 09:05 - Salida 18:00, María Gómez - 2026-06-10 - Home Office, Carlos López - 2026-06-10 - Ausente

Para la demo, el flujo sería:

~~~ yaml
Crear tipo de asistencia
Crear horario laboral
Asignar horario a empleado
Registrar asistencia diaria
Consultar resumen de asistencia
~~~


> vista util: `rrhh.vw_asistencia_resumen`

Mostrando:

~~~ yaml
Empleado | Fecha | Tipo asistencia | Entrada | Salida | Horas trabajadas | Observaciones
~~~

~~~ bash
employees
   |
   |-- employee_schedules
   |        |
   |        |-- work_schedules
   |
   |-- attendance_records
            |
            |-- attendance_types
~~~

### 7. Modulo 5 - Desempeño y desarrollo

to do

### X. Inicio. Correr la base, cargar los scripts

- Ir a File/Open/File, y seleccionar los scripts desde el 01 en adelante, e ir corriendolos uno por uno en orden, con el comando `Execute`, verificando que se esten ejecutando correctamente

|script|que hace?|
|------|---------|
|00_drop_database|borra todo lo creado|
|01_create_database|crea la db DataCoreRRHH|
|02_create_schema.sql|usa la db creada en el paso anterior y le agrega un schema adentro|
|03_create_tables_m2_organizacion.sql|crea 4 tablas|

### 