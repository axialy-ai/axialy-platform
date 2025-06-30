# TEST 01

# /admin.axiaba.com/

This directory (`/admin.axialy.com`) contains all files for the Axialy administrative interface, including authentication, session management, documentation and data viewers, and specialty tools.

## Files

- **admin_login.php**: Handles the login form for administrators, validating credentials against the `admin_users` table in `Axialy_ADMIN`.
- **auth.php**: Defines functions `adminRequireAuth()` and `adminLogoutAndRedirect()` to enforce admin authentication and manage sessions.
- **auth_check.php**: Alternative authentication check for admin sessions; verifies sys_admin status and session validity in `ui_user_sessions`.
- **create_minimal_docx.php**: Utility to generate a minimal DOCX file from plain text using `ZipArchive`.
- **db_viewer_admin.php**: Frontend for browsing and querying the UI database tables with pagination and filters.
- **db_viewer_ajax.php**: Backend AJAX endpoints (`list_tables`, `table_data_indef`) for `db_viewer_admin.php`.
- **doc_ajax_actions.php**: AJAX endpoints for managing documents and versions (`listDocs`, `listVersions`, `createDoc`, `createVersion`, `setActiveVersion`, `generatePdf`, `generateDocx`, `uploadDocFile`, `downloadDocFile`, `getDoc`, `updateDoc`).
- **docs_admin.php**: Frontend for document and version management interface.
- **favicon.ico**: Icon displayed in browser tabs.
- **index.php**: Main admin dashboard; initializes the first admin user (`caseylide`), enforces authentication, and provides navigation to tools.
- **init_user.php**: AJAX endpoint to initialize the default `caseylide` admin user with password `Casellio`.
- **issue_ajax_actions.php**: *Deprecated* AJAX actions for issue management (old version).
- **issues_admin.php**: Frontend for viewing and editing user-submitted issues.
- **issues_ajax_actions.php**: AJAX endpoints (`list`, `get`, `update`, `sendEmail`) for issue management, including sending email updates to users.
- **login.php**: Admin login interface and authentication logic against `ui_users` with environment selection (`production`, `beta`, `test`, `uat`, `aii`).
- **login_admin.php**: Another admin login variant that connects to the UI environment DB for authentication.
- **logout.php**: Logs out an admin session from `Axialy_ADMIN`.
- **logout_admin.php**: Logs out an admin session from the UI environment DB.
- **promo_codes_admin.php**: Frontend for creating, viewing, and editing promotional codes.
- **promo_codes_ajax_actions.php**: AJAX endpoints (`list`, `get`, `create`, `update`) for promo code management.

## Subdirectories

- **includes/**: Contains shared PHP classes and scripts for configuration, database connections, and authentication.
