USE DataCoreRRHH;
GO

/* =========================================================
   Módulo 3 - Nómina y Compensación
   Script: 09_insert_demo_data_payroll.sql
   Ejecutar con app_user
   ========================================================= */

------------------------------------------------------------
-- Validaciones previas
------------------------------------------------------------

IF NOT EXISTS (SELECT 1 FROM rrhh.employees WHERE is_active = 1)
BEGIN
    RAISERROR('No existen empleados activos. Ejecutar primero demo data del Módulo 1.', 16, 1);
    RETURN;
END;
GO


------------------------------------------------------------
-- payroll_periods
------------------------------------------------------------

INSERT INTO rrhh.payroll_periods (
    period_name,
    period_year,
    period_month,
    start_date,
    end_date,
    payment_date,
    period_status
)
SELECT
    'Junio 2026',
    2026,
    6,
    '2026-06-01',
    '2026-06-30',
    '2026-07-05',
    'ABIERTO'
WHERE NOT EXISTS (
    SELECT 1
    FROM rrhh.payroll_periods
    WHERE period_year = 2026
      AND period_month = 6
);
GO


------------------------------------------------------------
-- compensation_concepts
------------------------------------------------------------

INSERT INTO rrhh.compensation_concepts (
    concept_code,
    concept_name,
    concept_type,
    is_fixed,
    is_active
)
SELECT 'BASICO', 'Sueldo básico', 'HABER', 1, 1
WHERE NOT EXISTS (
    SELECT 1 FROM rrhh.compensation_concepts WHERE concept_code = 'BASICO'
);

INSERT INTO rrhh.compensation_concepts (
    concept_code,
    concept_name,
    concept_type,
    is_fixed,
    is_active
)
SELECT 'PRESENTISMO', 'Presentismo', 'HABER', 0, 1
WHERE NOT EXISTS (
    SELECT 1 FROM rrhh.compensation_concepts WHERE concept_code = 'PRESENTISMO'
);

INSERT INTO rrhh.compensation_concepts (
    concept_code,
    concept_name,
    concept_type,
    is_fixed,
    is_active
)
SELECT 'BONO', 'Bono desempeño', 'HABER', 0, 1
WHERE NOT EXISTS (
    SELECT 1 FROM rrhh.compensation_concepts WHERE concept_code = 'BONO'
);

INSERT INTO rrhh.compensation_concepts (
    concept_code,
    concept_name,
    concept_type,
    is_fixed,
    is_active
)
SELECT 'JUBILACION', 'Descuento jubilación', 'DESCUENTO', 1, 1
WHERE NOT EXISTS (
    SELECT 1 FROM rrhh.compensation_concepts WHERE concept_code = 'JUBILACION'
);

INSERT INTO rrhh.compensation_concepts (
    concept_code,
    concept_name,
    concept_type,
    is_fixed,
    is_active
)
SELECT 'OBRA_SOCIAL', 'Descuento obra social', 'DESCUENTO', 1, 1
WHERE NOT EXISTS (
    SELECT 1 FROM rrhh.compensation_concepts WHERE concept_code = 'OBRA_SOCIAL'
);
GO


------------------------------------------------------------
-- employee_compensation
-- Asignación de sueldo base a empleados demo
------------------------------------------------------------

DECLARE @emp_juan INT;
DECLARE @emp_maria INT;
DECLARE @emp_carlos INT;

SELECT @emp_juan = employee_id
FROM rrhh.employees
WHERE employee_code = 'EMP001';

SELECT @emp_maria = employee_id
FROM rrhh.employees
WHERE employee_code = 'EMP002';

SELECT @emp_carlos = employee_id
FROM rrhh.employees
WHERE employee_code = 'EMP003';


IF @emp_juan IS NOT NULL
BEGIN
    INSERT INTO rrhh.employee_compensation (
        employee_id,
        base_salary,
        valid_from,
        valid_to,
        is_active
    )
    SELECT
        @emp_juan,
        2500000.00,
        '2026-06-01',
        NULL,
        1
    WHERE NOT EXISTS (
        SELECT 1
        FROM rrhh.employee_compensation
        WHERE employee_id = @emp_juan
          AND is_active = 1
    );
