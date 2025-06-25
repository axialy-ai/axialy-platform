<?php
/**
 * includes/bootstrap_env.php
 *
 * Single responsibility: if the deployment script dropped
 * /etc/axialy_admin_env on the server, read it once and push
 * every KEY=value into the PHP process environment.
 *
 *   • harmless on a dev laptop (file simply not found)
 *   • no hard-coding of secrets in the repo
 */

$envFile = '/etc/axialy_admin_env';
if (!file_exists($envFile) || !is_readable($envFile)) {
    return;                     // nothing to do – fall back later if needed
}

$lines = file($envFile, FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES);
foreach ($lines as $line) {
    // ignore comments
    if (preg_match('/^\s*#/', $line)) {
        continue;
    }
    if (!str_contains($line, '=')) {
        continue;
    }
    [$key, $val] = explode('=', $line, 2);
    $key = trim($key);
    $val = trim($val);
    putenv("$key=$val");
}
