<?php
/*  Axialy ▸ Admin – one-shot bootstrap for an empty Axialy_Admin DB.
    Safe to include multiple times (runs once per request).             */

namespace Axialy\AdminBootstrap;

function ensureAdminSchema(\PDO $pdo): void
{
    static $done = false;
    if ($done) { return; }

    /* ─────────── admin_users ─────────── */
    $pdo->exec("
        CREATE TABLE IF NOT EXISTS admin_users (
            id            INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
            username      VARCHAR(191) NOT NULL UNIQUE,
            password      VARCHAR(255) NOT NULL,
            email         VARCHAR(255),
            is_active     TINYINT(1)  NOT NULL DEFAULT 1,
            is_sys_admin  TINYINT(1)  NOT NULL DEFAULT 1,
            created_at    DATETIME    NOT NULL DEFAULT CURRENT_TIMESTAMP
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ");

    /* ─────────── admin_user_sessions ─────────── */
    $pdo->exec("
        CREATE TABLE IF NOT EXISTS admin_user_sessions (
            id             INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
            admin_user_id  INT UNSIGNED NOT NULL,
            session_token  CHAR(64)    NOT NULL,
            created_at     DATETIME    NOT NULL DEFAULT CURRENT_TIMESTAMP,
            expires_at     DATETIME    NOT NULL,
            INDEX (admin_user_id),
            CONSTRAINT fk_admin_user
              FOREIGN KEY (admin_user_id)
              REFERENCES admin_users(id)
              ON DELETE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ");

    $done = true;
}
