<?php
/* axialy-admin-product/includes/ui_db_connection.php
   Connects the Admin panel to the chosen UI-environment database.
   Looks for .env files in /mnt/private_axiaba (override with PRIVATE_AXIABA_PATH). */

if (session_status() === PHP_SESSION_NONE) {
    session_start();
}

/* ------------------------------------------------------------------
 * 1) Which environment?  – fall back to 'production'
 * ------------------------------------------------------------------ */
$chosenEnv = $_SESSION['admin_env'] ?? 'production';

/* ------------------------------------------------------------------
 * 2) Locate & parse the .env.<env> file
 * ------------------------------------------------------------------ */
$basePath = getenv('PRIVATE_AXIABA_PATH') ?: '/mnt/private_axiaba';
$envFile  = "{$basePath}/.env.{$chosenEnv}";
if (!is_readable($envFile)) {
    $envFile = "{$basePath}/.env.production";        // graceful fallback
}

foreach (file($envFile, FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES) as $line) {
    $line = trim($line);
    if ($line === '' || $line[0] === '#') { continue; }

    if (!str_contains($line, '=')) { continue; }
    [$k, $v] = array_pad(explode('=', $line, 2), 2, '');
    $k = trim($k);
    $v = trim($v);
    if (preg_match('/^([\'"])(.*)\1$/', $v, $m)) { $v = $m[2]; }
    putenv("{$k}={$v}");
}

/* ------------------------------------------------------------------
 * 3) Build PDO connection
 * ------------------------------------------------------------------ */
$uiDbHost = getenv('DB_HOST');
$uiDbPort = getenv('DB_PORT') ?: 3306;
$uiDbName = getenv('DB_NAME');
$uiDbUser = getenv('DB_USER');
$uiDbPass = getenv('DB_PASSWORD');

if (!$uiDbHost || !$uiDbName || !$uiDbUser || !$uiDbPass) {
    throw new RuntimeException("ui_db_connection: missing DB_* vars in {$envFile}");
}

$dsn = "mysql:host={$uiDbHost};port={$uiDbPort};dbname={$uiDbName};charset=utf8mb4";

try {
    $pdoUI = new PDO($dsn, $uiDbUser, $uiDbPass, [
        PDO::ATTR_ERRMODE            => PDO::ERRMODE_EXCEPTION,
        PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
    ]);
} catch (PDOException $e) {
    throw new RuntimeException("ui_db_connection: PDO error – " . $e->getMessage());
}
