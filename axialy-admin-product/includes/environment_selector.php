<?php
// /home/i17z4s936h3j/public_html/admin.axiaba.com/includes/environment_selector.php

/**
 * This file decides which environment to connect for the "admin" tool.
 * We now allow environment selection from the admin session.
 * Fallback default is 'production' if not found in session.
 */

session_start();
if (!empty($_SESSION['admin_env'])) {
    $TARGET_ENV = $_SESSION['admin_env'];
} else {
    $TARGET_ENV = 'production'; // fallback if no session-based environment found
}