END;

IF @emp_maria IS NOT NULL
BEGIN
    INSERT INTO rrhh.employee_compensation (
        employee_id,
        base_salary,
        valid_from,
        valid_to,
        is_active
    )
    SELECT
        @emp_maria,
        3800000.00,
        '2026-06-01',
        NULL,
        1
    WHERE NOT EXISTS (
        SELECT 1
        FROM rrhh.employee_compensation
        WHERE employee_id = @emp_maria
          AND is_active = 1
    );
END;

IF @emp_carlos IS NOT NULL
BEGIN
    INSERT INTO rrhh.employee_compensation (
        employee_id,
        base_salary,
        valid_from,
        valid_to,
        is_active
    )
    SELECT
        @emp_carlos,
        1800000.00,
        '2026-06-01',
        NULL,
        1
    WHERE NOT EXISTS (
        SELECT 1
        FROM rrhh.employee_compensation
        WHERE employee_id = @emp_carlos
          AND is_active = 1
    );
END;
GO


------------------------------------------------------------
-- payroll_headers
-- Crea cabeceras de liquidación para empleados activos
------------------------------------------------------------

DECLARE @period_junio_2026 INT;

SELECT @period_junio_2026 = payroll_period_id
FROM rrhh.payroll_periods
WHERE period_year = 2026
  AND period_month = 6;

INSERT INTO rrhh.payroll_headers (
    employee_id,
    payroll_period_id,
    gross_amount,
    discount_amount,
    net_amount,
    payroll_status
)
SELECT
    e.employee_id,
    @period_junio_2026,
    0,
    0,
    0,
    'GENERADO'
FROM rrhh.employees e
WHERE e.is_active = 1
  AND NOT EXISTS (
      SELECT 1
      FROM rrhh.payroll_headers ph
      WHERE ph.employee_id = e.employee_id
        AND ph.payroll_period_id = @period_junio_2026
  );
GO


------------------------------------------------------------
-- payroll_details
-- Inserta conceptos liquidados
------------------------------------------------------------

DECLARE @concept_basico INT;
DECLARE @concept_presentismo INT;
DECLARE @concept_bono INT;
DECLARE @concept_jubilacion INT;
DECLARE @concept_obra_social INT;

SELECT @concept_basico = concept_id
FROM rrhh.compensation_concepts
WHERE concept_code = 'BASICO';

SELECT @concept_presentismo = concept_id
FROM rrhh.compensation_concepts
WHERE concept_code = 'PRESENTISMO';

SELECT @concept_bono = concept_id
FROM rrhh.compensation_concepts
WHERE concept_code = 'BONO';

SELECT @concept_jubilacion = concept_id
FROM rrhh.compensation_concepts
WHERE concept_code = 'JUBILACION';

SELECT @concept_obra_social = concept_id
FROM rrhh.compensation_concepts
WHERE concept_code = 'OBRA_SOCIAL';


------------------------------------------------------------
-- Sueldo básico
------------------------------------------------------------

INSERT INTO rrhh.payroll_details (
    payroll_header_id,
    concept_id,
    quantity,
    amount,
    observations
)
SELECT
    ph.payroll_header_id,
    @concept_basico,
    1,
    ec.base_salary,
    'Sueldo básico mensual'
FROM rrhh.payroll_headers ph
INNER JOIN rrhh.employee_compensation ec
    ON ph.employee_id = ec.employee_id
WHERE ec.is_active = 1
  AND NOT EXISTS (
      SELECT 1
      FROM rrhh.payroll_details pd
      WHERE pd.payroll_header_id = ph.payroll_header_id
        AND pd.concept_id = @concept_basico
  );


------------------------------------------------------------
-- Presentismo: 10% del básico
------------------------------------------------------------

INSERT INTO rrhh.payroll_details (
    payroll_header_id,
    concept_id,
    quantity,
    amount,
    observations
)
SELECT
    ph.payroll_header_id,
    @concept_presentismo,
    1,
    ec.base_salary * 0.10,
    'Presentismo del período'
FROM rrhh.payroll_headers ph
INNER JOIN rrhh.employee_compensation ec
    ON ph.employee_id = ec.employee_id
