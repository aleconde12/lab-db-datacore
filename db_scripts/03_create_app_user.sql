USE master;
GO

/* ============================================================
   Usuario de aplicación para el frontend PHP
   Archivo: 03_create_app_user.sql

   Este script crea:
   - LOGIN a nivel servidor: datacore_app
   - USER dentro de la base DataCoreRRHH
   - Permisos sobre el schema rrhh

   Requiere:
   - Ejecutarse con usuario administrador de SQL Server
   - SQL Server en modo mixto:
     SQL Server and Windows Authentication mode
   ============================================================ */

IF NOT EXISTS (
    SELECT 1
    FROM sys.sql_logins
    WHERE name = 'datacore_app'
)
BEGIN
    CREATE LOGIN datacore_app
    WITH PASSWORD = 'Datacore123!',
         CHECK_POLICY = OFF,
         CHECK_EXPIRATION = OFF;
END
GO

ALTER LOGIN datacore_app ENABLE;
GO

USE DataCoreRRHH;
GO

IF NOT EXISTS (
    SELECT 1
    FROM sys.database_principals
    WHERE name = 'datacore_app'
)
BEGIN
    CREATE USER datacore_app FOR LOGIN datacore_app;
END
GO

GRANT SELECT, INSERT, UPDATE, DELETE ON SCHEMA::rrhh TO datacore_app;
GO