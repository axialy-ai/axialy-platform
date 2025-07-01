<?php
namespace Axialy\AdminConfig;

/**
 * AdminDBConfig - Singleton for connecting to the Axialy_ADMIN DB.
 * Reads credentials from /home/i17z4s936h3j/private_axialy/.env.admin.
 */
class AdminDBConfig
{
    private static $instance = null;
    private $pdo;

    private function __construct()
    {
        // Path to the .env.admin file
        $envFile = '/home/i17z4s936h3j/private_axialy/.env.admin';
        if (!file_exists($envFile)) {
            throw new \RuntimeException("Admin env file not found: $envFile");
        }

        // Parse .env.admin line by line
        $lines = file($envFile, FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES);
        foreach ($lines as $line) {
            if (strpos(trim($line), '#') === 0) {
                continue; // comment
            }
            if (strpos($line, '=') !== false) {
                list($key, $val) = explode('=', $line, 2);
                $key = trim($key);
                $val = trim($val);
                putenv("$key=$val");
            }
        }

        // Retrieve environment variables
        $host = getenv('DB_HOST');
        $db   = getenv('DB_NAME');
        $user = getenv('DB_USER');
        $pass = getenv('DB_PASSWORD');
        if (!$host || !$db || !$user || !$pass) {
            throw new \RuntimeException("Missing required Admin DB env vars.");
        }

        $dsn = "mysql:host=$host;dbname=$db;charset=utf8mb4";

        // Create PDO
        $this->pdo = new \PDO($dsn, $user, $pass, [
            \PDO::ATTR_ERRMODE => \PDO::ERRMODE_EXCEPTION,
        ]);
    }

    public static function getInstance()
    {
        if (!self::$instance) {
            self::$instance = new self();
        }
        return self::$instance;
    }

    public function getPdo()
    {
        return $this->pdo;
    }
}
