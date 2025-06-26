<?php
/**
 *  Axialy ▸ AdminDBConfig
 *  ---------------------------------------------------------------
 *  PDO singleton for the Axialy_ADMIN schema.
 *  Primary source of truth is the environment variables injected by
 *  GitHub Actions → PHP-FPM (`DB_HOST DB_PORT DB_NAME DB_USER DB_PASSWORD`).
 *  A legacy fallback still parses a local .env.admin if the variables
 *  are missing, so you can run the code on a laptop without Docker.
 */

namespace Axialy\AdminConfig;

final class AdminDBConfig
{
    private static ?self $instance = null;
    private \PDO $pdo;

    /** @throws \RuntimeException */
    private function __construct()
    {
        /* ---------- 1) read env vars injected by IaC ---------------------- */
        $host = getenv('DB_HOST');
        $port = getenv('DB_PORT') ?: '3306';
        $db   = getenv('DB_NAME');
        $user = getenv('DB_USER');
        $pass = getenv('DB_PASSWORD');

        /* ---------- 2) dev-only fallback to .env.admin -------------------- */
        if (!$host || !$db || !$user || !$pass) {
            $legacyFile = __DIR__ . '/../../private_axiaba/.env.admin';
            if (is_file($legacyFile)) {
                self::loadDotEnv($legacyFile);
                $host = $host ?: getenv('DB_HOST');
                $port = $port ?: getenv('DB_PORT') ?: '3306';
                $db   = $db   ?: getenv('DB_NAME');
                $user = $user ?: getenv('DB_USER');
                $pass = $pass ?: getenv('DB_PASSWORD');
            }
        }

        if (!$host || !$db || !$user || !$pass) {
            throw new \RuntimeException(
                'AdminDBConfig: missing DB_* environment variables after all fallbacks.'
            );
        }

        /* ---------- 3) open PDO connection -------------------------------- */
        $dsn      = "mysql:host={$host};port={$port};dbname={$db};charset=utf8mb4";
        $this->pdo = new \PDO($dsn, $user, $pass, [
            \PDO::ATTR_ERRMODE            => \PDO::ERRMODE_EXCEPTION,
            \PDO::ATTR_DEFAULT_FETCH_MODE => \PDO::FETCH_ASSOC,
        ]);
    }

    /* --------------------------------------------------------------------- */
    private static function loadDotEnv(string $file): void
    {
        foreach (file($file, FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES) as $line) {
            if ($line[0] === '#' || !str_contains($line, '=')) {
                continue;
            }
            [$k, $v] = array_map('trim', explode('=', $line, 2));
            $v = preg_replace('/^([\'"])(.*)\1$/', '$2', $v); // strip quotes
            putenv("$k=$v");
        }
    }

    /* --------------------------------------------------------------------- */
    public static function getInstance(): self
    {
        return self::$instance ??= new self();
    }

    public function getPdo(): \PDO
    {
        return $this->pdo;
    }

    private function __clone() {}
    private function __wakeup() {}
}
