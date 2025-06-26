<?php
// /home/i17z4s936h3j/admin.axiaba.com/logout_admin.php
require_once __DIR__ . '/includes/db_connection.php';
session_start();

// If we do have an admin session in place, remove it from ui_user_sessions
if (isset($_SESSION['admin_user_id'], $_SESSION['admin_session_token'])) {
    $uid = (int)$_SESSION['admin_user_id'];
    $tok = $_SESSION['admin_session_token'];

    try {
        $stmt = $pdo->prepare("
            DELETE FROM ui_user_sessions
            WHERE user_id = :uid
              AND session_token = :tok
              AND product = 'admin'
        ");
        $stmt->execute([
            ':uid' => $uid,
            ':tok' => $tok
        ]);
    } catch (\Exception $ex) {
        error_log("Admin logout error: " . $ex->getMessage());
        // We still proceed to clear local session
    }
}

// Clear local session
session_unset();
session_destroy();

// Redirect to login
header('Location: /login_admin.php?logged_out=1');
exit;
