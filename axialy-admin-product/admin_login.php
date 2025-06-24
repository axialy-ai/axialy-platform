<?php
// /home/i17z4s936h3j/public_html/admin.axiaba.com/admin_login.php

session_name('axiaba_admin_session');
session_start();

require_once __DIR__ . '/includes/AdminDBConfig.php';
use AxiaBA\AdminConfig\AdminDBConfig;

$errorMessage = '';

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $username = trim($_POST['username'] ?? '');
    $password = trim($_POST['password'] ?? '');

    if (!$username || !$password) {
        $errorMessage = 'Please enter your username and password.';
    } else {
        try {
            // Connect to AxiaBA_ADMIN
            $adminDB = AdminDBConfig::getInstance()->getPdo();

            // Lookup admin user in AxiaBA_ADMIN.admin_users
            $stmt = $adminDB->prepare("SELECT * FROM admin_users WHERE username = :u LIMIT 1");
            $stmt->execute([':u' => $username]);
            $adminUser = $stmt->fetch(\PDO::FETCH_ASSOC);

            if (!$adminUser) {
                $errorMessage = 'Invalid credentials.';
            } else {
                // Check if active
                if (intval($adminUser['is_active']) !== 1) {
                    $errorMessage = 'This admin account is disabled.';
                }
                // Verify password
                elseif (!password_verify($password, $adminUser['password'])) {
                    $errorMessage = 'Invalid credentials.';
                } else {
                    // Auth success: remove old sessions for this user
                    $del = $adminDB->prepare("DELETE FROM admin_user_sessions WHERE admin_user_id = :uid");
                    $del->execute([':uid' => $adminUser['id']]);

                    // Create new session row
                    $sessionToken = bin2hex(random_bytes(32));
                    $expiresAt    = date('Y-m-d H:i:s', strtotime('+4 hours'));

                    $ins = $adminDB->prepare("
                        INSERT INTO admin_user_sessions (admin_user_id, session_token, created_at, expires_at)
                        VALUES (:uid, :tok, NOW(), :exp)
                    ");
                    $ins->execute([
                        ':uid' => $adminUser['id'],
                        ':tok' => $sessionToken,
                        ':exp' => $expiresAt,
                    ]);

                    // Store in PHP session
                    $_SESSION['admin_user_id']       = $adminUser['id'];
                    $_SESSION['admin_session_token'] = $sessionToken;

                    // Redirect to index
                    header('Location: index.php');
                    exit;
                }
            }
        } catch (\Exception $ex) {
            error_log("Admin login error: " . $ex->getMessage());
            $errorMessage = 'An error occurred. Please try again.';
        }
    }
}
?>
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <title>AxiaBA Admin Login</title>
  <style>
    body {
      font-family: sans-serif;
      background: #f4f4f4;
      margin: 0;
      padding: 0;
    }
    .header {
      background: #fff;
      padding: 15px;
      border-bottom: 1px solid #ddd;
      text-align: center;
    }
    .header img {
      height: 50px;
    }
    .login-container {
      max-width: 400px;
      margin: 40px auto;
      background: #fff;
      padding: 20px;
      border: 1px solid #ccc;
      border-radius: 6px;
    }
    h2 {
      margin-top: 0;
      text-align: center;
    }
    .error {
      color: red;
      margin-bottom: 1em;
      text-align: center;
    }
    label {
      display: block;
      margin-top: 1em;
      font-weight: bold;
    }
    input[type="text"],
    input[type="password"] {
      width: 100%;
      padding: 8px;
      box-sizing: border-box;
      margin-top: 4px;
    }
    button {
      margin-top: 1.5em;
      padding: 10px 20px;
      cursor: pointer;
      width: 100%;
      background: #007BFF;
      color: #fff;
      border: none;
      border-radius: 4px;
      font-size: 16px;
    }
    button:hover {
      background: #0056b3;
    }
    /* Add this to the bottom of each page's <style> */
    /* Adjust 768px if you prefer a different breakpoint */
    
    @media (max-width: 768px) {
      body {
        flex-direction: column; /* Instead of row */
        height: auto;           /* Let panels expand naturally */
      }
    
      #left-panel, #right-panel {
        width: 100% !important;
        max-width: 100% !important;
        height: auto; /* Allow full height as needed */
      }
    
      /* If using 'expanded'/'collapsed' classes, override them for mobile: */
      #left-panel.expanded, #left-panel.collapsed {
        width: 100% !important;
        max-width: 100% !important;
      }
    
      /* Possibly hide the toggle button or rename it for mobile, etc. */
      /* Example: place toggle button at the top if you prefer. */
      #toggle-btn {
        margin-bottom: 10px;
      }
    
      /* You can also adjust fonts, padding, etc., if desired. */
      #panel-header h1,
      #right-header-left strong {
        font-size: 1rem;
      }
    }

  </style>
</head>
<body>
  <div class="header">
    <img src="https://axiaba.com/assets/img/SOI.png" alt="AxiaBA Logo">
  </div>
  <div class="login-container">
    <h2>Admin Login</h2>
    <?php if ($errorMessage): ?>
      <div class="error"><?php echo htmlspecialchars($errorMessage); ?></div>
    <?php endif; ?>
    <form method="POST" action="">
      <label>Username:
        <input type="text" name="username" autofocus required>
      </label>
      <label>Password:
        <input type="password" name="password" required>
      </label>
      <button type="submit">Log In</button>
    </form>
  </div>
</body>
</html>
