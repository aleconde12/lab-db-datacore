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
        if ($action === "create_employee") {
            $sql = "
                INSERT INTO rrhh.employees (
                    employee_code,
                    first_name,
                    last_name,
                    dni_cuil,
                    hire_date,
                    position_id,
                    is_active
                )
                VALUES (?, ?, ?, ?, ?, ?, 1)
            ";

            $params = [
                trim($_POST["employee_code"]),
                trim($_POST["first_name"]),
                trim($_POST["last_name"]),
                trim($_POST["dni_cuil"]),
                $_POST["hire_date"],
                $_POST["position_id"]
            ];

            $stmt = sqlsrv_query($conn, $sql, $params);

            if ($stmt === false) {
                throw new Exception(print_r(sqlsrv_errors(), true));
            }

            $message = "Empleado creado correctamente.";
        }

        if ($action === "create_personal_info") {
            $sql = "
                INSERT INTO rrhh.personal_info (
                    employee_id,
                    birth_date,
                    address,
                    phone,
                    personal_email,
                    marital_status,
                    nationality
                )
                VALUES (?, ?, ?, ?, ?, ?, ?)
            ";

            $params = [
                $_POST["employee_id"],
                $_POST["birth_date"] === "" ? null : $_POST["birth_date"],
                trim($_POST["address"]),
                trim($_POST["phone"]),
                trim($_POST["personal_email"]),
                trim($_POST["marital_status"]),
                trim($_POST["nationality"])
            ];

            $stmt = sqlsrv_query($conn, $sql, $params);

            if ($stmt === false) {
                throw new Exception(print_r(sqlsrv_errors(), true));
            }

            $message = "Datos personales cargados correctamente.";
        }

        if ($action === "create_document") {
            $sql = "
                INSERT INTO rrhh.documents (
                    employee_id,
                    document_type,
                    document_number,
                    issue_date,
                    expiration_date,
                    document_status,
                    observations
                )
                VALUES (?, ?, ?, ?, ?, ?, ?)
            ";

            $params = [
                $_POST["employee_id"],
                trim($_POST["document_type"]),
                trim($_POST["document_number"]),
                $_POST["issue_date"] === "" ? null : $_POST["issue_date"],
                $_POST["expiration_date"] === "" ? null : $_POST["expiration_date"],
                $_POST["document_status"],
                trim($_POST["observations"])
            ];

            $stmt = sqlsrv_query($conn, $sql, $params);

            if ($stmt === false) {
                throw new Exception(print_r(sqlsrv_errors(), true));
            }

            $message = "Documento cargado correctamente.";
        }

    } catch (Exception $e) {
        $error = $e->getMessage();
    }
}

