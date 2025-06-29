<?php
// /home/i17z4s1xj1hd/public_html/includes/admin_auth.php

session_start();

// Fetching secrets from environment variables
$DEF_USER     = getenv('ADMIN_DEFAULT_USER');
$DEF_EMAIL    = getenv('ADMIN_DEFAULT_EMAIL');
$DEF_PASSWORD = getenv('ADMIN_DEFAULT_PASSWORD');

if (!$DEF_USER || !$DEF_EMAIL || !$DEF_PASSWORD) {
    error_log('Admin auth credentials are not properly set in environment variables.');
    exit('Configuration error.');
}

if (isset($_POST['username']) && isset($_POST['password'])) {
    $username = $_POST['username'];
    $password = $_POST['password'];

    if ($username === $DEF_USER && $password === $DEF_PASSWORD) {
        $_SESSION['authenticated'] = true;
        $_SESSION['user'] = $DEF_USER;
        header("Location: dashboard.php");
        exit;
    } else {
        header("Location: login.php?error=Invalid credentials");
        exit;
    }
}

if (!isset($_SESSION['authenticated']) || $_SESSION['authenticated'] !== true) {
    header("Location: login.php");
    exit;
}
