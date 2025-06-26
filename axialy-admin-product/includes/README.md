# /admin.axiaba.com/includes/

This directory contains shared PHP classes and scripts used by the admin panel for configuration, authentication, and database connections.

## Files

- **AdminDBConfig.php**: Singleton class for connecting to the `Axialy_ADMIN` database; reads credentials from `.env.admin`.
- **Config.php**: Loads environment variables from `.env.<environment>` (set by `environment_selector.php`) and provides accessors for admin DB configuration.
- **admin_auth.php**: Enforces admin authentication against `Axialy_ADMIN.admin_user_sessions` and `admin_users`; provides `requireAdminAuth()` and `logoutAndRedirect()`.
- **auth_admin.php**: Alternative admin authentication for the UI environment DB; ensures `sys_admin=1` and valid sessions in `ui_user_sessions`.
- **db_connection.php**: Establishes a PDO connection to the admin database using `Axialy\AdminConfig\Config`.
- **environment_selector.php**: Determines the target environment (`production` by default or from session `admin_env`).
- **ui_db_connection.php**: Establishes a PDO connection to the selected UI environment's database by parsing the corresponding `.env.<environment>` file.
