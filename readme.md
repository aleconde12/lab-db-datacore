# Laboratorio DB Datacore

## Laboratorio para administracion de bases de datos 1

### 1. Requisitos
- Instalar SQL Server Express 2022 o equivalente
- Instalar SQL Server Management Studio (SSMS)
- Clonarse este repositorio para tener los mismos scripts
- Abrir el SSMS, usar `.\SQLEXPRESS` como host, `Windows Authentication` como credenciales, y tildar la opcion `Trust Server Certificate` y encrypt `optional`.
- Con esos pasos, deberiamos tener el motor de base de datos y el cliente funcionando

### 2. Modulos

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


### 3. Inicio. Correr la base, cargar los scripts

- Ir a File/Open/File, y seleccionar los scripts desde el 01 en adelante, e ir corriendolos uno por uno en orden, con el comando `Execute`, verificando que se esten ejecutando correctamente

|script|que hace?|
|------|---------|
|00_drop_database|borra todo lo creado|
|01_create_database|crea la db DataCoreRRHH|
|02_create_schema.sql|usa la db creada en el paso anterior y le agrega un schema adentro|
|03_create_tables.sql|crea 4 tablas|