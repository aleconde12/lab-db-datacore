USE DataCoreRRHH;
GO

/* ============================================================
   M2 - Organización y Cargos
   Archivo: 05_insert_demo_data_m2.sql

   Inserta datos iniciales para probar:
   - departments
   - job_levels
   - positions
   - reporting_structure
   ============================================================ */

INSERT INTO rrhh.departments (
    department_name,
    description
)
VALUES
('Tecnologia', 'Departamento de sistemas, infraestructura y soporte tecnico'),
('Recursos Humanos', 'Departamento encargado de la gestion del personal'),
('Finanzas', 'Departamento encargado de administracion, pagos y presupuesto'),
('Operaciones', 'Departamento encargado de procesos internos y coordinacion operativa');
GO

INSERT INTO rrhh.job_levels (
    level_number,
    level_name,
    description,
    min_salary,
    max_salary
)
VALUES
(1, 'Junior', 'Nivel inicial con supervision frecuente', 800000.00, 1500000.00),
(3, 'Semi Senior', 'Nivel intermedio con autonomia parcial', 2000000.00, 3500000.00),
(5, 'Senior', 'Nivel avanzado con autonomia tecnica', 4500000.00, 6000000.00),
(6, 'Gerencial', 'Nivel de liderazgo y gestion de equipos', 6000000.00, 8500000.00);
GO

INSERT INTO rrhh.positions (
    department_id,
    job_level_id,
    position_name,
    description,
    base_salary
)
VALUES
(
    (SELECT department_id FROM rrhh.departments WHERE department_name = 'Tecnologia'),
    (SELECT job_level_id FROM rrhh.job_levels WHERE level_number = 5),
    'Analista Senior',
    'Responsable de analisis tecnico, soporte avanzado y mejoras de sistemas',
    5000000.00
),
(
    (SELECT department_id FROM rrhh.departments WHERE department_name = 'Tecnologia'),
    (SELECT job_level_id FROM rrhh.job_levels WHERE level_number = 6),
    'Gerente TI',
    'Responsable de la gestion del area de tecnologia',
    7000000.00
),
(
    (SELECT department_id FROM rrhh.departments WHERE department_name = 'Recursos Humanos'),
    (SELECT job_level_id FROM rrhh.job_levels WHERE level_number = 3),
    'Analista RRHH',
    'Responsable de tareas administrativas del area de recursos humanos',
    2800000.00
),
(
    (SELECT department_id FROM rrhh.departments WHERE department_name = 'Finanzas'),
    (SELECT job_level_id FROM rrhh.job_levels WHERE level_number = 6),
    'Gerente Financiero',
    'Responsable de presupuesto, pagos y control financiero',
    7500000.00
);
GO

INSERT INTO rrhh.reporting_structure (
    position_id,
    reports_to_position_id,
    effective_from
)
VALUES
(
    (SELECT position_id FROM rrhh.positions WHERE position_name = 'Analista Senior'),
    (SELECT position_id FROM rrhh.positions WHERE position_name = 'Gerente TI'),
    '2026-01-01'
),
(
    (SELECT position_id FROM rrhh.positions WHERE position_name = 'Analista RRHH'),
    NULL,
    '2026-01-01'
),
(
    (SELECT position_id FROM rrhh.positions WHERE position_name = 'Gerente TI'),
    NULL,
    '2026-01-01'
),
(
    (SELECT position_id FROM rrhh.positions WHERE position_name = 'Gerente Financiero'),
    NULL,
    '2026-01-01'
);
GO