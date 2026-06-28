USE DataCoreRRHH;
GO

/* =========================================================
   Módulo 4 - Asistencia y Tiempo
   Script: 11_insert_demo_data_attendance.sql
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
-- attendance_types
------------------------------------------------------------

INSERT INTO rrhh.attendance_types (
    type_code,
    type_name,
    description,
    affects_worked_hours,
    is_active
)
SELECT
    'PRESENTE',
    'Presente',
    'Empleado presente en su jornada laboral',
    1,
    1
WHERE NOT EXISTS (
    SELECT 1 FROM rrhh.attendance_types WHERE type_code = 'PRESENTE'
);

INSERT INTO rrhh.attendance_types (
    type_code,
    type_name,
    description,
    affects_worked_hours,
    is_active
)
SELECT
    'AUSENTE',
    'Ausente',
    'Empleado ausente durante la jornada',
    0,
    1
WHERE NOT EXISTS (
    SELECT 1 FROM rrhh.attendance_types WHERE type_code = 'AUSENTE'
);

INSERT INTO rrhh.attendance_types (
    type_code,
    type_name,
    description,
    affects_worked_hours,
    is_active
)
SELECT
    'LLEGADA_TARDE',
    'Llegada tarde',
    'Empleado presente con ingreso posterior al horario esperado',
    1,
    1
WHERE NOT EXISTS (
    SELECT 1 FROM rrhh.attendance_types WHERE type_code = 'LLEGADA_TARDE'
);

INSERT INTO rrhh.attendance_types (
    type_code,
    type_name,
    description,
    affects_worked_hours,
    is_active
)
SELECT
    'HOME_OFFICE',
    'Home office',
    'Empleado trabajando de forma remota',
    1,
    1
WHERE NOT EXISTS (
    SELECT 1 FROM rrhh.attendance_types WHERE type_code = 'HOME_OFFICE'
);

INSERT INTO rrhh.attendance_types (
    type_code,
    type_name,
    description,
    affects_worked_hours,
    is_active
)
SELECT
    'LICENCIA',
    'Licencia',
    'Empleado con licencia aprobada',
    0,
    1
WHERE NOT EXISTS (
    SELECT 1 FROM rrhh.attendance_types WHERE type_code = 'LICENCIA'
);

INSERT INTO rrhh.attendance_types (
    type_code,
    type_name,
    description,
    affects_worked_hours,
    is_active
)
SELECT
    'VACACIONES',
    'Vacaciones',
    'Empleado en período de vacaciones',
    0,
    1
WHERE NOT EXISTS (
    SELECT 1 FROM rrhh.attendance_types WHERE type_code = 'VACACIONES'
);
GO


------------------------------------------------------------
-- work_schedules
------------------------------------------------------------

INSERT INTO rrhh.work_schedules (
    schedule_name,
    start_time,
    end_time,
    expected_hours,
    description,
    is_active
)
SELECT
    'Jornada completa 09 a 18',
    '09:00',
    '18:00',
    8.00,
    'Jornada laboral de lunes a viernes con una hora de almuerzo',
    1
WHERE NOT EXISTS (
    SELECT 1 FROM rrhh.work_schedules WHERE schedule_name = 'Jornada completa 09 a 18'
);

INSERT INTO rrhh.work_schedules (
    schedule_name,
    start_time,
    end_time,
    expected_hours,
    description,
    is_active
)
SELECT
    'Turno mañana 08 a 14',
    '08:00',
    '14:00',
    6.00,
    'Turno reducido de mañana',
    1
WHERE NOT EXISTS (
    SELECT 1 FROM rrhh.work_schedules WHERE schedule_name = 'Turno mañana 08 a 14'
);

INSERT INTO rrhh.work_schedules (
    schedule_name,
    start_time,
    end_time,
    expected_hours,
    description,
    is_active
)
SELECT
    'Turno tarde 14 a 20',
    '14:00',
    '20:00',
    6.00,
    'Turno reducido de tarde',
    1
WHERE NOT EXISTS (
    SELECT 1 FROM rrhh.work_schedules WHERE schedule_name = 'Turno tarde 14 a 20'
);
GO


------------------------------------------------------------
-- employee_schedules
-- Asignación de horarios a empleados demo
------------------------------------------------------------

DECLARE @emp_juan INT;
DECLARE @emp_maria INT;
DECLARE @emp_carlos INT;

DECLARE @schedule_completa INT;
DECLARE @schedule_manana INT;
DECLARE @schedule_tarde INT;

SELECT @emp_juan = employee_id
FROM rrhh.employees
WHERE employee_code = 'EMP001';

SELECT @emp_maria = employee_id
FROM rrhh.employees
WHERE employee_code = 'EMP002';

SELECT @emp_carlos = employee_id
FROM rrhh.employees
WHERE employee_code = 'EMP003';

SELECT @schedule_completa = work_schedule_id
FROM rrhh.work_schedules
WHERE schedule_name = 'Jornada completa 09 a 18';

SELECT @schedule_manana = work_schedule_id
FROM rrhh.work_schedules
WHERE schedule_name = 'Turno mañana 08 a 14';

SELECT @schedule_tarde = work_schedule_id
FROM rrhh.work_schedules
WHERE schedule_name = 'Turno tarde 14 a 20';


IF @emp_juan IS NOT NULL AND @schedule_completa IS NOT NULL
BEGIN
    INSERT INTO rrhh.employee_schedules (
        employee_id,
        work_schedule_id,
        valid_from,
        valid_to,
        is_active
    )
    SELECT
        @emp_juan,
        @schedule_completa,
        '2026-06-01',
        NULL,
        1
    WHERE NOT EXISTS (
        SELECT 1
        FROM rrhh.employee_schedules
        WHERE employee_id = @emp_juan
          AND work_schedule_id = @schedule_completa
          AND is_active = 1
    );
END;

IF @emp_maria IS NOT NULL AND @schedule_completa IS NOT NULL
BEGIN
    INSERT INTO rrhh.employee_schedules (
        employee_id,
        work_schedule_id,
        valid_from,
        valid_to,
        is_active
    )
    SELECT
        @emp_maria,
        @schedule_completa,
        '2026-06-01',
        NULL,
        1
    WHERE NOT EXISTS (
        SELECT 1
        FROM rrhh.employee_schedules
        WHERE employee_id = @emp_maria
          AND work_schedule_id = @schedule_completa
          AND is_active = 1
    );
END;

IF @emp_carlos IS NOT NULL AND @schedule_manana IS NOT NULL
BEGIN
    INSERT INTO rrhh.employee_schedules (
        employee_id,
        work_schedule_id,
        valid_from,
        valid_to,
        is_active
    )
    SELECT
        @emp_carlos,
        @schedule_manana,
        '2026-06-01',
        NULL,
        1
    WHERE NOT EXISTS (
        SELECT 1
        FROM rrhh.employee_schedules
        WHERE employee_id = @emp_carlos
          AND work_schedule_id = @schedule_manana
          AND is_active = 1
    );
END;
GO


------------------------------------------------------------
-- attendance_records
-- Registros demo de asistencia
------------------------------------------------------------

DECLARE @type_presente INT;
DECLARE @type_ausente INT;
DECLARE @type_llegada_tarde INT;
DECLARE @type_home_office INT;
DECLARE @type_licencia INT;

DECLARE @emp_juan INT;
DECLARE @emp_maria INT;
DECLARE @emp_carlos INT;

SELECT @type_presente = attendance_type_id
FROM rrhh.attendance_types
WHERE type_code = 'PRESENTE';

SELECT @type_ausente = attendance_type_id
FROM rrhh.attendance_types
WHERE type_code = 'AUSENTE';

SELECT @type_llegada_tarde = attendance_type_id
FROM rrhh.attendance_types
WHERE type_code = 'LLEGADA_TARDE';

SELECT @type_home_office = attendance_type_id
FROM rrhh.attendance_types
WHERE type_code = 'HOME_OFFICE';

SELECT @type_licencia = attendance_type_id
FROM rrhh.attendance_types
WHERE type_code = 'LICENCIA';

SELECT @emp_juan = employee_id
FROM rrhh.employees
WHERE employee_code = 'EMP001';

SELECT @emp_maria = employee_id
FROM rrhh.employees
WHERE employee_code = 'EMP002';

SELECT @emp_carlos = employee_id
FROM rrhh.employees
WHERE employee_code = 'EMP003';


------------------------------------------------------------
-- Juan Pérez
------------------------------------------------------------

IF @emp_juan IS NOT NULL
BEGIN
    INSERT INTO rrhh.attendance_records (
        employee_id,
        attendance_type_id,
        attendance_date,
        check_in_time,
        check_out_time,
        worked_hours,
        observations
    )
    SELECT
        @emp_juan,
        @type_presente,
        '2026-06-10',
        '09:00',
        '18:00',
        8.00,
        'Jornada completa registrada'
    WHERE NOT EXISTS (
        SELECT 1 FROM rrhh.attendance_records
        WHERE employee_id = @emp_juan
          AND attendance_date = '2026-06-10'
    );

    INSERT INTO rrhh.attendance_records (
        employee_id,
        attendance_type_id,
        attendance_date,
        check_in_time,
        check_out_time,
        worked_hours,
        observations
    )
    SELECT
        @emp_juan,
        @type_llegada_tarde,
        '2026-06-11',
        '09:25',
        '18:00',
        7.50,
        'Llegada tarde registrada'
    WHERE NOT EXISTS (
        SELECT 1 FROM rrhh.attendance_records
        WHERE employee_id = @emp_juan
          AND attendance_date = '2026-06-11'
    );

    INSERT INTO rrhh.attendance_records (
        employee_id,
        attendance_type_id,
        attendance_date,
        check_in_time,
        check_out_time,
        worked_hours,
        observations
    )
    SELECT
        @emp_juan,
        @type_home_office,
        '2026-06-12',
        '09:00',
        '18:00',
        8.00,
        'Trabajo remoto aprobado'
    WHERE NOT EXISTS (
        SELECT 1 FROM rrhh.attendance_records
        WHERE employee_id = @emp_juan
          AND attendance_date = '2026-06-12'
    );
END;


------------------------------------------------------------
-- María Gómez
------------------------------------------------------------

IF @emp_maria IS NOT NULL
BEGIN
    INSERT INTO rrhh.attendance_records (
        employee_id,
        attendance_type_id,
        attendance_date,
        check_in_time,
        check_out_time,
        worked_hours,
        observations
    )
    SELECT
        @emp_maria,
        @type_presente,
        '2026-06-10',
        '09:00',
        '18:00',
        8.00,
        'Jornada completa registrada'
    WHERE NOT EXISTS (
        SELECT 1 FROM rrhh.attendance_records
        WHERE employee_id = @emp_maria
          AND attendance_date = '2026-06-10'
    );

    INSERT INTO rrhh.attendance_records (
        employee_id,
        attendance_type_id,
        attendance_date,
        check_in_time,
        check_out_time,
        worked_hours,
        observations
    )
    SELECT
        @emp_maria,
        @type_presente,
        '2026-06-11',
        '09:00',
        '18:00',
        8.00,
        'Jornada completa registrada'
    WHERE NOT EXISTS (
        SELECT 1 FROM rrhh.attendance_records
        WHERE employee_id = @emp_maria
          AND attendance_date = '2026-06-11'
    );

    INSERT INTO rrhh.attendance_records (
        employee_id,
        attendance_type_id,
        attendance_date,
        check_in_time,
        check_out_time,
        worked_hours,
        observations
    )
    SELECT
        @emp_maria,
        @type_licencia,
        '2026-06-12',
        NULL,
        NULL,
        0.00,
        'Licencia aprobada por RRHH'
    WHERE NOT EXISTS (
        SELECT 1 FROM rrhh.attendance_records
        WHERE employee_id = @emp_maria
          AND attendance_date = '2026-06-12'
    );
END;


------------------------------------------------------------
-- Carlos López
------------------------------------------------------------

IF @emp_carlos IS NOT NULL
BEGIN
    INSERT INTO rrhh.attendance_records (
        employee_id,
        attendance_type_id,
        attendance_date,
        check_in_time,
        check_out_time,
        worked_hours,
        observations
    )
    SELECT
        @emp_carlos,
        @type_presente,
        '2026-06-10',
        '08:00',
        '14:00',
        6.00,
        'Turno mañana completo'
    WHERE NOT EXISTS (
        SELECT 1 FROM rrhh.attendance_records
        WHERE employee_id = @emp_carlos
          AND attendance_date = '2026-06-10'
    );

    INSERT INTO rrhh.attendance_records (
        employee_id,
        attendance_type_id,
        attendance_date,
        check_in_time,
        check_out_time,
        worked_hours,
        observations
    )
    SELECT
        @emp_carlos,
        @type_ausente,
        '2026-06-11',
        NULL,
        NULL,
        0.00,
        'Ausencia registrada'
    WHERE NOT EXISTS (
        SELECT 1 FROM rrhh.attendance_records
        WHERE employee_id = @emp_carlos
          AND attendance_date = '2026-06-11'
    );

    INSERT INTO rrhh.attendance_records (
        employee_id,
        attendance_type_id,
        attendance_date,
        check_in_time,
        check_out_time,
        worked_hours,
        observations
    )
    SELECT
        @emp_carlos,
        @type_presente,
        '2026-06-12',
        '08:00',
        '14:00',
        6.00,
        'Turno mañana completo'
    WHERE NOT EXISTS (
        SELECT 1 FROM rrhh.attendance_records
        WHERE employee_id = @emp_carlos
          AND attendance_date = '2026-06-12'
    );
END;
GO


------------------------------------------------------------
-- Consultas de validación
------------------------------------------------------------

SELECT *
FROM rrhh.attendance_types;

SELECT *
FROM rrhh.work_schedules;

SELECT *
FROM rrhh.employee_schedules;

SELECT *
FROM rrhh.attendance_records;

SELECT *
FROM rrhh.vw_asistencia_resumen
ORDER BY attendance_date, employee_code;

SELECT *
FROM rrhh.vw_asistencia_por_empleado
ORDER BY employee_code;
GO