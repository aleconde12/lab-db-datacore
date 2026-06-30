USE DataCoreRRHH;
GO

/* =========================================================
   Módulo 4 - Asistencia y Tiempo
   Script: 10_create_attendance_module.sql
   Ejecutar con usuario admin
   ========================================================= */

------------------------------------------------------------
-- Tabla: attendance_types
-- Define los tipos de asistencia o novedades
------------------------------------------------------------

IF OBJECT_ID('rrhh.attendance_types', 'U') IS NULL
BEGIN
    CREATE TABLE rrhh.attendance_types (
        attendance_type_id INT IDENTITY(1,1) NOT NULL,
        type_code VARCHAR(30) NOT NULL,
        type_name VARCHAR(100) NOT NULL,
        description VARCHAR(250) NULL,
        affects_worked_hours BIT NOT NULL 
            CONSTRAINT df_attendance_types_affects_worked_hours DEFAULT (1),
        is_active BIT NOT NULL 
            CONSTRAINT df_attendance_types_is_active DEFAULT (1),
        created_at DATETIME2 NOT NULL 
            CONSTRAINT df_attendance_types_created_at DEFAULT (SYSDATETIME()),
        updated_at DATETIME2 NULL,

        CONSTRAINT pk_attendance_types 
            PRIMARY KEY (attendance_type_id),

        CONSTRAINT uq_attendance_types_code 
            UNIQUE (type_code)
    );
END;
GO


------------------------------------------------------------
-- Tabla: work_schedules
-- Define horarios o jornadas laborales
------------------------------------------------------------

IF OBJECT_ID('rrhh.work_schedules', 'U') IS NULL
BEGIN
    CREATE TABLE rrhh.work_schedules (
        work_schedule_id INT IDENTITY(1,1) NOT NULL,
        schedule_name VARCHAR(100) NOT NULL,
        start_time TIME NOT NULL,
        end_time TIME NOT NULL,
        expected_hours DECIMAL(5,2) NOT NULL,
        description VARCHAR(250) NULL,
        is_active BIT NOT NULL 
            CONSTRAINT df_work_schedules_is_active DEFAULT (1),
        created_at DATETIME2 NOT NULL 
            CONSTRAINT df_work_schedules_created_at DEFAULT (SYSDATETIME()),
        updated_at DATETIME2 NULL,

        CONSTRAINT pk_work_schedules 
            PRIMARY KEY (work_schedule_id),

        CONSTRAINT uq_work_schedules_name 
            UNIQUE (schedule_name),

        CONSTRAINT ck_work_schedules_expected_hours 
            CHECK (expected_hours > 0 AND expected_hours <= 24),

        CONSTRAINT ck_work_schedules_time_range 
            CHECK (end_time > start_time)
    );
END;
GO


------------------------------------------------------------
-- Tabla: employee_schedules
-- Asigna horarios laborales a empleados
------------------------------------------------------------

IF OBJECT_ID('rrhh.employee_schedules', 'U') IS NULL
BEGIN
    CREATE TABLE rrhh.employee_schedules (
        employee_schedule_id INT IDENTITY(1,1) NOT NULL,
        employee_id INT NOT NULL,
        work_schedule_id INT NOT NULL,
        valid_from DATE NOT NULL,
        valid_to DATE NULL,
        is_active BIT NOT NULL 
            CONSTRAINT df_employee_schedules_is_active DEFAULT (1),
        created_at DATETIME2 NOT NULL 
            CONSTRAINT df_employee_schedules_created_at DEFAULT (SYSDATETIME()),
        updated_at DATETIME2 NULL,

        CONSTRAINT pk_employee_schedules 
            PRIMARY KEY (employee_schedule_id),

        CONSTRAINT fk_employee_schedules_employees 
            FOREIGN KEY (employee_id) 
            REFERENCES rrhh.employees(employee_id),

        CONSTRAINT fk_employee_schedules_work_schedules 
            FOREIGN KEY (work_schedule_id) 
            REFERENCES rrhh.work_schedules(work_schedule_id),

        CONSTRAINT ck_employee_schedules_dates 
            CHECK (valid_to IS NULL OR valid_to >= valid_from)
    );
END;
GO


------------------------------------------------------------
-- Tabla: attendance_records
-- Registra la asistencia diaria del empleado
------------------------------------------------------------

