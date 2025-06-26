<?php
/**
 * Simple procedural PDO for scripts that only need a single connection.
 * Relies entirely on environment variables set by the GitHub deploy workflow.
 */
try {
    $host = getenv('DB_HOST');
    $port = getenv('DB_PORT');  // optional
    $db   = getenv('DB_NAME');
    $user = getenv('DB_USER');
    $pass = getenv('DB_PASSWORD');

    if (!$host || !$db || !$user || !$pass) {
        throw new RuntimeException('DB credentials not present in environment.');
    }
    if ($port) $host .= ':' . $port;

    $dsn = "mysql:host=$host;dbname=$db;charset=utf8mb4";
    $pdo = new PDO($dsn, $user, $pass, [
        PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
    ]);
} catch (Throwable $e) {
    error_log('Admin DB connection failed: ' . $e->getMessage());
    die('Database error (Admin).');
}
