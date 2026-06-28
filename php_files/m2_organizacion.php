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

if ($_SERVER["REQUEST_METHOD"] === "POST") {
    $action = $_POST["action"] ?? "";

    try {
if ($action === "create_department") {
    $departmentName = trim($_POST["department_name"]);
    $description = trim($_POST["description"]);

    $checkSql = "
        SELECT COUNT(*) AS total
        FROM rrhh.departments
        WHERE department_name = ?
    ";

    $checkStmt = sqlsrv_query($conn, $checkSql, [$departmentName]);

    if ($checkStmt === false) {
        throw new Exception(print_r(sqlsrv_errors(), true));
    }

    $checkRow = sqlsrv_fetch_array($checkStmt, SQLSRV_FETCH_ASSOC);

    if ($checkRow["total"] > 0) {
        $error = "Ya existe un departamento con el nombre '$departmentName'.";
    } else {
        $sql = "
            INSERT INTO rrhh.departments (department_name, description)
            VALUES (?, ?)
        ";

        $params = [
            $departmentName,
            $description
        ];

        $stmt = sqlsrv_query($conn, $sql, $params);

        if ($stmt === false) {
            throw new Exception(print_r(sqlsrv_errors(), true));
        }

        $message = "Departamento creado correctamente.";
    }
}

        if ($action === "create_job_level") {
            $sql = "
                INSERT INTO rrhh.job_levels (
                    level_number,
                    level_name,
                    description,
                    min_salary,
                    max_salary
                )
                VALUES (?, ?, ?, ?, ?)
            ";

            $params = [
                $_POST["level_number"],
                $_POST["level_name"],
                $_POST["description"],
                $_POST["min_salary"],
                $_POST["max_salary"]
            ];

            $stmt = sqlsrv_query($conn, $sql, $params);

            if ($stmt === false) {
                throw new Exception(print_r(sqlsrv_errors(), true));
            }

            $message = "Nivel jerárquico creado correctamente.";
        }

        if ($action === "create_position") {
            $sql = "
                INSERT INTO rrhh.positions (
                    department_id,
                    job_level_id,
                    position_name,
                    description,
                    base_salary
                )
                VALUES (?, ?, ?, ?, ?)
            ";

            $params = [
                $_POST["department_id"],
                $_POST["job_level_id"],
                $_POST["position_name"],
                $_POST["description"],
                $_POST["base_salary"]
            ];

            $stmt = sqlsrv_query($conn, $sql, $params);

            if ($stmt === false) {
                throw new Exception(print_r(sqlsrv_errors(), true));
            }

            $message = "Cargo creado correctamente.";
        }

        if ($action === "create_reporting") {
            $reportsTo = $_POST["reports_to_position_id"] === "" ? null : $_POST["reports_to_position_id"];

            $sql = "
                INSERT INTO rrhh.reporting_structure (
                    position_id,
                    reports_to_position_id,
                    effective_from
                )
                VALUES (?, ?, ?)
            ";

            $params = [
                $_POST["position_id"],
                $reportsTo,
                $_POST["effective_from"]
            ];

            $stmt = sqlsrv_query($conn, $sql, $params);

            if ($stmt === false) {
                throw new Exception(print_r(sqlsrv_errors(), true));
            }

            $message = "Relación de reporte creada correctamente.";
        }

    } catch (Exception $e) {
        $error = $e->getMessage();
    }
}