IF OBJECT_ID('rrhh.attendance_records', 'U') IS NULL
BEGIN
    CREATE TABLE rrhh.attendance_records (
        attendance_record_id INT IDENTITY(1,1) NOT NULL,
        employee_id INT NOT NULL,
        attendance_type_id INT NOT NULL,
        attendance_date DATE NOT NULL,
        check_in_time TIME NULL,
        check_out_time TIME NULL,
        worked_hours DECIMAL(5,2) NOT NULL 
            CONSTRAINT df_attendance_records_worked_hours DEFAULT (0),
        observations VARCHAR(250) NULL,
        created_at DATETIME2 NOT NULL 
            CONSTRAINT df_attendance_records_created_at DEFAULT (SYSDATETIME()),
        updated_at DATETIME2 NULL,

        CONSTRAINT pk_attendance_records 
            PRIMARY KEY (attendance_record_id),

        CONSTRAINT uq_attendance_records_employee_date 
            UNIQUE (employee_id, attendance_date),

        CONSTRAINT fk_attendance_records_employees 
            FOREIGN KEY (employee_id) 
            REFERENCES rrhh.employees(employee_id),

        CONSTRAINT fk_attendance_records_attendance_types 
            FOREIGN KEY (attendance_type_id) 
            REFERENCES rrhh.attendance_types(attendance_type_id),

        CONSTRAINT ck_attendance_records_date 
            CHECK (attendance_date <= CAST(SYSDATETIME() AS DATE)),

        CONSTRAINT ck_attendance_records_worked_hours 
            CHECK (worked_hours >= 0 AND worked_hours <= 24),

        CONSTRAINT ck_attendance_records_time_range 
            CHECK (
                check_in_time IS NULL 
                OR check_out_time IS NULL 
                OR check_out_time >= check_in_time
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
    WHERE name = 'ix_employee_schedules_employee_id'
      AND object_id = OBJECT_ID('rrhh.employee_schedules')
)
BEGIN
    CREATE INDEX ix_employee_schedules_employee_id
    ON rrhh.employee_schedules(employee_id);
END;
GO

IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = 'ix_employee_schedules_work_schedule_id'
      AND object_id = OBJECT_ID('rrhh.employee_schedules')
)
BEGIN
    CREATE INDEX ix_employee_schedules_work_schedule_id
    ON rrhh.employee_schedules(work_schedule_id);
END;
GO

IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = 'ix_attendance_records_employee_id'
      AND object_id = OBJECT_ID('rrhh.attendance_records')
)
BEGIN
    CREATE INDEX ix_attendance_records_employee_id
    ON rrhh.attendance_records(employee_id);
END;
GO

IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = 'ix_attendance_records_attendance_date'
      AND object_id = OBJECT_ID('rrhh.attendance_records')
)
BEGIN
    CREATE INDEX ix_attendance_records_attendance_date
    ON rrhh.attendance_records(attendance_date);
END;
GO

IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = 'ix_attendance_records_attendance_type_id'
      AND object_id = OBJECT_ID('rrhh.attendance_records')
)
BEGIN
    CREATE INDEX ix_attendance_records_attendance_type_id
    ON rrhh.attendance_records(attendance_type_id);
END;
GO


------------------------------------------------------------
-- Vista: vw_asistencia_resumen
-- Muestra asistencia diaria con empleado, cargo y departamento
------------------------------------------------------------

CREATE OR ALTER VIEW rrhh.vw_asistencia_resumen AS
SELECT
    ar.attendance_record_id,
    ar.attendance_date,
    e.employee_id,
    e.employee_code,
    e.first_name,
    e.last_name,
    p.position_name,
    d.department_name,
    at.type_code,
    at.type_name,
    ar.check_in_time,
    ar.check_out_time,
    ar.worked_hours,
    ar.observations
FROM rrhh.attendance_records ar
INNER JOIN rrhh.employees e
    ON ar.employee_id = e.employee_id
INNER JOIN rrhh.positions p
    ON e.position_id = p.position_id
INNER JOIN rrhh.departments d
    ON p.department_id = d.department_id
INNER JOIN rrhh.attendance_types at
    ON ar.attendance_type_id = at.attendance_type_id;
GO


------------------------------------------------------------
-- Vista: vw_asistencia_por_empleado
-- Resume días y horas trabajadas por empleado
------------------------------------------------------------

CREATE OR ALTER VIEW rrhh.vw_asistencia_por_empleado AS
SELECT
    e.employee_id,
    e.employee_code,
    e.first_name,
    e.last_name,
    COUNT(ar.attendance_record_id) AS total_registros,
    SUM(CASE WHEN at.affects_worked_hours = 1 THEN ar.worked_hours ELSE 0 END) AS total_horas_trabajadas,
    SUM(CASE WHEN at.type_code = 'PRESENTE' THEN 1 ELSE 0 END) AS dias_presente,
    SUM(CASE WHEN at.type_code = 'AUSENTE' THEN 1 ELSE 0 END) AS dias_ausente,
    SUM(CASE WHEN at.type_code = 'LLEGADA_TARDE' THEN 1 ELSE 0 END) AS llegadas_tarde,
    SUM(CASE WHEN at.type_code = 'HOME_OFFICE' THEN 1 ELSE 0 END) AS dias_home_office
FROM rrhh.employees e
LEFT JOIN rrhh.attendance_records ar
    ON e.employee_id = ar.employee_id
LEFT JOIN rrhh.attendance_types at
    ON ar.attendance_type_id = at.attendance_type_id
GROUP BY
    e.employee_id,
    e.employee_code,
    e.first_name,
    e.last_name;
GO


------------------------------------------------------------
-- Permisos para app_user
-- Ajustar el nombre del usuario si corresponde.
------------------------------------------------------------

GRANT SELECT, INSERT, UPDATE ON rrhh.attendance_types TO datacore_app;
GRANT SELECT, INSERT, UPDATE ON rrhh.work_schedules TO datacore_app;
GRANT SELECT, INSERT, UPDATE ON rrhh.employee_schedules TO datacore_app;
GRANT SELECT, INSERT, UPDATE ON rrhh.attendance_records TO datacore_app;

GRANT SELECT ON rrhh.vw_asistencia_resumen TO datacore_app;
GRANT SELECT ON rrhh.vw_asistencia_por_empleado TO datacore_app;
GO