<?php
// /home/i17z4s936h3j/public_html/admin.axiaba.com/includes/Config.php
namespace Axialy\AdminConfig;

require_once __DIR__ . '/environment_selector.php'; // sets $TARGET_ENV

class Config
{
    private static $instance = null;
    private $config = [];

    private function __construct()
    {
        // Use the global $TARGET_ENV set by environment_selector.php:
        global $TARGET_ENV;

        // Path to your .env.<environment> file
        $envFile = "/home/i17z4s936h3j/private_axiaba/.env.{$TARGET_ENV}";
        if (!file_exists($envFile)) {
            // Fall back to .env.production if somehow the file doesn't exist
            $envFile = "/home/i17z4s936h3j/private_axiaba/.env.production";
        }

        $this->loadEnvFile($envFile);

        // Build the config array from environment
        $this->config = [
            'db_host'     => getenv('DB_HOST'),
            'db_name'     => getenv('DB_NAME'),
            'db_user'     => getenv('DB_USER'),
            'db_password' => getenv('DB_PASSWORD'),

            // If your admin subdomain also needs to know base URLs:
            'api_base_url' => getenv('API_BASE_URL'),
            'app_base_url' => getenv('APP_BASE_URL'),

            'internal_api_key'     => getenv('INTERNAL_API_KEY'),
            'openai_api_key'       => getenv('OPENAI_API_KEY'),
            'stripe_api_key'       => getenv('STRIPE_API_KEY'),
            'stripe_publishable_key' => getenv('STRIPE_PUBLISHABLE_KEY'),
            'stripe_webhook_secret'=> getenv('STRIPE_WEBHOOK_SECRET'),

            // Etc. or any additional environment variables
        ];
    }

    /**
     * Loads and parses a .env.<environment> file line-by-line
     */
    private function loadEnvFile($filename)
    {
        $lines = file($filename, FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES);
        foreach ($lines as $line) {
            // Skip comments
            if (strpos(trim($line), '#') === 0) {
                continue;
            }
            if (strpos($line, '=') !== false) {
                list($name, $value) = explode('=', $line, 2);
                $name = trim($name);
                $value = trim($value);
                // If value is wrapped in quotes, unwrap it
                if (preg_match('/^([\'"])(.*)\1$/', $value, $matches)) {
                    $value = $matches[2];
                }
                putenv("$name=$value");
            }
        }
    }

    public static function getInstance()
    {
        if (self::$instance === null) {
            self::$instance = new self();
        }
        return self::$instance;
    }

    /**
     * Return any config key
     */
    public function get($key)
    {
        return $this->config[$key] ?? null;
    }
}
