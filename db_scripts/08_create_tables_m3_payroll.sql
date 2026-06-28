USE DataCoreRRHH;
GO

/* =========================================================
   Módulo 3 - Nómina y Compensación
   Script: 08_create_payroll_module.sql
   Ejecutar con usuario admin
   ========================================================= */

------------------------------------------------------------
-- Tabla: payroll_periods
-- Define los períodos de liquidación
------------------------------------------------------------

IF OBJECT_ID('rrhh.payroll_periods', 'U') IS NULL
BEGIN
    CREATE TABLE rrhh.payroll_periods (
        payroll_period_id INT IDENTITY(1,1) NOT NULL,
        period_name VARCHAR(80) NOT NULL,
        period_year INT NOT NULL,
        period_month INT NOT NULL,
        start_date DATE NOT NULL,
        end_date DATE NOT NULL,
        payment_date DATE NULL,
        period_status VARCHAR(30) NOT NULL 
            CONSTRAINT df_payroll_periods_status DEFAULT ('ABIERTO'),
        created_at DATETIME2 NOT NULL 
            CONSTRAINT df_payroll_periods_created_at DEFAULT (SYSDATETIME()),
        updated_at DATETIME2 NULL,

        CONSTRAINT pk_payroll_periods 
            PRIMARY KEY (payroll_period_id),

        CONSTRAINT uq_payroll_periods_year_month 
            UNIQUE (period_year, period_month),

        CONSTRAINT ck_payroll_periods_month 
            CHECK (period_month BETWEEN 1 AND 12),

        CONSTRAINT ck_payroll_periods_year 
            CHECK (period_year >= 2000),

        CONSTRAINT ck_payroll_periods_dates 
            CHECK (end_date >= start_date),

        CONSTRAINT ck_payroll_periods_status 
            CHECK (period_status IN ('ABIERTO', 'CERRADO', 'ANULADO'))
    );
END;
GO


------------------------------------------------------------
-- Tabla: compensation_concepts
-- Define conceptos salariales: haberes y descuentos
------------------------------------------------------------

IF OBJECT_ID('rrhh.compensation_concepts', 'U') IS NULL
BEGIN
    CREATE TABLE rrhh.compensation_concepts (
        concept_id INT IDENTITY(1,1) NOT NULL,
        concept_code VARCHAR(30) NOT NULL,
        concept_name VARCHAR(100) NOT NULL,
        concept_type VARCHAR(30) NOT NULL,
        is_fixed BIT NOT NULL 
            CONSTRAINT df_compensation_concepts_is_fixed DEFAULT (0),
        is_active BIT NOT NULL 
            CONSTRAINT df_compensation_concepts_is_active DEFAULT (1),
        created_at DATETIME2 NOT NULL 
            CONSTRAINT df_compensation_concepts_created_at DEFAULT (SYSDATETIME()),
        updated_at DATETIME2 NULL,

        CONSTRAINT pk_compensation_concepts 
            PRIMARY KEY (concept_id),

        CONSTRAINT uq_compensation_concepts_code 
            UNIQUE (concept_code),

        CONSTRAINT ck_compensation_concepts_type 
            CHECK (concept_type IN ('HABER', 'DESCUENTO'))
    );
END;
GO


------------------------------------------------------------
-- Tabla: employee_compensation
-- Define compensaciones asignadas a empleados
------------------------------------------------------------

IF OBJECT_ID('rrhh.employee_compensation', 'U') IS NULL
BEGIN
    CREATE TABLE rrhh.employee_compensation (
        employee_compensation_id INT IDENTITY(1,1) NOT NULL,
        employee_id INT NOT NULL,
        base_salary DECIMAL(12,2) NOT NULL,
        valid_from DATE NOT NULL,
        valid_to DATE NULL,
        is_active BIT NOT NULL 
            CONSTRAINT df_employee_compensation_is_active DEFAULT (1),
        created_at DATETIME2 NOT NULL 
            CONSTRAINT df_employee_compensation_created_at DEFAULT (SYSDATETIME()),
        updated_at DATETIME2 NULL,

        CONSTRAINT pk_employee_compensation 
            PRIMARY KEY (employee_compensation_id),

        CONSTRAINT fk_employee_compensation_employees 
            FOREIGN KEY (employee_id) 
            REFERENCES rrhh.employees(employee_id),

        CONSTRAINT ck_employee_compensation_salary 
            CHECK (base_salary > 0),

        CONSTRAINT ck_employee_compensation_dates 
            CHECK (valid_to IS NULL OR valid_to >= valid_from)
    );
