<?php
/*  Axialy ▸ Admin – dashboard / first-run bootstrap  */
session_name('axiaba_admin_session');
session_start();

require_once __DIR__ . '/includes/AdminDBConfig.php';
use Axialy\AdminConfig\AdminDBConfig;

/* ------------------------------------------------------------------ */
/*  0) Defaults injected via GitHub Actions (fallbacks for dev only)  */
/* ------------------------------------------------------------------ */
$DEFAULT_ADMIN_USER     = getenv('ADMIN_DEFAULT_USER')     ?: 'caseylide';
$DEFAULT_ADMIN_PASSWORD = getenv('ADMIN_DEFAULT_PASSWORD') ?: 'Casellio';
$DEFAULT_ADMIN_EMAIL    = getenv('ADMIN_DEFAULT_EMAIL')    ?: 'caseylide@gmail.com';

/* ------------------------------------------------------------------ */
/*  1) Ensure DB + tables exist                                       */
/* ------------------------------------------------------------------ */
$adminDB = AdminDBConfig::getInstance()->getPdo();
require_once __DIR__ . '/includes/AdminSchema.php';
\Axialy\AdminBootstrap\ensureAdminSchema($adminDB);

/* ------------------------------------------------------------------ */
/*  2) Is the default account present?                               */
/* ------------------------------------------------------------------ */
$stm = $adminDB->prepare('SELECT COUNT(*) FROM admin_users WHERE username = :u');
$stm->execute([':u' => $DEFAULT_ADMIN_USER]);
$defaultExists = (bool) $stm->fetchColumn();

/* ------------------------------------------------------------------ */
/*  3) First-run overlay to create the initial admin account          */
/* ------------------------------------------------------------------ */
if (!$defaultExists) {
    ?>
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <title>Axialy Admin – Initialise</title>
  <style>
    body{margin:0;font-family:sans-serif;background:#f0f0f0}
    .header{background:#fff;padding:15px;text-align:center;border-bottom:1px solid #ddd}
    .header img{height:50px}
    .overlay{position:fixed;inset:0;background:rgba(0,0,0,.55);
             display:flex;justify-content:center;align-items:center}
    .box{background:#fff;padding:28px 32px;border-radius:8px;max-width:420px;width:90%}
    .box h2{margin-top:0}
    input{width:100%;padding:10px;margin:1em 0;font-size:16px}
    button{padding:10px 20px;margin:0 10px;cursor:pointer}
  </style>
</head>
<body>
  <div class="header">
    <img src="https://axiaba.com/assets/img/product_logo.png" alt="Axialy">
  </div>

  <div class="overlay">
    <div class="box">
      <h2>Welcome to Axialy Platform Administration</h2>
      <p>This is the very first launch – create the initial administrator account.</p>

      <input type="password" id="secret"
             placeholder="Enter admin code (<?= htmlspecialchars($DEFAULT_ADMIN_PASSWORD) ?>)">
      <div>
        <button id="create">Create account</button>
        <button id="exit">Leave</button>
      </div>
    </div>
  </div>

<script>
const DEF_CODE = <?= json_encode($DEFAULT_ADMIN_PASSWORD) ?>;
document.getElementById('create').onclick = async () => {
    const val = document.getElementById('secret').value.trim();
    if (!val) return;
    if (val !== DEF_CODE) { alert('Incorrect admin code'); return; }

    try {
        const r  = await fetch('init_user.php', {method:'POST',body:''});
        const js = await r.json();
        if (js.success) {
            alert('Administrator account created.\nYou may now log in as "<?= addslashes($DEFAULT_ADMIN_USER) ?>".');
            location.reload();
        } else { alert('Error: ' + js.message); }
    } catch (e) { alert(e); }
};
document.getElementById('exit').onclick = () => location.href = 'https://www.axiaba.com';
</script>
</body>
</html>
<?php
    exit;
}

/* ------------------------------------------------------------------ */
/*  4) Normal authenticated flow                                      */
/* ------------------------------------------------------------------ */
require_once __DIR__ . '/includes/admin_auth.php';
requireAdminAuth();

/* ------------------------------------------------------------------ */
/*  5) Environment selector (UI instance)                             */
/* ------------------------------------------------------------------ */
$validEnvs = ['production','clients','beta','test','uat','firstlook','aii'];
if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_POST['env_select'])) {
    $choice = $_POST['env_select'];
    if (in_array($choice, $validEnvs, true)) {
        $_SESSION['admin_env'] = $choice;
    }
    header('Location: index.php'); exit;
}
$env = $_SESSION['admin_env'] ?? 'production';

$uiMap = [
    'production' => 'https://app.axiaba.com',
    'clients'    => 'https://clients.axiaba.com',
    'beta'       => 'https://beta.axiaba.com',
    'test'       => 'https://app-test.axiaba.com',
    'uat'        => 'https://app-uat.axiaba.com',
    'firstlook'  => 'https://firstlook.axiaba.com',
    'aii'        => 'https://aii.axiaba.com',
];
$uiUrl = $uiMap[$env] ?? $uiMap['production'];
?>
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <title>Axialy Admin – Home</title>
  <style>
    body{margin:0;font-family:sans-serif;background:#f9f9f9}
    .header{background:#fff;padding:15px;border-bottom:1px solid #ccc;
            display:flex;justify-content:space-between;align-items:center}
    .header-left{display:flex;align-items:center;gap:15px}
    .header-left img{height:50px}
    .container{max-width:800px;margin:30px auto;background:#fff;padding:20px;
               border:1px solid #ccc;border-radius:6px}
    .env-box{margin:1em 0;padding:1em;border:1px solid #ccc;background:#f9f9f9}
    form{margin-bottom:20px}
    select{padding:5px}
    .button{display:inline-block;margin:.5em 0;padding:.5em 1em;background:#007BFF;
            color:#fff;text-decoration:none;border-radius:4px}
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
      <strong>Current Environment:</strong> <?= htmlspecialchars($env) ?>
    </div>

    <form method="POST">
      <label for="env_select">Switch Environment:</label>
      <select name="env_select" id="env_select">
        <?php foreach ($validEnvs as $v): ?>
          <option value="<?= $v ?>" <?= $v === $env ? 'selected' : '' ?>>
            <?= ucfirst($v) ?>
          </option>
        <?php endforeach; ?>
      </select>
      <button type="submit" class="button">Apply</button>
    </form>

    <div class="link-block"><a class="button" href="/docs_admin.php">Open Documentation Management</a></div>
    <div class="link-block"><a class="button" href="/promo_codes_admin.php">Manage Promo Codes</a></div>
    <div class="link-block"><a class="button" href="/issues_admin.php">Manage Issues</a></div>
    <div class="link-block"><a class="button" href="/db_viewer_admin.php">Open Data Inspector</a></div>
    <div class="link-block">
      <a class="button" href="<?= $uiUrl ?>" target="_blank" rel="noopener">
        Open Axialy UI (<?= htmlspecialchars($env) ?>) in New Tab
      </a>
    </div>
  </div>
</body>
</html>
