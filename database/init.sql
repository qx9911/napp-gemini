-- database/init.sql

-- 建立資料庫 (如果不存在的話)
CREATE DATABASE IF NOT EXISTS napp_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- 使用 napp_db 資料庫
USE napp_db;

-- 建立使用者資料表 (如果不存在的話)
CREATE TABLE IF NOT EXISTS users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    username VARCHAR(255) NOT NULL UNIQUE,
    email VARCHAR(255) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL, -- 儲存雜湊後的密碼
    role ENUM('admin', 'user') DEFAULT 'user' NOT NULL,
    reset_token VARCHAR(255) NULL,       -- 密碼重設令牌
    reset_token_expires DATETIME NULL,    -- 密碼重設令牌過期時間
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- 注意：預設管理員帳號 (admin / admin123) 的插入邏輯已在 Python 後端 app.py 中處理。
-- 此處僅負責建立表結構。