USE DataCoreRRHH;
GO

/* =========================================================
   Módulo 1 - Empleados
   Script: 07_insert_demo_data_employees.sql
   Ejecutar con app_user
   ========================================================= */

------------------------------------------------------------
-- Validación previa: verificar que existan cargos cargados
------------------------------------------------------------

IF NOT EXISTS (SELECT 1 FROM rrhh.positions)
BEGIN
    RAISERROR('No existen cargos cargados en rrhh.positions. Ejecutar primero demo data del Módulo 2.', 16, 1);
    RETURN;
END;
GO


------------------------------------------------------------
-- Insertar empleados demo
------------------------------------------------------------

DECLARE @position_analista_ti INT;
DECLARE @position_gerente_ti INT;
DECLARE @position_rrhh INT;
DECLARE @position_admin INT;

SELECT @position_analista_ti = p.position_id
FROM rrhh.positions p
INNER JOIN rrhh.departments d
    ON p.department_id = d.department_id
WHERE p.position_name = 'Analista Senior'
  AND d.department_name = 'TI';

SELECT @position_gerente_ti = p.position_id
FROM rrhh.positions p
INNER JOIN rrhh.departments d
    ON p.department_id = d.department_id
WHERE p.position_name = 'Gerente TI'
  AND d.department_name = 'TI';

SELECT @position_rrhh = p.position_id
FROM rrhh.positions p
INNER JOIN rrhh.departments d
    ON p.department_id = d.department_id
WHERE p.position_name = 'Analista RRHH'
  AND d.department_name IN ('Recursos Humanos', 'RRHH');

SELECT @position_admin = p.position_id
FROM rrhh.positions p
INNER JOIN rrhh.departments d
    ON p.department_id = d.department_id
WHERE p.position_name = 'Administrativo'
  AND d.department_name = 'Administración';


------------------------------------------------------------
-- Fallback por si algún cargo exacto no existe
-- Toma cualquier cargo disponible para no frenar la demo
------------------------------------------------------------

IF @position_analista_ti IS NULL
    SELECT TOP 1 @position_analista_ti = position_id FROM rrhh.positions ORDER BY position_id;

IF @position_gerente_ti IS NULL
    SELECT TOP 1 @position_gerente_ti = position_id FROM rrhh.positions ORDER BY position_id;

IF @position_rrhh IS NULL
    SELECT TOP 1 @position_rrhh = position_id FROM rrhh.positions ORDER BY position_id;

IF @position_admin IS NULL
    SELECT TOP 1 @position_admin = position_id FROM rrhh.positions ORDER BY position_id;


------------------------------------------------------------
-- employees
------------------------------------------------------------

INSERT INTO rrhh.employees (
    employee_code,
    first_name,
    last_name,
    dni_cuil,
    hire_date,
    position_id,
    is_active
)
SELECT
    'EMP001',
    'Juan',
    'Pérez',
    '20-30111222-3',
    '2022-03-15',
    @position_analista_ti,
    1
WHERE NOT EXISTS (
    SELECT 1 FROM rrhh.employees WHERE employee_code = 'EMP001'
);

INSERT INTO rrhh.employees (
    employee_code,
    first_name,
    last_name,
    dni_cuil,
    hire_date,
    position_id,
    is_active
)
SELECT
    'EMP002',
    'María',
    'Gómez',
    '27-28444555-6',
    '2021-08-01',
    @position_gerente_ti,
    1
WHERE NOT EXISTS (
    SELECT 1 FROM rrhh.employees WHERE employee_code = 'EMP002'
);

INSERT INTO rrhh.employees (
    employee_code,
    first_name,
    last_name,
    dni_cuil,
    hire_date,
    position_id,
    is_active
)
SELECT
    'EMP003',
    'Carlos',
    'López',
    '20-35666777-8',
    '2023-01-10',
    @position_rrhh,
    1
WHERE NOT EXISTS (
    SELECT 1 FROM rrhh.employees WHERE employee_code = 'EMP003'
);

INSERT INTO rrhh.employees (
    employee_code,
    first_name,
    last_name,
    dni_cuil,
    hire_date,
    position_id,
    is_active
)
SELECT
    'EMP004',
    'Ana',
    'Martínez',
    '27-33777888-9',
    '2020-11-20',
    @position_admin,
    0
WHERE NOT EXISTS (
    SELECT 1 FROM rrhh.employees WHERE employee_code = 'EMP004'
);
GO


------------------------------------------------------------
-- personal_info
------------------------------------------------------------

INSERT INTO rrhh.personal_info (
    employee_id,
    birth_date,
    address,
    phone,
    personal_email,
    marital_status,
    nationality
)
SELECT
    e.employee_id,
    '1990-05-12',
    'Av. Rivadavia 1234, Buenos Aires',
    '1134567890',
    'juan.perez@mail.com',
    'Soltero',
    'Argentina'
FROM rrhh.employees e
WHERE e.employee_code = 'EMP001'
  AND NOT EXISTS (
      SELECT 1 
      FROM rrhh.personal_info pi 
      WHERE pi.employee_id = e.employee_id
  );

