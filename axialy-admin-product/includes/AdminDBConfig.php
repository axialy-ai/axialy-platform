<?php
/*  Axialy ▸ shared DB helper
    Drop-in replacement — no other files need to change                */

namespace Axialy\AdminConfig;

final class AdminDBConfig
{
    private static ?self $instance = null;
    private \PDO        $pdo;

    /* ----------------------------------------------------------------- */
    /*  Public API                                                       */
    /* ----------------------------------------------------------------- */

    public static function getInstance(): self
    {
        return self::$instance ??= new self();
    }

    public function getPdo(): \PDO
    {
        return $this->pdo;
    }

    /* This method must be public since PHP 8.1, even if it does nothing */
    public function __wakeup(): void {}

    /* ----------------------------------------------------------------- */
    /*  Internals                                                        */
    /* ----------------------------------------------------------------- */

    private function __construct()
    {
        $cfg = $this->resolveConfig();   // ← the ✨ new part

        $dsn = sprintf(
            'mysql:host=%s;port=%d;dbname=%s;charset=utf8mb4',
            $cfg['host'],
            $cfg['port'] ?? 3306,
            $cfg['name']
        );

        $this->pdo = new \PDO(
            $dsn,
            $cfg['user'],
            $cfg['pass'],
            [
                \PDO::ATTR_ERRMODE            => \PDO::ERRMODE_EXCEPTION,
                \PDO::ATTR_DEFAULT_FETCH_MODE => \PDO::FETCH_ASSOC,
            ]
        );
    }

    /** Try ENV first, then .env file beside index.php. */
    private function resolveConfig(): array
    {
        $pull = static fn(string $k) => getenv($k) ?: null;

        $cfg = [
            'host' => $pull('DB_HOST'),
            'port' => $pull('DB_PORT') ?: 3306,
            'name' => $pull('DB_NAME'),
            'user' => $pull('DB_USER'),
            'pass' => $pull('DB_PASSWORD'),
        ];
        if ($this->isComplete($cfg)) {
            return $cfg;
        }

        /* Fallback: parse .env (KEY=VAL per line, # comments ignored) */
        $envFile = dirname(__DIR__, 1) . '/.env';
        if (is_readable($envFile)) {
            foreach (file($envFile, FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES) as $line) {
                if ($line[0] === '#' || !str_contains($line, '=')) {
                    continue;
                }
                [$k, $v] = explode('=', $line, 2);
                putenv(trim($k) . '=' . trim($v));
            }

            $cfg = [
                'host' => getenv('DB_HOST'),
                'port' => getenv('DB_PORT') ?: 3306,
                'name' => getenv('DB_NAME'),
                'user' => getenv('DB_USER'),
                'pass' => getenv('DB_PASSWORD'),
            ];
            if ($this->isComplete($cfg)) {
                return $cfg;
            }
        }

        throw new \RuntimeException(
            'AdminDBConfig: DB_* variables not found in the environment or .env file.'
        );
    }

    private function isComplete(array $c): bool
    {
        return $c['host'] && $c['name'] && $c['user'] && $c['pass'];
    }

    private function __clone() {}
}
