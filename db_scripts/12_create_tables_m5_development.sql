USE DataCoreRRHH;
GO

/* =========================================================
   Módulo 5 - Desempeño y Capacitación
   Script: 12_create_development_module.sql
   Ejecutar con usuario admin
   ========================================================= */

------------------------------------------------------------
-- Tabla: performance_review_periods
-- Define períodos de evaluación de desempeño
------------------------------------------------------------

IF OBJECT_ID('rrhh.performance_review_periods', 'U') IS NULL
BEGIN
    CREATE TABLE rrhh.performance_review_periods (
        review_period_id INT IDENTITY(1,1) NOT NULL,
        period_name VARCHAR(100) NOT NULL,
        start_date DATE NOT NULL,
        end_date DATE NOT NULL,
        period_status VARCHAR(30) NOT NULL
            CONSTRAINT df_performance_review_periods_status DEFAULT ('ABIERTO'),
        created_at DATETIME2 NOT NULL
            CONSTRAINT df_performance_review_periods_created_at DEFAULT (SYSDATETIME()),
        updated_at DATETIME2 NULL,

        CONSTRAINT pk_performance_review_periods
            PRIMARY KEY (review_period_id),

        CONSTRAINT uq_performance_review_periods_name
            UNIQUE (period_name),

        CONSTRAINT ck_performance_review_periods_dates
            CHECK (end_date >= start_date),

        CONSTRAINT ck_performance_review_periods_status
            CHECK (period_status IN ('ABIERTO', 'CERRADO', 'ANULADO'))
    );
END;
GO


------------------------------------------------------------
-- Tabla: performance_reviews
-- Registra evaluaciones de desempeño por empleado y período
------------------------------------------------------------

IF OBJECT_ID('rrhh.performance_reviews', 'U') IS NULL
BEGIN
    CREATE TABLE rrhh.performance_reviews (
        performance_review_id INT IDENTITY(1,1) NOT NULL,
        employee_id INT NOT NULL,
        reviewer_employee_id INT NULL,
        review_period_id INT NOT NULL,
        review_date DATE NOT NULL,
        score DECIMAL(5,2) NOT NULL,
        strengths VARCHAR(500) NULL,
        improvement_areas VARCHAR(500) NULL,
        comments VARCHAR(500) NULL,
        review_status VARCHAR(30) NOT NULL
            CONSTRAINT df_performance_reviews_status DEFAULT ('BORRADOR'),
        created_at DATETIME2 NOT NULL
            CONSTRAINT df_performance_reviews_created_at DEFAULT (SYSDATETIME()),
        updated_at DATETIME2 NULL,

        CONSTRAINT pk_performance_reviews
            PRIMARY KEY (performance_review_id),

        CONSTRAINT uq_performance_reviews_employee_period
            UNIQUE (employee_id, review_period_id),

        CONSTRAINT fk_performance_reviews_employee
            FOREIGN KEY (employee_id)
            REFERENCES rrhh.employees(employee_id),

        CONSTRAINT fk_performance_reviews_reviewer
            FOREIGN KEY (reviewer_employee_id)
            REFERENCES rrhh.employees(employee_id),

        CONSTRAINT fk_performance_reviews_period
            FOREIGN KEY (review_period_id)
            REFERENCES rrhh.performance_review_periods(review_period_id),

        CONSTRAINT ck_performance_reviews_score
            CHECK (score >= 0 AND score <= 10),

        CONSTRAINT ck_performance_reviews_status
            CHECK (review_status IN ('BORRADOR', 'FINALIZADA', 'ANULADA'))
    );
END;
GO


------------------------------------------------------------
-- Tabla: training_courses
-- Define cursos o capacitaciones disponibles
------------------------------------------------------------

IF OBJECT_ID('rrhh.training_courses', 'U') IS NULL
BEGIN
    CREATE TABLE rrhh.training_courses (
        training_course_id INT IDENTITY(1,1) NOT NULL,
        course_code VARCHAR(30) NOT NULL,
        course_name VARCHAR(150) NOT NULL,
        provider VARCHAR(120) NULL,
        duration_hours DECIMAL(6,2) NOT NULL,
        course_type VARCHAR(50) NOT NULL,
        is_active BIT NOT NULL
            CONSTRAINT df_training_courses_is_active DEFAULT (1),
        created_at DATETIME2 NOT NULL
            CONSTRAINT df_training_courses_created_at DEFAULT (SYSDATETIME()),
        updated_at DATETIME2 NULL,

        CONSTRAINT pk_training_courses
            PRIMARY KEY (training_course_id),

        CONSTRAINT uq_training_courses_code
            UNIQUE (course_code),

        CONSTRAINT ck_training_courses_duration
            CHECK (duration_hours > 0),

        CONSTRAINT ck_training_courses_type
            CHECK (course_type IN ('TECNICA', 'BLANDA', 'OBLIGATORIA', 'SEGURIDAD'))
    );
END;
GO


------------------------------------------------------------
-- Tabla: employee_training
-- Registra capacitaciones asignadas a empleados
------------------------------------------------------------

