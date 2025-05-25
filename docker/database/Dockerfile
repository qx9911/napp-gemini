<<<<<<< HEAD
# docker/database/Dockerfile

# 使用 MySQL 8.0 官方映像檔作為基礎映像檔
FROM mysql:8.0

# 設定 MySQL 相關的環境變數
# 這些變數將用於初始化 MySQL 服務和創建預設資料庫/使用者
# 注意：這些是預設值，在 docker-compose.yml 中可以覆寫
ENV MYSQL_ROOT_PASSWORD=your_root_password_here # MySQL root 帳號的密碼
ENV MYSQL_DATABASE=napp_db                     # 預設建立的資料庫名稱
ENV MYSQL_USER=napp_user                       # 預設建立的使用者名稱
ENV MYSQL_PASSWORD=napp_password               # 預設建立的使用者密碼

# 將本地的 init.sql 腳本複製到 Docker 映像檔的指定目錄
# /docker-entrypoint-initdb.d/ 是 MySQL 官方映像檔在啟動時會自動執行 .sql 腳本的目錄
COPY database/init.sql /docker-entrypoint-initdb.d/

# 暴露 MySQL 預設端口 3306
EXPOSE 3306

# CMD 指令由基礎映像檔 (mysql:8.0) 提供，無需在此處額外指定
# 基礎映像檔的 ENTRYPOINT 會自動處理 MySQL 服務的啟動和 init.sql 的執行

=======
    FROM mysql:8.0

    COPY database/init.sql /docker-entrypoint-initdb.d/

    EXPOSE 3306
    
>>>>>>> 2fde534 (Add comprehensive .gitignore and initial project files)
