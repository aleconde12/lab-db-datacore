<?php
require_once "config.php";

echo "<h3>Conexión reutilizable funcionando</h3>";

$sql = "SELECT DB_NAME() AS database_actual, SYSDATETIME() AS fecha_servidor";
$stmt = sqlsrv_query($conn, $sql);

$row = sqlsrv_fetch_array($stmt, SQLSRV_FETCH_ASSOC);

echo "<pre>";
print_r($row);
echo "</pre>";

sqlsrv_close($conn);