<?php
// /home/i17z4s936h3j/public_html/admin.axiaba.com/includes/db_connection.php

use Axialy\AdminConfig\Config;
require_once __DIR__ . '/Config.php';
try {
    $cfg = Config::getInstance();
    $dsn = "mysql:host={$cfg->get('db_host')};dbname={$cfg->get('db_name')};charset=utf8mb4";
    $pdo = new PDO($dsn, $cfg->get('db_user'), $cfg->get('db_password'));
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
} catch (Exception $e) {
    error_log('Admin DB connection failed: ' . $e->getMessage());
    die('Database error (Admin). Please try again later.');
}
