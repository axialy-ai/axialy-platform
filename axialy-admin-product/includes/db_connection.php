<?php
/* axialy-admin-product/includes/db_connection.php
   Unified DB connector – always use AdminDBConfig */

require_once __DIR__ . '/AdminDBConfig.php';
use Axialy\AdminConfig\AdminDBConfig;

try {
    $pdo = AdminDBConfig::getInstance()->getPdo();
} catch (\Throwable $e) {
    error_log('Admin DB connection failed: ' . $e->getMessage());
    http_response_code(500);
    die('Database error (Admin). Please try again later.');
}