END;
GO


------------------------------------------------------------
-- Tabla: payroll_headers
-- Cabecera de liquidación por empleado y período
------------------------------------------------------------

IF OBJECT_ID('rrhh.payroll_headers', 'U') IS NULL
BEGIN
    CREATE TABLE rrhh.payroll_headers (
        payroll_header_id INT IDENTITY(1,1) NOT NULL,
        employee_id INT NOT NULL,
        payroll_period_id INT NOT NULL,
        gross_amount DECIMAL(12,2) NOT NULL 
            CONSTRAINT df_payroll_headers_gross DEFAULT (0),
        discount_amount DECIMAL(12,2) NOT NULL 
            CONSTRAINT df_payroll_headers_discount DEFAULT (0),
        net_amount DECIMAL(12,2) NOT NULL 
            CONSTRAINT df_payroll_headers_net DEFAULT (0),
        payroll_status VARCHAR(30) NOT NULL 
            CONSTRAINT df_payroll_headers_status DEFAULT ('GENERADO'),
        created_at DATETIME2 NOT NULL 
            CONSTRAINT df_payroll_headers_created_at DEFAULT (SYSDATETIME()),
        updated_at DATETIME2 NULL,

        CONSTRAINT pk_payroll_headers 
            PRIMARY KEY (payroll_header_id),

        CONSTRAINT uq_payroll_headers_employee_period 
            UNIQUE (employee_id, payroll_period_id),

        CONSTRAINT fk_payroll_headers_employees 
            FOREIGN KEY (employee_id) 
            REFERENCES rrhh.employees(employee_id),

        CONSTRAINT fk_payroll_headers_periods 
            FOREIGN KEY (payroll_period_id) 
            REFERENCES rrhh.payroll_periods(payroll_period_id),

        CONSTRAINT ck_payroll_headers_amounts 
            CHECK (
                gross_amount >= 0 
                AND discount_amount >= 0 
                AND net_amount >= 0
            ),

        CONSTRAINT ck_payroll_headers_status 
            CHECK (payroll_status IN ('GENERADO', 'PAGADO', 'ANULADO'))
    );
END;
GO


------------------------------------------------------------
-- Tabla: payroll_details
-- Detalle de conceptos liquidados
------------------------------------------------------------

IF OBJECT_ID('rrhh.payroll_details', 'U') IS NULL
BEGIN
    CREATE TABLE rrhh.payroll_details (
        payroll_detail_id INT IDENTITY(1,1) NOT NULL,
        payroll_header_id INT NOT NULL,
        concept_id INT NOT NULL,
        quantity DECIMAL(10,2) NOT NULL 
            CONSTRAINT df_payroll_details_quantity DEFAULT (1),
        amount DECIMAL(12,2) NOT NULL,
        observations VARCHAR(250) NULL,
        created_at DATETIME2 NOT NULL 
            CONSTRAINT df_payroll_details_created_at DEFAULT (SYSDATETIME()),

        CONSTRAINT pk_payroll_details 
            PRIMARY KEY (payroll_detail_id),

        CONSTRAINT fk_payroll_details_headers 
            FOREIGN KEY (payroll_header_id) 
            REFERENCES rrhh.payroll_headers(payroll_header_id),

        CONSTRAINT fk_payroll_details_concepts 
            FOREIGN KEY (concept_id) 
            REFERENCES rrhh.compensation_concepts(concept_id),

        CONSTRAINT ck_payroll_details_quantity 
            CHECK (quantity > 0),

        CONSTRAINT ck_payroll_details_amount 
            CHECK (amount >= 0)
    );
END;
GO


------------------------------------------------------------
-- Índices recomendados
------------------------------------------------------------

IF NOT EXISTS (
    SELECT 1 
    FROM sys.indexes 
    WHERE name = 'ix_employee_compensation_employee_id'
      AND object_id = OBJECT_ID('rrhh.employee_compensation')
)
BEGIN
    CREATE INDEX ix_employee_compensation_employee_id
    ON rrhh.employee_compensation(employee_id);
