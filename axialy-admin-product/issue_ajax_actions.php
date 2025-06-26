!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!!!!!!!!!!!          DEPRECATED        !!!!!!!!!!!!!!!!!!
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!













<?php
// /home/i17z4s936h3j/public_html/admin.axiaba.com/issues_ajax_actions.php
require_once __DIR__ . '/includes/admin_auth.php';
requireAdminAuth();
header('Content-Type: application/json');

require_once __DIR__ . '/includes/db_connection.php';

$action = $_GET['action'] ?? $_POST['action'] ?? '';

switch($action) {
    case 'list':
        listIssues($pdo);
        break;
    case 'get':
        getIssue($pdo);
        break;
    case 'update':
        updateIssue($pdo);
        break;
    default:
        echo json_encode(['success'=>false, 'message'=>'Unknown action']);
        break;
}

function listIssues(PDO $pdo) {
    $stmt = $pdo->query("SELECT * FROM issues ORDER BY id DESC");
    $rows = $stmt->fetchAll(PDO::FETCH_ASSOC);
    echo json_encode($rows);
}

function getIssue(PDO $pdo) {
    $id = (int)($_GET['id'] ?? 0);
    if (!$id) {
        echo json_encode(['success'=>false, 'message'=>'No ID provided']);
        return;
    }
    $stmt = $pdo->prepare("SELECT * FROM issues WHERE id=?");
    $stmt->execute([$id]);
    $row = $stmt->fetch(PDO::FETCH_ASSOC);
    if (!$row) {
        echo json_encode(['success'=>false, 'message'=>'Issue not found']);
        return;
    }
    echo json_encode($row);
}

function updateIssue(PDO $pdo) {
    $input = json_decode(file_get_contents('php://input'), true);
    if (!$input || empty($input['id'])) {
        echo json_encode(['success'=>false, 'message'=>'No ID']);
        return;
    }
    $id     = (int)$input['id'];
    $title  = trim($input['issue_title'] ?? '');
    $desc   = trim($input['issue_description'] ?? '');
    $stat   = trim($input['status'] ?? 'Open');
    if (!$title || !$desc) {
        echo json_encode(['success'=>false, 'message'=>'Title and description cannot be empty.']);
        return;
    }
    try {
        $stmt = $pdo->prepare("
          UPDATE issues
             SET issue_title=:t,
                 issue_description=:d,
                 status=:s,
                 updated_at=NOW()
           WHERE id=:id
        ");
        $stmt->execute([
            ':t' => $title,
            ':d' => $desc,
            ':s' => $stat,
            ':id'=> $id
        ]);
        echo json_encode(['success'=>true]);
    } catch (Exception $ex) {
        echo json_encode(['success'=>false, 'message'=>$ex->getMessage()]);
    }
}
