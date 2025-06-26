<?php
header('Content-Type: application/json');
if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    echo json_encode(['success' => false, 'message' => 'Method not allowed']); exit;
}

require_once __DIR__ . '/includes/AdminDBConfig.php';
use AxiaBA\AdminConfig\AdminDBConfig;

$user     = getenv('ADMIN_DEFAULT_USER')     ?: 'caseylide';
$email    = getenv('ADMIN_DEFAULT_EMAIL')    ?: 'caseylide@gmail.com';
$password = getenv('ADMIN_DEFAULT_PASSWORD') ?: 'Casellio';

try {
    $pdo = AdminDBConfig::getInstance()->getPdo();

    $stmt = $pdo->prepare("SELECT COUNT(*) FROM admin_users WHERE username = :u");
    $stmt->execute([':u' => $user]);
    if ($stmt->fetchColumn()) {
        echo json_encode(['success' => false, 'message' => "User \"$user\" already exists."]); exit;
    }

    $stmt = $pdo->prepare("
        INSERT INTO admin_users (username, password, email, is_active, is_sys_admin, created_at)
        VALUES (:u, :p, :e, 1, 1, NOW())
    ");
    $stmt->execute([
        ':u' => $user,
        ':p' => password_hash($password, PASSWORD_BCRYPT),
        ':e' => $email,
    ]);

    echo json_encode(['success' => true]);
} catch (Throwable $e) {
    echo json_encode(['success' => false, 'message' => $e->getMessage()]);
}
