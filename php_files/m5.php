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

    if ($value === null) {
        return "";
    }

    return htmlspecialchars((string)$value);
}

function format_decimal($value) {
    if ($value === null || $value === "") {
        return "";
    }

    return number_format((float)$value, 2, ",", ".");
}

if ($_SERVER["REQUEST_METHOD"] === "POST") {
    $action = $_POST["action"] ?? "";

    try {
        if ($action === "create_review_period") {
            $sql = "
                INSERT INTO rrhh.performance_review_periods (
                    period_name,
                    start_date,
                    end_date,
                    period_status
                )
                VALUES (?, ?, ?, ?)
            ";

            $params = [
                trim($_POST["period_name"]),
                $_POST["start_date"],
                $_POST["end_date"],
                $_POST["period_status"]
            ];

            execute_query($conn, $sql, $params);
            $message = "Período de evaluación creado correctamente.";
        }

        if ($action === "create_training_course") {
            $sql = "
                INSERT INTO rrhh.training_courses (
                    course_code,
                    course_name,
                    provider,
                    duration_hours,
                    course_type,
                    is_active
                )
                VALUES (?, ?, ?, ?, ?, 1)
            ";

            $params = [
                strtoupper(trim($_POST["course_code"])),
                trim($_POST["course_name"]),
                trim($_POST["provider"]),
                $_POST["duration_hours"],
                $_POST["course_type"]
            ];

            execute_query($conn, $sql, $params);
            $message = "Curso de capacitación creado correctamente.";
        }

        if ($action === "create_performance_review") {
            $reviewer = $_POST["reviewer_employee_id"] === "" ? null : $_POST["reviewer_employee_id"];

            $sql = "
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
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
            ";

            $params = [
                $_POST["employee_id"],
                $reviewer,
                $_POST["review_period_id"],
                $_POST["review_date"],
                $_POST["score"],
                trim($_POST["strengths"]),
                trim($_POST["improvement_areas"]),
                trim($_POST["comments"]),
                $_POST["review_status"]
            ];

            execute_query($conn, $sql, $params);
            $message = "Evaluación de desempeño registrada correctamente.";
        }

        if ($action === "assign_training") {
            $completionDate = $_POST["completion_date"] === "" ? null : $_POST["completion_date"];
            $resultScore = $_POST["result_score"] === "" ? null : $_POST["result_score"];

            $sql = "
                INSERT INTO rrhh.employee_training (
                    employee_id,
                    training_course_id,
                    enrollment_date,
                    completion_date,
                    training_status,
                    result_score,
                    observations
                )
                VALUES (?, ?, ?, ?, ?, ?, ?)
            ";

            $params = [
                $_POST["employee_id"],
                $_POST["training_course_id"],
                $_POST["enrollment_date"],
                $completionDate,
                $_POST["training_status"],
                $resultScore,
                trim($_POST["observations"])
            ];

            execute_query($conn, $sql, $params);
            $message = "Capacitación asignada correctamente.";
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

$reviewPeriods = fetch_all($conn, "
    SELECT
        review_period_id,
        period_name,
        start_date,
        end_date,
        period_status
    FROM rrhh.performance_review_periods
    ORDER BY start_date DESC
");

$trainingCourses = fetch_all($conn, "
    SELECT
        training_course_id,
        course_code,
        course_name,
        provider,
        duration_hours,
        course_type,
        is_active
    FROM rrhh.training_courses
    ORDER BY course_code
");

$performanceSummary = fetch_all($conn, "
    SELECT
        performance_review_id,
        period_name,
        employee_code,
        first_name,
        last_name,
        position_name,
        department_name,
        reviewer_code,
        reviewer_first_name,
        reviewer_last_name,
        review_date,
        score,
        review_status,
        strengths,
        improvement_areas,
        comments
    FROM rrhh.vw_desempeno_resumen
    ORDER BY period_name, last_name, first_name
");

$trainingSummary = fetch_all($conn, "
    SELECT
        employee_training_id,
        employee_code,
        first_name,
        last_name,
        position_name,
        department_name,
        course_code,
        course_name,
        provider,
        duration_hours,
        course_type,
        enrollment_date,
        completion_date,
        training_status,
        result_score,
        observations
    FROM rrhh.vw_capacitaciones_empleado
    ORDER BY employee_code, course_code
");
?>

<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <title>M5 - Desempeño y Capacitación</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet">
</head>

<body class="bg-light">
<div class="container py-4">

    <h1 class="mb-4">M5 - Desempeño y Capacitación</h1>

    <div class="mb-3">
        <a href="m1.php" class="btn btn-outline-secondary btn-sm">M1 - Empleados</a>
        <a href="m2.php" class="btn btn-outline-secondary btn-sm">M2 - Organización</a>
        <a href="m3.php" class="btn btn-outline-secondary btn-sm">M3 - Nómina</a>
        <a href="m4.php" class="btn btn-outline-secondary btn-sm">M4 - Asistencia</a>
        <a href="m5.php" class="btn btn-primary btn-sm">M5 - Desempeño</a>
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
                <div class="card-header">Crear período de evaluación</div>
                <div class="card-body">
                    <form method="POST">
                        <input type="hidden" name="action" value="create_review_period">

                        <div class="mb-3">
                            <label class="form-label">Nombre del período</label>
                            <input type="text" name="period_name" class="form-control" placeholder="Evaluación 2do Semestre 2026" required>
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
                <div class="card-header">Crear curso de capacitación</div>
                <div class="card-body">
                    <form method="POST">
                        <input type="hidden" name="action" value="create_training_course">

                        <div class="mb-3">
                            <label class="form-label">Código</label>
                            <input type="text" name="course_code" class="form-control" placeholder="TEC-002" required>
                        </div>

                        <div class="mb-3">
                            <label class="form-label">Nombre del curso</label>
                            <input type="text" name="course_name" class="form-control" required>
                        </div>

                        <div class="mb-3">
                            <label class="form-label">Proveedor</label>
                            <input type="text" name="provider" class="form-control" placeholder="DataCore Academy">
                        </div>

                        <div class="mb-3">
                            <label class="form-label">Duración en horas</label>
                            <input type="number" step="0.5" min="0.5" name="duration_hours" class="form-control" required>
                        </div>

                        <div class="mb-3">
                            <label class="form-label">Tipo</label>
                            <select name="course_type" class="form-select" required>
                                <option value="TECNICA">Técnica</option>
                                <option value="BLANDA">Blanda</option>
                                <option value="OBLIGATORIA">Obligatoria</option>
                                <option value="SEGURIDAD">Seguridad</option>
                            </select>
                        </div>

                        <button class="btn btn-primary">Crear curso</button>
                    </form>
                </div>
            </div>
        </div>

    </div>

    <div class="row">

        <div class="col-md-6 mb-4">
            <div class="card">
                <div class="card-header">Registrar evaluación de desempeño</div>
                <div class="card-body">
                    <form method="POST">
                        <input type="hidden" name="action" value="create_performance_review">

                        <div class="mb-3">
                            <label class="form-label">Empleado evaluado</label>
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
                            <label class="form-label">Evaluador</label>
                            <select name="reviewer_employee_id" class="form-select">
                                <option value="">Sin evaluador asignado</option>
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
                            <label class="form-label">Período</label>
                            <select name="review_period_id" class="form-select" required>
                                <option value="">Seleccionar...</option>
                                <?php foreach ($reviewPeriods as $period): ?>
                                    <option value="<?= $period["review_period_id"] ?>">
                                        <?= htmlspecialchars($period["period_name"]) ?>
                                    </option>
                                <?php endforeach; ?>
                            </select>
                        </div>

                        <div class="mb-3">
                            <label class="form-label">Fecha de evaluación</label>
                            <input type="date" name="review_date" class="form-control" required>
                        </div>

                        <div class="mb-3">
                            <label class="form-label">Puntaje 0 a 10</label>
                            <input type="number" step="0.25" min="0" max="10" name="score" class="form-control" required>
                        </div>

                        <div class="mb-3">
                            <label class="form-label">Fortalezas</label>
                            <textarea name="strengths" class="form-control" rows="2"></textarea>
                        </div>

                        <div class="mb-3">
                            <label class="form-label">Áreas de mejora</label>
                            <textarea name="improvement_areas" class="form-control" rows="2"></textarea>
                        </div>

                        <div class="mb-3">
                            <label class="form-label">Comentarios</label>
                            <textarea name="comments" class="form-control" rows="2"></textarea>
                        </div>

                        <div class="mb-3">
                            <label class="form-label">Estado</label>
                            <select name="review_status" class="form-select" required>
                                <option value="BORRADOR">Borrador</option>
                                <option value="FINALIZADA">Finalizada</option>
                                <option value="ANULADA">Anulada</option>
                            </select>
                        </div>

                        <button class="btn btn-primary">Registrar evaluación</button>
                    </form>
                </div>
            </div>
        </div>

        <div class="col-md-6 mb-4">
            <div class="card">
                <div class="card-header">Asignar capacitación</div>
                <div class="card-body">
                    <form method="POST">
                        <input type="hidden" name="action" value="assign_training">

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
                            <label class="form-label">Curso</label>
                            <select name="training_course_id" class="form-select" required>
                                <option value="">Seleccionar...</option>
                                <?php foreach ($trainingCourses as $course): ?>
                                    <option value="<?= $course["training_course_id"] ?>">
                                        <?= htmlspecialchars($course["course_code"]) ?> -
                                        <?= htmlspecialchars($course["course_name"]) ?>
                                    </option>
                                <?php endforeach; ?>
                            </select>
                        </div>

                        <div class="mb-3">
                            <label class="form-label">Fecha de inscripción</label>
                            <input type="date" name="enrollment_date" class="form-control" required>
                        </div>

                        <div class="mb-3">
                            <label class="form-label">Fecha de finalización</label>
                            <input type="date" name="completion_date" class="form-control">
                        </div>

                        <div class="mb-3">
                            <label class="form-label">Estado</label>
                            <select name="training_status" class="form-select" required>
                                <option value="INSCRIPTO">Inscripto</option>
                                <option value="EN_CURSO">En curso</option>
                                <option value="COMPLETADO">Completado</option>
                                <option value="CANCELADO">Cancelado</option>
                            </select>
                        </div>

                        <div class="mb-3">
                            <label class="form-label">Resultado 0 a 10</label>
                            <input type="number" step="0.25" min="0" max="10" name="result_score" class="form-control">
                        </div>

                        <div class="mb-3">
                            <label class="form-label">Observaciones</label>
                            <textarea name="observations" class="form-control" rows="2"></textarea>
                        </div>

                        <button class="btn btn-primary">Asignar capacitación</button>
                    </form>
                </div>
            </div>
        </div>

    </div>

    <h2 class="mt-4">Resumen de desempeño</h2>

    <table class="table table-bordered table-striped bg-white">
        <thead>
            <tr>
                <th>Período</th>
                <th>Legajo</th>
                <th>Empleado</th>
                <th>Cargo</th>
                <th>Departamento</th>
                <th>Evaluador</th>
                <th>Fecha</th>
                <th>Puntaje</th>
                <th>Estado</th>
            </tr>
        </thead>
        <tbody>
            <?php foreach ($performanceSummary as $review): ?>
                <tr>
                    <td><?= htmlspecialchars($review["period_name"]) ?></td>
                    <td><?= htmlspecialchars($review["employee_code"]) ?></td>
                    <td><?= htmlspecialchars($review["last_name"]) ?>, <?= htmlspecialchars($review["first_name"]) ?></td>
                    <td><?= htmlspecialchars($review["position_name"]) ?></td>
                    <td><?= htmlspecialchars($review["department_name"]) ?></td>
                    <td>
                        <?php if ($review["reviewer_code"]): ?>
                            <?= htmlspecialchars($review["reviewer_code"]) ?> -
                            <?= htmlspecialchars($review["reviewer_last_name"]) ?>,
                            <?= htmlspecialchars($review["reviewer_first_name"]) ?>
                        <?php else: ?>
                            -
                        <?php endif; ?>
                    </td>
                    <td><?= format_date_value($review["review_date"]) ?></td>
                    <td><?= format_decimal($review["score"]) ?></td>
                    <td><?= htmlspecialchars($review["review_status"]) ?></td>
                </tr>
            <?php endforeach; ?>
        </tbody>
    </table>

    <h2 class="mt-4">Capacitaciones por empleado</h2>

    <table class="table table-bordered table-striped bg-white">
        <thead>
            <tr>
                <th>Legajo</th>
                <th>Empleado</th>
                <th>Curso</th>
                <th>Tipo</th>
                <th>Proveedor</th>
                <th>Horas</th>
                <th>Inscripción</th>
                <th>Finalización</th>
                <th>Estado</th>
                <th>Resultado</th>
                <th>Observaciones</th>
            </tr>
        </thead>
        <tbody>
            <?php foreach ($trainingSummary as $training): ?>
                <tr>
                    <td><?= htmlspecialchars($training["employee_code"]) ?></td>
                    <td><?= htmlspecialchars($training["last_name"]) ?>, <?= htmlspecialchars($training["first_name"]) ?></td>
                    <td>
                        <?= htmlspecialchars($training["course_code"]) ?> -
                        <?= htmlspecialchars($training["course_name"]) ?>
                    </td>
                    <td><?= htmlspecialchars($training["course_type"]) ?></td>
                    <td><?= htmlspecialchars($training["provider"] ?? "") ?></td>
                    <td><?= format_decimal($training["duration_hours"]) ?></td>
                    <td><?= format_date_value($training["enrollment_date"]) ?></td>
                    <td><?= format_date_value($training["completion_date"]) ?></td>
                    <td><?= htmlspecialchars($training["training_status"]) ?></td>
                    <td><?= format_decimal($training["result_score"]) ?></td>
                    <td><?= htmlspecialchars($training["observations"] ?? "") ?></td>
                </tr>
            <?php endforeach; ?>
        </tbody>
    </table>

    <h2 class="mt-4">Períodos de evaluación</h2>

    <table class="table table-bordered table-striped bg-white">
        <thead>
            <tr>
                <th>Período</th>
                <th>Inicio</th>
                <th>Fin</th>
                <th>Estado</th>
            </tr>
        </thead>
        <tbody>
            <?php foreach ($reviewPeriods as $period): ?>
                <tr>
                    <td><?= htmlspecialchars($period["period_name"]) ?></td>
                    <td><?= format_date_value($period["start_date"]) ?></td>
                    <td><?= format_date_value($period["end_date"]) ?></td>
                    <td><?= htmlspecialchars($period["period_status"]) ?></td>
                </tr>
            <?php endforeach; ?>
        </tbody>
    </table>

    <h2 class="mt-4">Cursos disponibles</h2>

    <table class="table table-bordered table-striped bg-white">
        <thead>
            <tr>
                <th>Código</th>
                <th>Curso</th>
                <th>Proveedor</th>
                <th>Horas</th>
                <th>Tipo</th>
                <th>Activo</th>
            </tr>
        </thead>
        <tbody>
            <?php foreach ($trainingCourses as $course): ?>
                <tr>
                    <td><?= htmlspecialchars($course["course_code"]) ?></td>
                    <td><?= htmlspecialchars($course["course_name"]) ?></td>
                    <td><?= htmlspecialchars($course["provider"] ?? "") ?></td>
                    <td><?= format_decimal($course["duration_hours"]) ?></td>
                    <td><?= htmlspecialchars($course["course_type"]) ?></td>
                    <td><?= $course["is_active"] ? "Sí" : "No" ?></td>
                </tr>
            <?php endforeach; ?>
        </tbody>
    </table>

</div>
</body>
</html>