IF OBJECT_ID('rrhh.employee_training', 'U') IS NULL
BEGIN
    CREATE TABLE rrhh.employee_training (
        employee_training_id INT IDENTITY(1,1) NOT NULL,
        employee_id INT NOT NULL,
        training_course_id INT NOT NULL,
        enrollment_date DATE NOT NULL,
        completion_date DATE NULL,
        training_status VARCHAR(30) NOT NULL
            CONSTRAINT df_employee_training_status DEFAULT ('INSCRIPTO'),
        result_score DECIMAL(5,2) NULL,
        observations VARCHAR(250) NULL,
        created_at DATETIME2 NOT NULL
            CONSTRAINT df_employee_training_created_at DEFAULT (SYSDATETIME()),
        updated_at DATETIME2 NULL,

        CONSTRAINT pk_employee_training
            PRIMARY KEY (employee_training_id),

        CONSTRAINT uq_employee_training_employee_course
            UNIQUE (employee_id, training_course_id),

        CONSTRAINT fk_employee_training_employee
            FOREIGN KEY (employee_id)
            REFERENCES rrhh.employees(employee_id),

        CONSTRAINT fk_employee_training_course
            FOREIGN KEY (training_course_id)
            REFERENCES rrhh.training_courses(training_course_id),

        CONSTRAINT ck_employee_training_dates
            CHECK (completion_date IS NULL OR completion_date >= enrollment_date),

        CONSTRAINT ck_employee_training_status
            CHECK (training_status IN ('INSCRIPTO', 'EN_CURSO', 'COMPLETADO', 'CANCELADO')),

        CONSTRAINT ck_employee_training_result_score
            CHECK (result_score IS NULL OR (result_score >= 0 AND result_score <= 10))
    );
END;
GO


------------------------------------------------------------
-- Índices recomendados
------------------------------------------------------------

IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = 'ix_performance_reviews_employee_id'
      AND object_id = OBJECT_ID('rrhh.performance_reviews')
)
BEGIN
    CREATE INDEX ix_performance_reviews_employee_id
    ON rrhh.performance_reviews(employee_id);
END;
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = 'ix_performance_reviews_period_id'
      AND object_id = OBJECT_ID('rrhh.performance_reviews')
)
BEGIN
    CREATE INDEX ix_performance_reviews_period_id
    ON rrhh.performance_reviews(review_period_id);
END;
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = 'ix_employee_training_employee_id'
      AND object_id = OBJECT_ID('rrhh.employee_training')
)
BEGIN
    CREATE INDEX ix_employee_training_employee_id
    ON rrhh.employee_training(employee_id);
END;
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = 'ix_employee_training_course_id'
      AND object_id = OBJECT_ID('rrhh.employee_training')
)
BEGIN
    CREATE INDEX ix_employee_training_course_id
    ON rrhh.employee_training(training_course_id);
END;
GO


------------------------------------------------------------
-- Vista: vw_desempeno_resumen
-- Resume evaluaciones de desempeño por empleado
------------------------------------------------------------

CREATE OR ALTER VIEW rrhh.vw_desempeno_resumen AS
SELECT
    pr.performance_review_id,
    rperiod.period_name,
    e.employee_id,
    e.employee_code,
    e.first_name,
    e.last_name,
    p.position_name,
    d.department_name,
    reviewer.employee_code AS reviewer_code,
    reviewer.first_name AS reviewer_first_name,
    reviewer.last_name AS reviewer_last_name,
    pr.review_date,
    pr.score,
    pr.review_status,
    pr.strengths,
    pr.improvement_areas,
    pr.comments
FROM rrhh.performance_reviews pr
INNER JOIN rrhh.performance_review_periods rperiod
    ON pr.review_period_id = rperiod.review_period_id
INNER JOIN rrhh.employees e
    ON pr.employee_id = e.employee_id
INNER JOIN rrhh.positions p
    ON e.position_id = p.position_id
INNER JOIN rrhh.departments d
    ON p.department_id = d.department_id
LEFT JOIN rrhh.employees reviewer
    ON pr.reviewer_employee_id = reviewer.employee_id;
GO


------------------------------------------------------------
-- Vista: vw_capacitaciones_empleado
-- Muestra capacitaciones asignadas por empleado
------------------------------------------------------------

CREATE OR ALTER VIEW rrhh.vw_capacitaciones_empleado AS
SELECT
    et.employee_training_id,
    e.employee_id,
    e.employee_code,
    e.first_name,
    e.last_name,
    p.position_name,
    d.department_name,
    tc.course_code,
    tc.course_name,
    tc.provider,
    tc.duration_hours,
    tc.course_type,
    et.enrollment_date,
    et.completion_date,
    et.training_status,
    et.result_score,
    et.observations
FROM rrhh.employee_training et
INNER JOIN rrhh.employees e
    ON et.employee_id = e.employee_id
INNER JOIN rrhh.training_courses tc
    ON et.training_course_id = tc.training_course_id
INNER JOIN rrhh.positions p
    ON e.position_id = p.position_id
INNER JOIN rrhh.departments d
    ON p.department_id = d.department_id;
GO


------------------------------------------------------------
-- Permisos para app_user
-- Ajustar el nombre del usuario si corresponde.
------------------------------------------------------------

GRANT SELECT, INSERT, UPDATE ON rrhh.performance_review_periods TO datacore_app;
GRANT SELECT, INSERT, UPDATE ON rrhh.performance_reviews TO datacore_app;
GRANT SELECT, INSERT, UPDATE ON rrhh.training_courses TO datacore_app;
GRANT SELECT, INSERT, UPDATE ON rrhh.employee_training TO datacore_app;

GRANT SELECT ON rrhh.vw_desempeno_resumen TO datacore_app;
GRANT SELECT ON rrhh.vw_capacitaciones_empleado TO datacore_app;
GO
