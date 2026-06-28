<?php
require_once "config.php";

$message = "";
$error = "";

function fetch_all($conn, $sql, $params = []) {
    $stmt = sqlsrv_query($conn, $sql, $params);

    if ($stmt === false) {
        die("<pre>" . print_r(sqlsrv_errors(), true) . "</pre>");
    }

    $rows = [];
    while ($row = sqlsrv_fetch_array($stmt, SQLSRV_FETCH_ASSOC)) {
        $rows[] = $row;
    }

    return $rows;
}

function execute_query($conn, $sql, $params = []) {
    $stmt = sqlsrv_query($conn, $sql, $params);

    if ($stmt === false) {
        throw new Exception(print_r(sqlsrv_errors(), true));
    }

    return $stmt;
}

function update_payroll_totals($conn, $payrollHeaderId) {
    $sql = "
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
            WHERE pd.payroll_header_id = ?
            GROUP BY pd.payroll_header_id
        ) totals
            ON ph.payroll_header_id = totals.payroll_header_id
        WHERE ph.payroll_header_id = ?
    ";

    execute_query($conn, $sql, [$payrollHeaderId, $payrollHeaderId]);
}

function format_date_value($value) {
    if ($value instanceof DateTime) {
        return $value->format("Y-m-d");
    }

    return htmlspecialchars((string)$value);
}

function format_money($value) {
    return "$ " . number_format((float)$value, 2, ",", ".");
}

