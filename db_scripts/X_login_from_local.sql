USE master;
GO

IF EXISTS (
    SELECT 1
    FROM sys.sql_logins
    WHERE name = 'datacore_app'
)
BEGIN
    DROP LOGIN datacore_app;
END
GO

CREATE LOGIN datacore_app
WITH PASSWORD = 'Datacore123!',
     CHECK_POLICY = OFF,
     CHECK_EXPIRATION = OFF;
GO

ALTER LOGIN datacore_app ENABLE;
GO

USE DataCoreRRHH;
GO

IF EXISTS (
    SELECT 1
    FROM sys.database_principals
    WHERE name = 'datacore_app'
)
BEGIN
    DROP USER datacore_app;
END
GO

CREATE USER datacore_app FOR LOGIN datacore_app;
GO

ALTER ROLE db_datareader ADD MEMBER datacore_app;
ALTER ROLE db_datawriter ADD MEMBER datacore_app;
GO