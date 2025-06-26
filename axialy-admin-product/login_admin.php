<?php
// /home/i17z4s936h3j/admin.axiaba.com/login_admin.php

require_once __DIR__ . '/includes/db_connection.php';
session_start();

// If the user is already logged in (admin session), redirect to index
if (isset($_SESSION['admin_user_id']) && isset($_SESSION['admin_session_token'])) {
    header('Location: /index.php');
    exit;
}

// The recognized environment choices:
$validEnvironments = ['production','beta','test','uat','aii']; // <-- ADDED "aii"
$errorMsg = '';

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $envChoice = $_POST['environment'] ?? 'production';
    $username  = trim($_POST['username'] ?? '');
    $password  = trim($_POST['password'] ?? '');

    if (!in_array($envChoice, $validEnvironments)) {
        $envChoice = 'production'; // fallback
    }
    if (!$username || !$password) {
        $errorMsg = 'Please provide username and password.';
    } else {
        try {
            $_SESSION['admin_target_env'] = $envChoice;
            // re-include or re-instantiate $pdo with new environment if needed
            require __DIR__ . '/includes/db_connection.php';

            $sql = "SELECT * FROM ui_users WHERE username = :uname LIMIT 1";
            $stmt = $pdo->prepare($sql);
            $stmt->execute([':uname'=>$username]);
            $userRow = $stmt->fetch(PDO::FETCH_ASSOC);

            if (!$userRow) {
                $errorMsg = "Invalid username or password.";
            } else {
                if (!password_verify($password, $userRow['password'])) {
                    $errorMsg = "Invalid username or password.";
                } else {
                    if (empty($userRow['sys_admin']) || (int)$userRow['sys_admin'] !== 1) {
                        $errorMsg = "Access denied. You are not a system admin user.";
                    } else {
                        // Good
                        $del = $pdo->prepare("
                            DELETE FROM ui_user_sessions
                             WHERE user_id = :uid
                               AND product = 'admin'
                        ");
                        $del->execute([':uid'=>$userRow['id']]);

                        $sessionToken = bin2hex(random_bytes(32));
                        $expiresAt = date('Y-m-d H:i:s', strtotime('+12 hours'));
                        $ins = $pdo->prepare("
                            INSERT INTO ui_user_sessions
                            (user_id, session_token, product, created_at, expires_at)
                            VALUES
                            (:uid, :tok, 'admin', NOW(), :exp)
                        ");
                        $ins->execute([
                            ':uid'=>$userRow['id'],
                            ':tok'=>$sessionToken,
                            ':exp'=>$expiresAt
                        ]);

                        $_SESSION['admin_user_id']       = $userRow['id'];
                        $_SESSION['admin_session_token'] = $sessionToken;
                        $_SESSION['admin_target_env']    = $envChoice;

                        header('Location: /index.php');
                        exit;
                    }
                }
            }
        } catch (\Exception $ex) {
            $errorMsg = "Error during login attempt: " . $ex->getMessage();
        }
    }
}
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Axialy Admin Login</title>
    <style>
        body {
            font-family: sans-serif;
            margin: 40px;
        }
        .login-container {
            max-width: 400px;
            margin: auto;
        }
        label {
            display: inline-block;
            margin-top: 10px;
            font-weight: bold;
        }
        input, select {
            width: 100%;
            padding: 8px;
            margin-top: 4px;
        }
        .error {
            color: #b70000;
            margin-top: 15px;
        }
        button {
            margin-top: 15px;
            padding: 10px 15px;
            cursor: pointer;
        }
        .env-note {
            font-size: 0.9em;
            margin-top: 10px;
            color: #666;
        }
    </style>
</head>
<body>
<div class="login-container">
    <h1>Axialy Admin Login</h1>
    <?php if ($errorMsg): ?>
        <div class="error"><?php echo htmlspecialchars($errorMsg); ?></div>
    <?php endif; ?>
    <form method="post" action="">
        <label for="environment">Select Environment:</label>
        <select name="environment" id="environment">
            <option value="production">Production</option>
            <option value="beta">Beta</option>
            <option value="test">Test</option>
            <option value="uat">UAT</option>
            <option value="aii">AII</option> <!-- ADDED -->
        </select>
        <div class="env-note">
            (This choice will determine which Axialy_UI DB to connect to for user auth and management.)
        </div>

        <label for="username">Username:</label>
        <input type="text" name="username" id="username" required>

        <label for="password">Password:</label>
        <input type="password" name="password" id="password" required>

        <button type="submit">Log In</button>
    </form>
</div>
</body>
</html>