WHERE ec.is_active = 1
  AND NOT EXISTS (
      SELECT 1
      FROM rrhh.payroll_details pd
      WHERE pd.payroll_header_id = ph.payroll_header_id
        AND pd.concept_id = @concept_presentismo
  );


------------------------------------------------------------
-- Bono demo: solo EMP001
------------------------------------------------------------

INSERT INTO rrhh.payroll_details (
    payroll_header_id,
    concept_id,
    quantity,
    amount,
    observations
)
SELECT
    ph.payroll_header_id,
    @concept_bono,
    1,
    150000.00,
    'Bono por desempeño'
FROM rrhh.payroll_headers ph
INNER JOIN rrhh.employees e
    ON ph.employee_id = e.employee_id
WHERE e.employee_code = 'EMP001'
  AND NOT EXISTS (
      SELECT 1
      FROM rrhh.payroll_details pd
      WHERE pd.payroll_header_id = ph.payroll_header_id
        AND pd.concept_id = @concept_bono
  );


------------------------------------------------------------
-- Jubilación: 11% del básico
------------------------------------------------------------

INSERT INTO rrhh.payroll_details (
    payroll_header_id,
    concept_id,
    quantity,
    amount,
    observations
)
SELECT
    ph.payroll_header_id,
    @concept_jubilacion,
    1,
    ec.base_salary * 0.11,
    'Descuento jubilatorio demo'
FROM rrhh.payroll_headers ph
INNER JOIN rrhh.employee_compensation ec
    ON ph.employee_id = ec.employee_id
WHERE ec.is_active = 1
  AND NOT EXISTS (
      SELECT 1
      FROM rrhh.payroll_details pd
      WHERE pd.payroll_header_id = ph.payroll_header_id
        AND pd.concept_id = @concept_jubilacion
  );


------------------------------------------------------------
-- Obra social: 3% del básico
------------------------------------------------------------

INSERT INTO rrhh.payroll_details (
    payroll_header_id,
    concept_id,
    quantity,
    amount,
    observations
)
SELECT
    ph.payroll_header_id,
    @concept_obra_social,
    1,
    ec.base_salary * 0.03,
    'Descuento obra social demo'
FROM rrhh.payroll_headers ph
INNER JOIN rrhh.employee_compensation ec
    ON ph.employee_id = ec.employee_id
WHERE ec.is_active = 1
  AND NOT EXISTS (
      SELECT 1
      FROM rrhh.payroll_details pd
      WHERE pd.payroll_header_id = ph.payroll_header_id
        AND pd.concept_id = @concept_obra_social
  );
GO


------------------------------------------------------------
-- Actualizar totales de payroll_headers
------------------------------------------------------------

UPDATE ph
SET
    gross_amount = totals.gross_amount,
    discount_amount = totals.discount_amount,
    net_amount = totals.gross_amount - totals.discount_amount,
    updated_at = SYSDATETIME()
FROM rrhh.payroll_headers ph
INNER JOIN (
    SELECT
        pd.payroll_header_id,
        SUM(CASE WHEN cc.concept_type = 'HABER' THEN pd.amount ELSE 0 END) AS gross_amount,
        SUM(CASE WHEN cc.concept_type = 'DESCUENTO' THEN pd.amount ELSE 0 END) AS discount_amount
    FROM rrhh.payroll_details pd
    INNER JOIN rrhh.compensation_concepts cc
        ON pd.concept_id = cc.concept_id
    GROUP BY pd.payroll_header_id
) totals
    ON ph.payroll_header_id = totals.payroll_header_id;
GO


------------------------------------------------------------
-- Consultas de validación
------------------------------------------------------------

SELECT *
FROM rrhh.payroll_periods;

SELECT *
FROM rrhh.compensation_concepts;

SELECT *
FROM rrhh.employee_compensation;

SELECT *
FROM rrhh.payroll_headers;

SELECT *
FROM rrhh.payroll_details;

SELECT *
FROM rrhh.vw_nomina_resumen;

SELECT *
FROM rrhh.vw_nomina_detalle
ORDER BY employee_code, concept_type, concept_name;
GO