INSERT INTO rrhh.personal_info (
    employee_id,
    birth_date,
    address,
    phone,
    personal_email,
    marital_status,
    nationality
)
SELECT
    e.employee_id,
    '1985-09-22',
    'Calle Mitre 850, Ramos Mejía',
    '1145678901',
    'maria.gomez@mail.com',
    'Casada',
    'Argentina'
FROM rrhh.employees e
WHERE e.employee_code = 'EMP002'
  AND NOT EXISTS (
      SELECT 1 
      FROM rrhh.personal_info pi 
      WHERE pi.employee_id = e.employee_id
  );

INSERT INTO rrhh.personal_info (
    employee_id,
    birth_date,
    address,
    phone,
    personal_email,
    marital_status,
    nationality
)
SELECT
    e.employee_id,
    '1994-02-18',
    'Belgrano 455, San Justo',
    '1156789012',
    'carlos.lopez@mail.com',
    'Soltero',
    'Argentina'
FROM rrhh.employees e
WHERE e.employee_code = 'EMP003'
  AND NOT EXISTS (
      SELECT 1 
      FROM rrhh.personal_info pi 
      WHERE pi.employee_id = e.employee_id
  );

INSERT INTO rrhh.personal_info (
    employee_id,
    birth_date,
    address,
    phone,
    personal_email,
    marital_status,
    nationality
)
SELECT
    e.employee_id,
    '1988-12-03',
    'Av. de Mayo 300, Morón',
    '1167890123',
    'ana.martinez@mail.com',
    'Divorciada',
    'Argentina'
FROM rrhh.employees e
WHERE e.employee_code = 'EMP004'
  AND NOT EXISTS (
      SELECT 1 
      FROM rrhh.personal_info pi 
      WHERE pi.employee_id = e.employee_id
  );
GO


------------------------------------------------------------
-- documents
------------------------------------------------------------

INSERT INTO rrhh.documents (
    employee_id,
    document_type,
    document_number,
    issue_date,
    expiration_date,
    document_status,
    observations
)
SELECT
    e.employee_id,
    'DNI',
    '30111222',
    '2020-01-01',
    NULL,
    'PRESENTADO',
    'Documento principal presentado'
FROM rrhh.employees e
WHERE e.employee_code = 'EMP001'
  AND NOT EXISTS (
      SELECT 1 
      FROM rrhh.documents d 
      WHERE d.employee_id = e.employee_id 
        AND d.document_type = 'DNI'
  );

INSERT INTO rrhh.documents (
    employee_id,
    document_type,
    document_number,
    issue_date,
    expiration_date,
    document_status,
    observations
)
SELECT
    e.employee_id,
    'Contrato',
    'CONT-EMP001',
    '2022-03-15',
    NULL,
    'PRESENTADO',
    'Contrato firmado al ingreso'
FROM rrhh.employees e
WHERE e.employee_code = 'EMP001'
  AND NOT EXISTS (
      SELECT 1 
      FROM rrhh.documents d 
      WHERE d.employee_id = e.employee_id 
        AND d.document_type = 'Contrato'
  );

INSERT INTO rrhh.documents (
    employee_id,
    document_type,
    document_number,
    issue_date,
    expiration_date,
    document_status,
    observations
)
SELECT
    e.employee_id,
    'DNI',
    '28444555',
    '2020-01-01',
    NULL,
    'PRESENTADO',
    'Documento principal presentado'
FROM rrhh.employees e
WHERE e.employee_code = 'EMP002'
  AND NOT EXISTS (
      SELECT 1 
      FROM rrhh.documents d 
      WHERE d.employee_id = e.employee_id 
        AND d.document_type = 'DNI'
  );

INSERT INTO rrhh.documents (
    employee_id,
    document_type,
    document_number,
    issue_date,
    expiration_date,
    document_status,
    observations
)
SELECT
    e.employee_id,
    'Certificado médico',
    NULL,
    NULL,
    NULL,
    'PENDIENTE',
    'Pendiente de presentación'
FROM rrhh.employees e
WHERE e.employee_code = 'EMP003'
  AND NOT EXISTS (
      SELECT 1 
      FROM rrhh.documents d 
      WHERE d.employee_id = e.employee_id 
        AND d.document_type = 'Certificado médico'
  );

INSERT INTO rrhh.documents (
    employee_id,
    document_type,
    document_number,
    issue_date,
    expiration_date,
    document_status,
    observations
)
SELECT
    e.employee_id,
    'Contrato',
    'CONT-EMP004',
    '2020-11-20',
    NULL,
    'PRESENTADO',
    'Empleado actualmente inactivo'
FROM rrhh.employees e
WHERE e.employee_code = 'EMP004'
  AND NOT EXISTS (
      SELECT 1 
      FROM rrhh.documents d 
      WHERE d.employee_id = e.employee_id 
        AND d.document_type = 'Contrato'
  );
GO


------------------------------------------------------------
-- Consultas de validación
------------------------------------------------------------

SELECT * 
FROM rrhh.employees;

SELECT * 
FROM rrhh.personal_info;

SELECT * 
FROM rrhh.documents;

SELECT * 
FROM rrhh.vw_empleados_activos;
GO