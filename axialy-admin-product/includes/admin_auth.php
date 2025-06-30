<?php
// /var/www/html/includes/admin_auth.php
require_once __DIR__ . '/AdminDBConfig.php';
use Axialy\AdminConfig\AdminDBConfig;

/**
 * Ensures the admin session is valid in Axialy_Admin.admin_user_sessions,
 * or else redirects to /admin_login.php.
 */
function requireAdminAuth(): void
{
    if (session_status() === PHP_SESSION_NONE) {
        session_start();
    }

    if (empty($_SESSION['admin_user_id']) || empty($_SESSION['admin_session_token'])) {
        logoutAndRedirect();
    }

    $adminDB = AdminDBConfig::getInstance()->getPdo();
    $stmt = $adminDB->prepare("
        SELECT s.id, s.expires_at,
               u.username, u.is_active, u.is_sys_admin
          FROM admin_user_sessions s
          JOIN admin_users       u ON u.id = s.admin_user_id
         WHERE s.admin_user_id = :uid
           AND s.session_token  = :tok
           AND s.expires_at    > NOW()
         LIMIT 1
    ");
    $stmt->execute([
        ':uid' => $_SESSION['admin_user_id'],
        ':tok' => $_SESSION['admin_session_token']
    ]);
    $row = $stmt->fetch(PDO::FETCH_ASSOC);

    if (!$row || (int)$row['is_active'] !== 1) {
        logoutAndRedirect();
    }
}

/**
 * Lightweight probe – lets login.php quickly check if the user
 * is already authenticated without throwing if tables are absent.
 */
function adminIsLoggedIn(\PDO $pdo): bool
{
    if (empty($_SESSION['admin_user_id']) || empty($_SESSION['admin_session_token'])) {
        return false;
    }

    try {
        $q = $pdo->prepare("
            SELECT 1
              FROM admin_user_sessions
             WHERE admin_user_id = :uid
               AND session_token  = :tok
               AND expires_at    > NOW()
             LIMIT 1
        ");
        $q->execute([
            ':uid' => $_SESSION['admin_user_id'],
            ':tok' => $_SESSION['admin_session_token']
        ]);
        return (bool) $q->fetchColumn();
    } catch (\Throwable $e) {
        // Table may not exist on first launch – treat as not logged in.
        return false;
    }
}

/**
 * Clears the admin session (both DB & PHP) and redirects to login.
 */
function logoutAndRedirect(string $msg = ''): never
{
    $adminDB = AdminDBConfig::getInstance()->getPdo();

    if (!empty($_SESSION['admin_user_id']) && !empty($_SESSION['admin_session_token'])) {
        $del = $adminDB->prepare("
            DELETE FROM admin_user_sessions
             WHERE admin_user_id = :uid
               AND session_token  = :tok
        ");
        $del->execute([
            ':uid' => $_SESSION['admin_user_id'],
            ':tok' => $_SESSION['admin_session_token']
        ]);
    }

    $_SESSION = [];
    session_destroy();

    header('Location: /admin_login.php');
    exit;
}