END;
GO

IF NOT EXISTS (
    SELECT 1 
    FROM sys.indexes 
    WHERE name = 'ix_payroll_headers_employee_id'
      AND object_id = OBJECT_ID('rrhh.payroll_headers')
)
BEGIN
    CREATE INDEX ix_payroll_headers_employee_id
    ON rrhh.payroll_headers(employee_id);
END;
GO

IF NOT EXISTS (
    SELECT 1 
    FROM sys.indexes 
    WHERE name = 'ix_payroll_headers_period_id'
      AND object_id = OBJECT_ID('rrhh.payroll_headers')
)
BEGIN
    CREATE INDEX ix_payroll_headers_period_id
    ON rrhh.payroll_headers(payroll_period_id);
END;
GO

IF NOT EXISTS (
    SELECT 1 
    FROM sys.indexes 
    WHERE name = 'ix_payroll_details_header_id'
      AND object_id = OBJECT_ID('rrhh.payroll_details')
)
BEGIN
    CREATE INDEX ix_payroll_details_header_id
    ON rrhh.payroll_details(payroll_header_id);
END;
GO

IF NOT EXISTS (
    SELECT 1 
    FROM sys.indexes 
    WHERE name = 'ix_payroll_details_concept_id'
      AND object_id = OBJECT_ID('rrhh.payroll_details')
)
BEGIN
    CREATE INDEX ix_payroll_details_concept_id
    ON rrhh.payroll_details(concept_id);
END;
GO


------------------------------------------------------------
-- Vista: vw_nomina_resumen
-- Resume liquidaciones por empleado y período
------------------------------------------------------------

CREATE OR ALTER VIEW rrhh.vw_nomina_resumen AS
SELECT
    ph.payroll_header_id,
    pp.period_name,
    pp.period_year,
    pp.period_month,
    e.employee_id,
    e.employee_code,
    e.first_name,
    e.last_name,
    p.position_name,
    d.department_name,
    ph.gross_amount,
    ph.discount_amount,
    ph.net_amount,
    ph.payroll_status
FROM rrhh.payroll_headers ph
INNER JOIN rrhh.payroll_periods pp
    ON ph.payroll_period_id = pp.payroll_period_id
INNER JOIN rrhh.employees e
    ON ph.employee_id = e.employee_id
INNER JOIN rrhh.positions p
    ON e.position_id = p.position_id
INNER JOIN rrhh.departments d
    ON p.department_id = d.department_id;
GO


------------------------------------------------------------
-- Vista: vw_nomina_detalle
-- Detalle completo de conceptos liquidados
------------------------------------------------------------

CREATE OR ALTER VIEW rrhh.vw_nomina_detalle AS
SELECT
    ph.payroll_header_id,
    pp.period_name,
    e.employee_code,
    e.first_name,
    e.last_name,
    cc.concept_code,
    cc.concept_name,
    cc.concept_type,
    pd.quantity,
    pd.amount,
    pd.observations
FROM rrhh.payroll_details pd
INNER JOIN rrhh.payroll_headers ph
    ON pd.payroll_header_id = ph.payroll_header_id
INNER JOIN rrhh.payroll_periods pp
    ON ph.payroll_period_id = pp.payroll_period_id
INNER JOIN rrhh.employees e
    ON ph.employee_id = e.employee_id
INNER JOIN rrhh.compensation_concepts cc
    ON pd.concept_id = cc.concept_id;
GO


------------------------------------------------------------
-- Permisos para app_user
-- Ajustar el nombre del usuario si corresponde.
------------------------------------------------------------

GRANT SELECT, INSERT, UPDATE ON rrhh.payroll_periods TO datacore_app;
GRANT SELECT, INSERT, UPDATE ON rrhh.compensation_concepts TO datacore_app;
GRANT SELECT, INSERT, UPDATE ON rrhh.employee_compensation TO datacore_app;
GRANT SELECT, INSERT, UPDATE ON rrhh.payroll_headers TO datacore_app;
GRANT SELECT, INSERT, UPDATE ON rrhh.payroll_details TO datacore_app;

GRANT SELECT ON rrhh.vw_nomina_resumen TO datacore_app;
GRANT SELECT ON rrhh.vw_nomina_detalle TO datacore_app;
GO