$departments = fetch_all($conn, "
    SELECT department_id, department_name, description, is_active
    FROM rrhh.departments
    ORDER BY department_name
");

$jobLevels = fetch_all($conn, "
    SELECT job_level_id, level_number, level_name, min_salary, max_salary, is_active
    FROM rrhh.job_levels
    ORDER BY level_number
");

$positions = fetch_all($conn, "
    SELECT 
        p.position_id,
        p.position_name,
        p.base_salary,
        d.department_name,
        jl.level_number,
        jl.level_name
    FROM rrhh.positions p
    INNER JOIN rrhh.departments d
        ON p.department_id = d.department_id
    INNER JOIN rrhh.job_levels jl
        ON p.job_level_id = jl.job_level_id
    ORDER BY d.department_name, jl.level_number
");

$organigrama = fetch_all($conn, "
    SELECT
        d.department_name,
        p.position_name,
        jl.level_number,
        jl.level_name,
        p.base_salary,
        manager.position_name AS reports_to_position
    FROM rrhh.positions p
    INNER JOIN rrhh.departments d
        ON p.department_id = d.department_id
    INNER JOIN rrhh.job_levels jl
        ON p.job_level_id = jl.job_level_id
    LEFT JOIN rrhh.reporting_structure rs
        ON p.position_id = rs.position_id
        AND rs.is_active = 1
    LEFT JOIN rrhh.positions manager
        ON rs.reports_to_position_id = manager.position_id
    ORDER BY d.department_name, jl.level_number
");
?>

<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <title>M2 - Organización y Cargos</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet">
</head>

<body class="bg-light">
<div class="container py-4">

    <h1 class="mb-4">M2 - Organización y Cargos</h1>

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
                <div class="card-header">Alta de departamento</div>
                <div class="card-body">
                    <form method="POST">
                        <input type="hidden" name="action" value="create_department">

                        <div class="mb-3">
                            <label class="form-label">Nombre</label>
                            <input type="text" name="department_name" class="form-control" required>
                        </div>

                        <div class="mb-3">
                            <label class="form-label">Descripción</label>
                            <input type="text" name="description" class="form-control">
                        </div>

                        <button class="btn btn-primary">Crear departamento</button>
                    </form>
                </div>
            </div>
        </div>

        <div class="col-md-6 mb-4">
            <div class="card">
                <div class="card-header">Alta de nivel jerárquico</div>
                <div class="card-body">
                    <form method="POST">
                        <input type="hidden" name="action" value="create_job_level">

                        <div class="mb-3">
                            <label class="form-label">Número de nivel</label>
                            <input type="number" name="level_number" class="form-control" required>
                        </div>

                        <div class="mb-3">
                            <label class="form-label">Nombre del nivel</label>
                            <input type="text" name="level_name" class="form-control" required>
                        </div>

                        <div class="mb-3">
                            <label class="form-label">Descripción</label>
                            <input type="text" name="description" class="form-control">
                        </div>

                        <div class="mb-3">
                            <label class="form-label">Salario mínimo</label>
                            <input type="number" step="0.01" name="min_salary" class="form-control" required>
                        </div>

                        <div class="mb-3">
                            <label class="form-label">Salario máximo</label>
                            <input type="number" step="0.01" name="max_salary" class="form-control" required>
                        </div>

                        <button class="btn btn-primary">Crear nivel</button>
                    </form>
                </div>
            </div>
        </div>

    </div>

    <div class="row">

        <div class="col-md-6 mb-4">
            <div class="card">
                <div class="card-header">Alta de cargo</div>
                <div class="card-body">
                    <form method="POST">
                        <input type="hidden" name="action" value="create_position">

                        <div class="mb-3">
                            <label class="form-label">Departamento</label>
                            <select name="department_id" class="form-select" required>
                                <option value="">Seleccionar...</option>
                                <?php foreach ($departments as $department): ?>
                                    <option value="<?= $department["department_id"] ?>">
                                        <?= htmlspecialchars($department["department_name"]) ?>
                                    </option>
                                <?php endforeach; ?>
                            </select>
                        </div>

                        <div class="mb-3">
                            <label class="form-label">Nivel jerárquico</label>
                            <select name="job_level_id" class="form-select" required>
                                <option value="">Seleccionar...</option>
                                <?php foreach ($jobLevels as $level): ?>
                                    <option value="<?= $level["job_level_id"] ?>">
                                        Nivel <?= htmlspecialchars($level["level_number"]) ?> - <?= htmlspecialchars($level["level_name"]) ?>
                                    </option>
                                <?php endforeach; ?>
                            </select>
                        </div>

                        <div class="mb-3">
                            <label class="form-label">Nombre del cargo</label>
                            <input type="text" name="position_name" class="form-control" required>
                        </div>

                        <div class="mb-3">
                            <label class="form-label">Descripción</label>
                            <input type="text" name="description" class="form-control">
                        </div>

                        <div class="mb-3">
                            <label class="form-label">Salario base</label>
                            <input type="number" step="0.01" name="base_salary" class="form-control" required>
                        </div>

                        <button class="btn btn-primary">Crear cargo</button>
                    </form>
                </div>
            </div>
        </div>

        <div class="col-md-6 mb-4">
            <div class="card">
                <div class="card-header">Definir reporte jerárquico</div>
                <div class="card-body">
                    <form method="POST">
                        <input type="hidden" name="action" value="create_reporting">

                        <div class="mb-3">
                            <label class="form-label">Cargo</label>
                            <select name="position_id" class="form-select" required>
                                <option value="">Seleccionar...</option>
                                <?php foreach ($positions as $position): ?>
                                    <option value="<?= $position["position_id"] ?>">
                                        <?= htmlspecialchars($position["position_name"]) ?> - <?= htmlspecialchars($position["department_name"]) ?>
                                    </option>
                                <?php endforeach; ?>
                            </select>
                        </div>

                        <div class="mb-3">
                            <label class="form-label">Reporta a</label>
                            <select name="reports_to_position_id" class="form-select">
                                <option value="">No reporta a otro cargo</option>
                                <?php foreach ($positions as $position): ?>
                                    <option value="<?= $position["position_id"] ?>">
                                        <?= htmlspecialchars($position["position_name"]) ?> - <?= htmlspecialchars($position["department_name"]) ?>
                                    </option>
                                <?php endforeach; ?>
                            </select>
                        </div>

                        <div class="mb-3">
                            <label class="form-label">Vigente desde</label>
                            <input type="date" name="effective_from" class="form-control" required>
                        </div>

                        <button class="btn btn-primary">Guardar reporte</button>
                    </form>
                </div>
            </div>
        </div>

    </div>

    <h2 class="mt-4">Organigrama</h2>

    <table class="table table-bordered table-striped bg-white">
        <thead>
            <tr>
                <th>Departamento</th>
                <th>Cargo</th>
                <th>Nivel</th>
                <th>Salario base</th>
                <th>Reporta a</th>
            </tr>
        </thead>
        <tbody>
            <?php foreach ($organigrama as $row): ?>
                <tr>
                    <td><?= htmlspecialchars($row["department_name"]) ?></td>
                    <td><?= htmlspecialchars($row["position_name"]) ?></td>
                    <td>
                        <?= htmlspecialchars($row["level_number"]) ?> -
                        <?= htmlspecialchars($row["level_name"]) ?>
                    </td>
                    <td>$<?= number_format((float)$row["base_salary"], 2, ",", ".") ?></td>
                    <td><?= htmlspecialchars($row["reports_to_position"] ?? "No definido") ?></td>
                </tr>
            <?php endforeach; ?>
        </tbody>
    </table>

</div>
</body>
</html>