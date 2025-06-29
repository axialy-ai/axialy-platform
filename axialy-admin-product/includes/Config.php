<?php
// axialy-admin-product/includes/Config.php
// Central environment loader for the Admin panel – DigitalOcean-ready.

namespace Axialy\AdminConfig;

require_once __DIR__ . '/environment_selector.php';   // sets $TARGET_ENV

final class Config
{
    private static ?self $instance = null;
    private array        $config   = [];

    /* ------------------------------------------------------------ */
    /*  Public helpers                                              */
    /* ------------------------------------------------------------ */

    public static function getInstance(): self
    {
        return self::$instance ??= new self();
    }

    public function get(string $key): ?string
    {
        return $this->config[$key] ?? null;
    }

    /* ------------------------------------------------------------ */
    /*  Internals                                                   */
    /* ------------------------------------------------------------ */

    private function __construct()
    {
        /** Which env file?  */
        global $TARGET_ENV;                 // set by environment_selector.php
        $basePath = getenv('PRIVATE_AXIABA_PATH') ?: '/mnt/private_axiaba';
        $envFile  = "{$basePath}/.env.{$TARGET_ENV}";
        if (!is_readable($envFile)) {
            $envFile = "{$basePath}/.env.production"; // graceful fallback
        }

        $this->loadEnvFile($envFile);

        // mirror frequently-used keys for quicker access
        $this->config = [
            'db_host'     => getenv('DB_HOST'),
            'db_name'     => getenv('DB_NAME'),
            'db_user'     => getenv('DB_USER'),
            'db_password' => getenv('DB_PASSWORD'),

            'api_base_url'            => getenv('API_BASE_URL'),
            'app_base_url'            => getenv('APP_BASE_URL'),
            'internal_api_key'        => getenv('INTERNAL_API_KEY'),
            'openai_api_key'          => getenv('OPENAI_API_KEY'),
            'stripe_api_key'          => getenv('STRIPE_API_KEY'),
            'stripe_publishable_key'  => getenv('STRIPE_PUBLISHABLE_KEY'),
            'stripe_webhook_secret'   => getenv('STRIPE_WEBHOOK_SECRET'),
        ];
    }

    /** Simple KEY=VAL parser (ignores blank lines & #comments). */
    private function loadEnvFile(string $file): void
    {
        if (!is_readable($file)) {
            throw new \RuntimeException("Config: .env file not found at {$file}");
        }

        foreach (file($file, FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES) as $line) {
            $line = trim($line);
            if ($line === '' || $line[0] === '#') { continue; }

            [$k, $v] = array_pad(explode('=', $line, 2), 2, '');
            $k = trim($k);
            $v = trim($v);

            if (preg_match('/^([\'"])(.*)\1$/', $v, $m)) { $v = $m[2]; } // un-quote
            putenv("{$k}={$v}");
        }
    }

    /* keep PHP-8.1 happy */
    public function __wakeup(): void {}
    private function __clone() {}
}