$positions = fetch_all($conn, "
    SELECT 
        p.position_id,
        p.position_name,
        d.department_name
    FROM rrhh.positions p
    INNER JOIN rrhh.departments d
        ON p.department_id = d.department_id
    WHERE p.is_active = 1
    ORDER BY d.department_name, p.position_name
");

$employees = fetch_all($conn, "
    SELECT
        e.employee_id,
        e.employee_code,
        e.first_name,
        e.last_name,
        e.dni_cuil,
        e.hire_date,
        e.is_active,
        p.position_name,
        d.department_name
    FROM rrhh.employees e
    INNER JOIN rrhh.positions p
        ON e.position_id = p.position_id
    INNER JOIN rrhh.departments d
        ON p.department_id = d.department_id
    ORDER BY e.last_name, e.first_name
");

$activeEmployees = fetch_all($conn, "
    SELECT
        employee_id,
        employee_code,
        first_name,
        last_name,
        dni_cuil,
        hire_date,
        position_name,
        department_name
    FROM rrhh.vw_empleados_activos
    ORDER BY last_name, first_name
");

$documents = fetch_all($conn, "
    SELECT
        doc.document_id,
        e.employee_code,
        e.first_name,
        e.last_name,
        doc.document_type,
        doc.document_number,
        doc.issue_date,
        doc.expiration_date,
        doc.document_status,
        doc.observations
    FROM rrhh.documents doc
    INNER JOIN rrhh.employees e
        ON doc.employee_id = e.employee_id
    ORDER BY e.last_name, e.first_name, doc.document_type
");
?>

<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <title>M1 - Empleados</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet">
</head>

<body class="bg-light">
<div class="container py-4">

    <h1 class="mb-4">M1 - Empleados</h1>

    <div class="mb-3">
        <a href="m2_organizacion.php" class="btn btn-outline-secondary btn-sm">
            Ir a M2 - Organización
        </a>
        <a href="m3_nomina.php" class="btn btn-outline-secondary btn-sm">
            Ir a M3 - Nómina
        </a>
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
                <div class="card-header">Alta de empleado</div>
                <div class="card-body">
                    <form method="POST">
                        <input type="hidden" name="action" value="create_employee">

                        <div class="mb-3">
                            <label class="form-label">Legajo</label>
                            <input type="text" name="employee_code" class="form-control" placeholder="EMP005" required>
                        </div>

                        <div class="mb-3">
                            <label class="form-label">Nombre</label>
                            <input type="text" name="first_name" class="form-control" required>
                        </div>

                        <div class="mb-3">
                            <label class="form-label">Apellido</label>
                            <input type="text" name="last_name" class="form-control" required>
                        </div>

                        <div class="mb-3">
                            <label class="form-label">DNI/CUIL</label>
                            <input type="text" name="dni_cuil" class="form-control" placeholder="20-30111222-3" required>
                        </div>

                        <div class="mb-3">
                            <label class="form-label">Fecha de ingreso</label>
                            <input type="date" name="hire_date" class="form-control" required>
                        </div>

                        <div class="mb-3">
                            <label class="form-label">Cargo</label>
                            <select name="position_id" class="form-select" required>
                                <option value="">Seleccionar...</option>
                                <?php foreach ($positions as $position): ?>
                                    <option value="<?= $position["position_id"] ?>">
                                        <?= htmlspecialchars($position["position_name"]) ?> -
                                        <?= htmlspecialchars($position["department_name"]) ?>
                                    </option>
                                <?php endforeach; ?>
                            </select>
                        </div>

                        <button class="btn btn-primary">Crear empleado</button>
                    </form>
                </div>
            </div>
        </div>

        <div class="col-md-6 mb-4">
            <div class="card">
                <div class="card-header">Carga de datos personales</div>
                <div class="card-body">
                    <form method="POST">
                        <input type="hidden" name="action" value="create_personal_info">

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
                            <label class="form-label">Fecha de nacimiento</label>
                            <input type="date" name="birth_date" class="form-control">
                        </div>

                        <div class="mb-3">
                            <label class="form-label">Dirección</label>
                            <input type="text" name="address" class="form-control">
                        </div>

                        <div class="mb-3">
                            <label class="form-label">Teléfono</label>
                            <input type="text" name="phone" class="form-control">
                        </div>

                        <div class="mb-3">
                            <label class="form-label">Email personal</label>
                            <input type="email" name="personal_email" class="form-control">
                        </div>

                        <div class="mb-3">
                            <label class="form-label">Estado civil</label>
                            <input type="text" name="marital_status" class="form-control">
                        </div>

                        <div class="mb-3">
                            <label class="form-label">Nacionalidad</label>
                            <input type="text" name="nationality" class="form-control" value="Argentina">
                        </div>

                        <button class="btn btn-primary">Guardar datos personales</button>
                    </form>
                </div>
            </div>
        </div>

    </div>

    <div class="row">

        <div class="col-md-6 mb-4">
            <div class="card">
                <div class="card-header">Carga de documentación</div>
                <div class="card-body">
                    <form method="POST">
                        <input type="hidden" name="action" value="create_document">

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
                            <label class="form-label">Tipo de documento</label>
                            <input type="text" name="document_type" class="form-control" placeholder="DNI / Contrato / Certificado médico" required>
                        </div>

                        <div class="mb-3">
                            <label class="form-label">Número o referencia</label>
                            <input type="text" name="document_number" class="form-control">
                        </div>

                        <div class="mb-3">
                            <label class="form-label">Fecha de emisión</label>
                            <input type="date" name="issue_date" class="form-control">
                        </div>

                        <div class="mb-3">
                            <label class="form-label">Fecha de vencimiento</label>
                            <input type="date" name="expiration_date" class="form-control">
                        </div>

                        <div class="mb-3">
                            <label class="form-label">Estado</label>
                            <select name="document_status" class="form-select" required>
                                <option value="PRESENTADO">Presentado</option>
                                <option value="PENDIENTE">Pendiente</option>
                                <option value="VENCIDO">Vencido</option>
                            </select>
                        </div>

                        <div class="mb-3">
                            <label class="form-label">Observaciones</label>
                            <input type="text" name="observations" class="form-control">
                        </div>

                        <button class="btn btn-primary">Guardar documento</button>
                    </form>
                </div>
            </div>
        </div>

    </div>

    <h2 class="mt-4">Empleados activos</h2>

    <table class="table table-bordered table-striped bg-white">
        <thead>
            <tr>
                <th>Legajo</th>
                <th>Nombre</th>
                <th>Apellido</th>
                <th>DNI/CUIL</th>
                <th>Ingreso</th>
                <th>Cargo</th>
                <th>Departamento</th>
            </tr>
        </thead>
        <tbody>
            <?php foreach ($activeEmployees as $employee): ?>
                <tr>
                    <td><?= htmlspecialchars($employee["employee_code"]) ?></td>
                    <td><?= htmlspecialchars($employee["first_name"]) ?></td>
                    <td><?= htmlspecialchars($employee["last_name"]) ?></td>
                    <td><?= htmlspecialchars($employee["dni_cuil"]) ?></td>
                    <td>
                        <?= $employee["hire_date"] instanceof DateTime
                            ? $employee["hire_date"]->format("Y-m-d")
                            : htmlspecialchars((string)$employee["hire_date"])
                        ?>
                    </td>
                    <td><?= htmlspecialchars($employee["position_name"]) ?></td>
                    <td><?= htmlspecialchars($employee["department_name"]) ?></td>
                </tr>
            <?php endforeach; ?>
        </tbody>
    </table>

    <h2 class="mt-4">Documentación cargada</h2>

    <table class="table table-bordered table-striped bg-white">
        <thead>
            <tr>
                <th>Legajo</th>
                <th>Empleado</th>
                <th>Tipo</th>
                <th>Número</th>
                <th>Emisión</th>
                <th>Vencimiento</th>
                <th>Estado</th>
                <th>Observaciones</th>
            </tr>
        </thead>
        <tbody>
            <?php foreach ($documents as $document): ?>
                <tr>
                    <td><?= htmlspecialchars($document["employee_code"]) ?></td>
                    <td>
                        <?= htmlspecialchars($document["last_name"]) ?>,
                        <?= htmlspecialchars($document["first_name"]) ?>
                    </td>
                    <td><?= htmlspecialchars($document["document_type"]) ?></td>
                    <td><?= htmlspecialchars($document["document_number"] ?? "") ?></td>
                    <td>
                        <?= $document["issue_date"] instanceof DateTime
                            ? $document["issue_date"]->format("Y-m-d")
                            : htmlspecialchars((string)$document["issue_date"])
                        ?>
                    </td>
                    <td>
                        <?= $document["expiration_date"] instanceof DateTime
                            ? $document["expiration_date"]->format("Y-m-d")
                            : htmlspecialchars((string)$document["expiration_date"])
                        ?>
                    </td>
                    <td><?= htmlspecialchars($document["document_status"]) ?></td>
                    <td><?= htmlspecialchars($document["observations"] ?? "") ?></td>
                </tr>
            <?php endforeach; ?>
        </tbody>
    </table>

</div>
</body>
</html>