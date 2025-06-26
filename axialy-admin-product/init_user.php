<?php
header('Content-Type: application/json');

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    echo json_encode(['success'=>false,'message'=>'Method not allowed']); exit;
}

require_once __DIR__ . '/includes/AdminDBConfig.php';
use AxiaBA\AdminConfig\AdminDBConfig;

/* ── bootstrap secrets ─────────────────────────────────────────────────── */
$DEF_USER     = getenv('ADMIN_DEFAULT_USER');
$DEF_EMAIL    = getenv('ADMIN_DEFAULT_EMAIL');
$DEF_PASSWORD = getenv('ADMIN_DEFAULT_PASSWORD');

if (!$DEF_USER || !$DEF_EMAIL || !$DEF_PASSWORD) {
    echo json_encode(['success'=>false,'message'=>'Server mis-configuration']); exit;
}

/* ── compare code supplied by browser ------------------------------------ */
$code = trim($_POST['code'] ?? '');
if ($code !== $DEF_PASSWORD) {
    echo json_encode(['success'=>false,'message'=>'Invalid initialisation code']); exit;
}

try {
    $pdo = AdminDBConfig::getInstance()->getPdo();

    $stmt = $pdo->prepare("SELECT COUNT(*) FROM admin_users WHERE username = :u");
    $stmt->execute([':u'=>$DEF_USER]);
    if ($stmt->fetchColumn()) {
        echo json_encode(['success'=>false,'message'=>"User \"$DEF_USER\" already exists."]); exit;
    }

    $stmt = $pdo->prepare("
        INSERT INTO admin_users (username,password,email,is_active,is_sys_admin,created_at)
        VALUES (:u,:p,:e,1,1,NOW())
    ");
    $stmt->execute([
        ':u'=>$DEF_USER,
        ':p'=>password_hash($DEF_PASSWORD, PASSWORD_BCRYPT),
        ':e'=>$DEF_EMAIL,
    ]);

    echo json_encode(['success'=>true]);
} catch (Throwable $e) {
    echo json_encode(['success'=>false,'message'=>$e->getMessage()]);
}