if ($_SERVER["REQUEST_METHOD"] === "POST") {
    $action = $_POST["action"] ?? "";

    try {
        if ($action === "create_period") {
            $periodYear = $_POST["period_year"];
            $periodMonth = $_POST["period_month"];

            $checkSql = "
                SELECT COUNT(*) AS total
                FROM rrhh.payroll_periods
                WHERE period_year = ?
                  AND period_month = ?
            ";

            $checkStmt = sqlsrv_query($conn, $checkSql, [$periodYear, $periodMonth]);

            if ($checkStmt === false) {
                throw new Exception(print_r(sqlsrv_errors(), true));
            }

            $checkRow = sqlsrv_fetch_array($checkStmt, SQLSRV_FETCH_ASSOC);

            if ($checkRow["total"] > 0) {
                $error = "Ya existe un período para $periodMonth/$periodYear.";
            } else {
                $sql = "
                    INSERT INTO rrhh.payroll_periods (
                        period_name,
                        period_year,
                        period_month,
                        start_date,
                        end_date,
                        payment_date,
                        period_status
                    )
                    VALUES (?, ?, ?, ?, ?, ?, ?)
                ";

                $params = [
                    trim($_POST["period_name"]),
                    $periodYear,
                    $periodMonth,
                    $_POST["start_date"],
                    $_POST["end_date"],
                    $_POST["payment_date"] === "" ? null : $_POST["payment_date"],
                    $_POST["period_status"]
                ];

                execute_query($conn, $sql, $params);
                $message = "Período de liquidación creado correctamente.";
            }
        }

        if ($action === "create_concept") {
            $conceptCode = strtoupper(trim($_POST["concept_code"]));

            $checkSql = "
                SELECT COUNT(*) AS total
                FROM rrhh.compensation_concepts
                WHERE concept_code = ?
            ";

            $checkStmt = sqlsrv_query($conn, $checkSql, [$conceptCode]);

            if ($checkStmt === false) {
                throw new Exception(print_r(sqlsrv_errors(), true));
            }

            $checkRow = sqlsrv_fetch_array($checkStmt, SQLSRV_FETCH_ASSOC);

            if ($checkRow["total"] > 0) {
                $error = "Ya existe un concepto con el código '$conceptCode'.";
            } else {
                $sql = "
                    INSERT INTO rrhh.compensation_concepts (
                        concept_code,
                        concept_name,
                        concept_type,
                        is_fixed,
                        is_active
                    )
                    VALUES (?, ?, ?, ?, 1)
                ";

                $params = [
                    $conceptCode,
                    trim($_POST["concept_name"]),
                    $_POST["concept_type"],
                    isset($_POST["is_fixed"]) ? 1 : 0
                ];

                execute_query($conn, $sql, $params);
                $message = "Concepto de compensación creado correctamente.";
            }
        }

        if ($action === "assign_compensation") {
            $sql = "
                INSERT INTO rrhh.employee_compensation (
                    employee_id,
                    base_salary,
                    valid_from,
                    valid_to,
                    is_active
                )
                VALUES (?, ?, ?, ?, 1)
            ";

            $params = [
                $_POST["employee_id"],
                $_POST["base_salary"],
                $_POST["valid_from"],
                $_POST["valid_to"] === "" ? null : $_POST["valid_to"]
            ];

            execute_query($conn, $sql, $params);
            $message = "Compensación asignada correctamente.";
        }

        if ($action === "create_payroll_header") {
            $employeeId = $_POST["employee_id"];
            $periodId = $_POST["payroll_period_id"];

            $checkSql = "
                SELECT COUNT(*) AS total
                FROM rrhh.payroll_headers
                WHERE employee_id = ?
                  AND payroll_period_id = ?
            ";

            $checkStmt = sqlsrv_query($conn, $checkSql, [$employeeId, $periodId]);

            if ($checkStmt === false) {
                throw new Exception(print_r(sqlsrv_errors(), true));
            }

            $checkRow = sqlsrv_fetch_array($checkStmt, SQLSRV_FETCH_ASSOC);

            if ($checkRow["total"] > 0) {
                $error = "Ya existe una liquidación para ese empleado y período.";
            } else {
                $sql = "
                    INSERT INTO rrhh.payroll_headers (
                        employee_id,
                        payroll_period_id,
                        gross_amount,
                        discount_amount,
                        net_amount,
                        payroll_status
                    )
                    VALUES (?, ?, 0, 0, 0, 'GENERADO')
                ";

                execute_query($conn, $sql, [$employeeId, $periodId]);
                $message = "Liquidación creada correctamente.";
            }
        }

        if ($action === "create_payroll_detail") {
            $payrollHeaderId = $_POST["payroll_header_id"];

            $sql = "
                INSERT INTO rrhh.payroll_details (
                    payroll_header_id,
                    concept_id,
                    quantity,
                    amount,
                    observations
                )
                VALUES (?, ?, ?, ?, ?)
            ";

            $params = [
                $payrollHeaderId,
                $_POST["concept_id"],
                $_POST["quantity"],
                $_POST["amount"],
                trim($_POST["observations"])
            ];

            execute_query($conn, $sql, $params);
            update_payroll_totals($conn, $payrollHeaderId);
            $message = "Concepto liquidado correctamente y totales actualizados.";
        }

    } catch (Exception $e) {
        $error = $e->getMessage();
    }
}

