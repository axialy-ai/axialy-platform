<?php
namespace AxiaBA\AdminConfig;

require_once __DIR__ . '/bootstrap_env.php';  // NEW – load vars from /etc/axialy_admin_env

/**
 * Singleton wrapper around the Axialy-Admin database connection.
 *
 * Priority order for config values
 * 1. Real environment variables provided by the droplet
 * 2. Legacy `.env.admin` file (useful on a developer workstation)
 */
class AdminDBConfig
{
    private static ?self $instance = null;
    private \PDO $pdo;

    private function __construct()
    {
        // ---------- 1) try real env-vars (preferred on DigitalOcean) ----------
        $host = getenv('DB_HOST');
        $db   = getenv('DB_NAME');
        $user = getenv('DB_USER');
        $pass = getenv('DB_PASSWORD');

        // ---------- 2) fall back to the legacy .env.admin if any are missing ----------
        if (!$host || !$db || !$user || !$pass) {
            // same location you had on GoDaddy; change if you moved it locally
            $legacyFile = dirname(__DIR__, 2) . '/private_axiaba/.env.admin';

            if (!file_exists($legacyFile)) {
                throw new \RuntimeException(
                    "Missing DB credentials – neither \$ENV nor {$legacyFile} supplied."
                );
            }

            foreach (file($legacyFile, FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES) as $line) {
                if (preg_match('/^\s*#/', $line) || !str_contains($line, '=')) {
                    continue;
                }
                [$k, $v] = explode('=', $line, 2);
                $k = trim($k);
                $v = trim($v);
                if (!getenv($k)) {          // don’t overwrite real env-vars
                    putenv("$k=$v");
                }
            }

            // re-pull after populating
            $host = getenv('DB_HOST');
            $db   = getenv('DB_NAME');
            $user = getenv('DB_USER');
            $pass = getenv('DB_PASSWORD');
        }

        // ---------- 3) final sanity check ----------
        if (!$host || !$db || !$user || !$pass) {
            throw new \RuntimeException('Still missing one or more DB_* variables after all attempts.');
        }

        // ---------- 4) make the connection ----------
        $dsn       = "mysql:host={$host};dbname={$db};charset=utf8mb4";
        $this->pdo = new \PDO($dsn, $user, $pass, [
            \PDO::ATTR_ERRMODE => \PDO::ERRMODE_EXCEPTION,
        ]);
    }

    /** @noinspection PhpHierarchyChecksInspection */
    public static function getInstance(): self
    {
        return self::$instance ??= new self();
    }

    public function getPdo(): \PDO
    {
        return $this->pdo;
    }

    // prevent cloning / unserialising
    private function __clone()             {}
    public function __wakeup(): void       {}
}
