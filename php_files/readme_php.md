## Puesta en marcha del WebServer PHP

Para ejecutar el frontend del sistema **DataCore HR Solutions** se utilizó un servidor web local sobre Windows mediante **Laragon**, con conexión a **SQL Server Express** usando el driver `sqlsrv` de PHP.

### 1. Instalar Laragon

Descargar e instalar Laragon en Windows.

Ruta esperada de instalación:

```text
C:\laragon
```

Una vez instalado, iniciar Laragon y verificar que Apache esté disponible desde el panel principal.

### 2. Ubicar el proyecto PHP

Dentro de la carpeta `www` de Laragon, crear la carpeta del proyecto:

```text
C:\laragon\www\datacore-hr
```

Copiar dentro de esa carpeta los archivos PHP del sistema:

```text
config.php
index.php
m1_empleados.php
m2_organizacion.php
m3_nomina.php
m4_asistencia.php
m5_desempeno_capacitacion.php
```

La estructura final queda así:

```text
C:\laragon\www\datacore-hr\
│
├── config.php
├── index.php
├── m1_empleados.php
├── m2_organizacion.php
├── m3_nomina.php
├── m4_asistencia.php
└── m5_desempeno_capacitacion.php
```

### 3. Instalar el driver ODBC de SQL Server

Para que PHP pueda conectarse a SQL Server, primero se instala el **Microsoft ODBC Driver for SQL Server** en Windows.

Luego de instalarlo, reiniciar Laragon para que el entorno tome correctamente los cambios.

### 4. Descargar los drivers PHP para SQL Server

Descargar los drivers de Microsoft para PHP:

```text
php_sqlsrv.dll
php_pdo_sqlsrv.dll
```

Es importante elegir los archivos compatibles con la versión de PHP usada por Laragon.

Ejemplo:

```text
php_sqlsrv_XX_ts_x64.dll
php_pdo_sqlsrv_XX_ts_x64.dll
```

Donde:

```text
XX     = versión de PHP
ts     = Thread Safe
x64    = arquitectura de 64 bits
```

Como Laragon usa Apache, normalmente corresponde usar la variante **Thread Safe**.

### 5. Copiar los DLL en la carpeta de extensiones de PHP

Los archivos `.dll` se copian en la carpeta `ext` de la versión de PHP que usa Laragon.

Ejemplo:

```text
C:\laragon\bin\php\php-8.x.x\ext
```

Dentro de esa carpeta deben quedar los archivos:

```text
php_sqlsrv.dll
php_pdo_sqlsrv.dll
```

O con el nombre completo descargado, por ejemplo:

```text
php_sqlsrv_82_ts_x64.dll
php_pdo_sqlsrv_82_ts_x64.dll
```

### 6. Habilitar las extensiones en php.ini

Abrir el archivo `php.ini` de la versión de PHP usada por Laragon.

Ejemplo:

```text
C:\laragon\bin\php\php-8.x.x\php.ini
```

Agregar al final del archivo las extensiones correspondientes:

```ini
extension=php_sqlsrv.dll
extension=php_pdo_sqlsrv.dll
```

Si los archivos mantienen el nombre completo, usar ese mismo nombre:

```ini
extension=php_sqlsrv_83_ts_x64.dll
extension=php_pdo_sqlsrv_83_ts_x64.dll
```

Guardar los cambios.

### 7. Reiniciar Laragon

Desde el panel de Laragon:

```text
Stop
Start
```

O directamente:

```text
Restart All
```

Esto reinicia Apache y recarga la configuración de PHP.

### 8. Validar PHP y conexión

Para validar la instalación se pueden usar archivos temporales de prueba:

```text
phpinfo.php
test_config.php
test_sqlserver.php
```

Una vez validado que PHP carga correctamente el driver `sqlsrv` y que la conexión a SQL Server funciona, estos archivos pueden eliminarse o moverse a una carpeta de backup.

### 9. Acceder al sistema

Desde el navegador, ingresar a:

```text
http://localhost/datacore-hr/
```

También se puede acceder directamente a cada módulo:

```text
http://localhost/datacore-hr/m1_empleados.php
http://localhost/datacore-hr/m2_organizacion.php
http://localhost/datacore-hr/m3_nomina.php
http://localhost/datacore-hr/m4_asistencia.php
http://localhost/datacore-hr/m5_desempeno_capacitacion.php
```

### 10. Verificar configuración de conexión

El archivo `config.php` contiene los datos de conexión a SQL Server.

Ejemplo conceptual:

```php
$serverName = "localhost\\SQLEXPRESS";
$connectionOptions = [
    "Database" => "DataCoreRRHH",
    "Uid" => "datacore_app",
    "PWD" => "********",
    "CharacterSet" => "UTF-8"
];
```

El usuario utilizado por la aplicación es `datacore_app`, que tiene permisos operativos sobre las tablas y vistas del schema `rrhh`.

### Resultado esperado

Con estos pasos, Laragon queda ejecutando Apache + PHP, y la aplicación PHP puede conectarse a SQL Server Express para operar los módulos del sistema:

```text
M1 - Empleados
M2 - Organización
M3 - Nómina y Compensación
M4 - Asistencia y Tiempo
M5 - Desempeño y Capacitación
```
