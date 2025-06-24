<?php
// /home/i17z4s936h3j/public_html/admin.axiaba.com/auth_check.php

// Example: Put this at the top of admin.axiaba.com/login.php

// Use a custom session name that won't collide with the UI site's session name
session_name('AXIABA_ADMIN_SESSION'); 

// Optionally configure any cookie params if needed (domain, secure, etc.)
// session_set_cookie_params([
//     'path'     => '/',
//     'domain'   => 'admin.axiaba.com',
//     'secure'   => true,     // if you have HTTPS
//     'httponly' => true,
//     'samesite' => 'None',   // or 'Lax', depends on your needs
// ]);

session_start(); // Start session after setting the name

require_once __DIR__ . '/includes/db_connection.php';

function adminAuthCheck(PDO $pdo) {
    if (!isset($_SESSION['admin_user_id']) || !isset($_SESSION['admin_session_token'])) {
        return false;
    }
    try {
        $stmt = $pdo->prepare("
            SELECT u.id, u.username, u.sys_admin, s.expires_at
            FROM ui_users u
            JOIN ui_user_sessions s ON s.user_id = u.id
            WHERE u.id = :uid
              AND s.session_token = :tok
              AND s.expires_at > NOW()
              AND u.sys_admin = 1
            LIMIT 1
        ");
        $stmt->execute([
            ':uid' => $_SESSION['admin_user_id'],
            ':tok' => $_SESSION['admin_session_token']
        ]);
        $row = $stmt->fetch(PDO::FETCH_ASSOC);
        if ($row) {
            // Confirm system_admin == 1
            if ((int)$row['sys_admin'] === 1) {
                return true;
            }
        }
    } catch (Exception $e) {
        error_log("Admin auth check error: " . $e->getMessage());
    }
    return false;
}

// Execute check
if (!adminAuthCheck($pdo)) {
    // If not authorized, kill session & redirect to login
    session_unset();
    session_destroy();
    header('Location: login.php');
    exit;
}
