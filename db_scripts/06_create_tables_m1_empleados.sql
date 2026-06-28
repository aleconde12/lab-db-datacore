USE DataCoreRRHH;
GO

/* =========================================================
   Módulo 1 - Empleados
   Script: 06_create_employees_module.sql
   Ejecutar con usuario admin
   ========================================================= */

------------------------------------------------------------
-- Tabla: employees
-- Guarda la información laboral principal del empleado
------------------------------------------------------------

IF OBJECT_ID('rrhh.employees', 'U') IS NULL
BEGIN
    CREATE TABLE rrhh.employees (
        employee_id INT IDENTITY(1,1) NOT NULL,
        employee_code VARCHAR(20) NOT NULL,
        first_name VARCHAR(100) NOT NULL,
        last_name VARCHAR(100) NOT NULL,
        dni_cuil VARCHAR(20) NOT NULL,
        hire_date DATE NOT NULL,
        position_id INT NOT NULL,
        is_active BIT NOT NULL CONSTRAINT df_employees_is_active DEFAULT (1),
        created_at DATETIME2 NOT NULL CONSTRAINT df_employees_created_at DEFAULT (SYSDATETIME()),
        updated_at DATETIME2 NULL,

        CONSTRAINT pk_employees 
            PRIMARY KEY (employee_id),

        CONSTRAINT uq_employees_employee_code 
            UNIQUE (employee_code),

        CONSTRAINT uq_employees_dni_cuil 
            UNIQUE (dni_cuil),

        CONSTRAINT fk_employees_positions 
            FOREIGN KEY (position_id) 
            REFERENCES rrhh.positions(position_id),

        CONSTRAINT ck_employees_hire_date 
            CHECK (hire_date <= CAST(SYSDATETIME() AS DATE))
    );
END;
GO


------------------------------------------------------------
-- Tabla: personal_info
-- Guarda datos personales complementarios del empleado
------------------------------------------------------------

IF OBJECT_ID('rrhh.personal_info', 'U') IS NULL
BEGIN
    CREATE TABLE rrhh.personal_info (
        personal_info_id INT IDENTITY(1,1) NOT NULL,
        employee_id INT NOT NULL,
        birth_date DATE NULL,
        address VARCHAR(200) NULL,
        phone VARCHAR(50) NULL,
        personal_email VARCHAR(150) NULL,
        marital_status VARCHAR(50) NULL,
        nationality VARCHAR(80) NULL,
        created_at DATETIME2 NOT NULL CONSTRAINT df_personal_info_created_at DEFAULT (SYSDATETIME()),
        updated_at DATETIME2 NULL,

        CONSTRAINT pk_personal_info 
            PRIMARY KEY (personal_info_id),

        CONSTRAINT uq_personal_info_employee 
            UNIQUE (employee_id),

        CONSTRAINT fk_personal_info_employees 
            FOREIGN KEY (employee_id) 
            REFERENCES rrhh.employees(employee_id),

        CONSTRAINT ck_personal_info_birth_date 
            CHECK (birth_date IS NULL OR birth_date < CAST(SYSDATETIME() AS DATE)),

        CONSTRAINT ck_personal_info_email 
            CHECK (
                personal_email IS NULL 
                OR personal_email LIKE '%_@_%._%'
            )
    );
END;
GO


------------------------------------------------------------
-- Tabla: documents
-- Guarda documentación asociada al empleado
------------------------------------------------------------

IF OBJECT_ID('rrhh.documents', 'U') IS NULL
BEGIN
    CREATE TABLE rrhh.documents (
        document_id INT IDENTITY(1,1) NOT NULL,
        employee_id INT NOT NULL,
        document_type VARCHAR(80) NOT NULL,
        document_number VARCHAR(80) NULL,
        issue_date DATE NULL,
        expiration_date DATE NULL,
        document_status VARCHAR(30) NOT NULL,
        observations VARCHAR(250) NULL,
        created_at DATETIME2 NOT NULL CONSTRAINT df_documents_created_at DEFAULT (SYSDATETIME()),
        updated_at DATETIME2 NULL,

        CONSTRAINT pk_documents 
            PRIMARY KEY (document_id),

        CONSTRAINT fk_documents_employees 
            FOREIGN KEY (employee_id) 
            REFERENCES rrhh.employees(employee_id),

        CONSTRAINT ck_documents_status 
            CHECK (document_status IN ('PRESENTADO', 'PENDIENTE', 'VENCIDO')),

        CONSTRAINT ck_documents_dates 
            CHECK (
                expiration_date IS NULL 
                OR issue_date IS NULL 
                OR expiration_date >= issue_date
            )
    );
END;
GO


------------------------------------------------------------
-- Índices recomendados
------------------------------------------------------------

IF NOT EXISTS (
    SELECT 1 
    FROM sys.indexes 
    WHERE name = 'ix_employees_position_id' 
      AND object_id = OBJECT_ID('rrhh.employees')
)
BEGIN
    CREATE INDEX ix_employees_position_id
    ON rrhh.employees(position_id);
END;
GO

IF NOT EXISTS (
    SELECT 1 
    FROM sys.indexes 
    WHERE name = 'ix_employees_is_active' 
      AND object_id = OBJECT_ID('rrhh.employees')
)
BEGIN
    CREATE INDEX ix_employees_is_active
    ON rrhh.employees(is_active);
END;
GO

IF NOT EXISTS (
    SELECT 1 
    FROM sys.indexes 
    WHERE name = 'ix_documents_employee_id' 
      AND object_id = OBJECT_ID('rrhh.documents')
)
BEGIN
    CREATE INDEX ix_documents_employee_id
    ON rrhh.documents(employee_id);
END;
GO

IF NOT EXISTS (
    SELECT 1 
    FROM sys.indexes 
    WHERE name = 'ix_documents_status' 
      AND object_id = OBJECT_ID('rrhh.documents')
)
BEGIN
    CREATE INDEX ix_documents_status
    ON rrhh.documents(document_status);
END;
GO


------------------------------------------------------------
-- Vista: vw_empleados_activos
-- Muestra empleados activos con cargo y departamento
------------------------------------------------------------

CREATE OR ALTER VIEW rrhh.vw_empleados_activos AS
SELECT
    e.employee_id,
    e.employee_code,
    e.first_name,
    e.last_name,
    e.dni_cuil,
    e.hire_date,
    e.is_active,
    p.position_id,
    p.position_name,
    d.department_id,
    d.department_name
FROM rrhh.employees e
INNER JOIN rrhh.positions p
    ON e.position_id = p.position_id
INNER JOIN rrhh.departments d
    ON p.department_id = d.department_id
WHERE e.is_active = 1;
GO


------------------------------------------------------------
-- Permisos para app_user
-- Descomentar si el app_user todavía no tiene permisos
-- suficientes sobre el schema rrhh.
------------------------------------------------------------

/*
GRANT SELECT, INSERT, UPDATE ON rrhh.employees TO app_user;
GRANT SELECT, INSERT, UPDATE ON rrhh.personal_info TO app_user;
GRANT SELECT, INSERT, UPDATE ON rrhh.documents TO app_user;
GRANT SELECT ON rrhh.vw_empleados_activos TO app_user;
*/
GO