<?php
// axialy-admin-product/index.php
session_name('axiaba_admin_session');
session_start();

require_once __DIR__ . '/includes/AdminDBConfig.php';
use AxiaBA\AdminConfig\AdminDBConfig;

/* --------------------------------------------------------------------------
   1.  Resolve DB connection (handled inside the singleton)                 
   -------------------------------------------------------------------------- */
$pdo = AdminDBConfig::getInstance()->getPdo();

/* --------------------------------------------------------------------------
   2.  Read “bootstrap admin” values from ENV (fallbacks keep legacy dev)   
   -------------------------------------------------------------------------- */
$DEF_USER     = getenv('ADMIN_DEFAULT_USER')     ?: 'caseylide';
$DEF_EMAIL    = getenv('ADMIN_DEFAULT_EMAIL')    ?: 'caseylide@gmail.com';
$DEF_PASSWORD = getenv('ADMIN_DEFAULT_PASSWORD') ?: 'Casellio';

/* --------------------------------------------------------------------------
   3.  If the default admin does NOT exist yet, show first-run overlay       
   -------------------------------------------------------------------------- */
$stmt = $pdo->prepare("SELECT COUNT(*) FROM admin_users WHERE username = :u");
$stmt->execute([':u' => $DEF_USER]);
$adminExists = (bool) $stmt->fetchColumn();

if (!$adminExists): ?>
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <title>Axialy Admin – Initialization</title>
  <style>
    body{font-family:sans-serif;margin:0;padding:0;background:#f0f0f0}
    .header{background:#fff;padding:15px;border-bottom:1px solid #ddd;text-align:center}
    .header img{height:50px}
    .overlay{position:fixed;top:0;left:0;width:100%;height:100%;
             background:rgba(0,0,0,.5);display:flex;justify-content:center;
             align-items:center;z-index:9999}
    .overlay-content{background:#fff;padding:30px;border-radius:8px;
                     max-width:400px;width:90%;text-align:center}
    .overlay h2{margin-top:0}
    .overlay input{width:100%;padding:10px;margin:1em 0;font-size:16px}
    .overlay .buttons{margin-top:1em}
    .overlay button{padding:10px 20px;margin:0 10px;cursor:pointer}
    @media(max-width:768px){
      #left-panel,#right-panel{width:100%!important;max-width:100%!important;height:auto}
    }
  </style>
</head>
<body>
  <div class="header">
    <img src="https://axiaba.com/assets/img/product_logo.png" alt="Axialy Logo">
  </div>

  <div class="overlay">
    <div class="overlay-content">
      <h2>Welcome to Axialy Platform Administration</h2>
      <p>The system is awaiting input from the primary administrator.</p>
      <input type="password" id="initPass" placeholder="Enter admin code…">
      <div class="buttons">
        <button id="btnEnter">Enter</button>
        <button id="btnExit">Exit</button>
      </div>
    </div>
  </div>

  <script>
    const PASS = <?php echo json_encode($DEF_PASSWORD); ?>;

    document.getElementById('btnEnter').onclick = () => {
      window.location.href = 'https://www.axiaba.com';
    };

    document.getElementById('btnExit').onclick = async () => {
      const val = document.getElementById('initPass').value.trim();
      if (val === PASS) {
        try {
          const resp = await fetch('init_user.php', {method:'POST'});
          const data = await resp.json();
          if (data.success) {
            alert('Initial admin user created. You may now log in as "<?php echo htmlspecialchars($DEF_USER); ?>".');
            location.reload();
          } else {
            alert('Error: '+data.message);
          }
        } catch (err) {
          alert('AJAX error: '+err);
        }
      }
    };
  </script>
</body>
</html>
<?php
  /* stop here so normal dashboard isn’t rendered */
  exit;
endif;

/* --------------------------------------------------------------------------
   4.  Default admin exists – proceed with normal authenticated dashboard    
   -------------------------------------------------------------------------- */
require_once __DIR__ . '/includes/admin_auth.php';
requireAdminAuth();

/* ---------- environment selector (unchanged) ---------------------------- */
$validEnvs = ['production','clients','beta','test','uat','firstlook','aii'];
if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_POST['env_select'])) {
    $choice = $_POST['env_select'];
    if (in_array($choice, $validEnvs, true)) {
        $_SESSION['admin_env'] = $choice;
    }
    header('Location: index.php');
    exit;
}
$env = $_SESSION['admin_env'] ?? 'production';
$mapping = [
  'production' => 'https://app.axiaba.com',
  'clients'    => 'https://clients.axiaba.com',
  'beta'       => 'https://beta.axiaba.com',
  'test'       => 'https://app-test.axiaba.com',
  'uat'        => 'https://app-uat.axiaba.com',
  'firstlook'  => 'https://firstlook.axiaba.com',
  'aii'        => 'https://aii.axiaba.com'
];
$uiUrl = $mapping[$env] ?? 'https://app.axiaba.com';
?>
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <title>Axialy Admin – Home</title>
  <style>
    body{font-family:sans-serif;margin:0;padding:0;background:#f9f9f9}
    .header{background:#fff;padding:15px;border-bottom:1px solid #ccc;
            display:flex;justify-content:space-between;align-items:center}
    .header-left{display:flex;align-items:center;gap:15px}
    .header-left img{height:50px}
    .container{max-width:800px;margin:30px auto;background:#fff;
               padding:20px;border:1px solid #ccc;border-radius:6px}
    .env-box{margin:1em 0;padding:1em;border:1px solid #ccc;background:#f9f9f9}
    form{margin-bottom:20px}
    select{padding:5px}
    .button{display:inline-block;margin:.5em 0;padding:.5em 1em;
            background:#007BFF;color:#fff;text-decoration:none;border-radius:4px}
    .button:hover{background:#0056b3}
    .logout-btn{background:#dc3545!important;margin-left:20px}
    h1{margin:0;font-size:1.4rem}
    .link-block{margin:1em 0}
  </style>
</head>
<body>
  <div class="header">
    <div class="header-left">
      <img src="https://axiaba.com/assets/img/SOI.png" alt="Axialy Logo">
      <h1>Axialy Admin</h1>
    </div>
    <div>
      <a class="button logout-btn" href="/logout.php">Logout</a>
    </div>
  </div>

  <div class="container">
    <p>Welcome, Admin. You are logged in.</p>

    <div class="env-box">
      <strong>Current Environment:</strong> <?php echo htmlspecialchars($env); ?>
    </div>

    <form method="POST">
      <label for="env_select">Switch Environment:</label>
      <select name="env_select" id="env_select">
        <?php foreach ($validEnvs as $v): ?>
          <option value="<?php echo $v; ?>" <?php if ($v === $env) echo 'selected'; ?>>
            <?php echo ucfirst($v); ?>
          </option>
        <?php endforeach; ?>
      </select>
      <button type="submit" class="button">Apply</button>
    </form>

    <div class="link-block">
      <a class="button" href="/docs_admin.php">Open Documentation Management</a>
    </div>
    <div class="link-block">
      <a class="button" href="/promo_codes_admin.php">Manage Promo Codes</a>
    </div>
    <div class="link-block">
      <a class="button" href="/issues_admin.php">Manage Issues</a>
    </div>
    <div class="link-block">
      <a class="button" href="/db_viewer_admin.php">Open Data Inspector</a>
    </div>
    <div class="link-block">
      <a class="button" href="<?php echo $uiUrl; ?>" target="_blank">
        Open Axialy UI (<?php echo htmlspecialchars($env); ?>)
      </a>
    </div>
  </div>
</body>
</html>
