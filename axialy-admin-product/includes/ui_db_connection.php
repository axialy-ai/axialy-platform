<?php
// /home/i17z4s936h3j/public_html/admin.axialy.com/includes/ui_db_connection.php
/**
 * This file connects to the "UI environment" DB, so doc management can
 * read/write the 'documents' table, etc. The environment is chosen from
 * $_SESSION['admin_env'] (production, beta, test, etc.).
 */

// Make sure the session is started, so $_SESSION is accessible.
if (session_status() === PHP_SESSION_NONE) {
    session_start();
}

// 1) Determine the environment from session
$chosenEnv = $_SESSION['admin_env'] ?? 'production';

// 2) Load the .env.<environment> file from private_axialy
$envFile = "/home/i17z4s936h3j/private_axialy/.env.{$chosenEnv}";
if (!file_exists($envFile)) {
    // fallback or throw error
    $envFile = "/home/i17z4s936h3j/private_axialy/.env.production";
}

// 3) Parse the file into environment variables
$lines = file($envFile, FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES);
foreach ($lines as $line) {
    if (strpos(trim($line), '#') === 0) {
        continue;
    }
    if (strpos($line, '=') !== false) {
        list($name, $value) = explode('=', $line, 2);
        $name  = trim($name);
        $value = trim($value);
        // If quoted
        if (preg_match('/^([\'"])(.*)\1$/', $value, $m)) {
            $value = $m[2];
        }
        putenv("$name=$value");
    }
}

// 4) Read needed vars: DB_HOST, DB_NAME, DB_USER, DB_PASSWORD
$uiDbHost = getenv('DB_HOST');
$uiDbName = getenv('DB_NAME');
$uiDbUser = getenv('DB_USER');
$uiDbPass = getenv('DB_PASSWORD');

if (!$uiDbHost || !$uiDbName || !$uiDbUser || !$uiDbPass) {
    throw new RuntimeException("Missing environment DB credentials in $envFile");
}

// 5) Create a PDO connection to that environment's UI DB
$dsn = "mysql:host=$uiDbHost;dbname=$uiDbName;charset=utf8mb4";

try {
    $pdoUI = new PDO($dsn, $uiDbUser, $uiDbPass, [
        PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION
    ]);
} catch (PDOException $e) {
    throw new RuntimeException("Error connecting to UI environment DB: " . $e->getMessage());
}
