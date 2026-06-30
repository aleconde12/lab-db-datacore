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

function format_date_value($value) {
    if ($value instanceof DateTime) {
        return $value->format("Y-m-d");
    }

    return htmlspecialchars((string)$value);
}

function format_time_value($value) {
    if ($value instanceof DateTime) {
        return $value->format("H:i");
    }

    if ($value === null) {
        return "";
    }

    return htmlspecialchars((string)$value);
}

function format_decimal($value) {
    return number_format((float)$value, 2, ",", ".");
}

if ($_SERVER["REQUEST_METHOD"] === "POST") {
    $action = $_POST["action"] ?? "";

    try {
        if ($action === "create_attendance_type") {
            $sql = "
                INSERT INTO rrhh.attendance_types (
                    type_code,
                    type_name,
                    description,
                    affects_worked_hours,
                    is_active
                )
                VALUES (?, ?, ?, ?, 1)
            ";

            $params = [
                strtoupper(trim($_POST["type_code"])),
                trim($_POST["type_name"]),
                trim($_POST["description"]),
                isset($_POST["affects_worked_hours"]) ? 1 : 0
            ];

            execute_query($conn, $sql, $params);
            $message = "Tipo de asistencia creado correctamente.";
        }

        if ($action === "create_work_schedule") {
            $sql = "
                INSERT INTO rrhh.work_schedules (
                    schedule_name,
                    start_time,
                    end_time,
                    expected_hours,
                    description,
                    is_active
                )
                VALUES (?, ?, ?, ?, ?, 1)
            ";

            $params = [
                trim($_POST["schedule_name"]),
                $_POST["start_time"],
                $_POST["end_time"],
                $_POST["expected_hours"],
                trim($_POST["description"])
            ];

            execute_query($conn, $sql, $params);
            $message = "Horario laboral creado correctamente.";
        }

        if ($action === "assign_schedule") {
            $sql = "
                INSERT INTO rrhh.employee_schedules (
                    employee_id,
                    work_schedule_id,
                    valid_from,
                    valid_to,
                    is_active
                )
                VALUES (?, ?, ?, ?, 1)
            ";

            $params = [
                $_POST["employee_id"],
                $_POST["work_schedule_id"],
                $_POST["valid_from"],
                $_POST["valid_to"] === "" ? null : $_POST["valid_to"]
            ];

            execute_query($conn, $sql, $params);
            $message = "Horario asignado al empleado correctamente.";
        }

        if ($action === "create_attendance_record") {
            $checkIn = $_POST["check_in_time"] === "" ? null : $_POST["check_in_time"];
            $checkOut = $_POST["check_out_time"] === "" ? null : $_POST["check_out_time"];
            $workedHours = $_POST["worked_hours"] === "" ? 0 : $_POST["worked_hours"];

            $sql = "
                INSERT INTO rrhh.attendance_records (
                    employee_id,
                    attendance_type_id,
                    attendance_date,
                    check_in_time,
                    check_out_time,
                    worked_hours,
                    observations
                )
                VALUES (?, ?, ?, ?, ?, ?, ?)
            ";

            $params = [
                $_POST["employee_id"],
                $_POST["attendance_type_id"],
                $_POST["attendance_date"],
                $checkIn,
                $checkOut,
                $workedHours,
                trim($_POST["observations"])
            ];

            execute_query($conn, $sql, $params);
            $message = "Registro de asistencia cargado correctamente.";
        }

    } catch (Exception $e) {
        $error = $e->getMessage();
    }
}

