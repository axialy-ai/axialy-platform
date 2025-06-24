<?php
// /home/i17z4s936h3j/admin.axiaba.com/includes/auth_admin.php
/**
 * Basic "admin" authentication check for AxiaBA Admin product.
 * - Reads session user_id, session_token
 * - Verifies there's a row in ui_user_sessions with product='admin' and expires_at > NOW()
 * - Checks that the user’s sys_admin=1.
 */

require_once __DIR__ . '/db_connection.php'; // ensures $pdo
session_start();

function adminRequireAuth()
{
    // If not set, redirect to admin login
    if (!isset($_SESSION['admin_user_id']) || !isset($_SESSION['admin_session_token'])) {
        header('Location: /login_admin.php');
        exit;
    }

    global $pdo;
    $userId = (int)$_SESSION['admin_user_id'];
    $token  = $_SESSION['admin_session_token'];

    try {
        // Verify that there's a matching session in ui_user_sessions
        $sql = "
            SELECT 
                u.id AS user_id,
                u.sys_admin,
                s.expires_at
            FROM ui_user_sessions s
            JOIN ui_users u ON s.user_id = u.id
            WHERE s.user_id = :uid
              AND s.session_token = :tok
              AND s.product = 'admin'
              AND s.expires_at > NOW()
            LIMIT 1
        ";
        $stmt = $pdo->prepare($sql);
        $stmt->execute([
            ':uid' => $userId,
            ':tok' => $token
        ]);
        $row = $stmt->fetch(PDO::FETCH_ASSOC);

        if (!$row) {
            // Session not found or expired => redirect to login
            adminLogoutAndRedirect();
        }

        // Check sys_admin=1
        if (empty($row['sys_admin']) || (int)$row['sys_admin'] !== 1) {
            // Not a valid sys admin => redirect
            adminLogoutAndRedirect();
        }
        // If we get here, the user is authorized.
    } catch (\Exception $ex) {
        error_log("adminRequireAuth error: " . $ex->getMessage());
        adminLogoutAndRedirect();
    }
}

function adminLogoutAndRedirect()
{
    // Clears the session data:
    if (isset($_SESSION['admin_user_id'], $_SESSION['admin_session_token'])) {
        global $pdo;
        try {
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
        } catch (\Exception $e) {
            // Log but continue
            error_log("adminLogoutAndRedirect exception: " . $e->getMessage());
        }
    }
    session_unset();
    session_destroy();
    header('Location: /login_admin.php');
    exit;
}

// Finally, call the auth check each time this file is required.
adminRequireAuth();
