/**
 * Lightweight validity probe – lets login.php skip the DB round-trip
 * on every page load.
 */
function adminIsLoggedIn(\PDO $pdo): bool
{
    if (empty($_SESSION['admin_user_id']) || empty($_SESSION['admin_session_token'])) {
        return false;
    }

    $stmt = $pdo->prepare("
        SELECT 1
          FROM admin_user_sessions
         WHERE admin_user_id = :uid
           AND session_token  = :tok
           AND expires_at    > NOW()
         LIMIT 1
    ");
    $stmt->execute([
        ':uid' => $_SESSION['admin_user_id'],
        ':tok' => $_SESSION['admin_session_token']
    ]);

    return (bool) $stmt->fetchColumn();
}
