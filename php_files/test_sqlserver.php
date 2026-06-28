<?php

sqlsrv_configure("WarningsReturnAsErrors", 0);

$serverName = "localhost\\SQLEXPRESS";

$connectionOptions = [
    "Database" => "DataCoreRRHH",
    "Uid" => "datacore_app",
    "PWD" => "Datacore123!",
    "CharacterSet" => "UTF-8"
];

$conn = sqlsrv_connect($serverName, $connectionOptions);

if ($conn === false) {
    echo "<h3>Error conectando a SQL Server</h3>";
    echo "<pre>";
    print_r(sqlsrv_errors());
    echo "</pre>";
    exit;
}

echo "<h3>Conexión exitosa a SQL Server</h3>";

$sql = "SELECT DB_NAME() AS database_actual, SYSDATETIME() AS fecha_servidor";
$stmt = sqlsrv_query($conn, $sql);

$row = sqlsrv_fetch_array($stmt, SQLSRV_FETCH_ASSOC);

echo "<pre>";
print_r($row);
echo "</pre>";

sqlsrv_close($conn);