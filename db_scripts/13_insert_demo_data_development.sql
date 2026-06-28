USE DataCoreRRHH;
GO

/* =========================================================
   Módulo 5 - Desempeño y Capacitación
   Script: 13_insert_demo_data_development.sql
   Ejecutar con app_user
   ========================================================= */

------------------------------------------------------------
-- Validación previa
------------------------------------------------------------

IF NOT EXISTS (SELECT 1 FROM rrhh.employees WHERE is_active = 1)
BEGIN
    RAISERROR('No existen empleados activos. Ejecutar primero demo data del Módulo 1.', 16, 1);
    RETURN;
END;
GO


------------------------------------------------------------
-- performance_review_periods
------------------------------------------------------------

INSERT INTO rrhh.performance_review_periods (
    period_name,
    start_date,
    end_date,
    period_status
)
SELECT
    'Evaluación 1er Semestre 2026',
    '2026-01-01',
    '2026-06-30',
    'ABIERTO'
WHERE NOT EXISTS (
    SELECT 1
    FROM rrhh.performance_review_periods
    WHERE period_name = 'Evaluación 1er Semestre 2026'
);
GO


------------------------------------------------------------
-- training_courses
------------------------------------------------------------

INSERT INTO rrhh.training_courses (
    course_code,
    course_name,
    provider,
    duration_hours,
    course_type,
    is_active
)
SELECT
    'SEG-001',
    'Seguridad e higiene laboral',
    'DataCore Academy',
    8.00,
    'SEGURIDAD',
    1
WHERE NOT EXISTS (
    SELECT 1 FROM rrhh.training_courses WHERE course_code = 'SEG-001'
);

INSERT INTO rrhh.training_courses (
    course_code,
    course_name,
    provider,
    duration_hours,
    course_type,
    is_active
)
SELECT
    'TEC-001',
    'SQL Server básico para usuarios internos',
    'DataCore Academy',
    12.00,
    'TECNICA',
    1
WHERE NOT EXISTS (
    SELECT 1 FROM rrhh.training_courses WHERE course_code = 'TEC-001'
);

INSERT INTO rrhh.training_courses (
    course_code,
    course_name,
    provider,
    duration_hours,
    course_type,
    is_active
)
SELECT
    'BLA-001',
    'Comunicación y trabajo en equipo',
    'Consultora externa',
    6.00,
    'BLANDA',
    1
WHERE NOT EXISTS (
    SELECT 1 FROM rrhh.training_courses WHERE course_code = 'BLA-001'
);

INSERT INTO rrhh.training_courses (
    course_code,
    course_name,
    provider,
    duration_hours,
    course_type,
    is_active
)
SELECT
    'OBL-001',
    'Inducción institucional',
    'Recursos Humanos',
    4.00,
    'OBLIGATORIA',
    1
WHERE NOT EXISTS (
    SELECT 1 FROM rrhh.training_courses WHERE course_code = 'OBL-001'
);
GO


------------------------------------------------------------
-- performance_reviews
------------------------------------------------------------

DECLARE @period_semestre INT;
DECLARE @emp_juan INT;
DECLARE @emp_maria INT;
DECLARE @emp_carlos INT;

SELECT @period_semestre = review_period_id
FROM rrhh.performance_review_periods
WHERE period_name = 'Evaluación 1er Semestre 2026';

SELECT @emp_juan = employee_id
FROM rrhh.employees
WHERE employee_code = 'EMP001';

SELECT @emp_maria = employee_id
FROM rrhh.employees
WHERE employee_code = 'EMP002';

SELECT @emp_carlos = employee_id
FROM rrhh.employees
WHERE employee_code = 'EMP003';


IF @emp_juan IS NOT NULL AND @period_semestre IS NOT NULL
BEGIN
    INSERT INTO rrhh.performance_reviews (
        employee_id,
        reviewer_employee_id,
        review_period_id,
        review_date,
        score,
        strengths,
        improvement_areas,
        comments,
        review_status
    )
    SELECT
        @emp_juan,
        @emp_maria,
        @period_semestre,
        '2026-06-25',
        8.50,
        'Buen desempeño técnico y cumplimiento de objetivos.',
        'Mejorar documentación de tareas recurrentes.',
        'Evaluación positiva del semestre.',
        'FINALIZADA'
    WHERE NOT EXISTS (
        SELECT 1
        FROM rrhh.performance_reviews
        WHERE employee_id = @emp_juan
          AND review_period_id = @period_semestre
    );
END;

IF @emp_maria IS NOT NULL AND @period_semestre IS NOT NULL
BEGIN
    INSERT INTO rrhh.performance_reviews (
        employee_id,
        reviewer_employee_id,
        review_period_id,
        review_date,
        score,
        strengths,
        improvement_areas,
        comments,
        review_status
    )
    SELECT
        @emp_maria,
        NULL,
        @period_semestre,
        '2026-06-26',
        9.00,
        'Liderazgo, planificación y seguimiento del equipo.',
        'Delegar más tareas operativas.',
        'Muy buen desempeño general.',
        'FINALIZADA'
    WHERE NOT EXISTS (
        SELECT 1
        FROM rrhh.performance_reviews
        WHERE employee_id = @emp_maria
          AND review_period_id = @period_semestre
    );
END;

