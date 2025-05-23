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
    password VARCHAR(255) NOT NULL, -- 儲存雜湊後的密碼
    role ENUM('admin', 'user') DEFAULT 'user' NOT NULL,
    resetToken VARCHAR(255) NULL,       -- 密碼重設令牌
    resetTokenExpires DATETIME NULL,    -- 密碼重設令牌過期時間
    createdAt DATETIME DEFAULT CURRENT_TIMESTAMP,
    updatedAt DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- 插入預設管理員帳號 (如果不存在的話)
-- 注意：這裡的密碼 'admin123' 應該是經過 bcrypt 雜湊後的字串
-- 您需要在後端啟動時，由 Node.js 程式碼檢查並插入這個預設帳號
-- 所以這裡的 SQL 腳本只負責創建表結構，不直接插入預設密碼，
-- 以避免硬編碼雜湊值，並確保密碼由 Node.js 的 bcrypt 處理。

-- 範例：如果您想在 SQL 腳本中直接插入預設管理員 (不推薦，因為密碼是硬編碼的雜湊值)
-- INSERT IGNORE INTO users (name, username, email, password, role) VALUES
-- ('Default Admin', 'admin', 'admin@example.com', '$2b$10$YOUR_BCRYPT_HASH_FOR_ADMIN123', 'admin');
-- 請替換 '$2b$10$YOUR_BCRYPT_HASH_FOR_ADMIN123' 為 'admin123' 的 bcrypt 雜湊值
-- 更好的做法是讓後端 (server.js) 處理預設管理員的創建，就像我們在 server.js 中所做的那樣。