$activeEmployees = fetch_all($conn, "
    SELECT
        employee_id,
        employee_code,
        first_name,
        last_name,
        position_name,
        department_name
    FROM rrhh.vw_empleados_activos
    ORDER BY last_name, first_name
");

$periods = fetch_all($conn, "
    SELECT
        payroll_period_id,
        period_name,
        period_year,
        period_month,
        start_date,
        end_date,
        payment_date,
        period_status
    FROM rrhh.payroll_periods
    ORDER BY period_year DESC, period_month DESC
");

$concepts = fetch_all($conn, "
    SELECT
        concept_id,
        concept_code,
        concept_name,
        concept_type,
        is_fixed,
        is_active
    FROM rrhh.compensation_concepts
    WHERE is_active = 1
    ORDER BY concept_type, concept_name
");

$compensations = fetch_all($conn, "
    SELECT
        ec.employee_compensation_id,
        e.employee_code,
        e.first_name,
        e.last_name,
        ec.base_salary,
        ec.valid_from,
        ec.valid_to,
        ec.is_active
    FROM rrhh.employee_compensation ec
    INNER JOIN rrhh.employees e
        ON ec.employee_id = e.employee_id
    ORDER BY e.last_name, e.first_name, ec.valid_from DESC
");

$payrollHeaders = fetch_all($conn, "
    SELECT
        ph.payroll_header_id,
        pp.period_name,
        e.employee_code,
        e.first_name,
        e.last_name,
        ph.gross_amount,
        ph.discount_amount,
        ph.net_amount,
        ph.payroll_status
    FROM rrhh.payroll_headers ph
    INNER JOIN rrhh.payroll_periods pp
        ON ph.payroll_period_id = pp.payroll_period_id
    INNER JOIN rrhh.employees e
        ON ph.employee_id = e.employee_id
    ORDER BY pp.period_year DESC, pp.period_month DESC, e.last_name, e.first_name
");

$payrollSummary = fetch_all($conn, "
    SELECT
        payroll_header_id,
        period_name,
        employee_code,
        first_name,
        last_name,
        position_name,
        department_name,
        gross_amount,
        discount_amount,
        net_amount,
        payroll_status
    FROM rrhh.vw_nomina_resumen
    ORDER BY period_year DESC, period_month DESC, last_name, first_name
");

$payrollDetail = fetch_all($conn, "
    SELECT
        payroll_header_id,
        period_name,
        employee_code,
        first_name,
        last_name,
        concept_code,
        concept_name,
        concept_type,
        quantity,
        amount,
        observations
    FROM rrhh.vw_nomina_detalle
    ORDER BY period_name, employee_code, concept_type, concept_name
");
?>

<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <title>M3 - Nómina y Compensación</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet">
</head>

<body class="bg-light">
<div class="container py-4">

    <h1 class="mb-4">M3 - Nómina y Compensación</h1>

    <div class="mb-3">
        <a href="m1_empleados.php" class="btn btn-outline-secondary btn-sm">M1 - Empleados</a>
        <a href="m2_organizacion.php" class="btn btn-outline-secondary btn-sm">M2 - Organización</a>
        <a href="m3_nomina.php" class="btn btn-primary btn-sm">M3 - Nómina</a>
        <a href="m4_asistencia.php" class="btn btn-outline-secondary btn-sm">M4 - Asistencia</a>
        <a href="m5_desempeno_capacitacion.php" class="btn btn-outline-secondary btn-sm">M5 - Desempeño</a>
    </div>

    <?php if ($message): ?>
        <div class="alert alert-success"><?= htmlspecialchars($message) ?></div>
    <?php endif; ?>

    <?php if ($error): ?>
        <div class="alert alert-danger">
            <strong>Error:</strong>
            <pre><?= htmlspecialchars($error) ?></pre>
        </div>
    <?php endif; ?>

    <div class="row">

        <div class="col-md-6 mb-4">
            <div class="card">
                <div class="card-header">Crear período de liquidación</div>
                <div class="card-body">
                    <form method="POST">
                        <input type="hidden" name="action" value="create_period">

                        <div class="mb-3">
                            <label class="form-label">Nombre del período</label>
                            <input type="text" name="period_name" class="form-control" placeholder="Julio 2026" required>
                        </div>

                        <div class="mb-3">
                            <label class="form-label">Año</label>
                            <input type="number" name="period_year" class="form-control" value="2026" required>
                        </div>

                        <div class="mb-3">
                            <label class="form-label">Mes</label>
                            <input type="number" name="period_month" min="1" max="12" class="form-control" required>
                        </div>

                        <div class="mb-3">
                            <label class="form-label">Fecha inicio</label>
                            <input type="date" name="start_date" class="form-control" required>
                        </div>

                        <div class="mb-3">
                            <label class="form-label">Fecha fin</label>
                            <input type="date" name="end_date" class="form-control" required>
                        </div>

                        <div class="mb-3">
                            <label class="form-label">Fecha de pago</label>
                            <input type="date" name="payment_date" class="form-control">
                        </div>

                        <div class="mb-3">
                            <label class="form-label">Estado</label>
                            <select name="period_status" class="form-select" required>
                                <option value="ABIERTO">Abierto</option>
                                <option value="CERRADO">Cerrado</option>
                                <option value="ANULADO">Anulado</option>
                            </select>
                        </div>

                        <button class="btn btn-primary">Crear período</button>
                    </form>
                </div>
            </div>
        </div>

        <div class="col-md-6 mb-4">
            <div class="card">
                <div class="card-header">Crear concepto salarial</div>
                <div class="card-body">
                    <form method="POST">
                        <input type="hidden" name="action" value="create_concept">

                        <div class="mb-3">
                            <label class="form-label">Código</label>
                            <input type="text" name="concept_code" class="form-control" placeholder="VIATICOS" required>
                        </div>

                        <div class="mb-3">
                            <label class="form-label">Nombre</label>
                            <input type="text" name="concept_name" class="form-control" placeholder="Viáticos" required>
                        </div>

                        <div class="mb-3">
                            <label class="form-label">Tipo</label>
                            <select name="concept_type" class="form-select" required>
                                <option value="HABER">Haber</option>
                                <option value="DESCUENTO">Descuento</option>
                            </select>
                        </div>

                        <div class="form-check mb-3">
                            <input class="form-check-input" type="checkbox" name="is_fixed" value="1" id="is_fixed">
                            <label class="form-check-label" for="is_fixed">
                                Concepto fijo
                            </label>
                        </div>

                        <button class="btn btn-primary">Crear concepto</button>
                    </form>
                </div>
            </div>
        </div>

    </div>

    <div class="row">

        <div class="col-md-6 mb-4">
            <div class="card">
                <div class="card-header">Asignar compensación al empleado</div>
                <div class="card-body">
                    <form method="POST">
                        <input type="hidden" name="action" value="assign_compensation">

                        <div class="mb-3">
                            <label class="form-label">Empleado</label>
                            <select name="employee_id" class="form-select" required>
                                <option value="">Seleccionar...</option>
                                <?php foreach ($activeEmployees as $employee): ?>
                                    <option value="<?= $employee["employee_id"] ?>">
                                        <?= htmlspecialchars($employee["employee_code"]) ?> -
                                        <?= htmlspecialchars($employee["last_name"]) ?>,
                                        <?= htmlspecialchars($employee["first_name"]) ?> -
                                        <?= htmlspecialchars($employee["position_name"]) ?>
                                    </option>
                                <?php endforeach; ?>
                            </select>
                        </div>

                        <div class="mb-3">
                            <label class="form-label">Sueldo base</label>
                            <input type="number" step="0.01" name="base_salary" class="form-control" required>
                        </div>

                        <div class="mb-3">
                            <label class="form-label">Vigente desde</label>
                            <input type="date" name="valid_from" class="form-control" required>
                        </div>

                        <div class="mb-3">
                            <label class="form-label">Vigente hasta</label>
                            <input type="date" name="valid_to" class="form-control">
                        </div>

                        <button class="btn btn-primary">Asignar compensación</button>
                    </form>
                </div>
            </div>
        </div>

        <div class="col-md-6 mb-4">
            <div class="card">
                <div class="card-header">Crear liquidación</div>
                <div class="card-body">
                    <form method="POST">
                        <input type="hidden" name="action" value="create_payroll_header">

                        <div class="mb-3">
                            <label class="form-label">Empleado</label>
                            <select name="employee_id" class="form-select" required>
                                <option value="">Seleccionar...</option>
                                <?php foreach ($activeEmployees as $employee): ?>
                                    <option value="<?= $employee["employee_id"] ?>">
                                        <?= htmlspecialchars($employee["employee_code"]) ?> -
                                        <?= htmlspecialchars($employee["last_name"]) ?>,
                                        <?= htmlspecialchars($employee["first_name"]) ?>
                                    </option>
                                <?php endforeach; ?>
                            </select>
                        </div>

                        <div class="mb-3">
                            <label class="form-label">Período</label>
                            <select name="payroll_period_id" class="form-select" required>
                                <option value="">Seleccionar...</option>
                                <?php foreach ($periods as $period): ?>
                                    <option value="<?= $period["payroll_period_id"] ?>">
                                        <?= htmlspecialchars($period["period_name"]) ?> -
                                        <?= htmlspecialchars($period["period_status"]) ?>
                                    </option>
                                <?php endforeach; ?>
                            </select>
                        </div>

                        <button class="btn btn-primary">Crear liquidación</button>
                    </form>
                </div>
            </div>
        </div>

    </div>

    <div class="row">

        <div class="col-md-6 mb-4">
            <div class="card">
                <div class="card-header">Agregar concepto a liquidación</div>
                <div class="card-body">
                    <form method="POST">
                        <input type="hidden" name="action" value="create_payroll_detail">

                        <div class="mb-3">
                            <label class="form-label">Liquidación</label>
                            <select name="payroll_header_id" class="form-select" required>
                                <option value="">Seleccionar...</option>
                                <?php foreach ($payrollHeaders as $header): ?>
                                    <option value="<?= $header["payroll_header_id"] ?>">
                                        #<?= htmlspecialchars($header["payroll_header_id"]) ?> -
                                        <?= htmlspecialchars($header["period_name"]) ?> -
                                        <?= htmlspecialchars($header["employee_code"]) ?> -
                                        <?= htmlspecialchars($header["last_name"]) ?>,
                                        <?= htmlspecialchars($header["first_name"]) ?>
                                    </option>
                                <?php endforeach; ?>
                            </select>
                        </div>

                        <div class="mb-3">
                            <label class="form-label">Concepto</label>
                            <select name="concept_id" class="form-select" required>
                                <option value="">Seleccionar...</option>
                                <?php foreach ($concepts as $concept): ?>
                                    <option value="<?= $concept["concept_id"] ?>">
                                        <?= htmlspecialchars($concept["concept_code"]) ?> -
                                        <?= htmlspecialchars($concept["concept_name"]) ?> -
                                        <?= htmlspecialchars($concept["concept_type"]) ?>
                                    </option>
                                <?php endforeach; ?>
                            </select>
                        </div>

                        <div class="mb-3">
                            <label class="form-label">Cantidad</label>
                            <input type="number" step="0.01" name="quantity" class="form-control" value="1" required>
                        </div>

                        <div class="mb-3">
                            <label class="form-label">Importe</label>
                            <input type="number" step="0.01" name="amount" class="form-control" required>
                        </div>

                        <div class="mb-3">
                            <label class="form-label">Observaciones</label>
                            <input type="text" name="observations" class="form-control">
                        </div>

                        <button class="btn btn-primary">Agregar concepto</button>
                    </form>
                </div>
            </div>
        </div>

    </div>

    <h2 class="mt-4">Resumen de nómina</h2>

    <table class="table table-bordered table-striped bg-white">
        <thead>
            <tr>
                <th>Período</th>
                <th>Legajo</th>
                <th>Empleado</th>
                <th>Cargo</th>
                <th>Departamento</th>
                <th>Bruto</th>
                <th>Descuentos</th>
                <th>Neto</th>
                <th>Estado</th>
            </tr>
        </thead>
        <tbody>
            <?php foreach ($payrollSummary as $row): ?>
                <tr>
                    <td><?= htmlspecialchars($row["period_name"]) ?></td>
                    <td><?= htmlspecialchars($row["employee_code"]) ?></td>
                    <td>
                        <?= htmlspecialchars($row["last_name"]) ?>,
                        <?= htmlspecialchars($row["first_name"]) ?>
                    </td>
                    <td><?= htmlspecialchars($row["position_name"]) ?></td>
                    <td><?= htmlspecialchars($row["department_name"]) ?></td>
                    <td><?= format_money($row["gross_amount"]) ?></td>
                    <td><?= format_money($row["discount_amount"]) ?></td>
                    <td><?= format_money($row["net_amount"]) ?></td>
                    <td><?= htmlspecialchars($row["payroll_status"]) ?></td>
                </tr>
            <?php endforeach; ?>
        </tbody>
    </table>

    <h2 class="mt-4">Detalle de liquidaciones</h2>

    <table class="table table-bordered table-striped bg-white">
        <thead>
            <tr>
                <th>Período</th>
                <th>Legajo</th>
                <th>Empleado</th>
                <th>Código</th>
                <th>Concepto</th>
                <th>Tipo</th>
                <th>Cantidad</th>
                <th>Importe</th>
                <th>Observaciones</th>
            </tr>
        </thead>
        <tbody>
            <?php foreach ($payrollDetail as $row): ?>
                <tr>
                    <td><?= htmlspecialchars($row["period_name"]) ?></td>
                    <td><?= htmlspecialchars($row["employee_code"]) ?></td>
                    <td>
                        <?= htmlspecialchars($row["last_name"]) ?>,
                        <?= htmlspecialchars($row["first_name"]) ?>
                    </td>
                    <td><?= htmlspecialchars($row["concept_code"]) ?></td>
                    <td><?= htmlspecialchars($row["concept_name"]) ?></td>
                    <td><?= htmlspecialchars($row["concept_type"]) ?></td>
                    <td><?= htmlspecialchars($row["quantity"]) ?></td>
                    <td><?= format_money($row["amount"]) ?></td>
                    <td><?= htmlspecialchars($row["observations"] ?? "") ?></td>
                </tr>
            <?php endforeach; ?>
        </tbody>
    </table>

    <h2 class="mt-4">Compensaciones asignadas</h2>

    <table class="table table-bordered table-striped bg-white">
        <thead>
            <tr>
                <th>Legajo</th>
                <th>Empleado</th>
                <th>Sueldo base</th>
                <th>Desde</th>
                <th>Hasta</th>
                <th>Activo</th>
            </tr>
        </thead>
        <tbody>
            <?php foreach ($compensations as $row): ?>
                <tr>
                    <td><?= htmlspecialchars($row["employee_code"]) ?></td>
                    <td>
                        <?= htmlspecialchars($row["last_name"]) ?>,
                        <?= htmlspecialchars($row["first_name"]) ?>
                    </td>
                    <td><?= format_money($row["base_salary"]) ?></td>
                    <td><?= format_date_value($row["valid_from"]) ?></td>
                    <td><?= $row["valid_to"] ? format_date_value($row["valid_to"]) : "" ?></td>
                    <td><?= $row["is_active"] ? "Sí" : "No" ?></td>
                </tr>
            <?php endforeach; ?>
        </tbody>
    </table>

    <h2 class="mt-4">Períodos cargados</h2>

    <table class="table table-bordered table-striped bg-white">
        <thead>
            <tr>
                <th>Nombre</th>
                <th>Año</th>
                <th>Mes</th>
                <th>Inicio</th>
                <th>Fin</th>
                <th>Pago</th>
                <th>Estado</th>
            </tr>
        </thead>
        <tbody>
            <?php foreach ($periods as $row): ?>
                <tr>
                    <td><?= htmlspecialchars($row["period_name"]) ?></td>
                    <td><?= htmlspecialchars($row["period_year"]) ?></td>
                    <td><?= htmlspecialchars($row["period_month"]) ?></td>
                    <td><?= format_date_value($row["start_date"]) ?></td>
                    <td><?= format_date_value($row["end_date"]) ?></td>
                    <td><?= $row["payment_date"] ? format_date_value($row["payment_date"]) : "" ?></td>
                    <td><?= htmlspecialchars($row["period_status"]) ?></td>
                </tr>
            <?php endforeach; ?>
        </tbody>
    </table>

</div>
</body>
</html>