IF @emp_carlos IS NOT NULL AND @period_semestre IS NOT NULL
BEGIN
    INSERT INTO rrhh.performance_reviews (
        employee_id,
        reviewer_employee_id,
        review_period_id,
        review_date,
        score,
        strengths,
        improvement_areas,
        comments,
        review_status
    )
    SELECT
        @emp_carlos,
        @emp_maria,
        @period_semestre,
        '2026-06-27',
        7.25,
        'Buena predisposición y aprendizaje rápido.',
        'Profundizar conocimiento de procesos internos.',
        'Desempeño correcto con oportunidades de mejora.',
        'FINALIZADA'
    WHERE NOT EXISTS (
        SELECT 1
        FROM rrhh.performance_reviews
        WHERE employee_id = @emp_carlos
          AND review_period_id = @period_semestre
    );
END;
GO


------------------------------------------------------------
-- employee_training
------------------------------------------------------------

DECLARE @emp_juan INT;
DECLARE @emp_maria INT;
DECLARE @emp_carlos INT;

DECLARE @course_seguridad INT;
DECLARE @course_sql INT;
DECLARE @course_comunicacion INT;
DECLARE @course_induccion INT;

SELECT @emp_juan = employee_id
FROM rrhh.employees
WHERE employee_code = 'EMP001';

SELECT @emp_maria = employee_id
FROM rrhh.employees
WHERE employee_code = 'EMP002';

SELECT @emp_carlos = employee_id
FROM rrhh.employees
WHERE employee_code = 'EMP003';

SELECT @course_seguridad = training_course_id
FROM rrhh.training_courses
WHERE course_code = 'SEG-001';

SELECT @course_sql = training_course_id
FROM rrhh.training_courses
WHERE course_code = 'TEC-001';

SELECT @course_comunicacion = training_course_id
FROM rrhh.training_courses
WHERE course_code = 'BLA-001';

SELECT @course_induccion = training_course_id
FROM rrhh.training_courses
WHERE course_code = 'OBL-001';


IF @emp_juan IS NOT NULL AND @course_sql IS NOT NULL
BEGIN
    INSERT INTO rrhh.employee_training (
        employee_id,
        training_course_id,
        enrollment_date,
        completion_date,
        training_status,
        result_score,
        observations
    )
    SELECT
        @emp_juan,
        @course_sql,
        '2026-06-03',
        '2026-06-18',
        'COMPLETADO',
        9.00,
        'Curso finalizado correctamente'
    WHERE NOT EXISTS (
        SELECT 1
        FROM rrhh.employee_training
        WHERE employee_id = @emp_juan
          AND training_course_id = @course_sql
    );
END;

IF @emp_juan IS NOT NULL AND @course_seguridad IS NOT NULL
BEGIN
    INSERT INTO rrhh.employee_training (
        employee_id,
        training_course_id,
        enrollment_date,
        completion_date,
        training_status,
        result_score,
        observations
    )
    SELECT
        @emp_juan,
        @course_seguridad,
        '2026-06-05',
        NULL,
        'EN_CURSO',
        NULL,
        'Capacitación obligatoria en curso'
    WHERE NOT EXISTS (
        SELECT 1
        FROM rrhh.employee_training
        WHERE employee_id = @emp_juan
          AND training_course_id = @course_seguridad
    );
END;

IF @emp_maria IS NOT NULL AND @course_comunicacion IS NOT NULL
BEGIN
    INSERT INTO rrhh.employee_training (
        employee_id,
        training_course_id,
        enrollment_date,
        completion_date,
        training_status,
        result_score,
        observations
    )
    SELECT
        @emp_maria,
        @course_comunicacion,
        '2026-06-07',
        '2026-06-20',
        'COMPLETADO',
        8.50,
        'Capacitación de liderazgo y comunicación'
    WHERE NOT EXISTS (
        SELECT 1
        FROM rrhh.employee_training
        WHERE employee_id = @emp_maria
          AND training_course_id = @course_comunicacion
    );
END;

IF @emp_carlos IS NOT NULL AND @course_induccion IS NOT NULL
BEGIN
    INSERT INTO rrhh.employee_training (
        employee_id,
        training_course_id,
        enrollment_date,
        completion_date,
        training_status,
        result_score,
        observations
    )
    SELECT
        @emp_carlos,
        @course_induccion,
        '2026-06-01',
        '2026-06-04',
        'COMPLETADO',
        8.00,
        'Inducción inicial completada'
    WHERE NOT EXISTS (
        SELECT 1
        FROM rrhh.employee_training
        WHERE employee_id = @emp_carlos
          AND training_course_id = @course_induccion
    );
END;

IF @emp_carlos IS NOT NULL AND @course_seguridad IS NOT NULL
BEGIN
    INSERT INTO rrhh.employee_training (
        employee_id,
        training_course_id,
        enrollment_date,
        completion_date,
        training_status,
        result_score,
        observations
    )
    SELECT
        @emp_carlos,
        @course_seguridad,
        '2026-06-05',
        NULL,
        'INSCRIPTO',
        NULL,
        'Pendiente de inicio'
    WHERE NOT EXISTS (
        SELECT 1
        FROM rrhh.employee_training
        WHERE employee_id = @emp_carlos
          AND training_course_id = @course_seguridad
    );
END;
GO


------------------------------------------------------------
-- Consultas de validación
------------------------------------------------------------

SELECT *
FROM rrhh.performance_review_periods;

SELECT *
FROM rrhh.training_courses;

SELECT *
FROM rrhh.performance_reviews;

SELECT *
FROM rrhh.employee_training;

SELECT *
FROM rrhh.vw_desempeno_resumen
ORDER BY employee_code;

SELECT *
FROM rrhh.vw_capacitaciones_empleado
ORDER BY employee_code, course_code;
GO
