<?php
// /home/i17z4s936h3j/public_html/admin.axiaba.com/logout.php

session_name('axiaba_admin_session');
session_start();

require_once __DIR__ . '/includes/AdminDBConfig.php';
use AxiaBA\AdminConfig\AdminDBConfig;

$adminDB = AdminDBConfig::getInstance()->getPdo();

// If we have a valid admin session
if (!empty($_SESSION['admin_user_id']) && !empty($_SESSION['admin_session_token'])) {
    $stmt = $adminDB->prepare("
        DELETE FROM admin_user_sessions
         WHERE admin_user_id = :uid
           AND session_token  = :tok
    ");
    $stmt->execute([
        ':uid' => $_SESSION['admin_user_id'],
        ':tok' => $_SESSION['admin_session_token'],
    ]);
}

// Clear local PHP session
$_SESSION = [];
session_destroy();

// Redirect to login
header('Location: /admin_login.php?logged_out=1');
exit;
