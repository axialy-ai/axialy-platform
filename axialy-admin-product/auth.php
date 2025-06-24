<?php
// /home/i17z4s936h3j/public_html/admin.axiaba.com/auth.php
// At the top of admin_login.php (and/or auth.php)
session_name('axiaba_admin_session');
session_start();

// /home/i17z4s936h3j/public_html/admin.axiaba.com/auth.php
require_once __DIR__ . '/includes/db_connection.php';

/**
 * Ensures the admin is logged in (session vars set) and has sys_admin=1
 * or else redirects to admin_login.php
 */
function adminRequireAuth()
{
    if (session_status() === PHP_SESSION_NONE) {
        session_start();
    }
    
    // If session keys are missing, bounce to admin_login
    if (empty($_SESSION['admin_user_id']) || empty($_SESSION['admin_session_token'])) {
        header('Location: admin_login.php');
        exit;
    }

    $userId    = $_SESSION['admin_user_id'];
    $token     = $_SESSION['admin_session_token'];

    global $pdo; // from db_connection

    try {
        // 1) Check user is sys_admin
        $sqlUser = "SELECT sys_admin FROM ui_users WHERE id = :uid LIMIT 1";
        $stmtU = $pdo->prepare($sqlUser);
        $stmtU->execute([':uid' => $userId]);
        $userRow = $stmtU->fetch(PDO::FETCH_ASSOC);
        if (!$userRow || !$userRow['sys_admin']) {
            // Not sys_admin => log out forcibly
            adminLogoutAndRedirect();
        }

        // 2) Check session is valid in ui_user_sessions
        $sqlSess = "
            SELECT 1 
            FROM ui_user_sessions
            WHERE user_id = :uid
              AND session_token = :tok
              AND product = 'admin'
              AND expires_at > NOW()
            LIMIT 1
        ";
        $stmtS = $pdo->prepare($sqlSess);
        $stmtS->execute([
            ':uid' => $userId,
            ':tok' => $token
        ]);
        $row = $stmtS->fetch(PDO::FETCH_ASSOC);
        if (!$row) {
            // Session not found or expired
            adminLogoutAndRedirect();
        }

        // If we get here, everything is good
    } catch (Exception $e) {
        error_log("Admin auth error: ".$e->getMessage());
        // Force a logout
        adminLogoutAndRedirect();
    }
}

function adminLogoutAndRedirect()
{
    // If we want to do the same steps as the official logout, we can:
    if (session_status() === PHP_SESSION_NONE) {
        session_start();
    }
    if (!empty($_SESSION['admin_user_id']) && !empty($_SESSION['admin_session_token'])) {
        global $pdo;
        $stmt = $pdo->prepare("
            DELETE FROM ui_user_sessions
             WHERE user_id = :uid
               AND session_token = :tok
               AND product = 'admin'
        ");
        $stmt->execute([
            ':uid' => $_SESSION['admin_user_id'],
            ':tok' => $_SESSION['admin_session_token']
        ]);
    }
    // Clear session
    $_SESSION = [];
    session_destroy();

    header('Location: admin_login.php');
    exit;
}
