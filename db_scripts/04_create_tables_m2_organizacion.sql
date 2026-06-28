USE DataCoreRRHH;
GO

/* ============================================================
   M2 - Organización y Cargos
   Archivo: 03_create_tables_m2_organizacion.sql

   Entidades:
   - rrhh.departments
   - rrhh.job_levels
   - rrhh.positions
   - rrhh.reporting_structure
   ============================================================ */

CREATE TABLE rrhh.departments (
    department_id INT IDENTITY(1,1) PRIMARY KEY,
    department_name VARCHAR(100) NOT NULL,
    description VARCHAR(255) NULL,
    is_active BIT NOT NULL DEFAULT 1,
    created_at DATETIME2 NOT NULL DEFAULT SYSDATETIME(),

    CONSTRAINT uq_departments_department_name 
        UNIQUE (department_name)
);
GO

CREATE TABLE rrhh.job_levels (
    job_level_id INT IDENTITY(1,1) PRIMARY KEY,
    level_number INT NOT NULL,
    level_name VARCHAR(100) NOT NULL,
    description VARCHAR(255) NULL,
    min_salary DECIMAL(12,2) NOT NULL,
    max_salary DECIMAL(12,2) NOT NULL,
    is_active BIT NOT NULL DEFAULT 1,
    created_at DATETIME2 NOT NULL DEFAULT SYSDATETIME(),

    CONSTRAINT uq_job_levels_level_number 
        UNIQUE (level_number),

    CONSTRAINT ck_job_levels_salary_range 
        CHECK (min_salary >= 0 AND max_salary >= min_salary)
);
GO

CREATE TABLE rrhh.positions (
    position_id INT IDENTITY(1,1) PRIMARY KEY,
    department_id INT NOT NULL,
    job_level_id INT NOT NULL,
    position_name VARCHAR(100) NOT NULL,
    description VARCHAR(255) NULL,
    base_salary DECIMAL(12,2) NOT NULL,
    is_active BIT NOT NULL DEFAULT 1,
    created_at DATETIME2 NOT NULL DEFAULT SYSDATETIME(),

    CONSTRAINT fk_positions_departments
        FOREIGN KEY (department_id)
        REFERENCES rrhh.departments(department_id),

    CONSTRAINT fk_positions_job_levels
        FOREIGN KEY (job_level_id)
        REFERENCES rrhh.job_levels(job_level_id),

    CONSTRAINT uq_positions_department_position
        UNIQUE (department_id, position_name),

    CONSTRAINT ck_positions_base_salary
        CHECK (base_salary >= 0)
);
GO

CREATE TABLE rrhh.reporting_structure (
    reporting_structure_id INT IDENTITY(1,1) PRIMARY KEY,
    position_id INT NOT NULL,
    reports_to_position_id INT NULL,
    effective_from DATE NOT NULL,
    effective_to DATE NULL,
    is_active BIT NOT NULL DEFAULT 1,
    created_at DATETIME2 NOT NULL DEFAULT SYSDATETIME(),

    CONSTRAINT fk_reporting_structure_position
        FOREIGN KEY (position_id)
        REFERENCES rrhh.positions(position_id),

    CONSTRAINT fk_reporting_structure_reports_to_position
        FOREIGN KEY (reports_to_position_id)
        REFERENCES rrhh.positions(position_id),

    CONSTRAINT ck_reporting_structure_not_self_reporting
        CHECK (position_id <> reports_to_position_id),

    CONSTRAINT ck_reporting_structure_dates
        CHECK (effective_to IS NULL OR effective_to >= effective_from)
);
GO