<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width,initial-scale=1">
  <title>Axialy • placeholder</title>
  <style>
    :root { --bg:#0d1117; --fg:#c9d1d9; --accent:#3fb950; }
    *{box-sizing:border-box;font-family:system-ui,Segoe UI,Roboto,"Helvetica Neue",Arial,sans-serif}
    body{margin:0;display:flex;min-height:100vh;align-items:center;justify-content:center;
         background:var(--bg);color:var(--fg);text-align:center;padding:2rem}
    h1{font-size:clamp(2.5rem,6vw,4rem);margin:0 0 .5em 0}
    a{color:var(--accent);text-decoration:none}
    code{background:#161b22;padding:.25em .5em;border-radius:6px;font-size:90%}
  </style>
</head>
<body>
  <main>
    <h1>🚀 Axialy is provisioning…</h1>
    <p>This is a temporary landing page served from<br><code id="host"></code></p>
    <p>As soon as CI finishes, the real application will appear here.</p>
    <p><small><a href="https://github.com/Axiamax/axialy-platform">view source on GitHub</a></small></p>
  </main>
  <script>
    /* show which droplet we actually hit */
    document.getElementById('host').textContent = location.hostname || location.host;
  </script>
</body>
</html>
