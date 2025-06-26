<?php
namespace AxiaBA\AdminConfig;

/**
 * Singleton wrapper for Admin DB.
 *   1️⃣  looks for DB_* environment variables injected by deploy workflow
 *   2️⃣  falls back to legacy /private_axiaba/.env.admin for dev boxes
 */
class AdminDBConfig
{
    private static ?self $instance = null;
    private \PDO $pdo;

    private function __construct()
    {
        // ── 1️⃣  modern env-vars path ───────────────────────────────────────
        $host = getenv('DB_HOST');   // host or host:port
        $port = getenv('DB_PORT');   // optional
        $db   = getenv('DB_NAME');
        $user = getenv('DB_USER');
        $pass = getenv('DB_PASSWORD');

        if ($host && $db && $user && $pass) {
            if ($port) $host .= ':' . $port;
            $this->connect($host, $db, $user, $pass);
            return;
        }

        // ── 2️⃣  legacy fallback ────────────────────────────────────────────
        $envFile = '/home/i17z4s936h3j/private_axiaba/.env.admin';
        if (!file_exists($envFile)) {
            throw new \RuntimeException(
                'Missing DB credentials – neither environment variables nor '
              . "$envFile present."
            );
        }

        foreach (file($envFile, FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES) as $ln) {
            if ($ln === '' || $ln[0] === '#') continue;
            if (!str_contains($ln, '='))        continue;
            [$k, $v] = array_map('trim', explode('=', $ln, 2));
            putenv("$k=$v");
        }

        $host = getenv('DB_HOST');
        $port = getenv('DB_PORT');
        $db   = getenv('DB_NAME');
        $user = getenv('DB_USER');
        $pass = getenv('DB_PASSWORD');
        if ($port) $host .= ':' . $port;

        $this->connect($host, $db, $user, $pass);
    }

    private function connect(string $host, string $db, string $user, string $pass): void
    {
        $dsn      = "mysql:host=$host;dbname=$db;charset=utf8mb4";
        $this->pdo = new \PDO($dsn, $user, $pass, [
            \PDO::ATTR_ERRMODE => \PDO::ERRMODE_EXCEPTION,
        ]);
    }

    public static function getInstance(): self
    {
        return self::$instance ??= new self();
    }

    public function getPdo(): \PDO
    {
        return $this->pdo;
    }
}
