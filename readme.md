# Laboratorio DB Datacore

## Laboratorio para administracion de bases de datos 1

### 1. Requisitos
> Instalar SQL Server Express 2022 o equivalente
> Instalar SQL Server Management Studio (SSMS)
> Clonarse este repositorio para tener los mismos scripts
> Abrir el SSMS, usar `.\SQLEXPRESS` como host, `Windows Authentication` como credenciales, y tildar la opcion `Trust Server Certificate` y encrypt `optional`.
> Con esos pasos, deberiamos tener el motor de base de datos y el cliente funcionando

### 2. Cargar scripts

>Ir a File/Open/File, y seleccionar los scripts desde el 01 en adelante, e ir corriendolos uno por uno en orden, con el comando `Execute`, verificando que se esten ejecutando correctamente

|script|que hace?|
|------|---------|
|00_drop_database|borra todo lo creado|
|01_create_database|crea la db DataCoreRRHH|
|02_create_schema.sql|usa la db creada en el paso anterior y le agrega un schema adentro|
|03_create_tables.sql|crea 4 tablas|