$employees = fetch_all($conn, "
    SELECT
        employee_id,
        employee_code,
        first_name,
        last_name
    FROM rrhh.employees
    WHERE is_active = 1
    ORDER BY last_name, first_name
");

$attendanceTypes = fetch_all($conn, "
    SELECT
        attendance_type_id,
        type_code,
        type_name,
        description,
        affects_worked_hours,
        is_active
    FROM rrhh.attendance_types
    ORDER BY type_name
");

$activeAttendanceTypes = fetch_all($conn, "
    SELECT
        attendance_type_id,
        type_code,
        type_name
    FROM rrhh.attendance_types
    WHERE is_active = 1
    ORDER BY type_name
");

$workSchedules = fetch_all($conn, "
    SELECT
        work_schedule_id,
        schedule_name,
        start_time,
        end_time,
        expected_hours,
        description,
        is_active
    FROM rrhh.work_schedules
    ORDER BY schedule_name
");

$activeWorkSchedules = fetch_all($conn, "
    SELECT
        work_schedule_id,
        schedule_name,
        start_time,
        end_time,
        expected_hours
    FROM rrhh.work_schedules
    WHERE is_active = 1
    ORDER BY schedule_name
");

$employeeSchedules = fetch_all($conn, "
    SELECT
        es.employee_schedule_id,
        e.employee_code,
        e.first_name,
        e.last_name,
        ws.schedule_name,
        ws.start_time,
        ws.end_time,
        ws.expected_hours,
        es.valid_from,
        es.valid_to,
        es.is_active
    FROM rrhh.employee_schedules es
    INNER JOIN rrhh.employees e
        ON es.employee_id = e.employee_id
    INNER JOIN rrhh.work_schedules ws
        ON es.work_schedule_id = ws.work_schedule_id
    ORDER BY e.last_name, e.first_name, es.valid_from DESC
");

$attendanceSummary = fetch_all($conn, "
    SELECT
        attendance_record_id,
        attendance_date,
        employee_code,
        first_name,
        last_name,
        position_name,
        department_name,
        type_code,
        type_name,
        check_in_time,
        check_out_time,
        worked_hours,
        observations
    FROM rrhh.vw_asistencia_resumen
    ORDER BY attendance_date DESC, employee_code
");

$attendanceByEmployee = fetch_all($conn, "
    SELECT
        employee_code,
        first_name,
        last_name,
        total_registros,
        total_horas_trabajadas,
        dias_presente,
        dias_ausente,
        llegadas_tarde,
        dias_home_office
    FROM rrhh.vw_asistencia_por_empleado
    ORDER BY employee_code
");
?>

<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <title>M4 - Asistencia y Tiempo</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet">
</head>

<body class="bg-light">
<div class="container py-4">

    <h1 class="mb-4">M4 - Asistencia y Tiempo</h1>

    <div class="mb-3">
        <a href="m1.php" class="btn btn-outline-secondary btn-sm">M1 - Empleados</a>
        <a href="m2.php" class="btn btn-outline-secondary btn-sm">M2 - Organización</a>
        <a href="m3.php" class="btn btn-outline-secondary btn-sm">M3 - Nómina</a>
        <a href="m4.php" class="btn btn-primary btn-sm">M4 - Asistencia</a>
        <a href="m5.php" class="btn btn-outline-secondary btn-sm">M5 - Desempeño</a>
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
                <div class="card-header">Crear tipo de asistencia</div>
                <div class="card-body">
                    <form method="POST">
                        <input type="hidden" name="action" value="create_attendance_type">

                        <div class="mb-3">
                            <label class="form-label">Código</label>
                            <input type="text" name="type_code" class="form-control" placeholder="PRESENTE" required>
                        </div>

                        <div class="mb-3">
                            <label class="form-label">Nombre</label>
                            <input type="text" name="type_name" class="form-control" placeholder="Presente" required>
                        </div>

                        <div class="mb-3">
                            <label class="form-label">Descripción</label>
                            <input type="text" name="description" class="form-control">
                        </div>

                        <div class="form-check mb-3">
                            <input class="form-check-input" type="checkbox" name="affects_worked_hours" id="affects_worked_hours" checked>
                            <label class="form-check-label" for="affects_worked_hours">
                                Afecta horas trabajadas
                            </label>
                        </div>

                        <button class="btn btn-primary">Crear tipo</button>
                    </form>
                </div>
            </div>
        </div>

        <div class="col-md-6 mb-4">
            <div class="card">
                <div class="card-header">Crear horario laboral</div>
                <div class="card-body">
                    <form method="POST">
                        <input type="hidden" name="action" value="create_work_schedule">

                        <div class="mb-3">
                            <label class="form-label">Nombre del horario</label>
                            <input type="text" name="schedule_name" class="form-control" placeholder="Jornada completa 09 a 18" required>
                        </div>

                        <div class="mb-3">
                            <label class="form-label">Hora de entrada</label>
                            <input type="time" name="start_time" class="form-control" required>
                        </div>

                        <div class="mb-3">
                            <label class="form-label">Hora de salida</label>
                            <input type="time" name="end_time" class="form-control" required>
                        </div>

                        <div class="mb-3">
                            <label class="form-label">Horas esperadas</label>
                            <input type="number" step="0.25" min="0" max="24" name="expected_hours" class="form-control" placeholder="8" required>
                        </div>

                        <div class="mb-3">
                            <label class="form-label">Descripción</label>
                            <input type="text" name="description" class="form-control">
                        </div>

                        <button class="btn btn-primary">Crear horario</button>
                    </form>
                </div>
            </div>
        </div>

    </div>

    <div class="row">

        <div class="col-md-6 mb-4">
            <div class="card">
                <div class="card-header">Asignar horario a empleado</div>
                <div class="card-body">
                    <form method="POST">
                        <input type="hidden" name="action" value="assign_schedule">

                        <div class="mb-3">
                            <label class="form-label">Empleado</label>
                            <select name="employee_id" class="form-select" required>
                                <option value="">Seleccionar...</option>
                                <?php foreach ($employees as $employee): ?>
                                    <option value="<?= $employee["employee_id"] ?>">
                                        <?= htmlspecialchars($employee["employee_code"]) ?> -
                                        <?= htmlspecialchars($employee["last_name"]) ?>,
                                        <?= htmlspecialchars($employee["first_name"]) ?>
                                    </option>
                                <?php endforeach; ?>
                            </select>
                        </div>

                        <div class="mb-3">
                            <label class="form-label">Horario</label>
                            <select name="work_schedule_id" class="form-select" required>
                                <option value="">Seleccionar...</option>
                                <?php foreach ($activeWorkSchedules as $schedule): ?>
                                    <option value="<?= $schedule["work_schedule_id"] ?>">
                                        <?= htmlspecialchars($schedule["schedule_name"]) ?>
                                        (<?= format_time_value($schedule["start_time"]) ?> a <?= format_time_value($schedule["end_time"]) ?>)
                                    </option>
                                <?php endforeach; ?>
                            </select>
                        </div>

                        <div class="mb-3">
                            <label class="form-label">Vigente desde</label>
                            <input type="date" name="valid_from" class="form-control" required>
                        </div>

                        <div class="mb-3">
                            <label class="form-label">Vigente hasta</label>
                            <input type="date" name="valid_to" class="form-control">
                        </div>

                        <button class="btn btn-primary">Asignar horario</button>
                    </form>
                </div>
            </div>
        </div>

        <div class="col-md-6 mb-4">
            <div class="card">
                <div class="card-header">Registrar asistencia diaria</div>
                <div class="card-body">
                    <form method="POST">
                        <input type="hidden" name="action" value="create_attendance_record">

                        <div class="mb-3">
                            <label class="form-label">Empleado</label>
                            <select name="employee_id" class="form-select" required>
                                <option value="">Seleccionar...</option>
                                <?php foreach ($employees as $employee): ?>
                                    <option value="<?= $employee["employee_id"] ?>">
                                        <?= htmlspecialchars($employee["employee_code"]) ?> -
                                        <?= htmlspecialchars($employee["last_name"]) ?>,
                                        <?= htmlspecialchars($employee["first_name"]) ?>
                                    </option>
                                <?php endforeach; ?>
                            </select>
                        </div>

                        <div class="mb-3">
                            <label class="form-label">Tipo de asistencia</label>
                            <select name="attendance_type_id" class="form-select" required>
                                <option value="">Seleccionar...</option>
                                <?php foreach ($activeAttendanceTypes as $type): ?>
                                    <option value="<?= $type["attendance_type_id"] ?>">
                                        <?= htmlspecialchars($type["type_name"]) ?>
                                        (<?= htmlspecialchars($type["type_code"]) ?>)
                                    </option>
                                <?php endforeach; ?>
                            </select>
                        </div>

                        <div class="mb-3">
                            <label class="form-label">Fecha</label>
                            <input type="date" name="attendance_date" class="form-control" required>
                        </div>

                        <div class="mb-3">
                            <label class="form-label">Entrada</label>
                            <input type="time" name="check_in_time" class="form-control">
                        </div>

                        <div class="mb-3">
                            <label class="form-label">Salida</label>
                            <input type="time" name="check_out_time" class="form-control">
                        </div>

                        <div class="mb-3">
                            <label class="form-label">Horas trabajadas</label>
                            <input type="number" step="0.25" min="0" max="24" name="worked_hours" class="form-control" placeholder="8">
                        </div>

                        <div class="mb-3">
                            <label class="form-label">Observaciones</label>
                            <input type="text" name="observations" class="form-control">
                        </div>

                        <button class="btn btn-primary">Registrar asistencia</button>
                    </form>
                </div>
            </div>
        </div>

    </div>

    <h2 class="mt-4">Resumen de asistencia diaria</h2>

    <table class="table table-bordered table-striped bg-white">
        <thead>
            <tr>
                <th>Fecha</th>
                <th>Legajo</th>
                <th>Empleado</th>
                <th>Cargo</th>
                <th>Departamento</th>
                <th>Tipo</th>
                <th>Entrada</th>
                <th>Salida</th>
                <th>Horas</th>
                <th>Observaciones</th>
            </tr>
        </thead>
        <tbody>
            <?php foreach ($attendanceSummary as $record): ?>
                <tr>
                    <td><?= format_date_value($record["attendance_date"]) ?></td>
                    <td><?= htmlspecialchars($record["employee_code"]) ?></td>
                    <td>
                        <?= htmlspecialchars($record["last_name"]) ?>,
                        <?= htmlspecialchars($record["first_name"]) ?>
                    </td>
                    <td><?= htmlspecialchars($record["position_name"]) ?></td>
                    <td><?= htmlspecialchars($record["department_name"]) ?></td>
                    <td><?= htmlspecialchars($record["type_name"]) ?></td>
                    <td><?= format_time_value($record["check_in_time"]) ?></td>
                    <td><?= format_time_value($record["check_out_time"]) ?></td>
                    <td><?= format_decimal($record["worked_hours"]) ?></td>
                    <td><?= htmlspecialchars($record["observations"] ?? "") ?></td>
                </tr>
            <?php endforeach; ?>
        </tbody>
    </table>

    <h2 class="mt-4">Resumen por empleado</h2>

    <table class="table table-bordered table-striped bg-white">
        <thead>
            <tr>
                <th>Legajo</th>
                <th>Empleado</th>
                <th>Registros</th>
                <th>Horas trabajadas</th>
                <th>Días presente</th>
                <th>Días ausente</th>
                <th>Llegadas tarde</th>
                <th>Home office</th>
            </tr>
        </thead>
        <tbody>
            <?php foreach ($attendanceByEmployee as $summary): ?>
                <tr>
                    <td><?= htmlspecialchars($summary["employee_code"]) ?></td>
                    <td>
                        <?= htmlspecialchars($summary["last_name"]) ?>,
                        <?= htmlspecialchars($summary["first_name"]) ?>
                    </td>
                    <td><?= htmlspecialchars((string)$summary["total_registros"]) ?></td>
                    <td><?= format_decimal($summary["total_horas_trabajadas"] ?? 0) ?></td>
                    <td><?= htmlspecialchars((string)$summary["dias_presente"]) ?></td>
                    <td><?= htmlspecialchars((string)$summary["dias_ausente"]) ?></td>
                    <td><?= htmlspecialchars((string)$summary["llegadas_tarde"]) ?></td>
                    <td><?= htmlspecialchars((string)$summary["dias_home_office"]) ?></td>
                </tr>
            <?php endforeach; ?>
        </tbody>
    </table>

    <h2 class="mt-4">Horarios asignados</h2>

    <table class="table table-bordered table-striped bg-white">
        <thead>
            <tr>
                <th>Legajo</th>
                <th>Empleado</th>
                <th>Horario</th>
                <th>Entrada</th>
                <th>Salida</th>
                <th>Horas esperadas</th>
                <th>Desde</th>
                <th>Hasta</th>
                <th>Activo</th>
            </tr>
        </thead>
        <tbody>
            <?php foreach ($employeeSchedules as $assignment): ?>
                <tr>
                    <td><?= htmlspecialchars($assignment["employee_code"]) ?></td>
                    <td>
                        <?= htmlspecialchars($assignment["last_name"]) ?>,
                        <?= htmlspecialchars($assignment["first_name"]) ?>
                    </td>
                    <td><?= htmlspecialchars($assignment["schedule_name"]) ?></td>
                    <td><?= format_time_value($assignment["start_time"]) ?></td>
                    <td><?= format_time_value($assignment["end_time"]) ?></td>
                    <td><?= format_decimal($assignment["expected_hours"]) ?></td>
                    <td><?= format_date_value($assignment["valid_from"]) ?></td>
                    <td><?= $assignment["valid_to"] ? format_date_value($assignment["valid_to"]) : "" ?></td>
                    <td><?= $assignment["is_active"] ? "Sí" : "No" ?></td>
                </tr>
            <?php endforeach; ?>
        </tbody>
    </table>

    <h2 class="mt-4">Tipos de asistencia</h2>

    <table class="table table-bordered table-striped bg-white">
        <thead>
            <tr>
                <th>Código</th>
                <th>Nombre</th>
                <th>Descripción</th>
                <th>Afecta horas</th>
                <th>Activo</th>
            </tr>
        </thead>
        <tbody>
            <?php foreach ($attendanceTypes as $type): ?>
                <tr>
                    <td><?= htmlspecialchars($type["type_code"]) ?></td>
                    <td><?= htmlspecialchars($type["type_name"]) ?></td>
                    <td><?= htmlspecialchars($type["description"] ?? "") ?></td>
                    <td><?= $type["affects_worked_hours"] ? "Sí" : "No" ?></td>
                    <td><?= $type["is_active"] ? "Sí" : "No" ?></td>
                </tr>
            <?php endforeach; ?>
        </tbody>
    </table>

    <h2 class="mt-4">Horarios laborales</h2>

    <table class="table table-bordered table-striped bg-white">
        <thead>
            <tr>
                <th>Nombre</th>
                <th>Entrada</th>
                <th>Salida</th>
                <th>Horas esperadas</th>
                <th>Descripción</th>
                <th>Activo</th>
            </tr>
        </thead>
        <tbody>
            <?php foreach ($workSchedules as $schedule): ?>
                <tr>
                    <td><?= htmlspecialchars($schedule["schedule_name"]) ?></td>
                    <td><?= format_time_value($schedule["start_time"]) ?></td>
                    <td><?= format_time_value($schedule["end_time"]) ?></td>
                    <td><?= format_decimal($schedule["expected_hours"]) ?></td>
                    <td><?= htmlspecialchars($schedule["description"] ?? "") ?></td>
                    <td><?= $schedule["is_active"] ? "Sí" : "No" ?></td>
                </tr>
            <?php endforeach; ?>
        </tbody>
    </table>

</div>
</body>
</html>
