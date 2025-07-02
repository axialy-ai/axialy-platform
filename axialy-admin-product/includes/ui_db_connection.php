<?php
/**
 *  Axialy Admin – UI-database connection
 *  --------------------------------------------------------------------------
 *  This helper builds a PDO connection to the Axialy_UI database that lives
 *  in the **selected environment** (production / beta / test / …).  
 *
 *  ► Primary mechanism – container/Ansible exports
 *        UI_DB_HOST, UI_DB_PORT, UI_DB_NAME, UI_DB_USER, UI_DB_PASSWORD
 *    (see infra/ansible roles)
 *
 *  ► Fallback for local-dev – read a legacy “.env.<env>” file that sits
 *    outside the repo, e.g. /home/…/private_axialy/.env.production
 *
 *  After this file is included, `$pdoUI` is available to callers.
 */

declare(strict_types=1);

// make sure we can access $_SESSION['admin_env']
if (session_status() === PHP_SESSION_NONE) {
    session_start();
}

/* --------------------------------------------------------------------------
 *  (1) Figure out WHICH environment was chosen in Axialy Admin.
 * ------------------------------------------------------------------------*/
$env   = $_SESSION['admin_env'] ?? 'production';
$env   = preg_replace('/[^A-Za-z0-9_\-]/', '', $env);   // simple hardening
$port  = getenv('UI_DB_PORT') ?: '3306';
$db    = getenv('UI_DB_NAME') ?: 'axialy_ui';

/* --------------------------------------------------------------------------
 *  (2) Either grab credentials from environment variables …
 * ------------------------------------------------------------------------*/
$host = getenv('UI_DB_HOST');
$user = getenv('UI_DB_USER');
$pass = getenv('UI_DB_PASSWORD');

if ($host && $user && $pass) {
    // good to go ✨
} else {
    /* ----------------------------------------------------------------------
     *  (3) … or fall back to a local `.env.<env>` file for developers who
     *       run the PHP code outside Docker.
     * --------------------------------------------------------------------*/
    $legacyFile = sprintf(
        '/home/i17z4s936h3j/private_axialy/.env.%s',
        $env
    );
    if (!is_readable($legacyFile)) {
        $legacyFile = '/home/i17z4s936h3j/private_axialy/.env.production';
    }

    if (is_readable($legacyFile)) {
        foreach (file($legacyFile, FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES) as $line) {
            $line = trim($line);
            if ($line === '' || $line[0] === '#') {
                continue;
            }
            if (!str_contains($line, '=')) {
                continue;
            }
            [$k, $v] = array_map('trim', explode('=', $line, 2));
            if ($k !== '' && getenv($k) === false) {
                putenv("$k=$v");
            }
        }

        // re-load after putenv()
        $host = getenv('DB_HOST');
        $port = getenv('DB_PORT') ?: $port;
        $db   = getenv('DB_NAME') ?: $db;
        $user = getenv('DB_USER');
        $pass = getenv('DB_PASSWORD');
    }
}

/* --------------------------------------------------------------------------
 *  (4) Sanity-check & connect
 * ------------------------------------------------------------------------*/
if (!$host || !$user || !$pass) {
    throw new RuntimeException(
        'UI DB credentials are missing. Make sure the Ansible-written .env '
        .'file is mounted or set UI_DB_* variables.'
    );
}

$dsn   = sprintf('mysql:host=%s;port=%s;dbname=%s;charset=utf8mb4', $host, $port, $db);
$pdoUI = new PDO(
    $dsn,
    $user,
    $pass,
    [
        PDO::ATTR_ERRMODE            => PDO::ERRMODE_EXCEPTION,
        PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
    ]
);
