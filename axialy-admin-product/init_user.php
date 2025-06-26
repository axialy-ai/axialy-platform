<?php
/**  Axialy ▸ Admin ▸ AJAX endpoint
 *   Creates the very first administrator account.
 *   Reads ADMIN_DEFAULT_* values from the environment.
 */
header('Content-Type: application/json');
if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    echo json_encode(['success'=>false,'message'=>'Method Not Allowed']);  exit;
}

require_once __DIR__ . '/includes/AdminDBConfig.php';
use Axialy\AdminConfig\AdminDBConfig;

$USER  = getenv('ADMIN_DEFAULT_USER')     ?: 'caseylide';
$EMAIL = getenv('ADMIN_DEFAULT_EMAIL')    ?: 'caseylide@gmail.com';
$PASS  = getenv('ADMIN_DEFAULT_PASSWORD') ?: 'Casellio';

try {
    $pdo = AdminDBConfig::getInstance()->getPdo();

    /* abort if the account already exists -------------------------------- */
    $stmt = $pdo->prepare('SELECT COUNT(*) FROM admin_users WHERE username = :u');
    $stmt->execute([':u'=>$USER]);
    if ($stmt->fetchColumn() > 0) {
        echo json_encode(['success'=>false,'message'=>"User \"$USER\" already exists"]); exit;
    }

    /* create the user ---------------------------------------------------- */
    $hash = password_hash($PASS, PASSWORD_BCRYPT);
    $ins  = $pdo->prepare('INSERT INTO admin_users
        (username,password,email,is_active,is_sys_admin,created_at)
        VALUES (:u,:p,:e,1,1,NOW())');
    $ins->execute([':u'=>$USER, ':p'=>$hash, ':e'=>$EMAIL]);

    echo json_encode(['success'=>true]);
} catch (\Throwable $e) {
    echo json_encode(['success'=>false,'message'=>$e->getMessage()]);
}
