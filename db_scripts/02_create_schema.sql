USE DataCoreRRHH;
GO

IF NOT EXISTS (
    SELECT 1
    FROM sys.schemas
    WHERE name = 'rrhh'
)
BEGIN
    EXEC('CREATE SCHEMA rrhh');
END
GO