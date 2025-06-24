<?php
// /home/i17z4s936h3j/public_html/admin.axiaba.com/login.php
// AxiaBA Admin Login

session_name('axiaba_admin_session');
session_start();
require_once __DIR__ . '/includes/environment_selector.php'; 
// environment_selector currently just sets $TARGET_ENV from session or fallback 'production'
require_once __DIR__ . '/includes/db_connection.php';
require_once __DIR__ . '/includes/admin_auth.php';

// If already logged in & valid, send them to index
if (adminIsLoggedIn($pdo)) {
    header('Location: index.php');
    exit;
}

$error = '';

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $username   = trim($_POST['username']   ?? '');
    $password   = trim($_POST['password']   ?? '');
    $envChoice  = trim($_POST['env_choice'] ?? 'production');
    
    if (!$username || !$password) {
        $error = 'Please enter both username and password.';
    } 
    // Added "aii" here:
    else if (!in_array($envChoice, ['production','beta','test','uat','aii'])) {
        $error = 'Invalid environment choice.';
    } else {
        // Attempt to validate user in the chosen environment
        $pdoChosen = getAdminPdoForEnv($envChoice);
        if (!$pdoChosen) {
            $error = 'Failed to connect to the selected environment database.';
        } else {
            // Now fetch user row from ui_users
            $stmt = $pdoChosen->prepare("SELECT id, username, password, sys_admin FROM ui_users WHERE username = ?");
            $stmt->execute([$username]);
            $userRow = $stmt->fetch(PDO::FETCH_ASSOC);

            if (!$userRow) {
                $error = 'Invalid credentials.';
            } else {
                // Check password
                if (!password_verify($password, $userRow['password'])) {
                    $error = 'Invalid credentials.';
                } else {
                    // Check sys_admin
                    if ((int)$userRow['sys_admin'] !== 1) {
                        $error = 'Access restricted to system administrators only.';
                    } else {
                        // Good. We can log them in:
                        // Clean up old sessions for this user, product='admin'
                        $cleanup = $pdoChosen->prepare("DELETE FROM ui_user_sessions WHERE user_id=? AND product='admin'");
                        $cleanup->execute([$userRow['id']]);

                        // Create new session token
                        $adminToken = bin2hex(random_bytes(32));
                        $expiresAt  = date('Y-m-d H:i:s', strtotime('+6 hours'));

                        // Insert session row
                        $ins = $pdoChosen->prepare("
                            INSERT INTO ui_user_sessions (user_id, session_token, product, expires_at)
                            VALUES (:uid, :token, 'admin', :exp)
                        ");
                        $ins->execute([
                            ':uid'   => $userRow['id'],
                            ':token' => $adminToken,
                            ':exp'   => $expiresAt
                        ]);

                        // Store in session
                        $_SESSION['admin_user_id']       = $userRow['id'];
                        $_SESSION['admin_session_token'] = $adminToken;
                        $_SESSION['admin_env']           = $envChoice;

                        // Redirect to index
                        header('Location: index.php');
                        exit;
                    }
                }
            }
        }
    }
}
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>AxiaBA Admin - Login</title>
    <style>
      body { font-family: sans-serif; margin: 30px; }
      .login-container { max-width: 400px; margin: auto; padding: 20px; border: 1px solid #ccc; }
      .error { color: red; margin-bottom: 10px; }
      label { display: block; margin-top: 10px; }
      input[type="text"], input[type="password"] {
          width: 100%; padding: 8px; box-sizing: border-box; margin-top: 4px;
      }
      select { margin-top: 4px; }
      button { margin-top: 16px; padding: 8px 16px; }
      h2 { margin-bottom: 16px; }
    </style>
</head>
<body>
<div class="login-container">
    <h2>AxiaBA Admin Login</h2>
    <?php if ($error): ?>
      <div class="error"><?php echo htmlspecialchars($error); ?></div>
    <?php endif; ?>
    
    <form method="POST" action="">
      <label for="username">Username:</label>
      <input type="text" name="username" id="username" required>
      
      <label for="password">Password:</label>
      <input type="password" name="password" id="password" required>
      
      <label for="env_choice">Select Environment:</label>
      <select name="env_choice" id="env_choice">
        <option value="production">Production</option>
        <option value="beta">Beta</option>
        <option value="test">Test</option>
        <option value="uat">UAT</option>
        <option value="aii">AII</option> <!-- ADDED -->
      </select>
      
      <button type="submit">Login</button>
    </form>
</div>
</body>
</html>
