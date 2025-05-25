# /opt/napp-gemini/docker/database/Dockerfile

# 使用 MySQL 8.0 官方映像檔作為基礎映像檔
FROM mysql:8.0

# 將本地的 init.sql 腳本複製到 Docker 映像檔的指定目錄
# /docker-entrypoint-initdb.d/ 是 MySQL 官方映像檔在啟動時會自動執行 .sql 腳本的目錄
# COPY 指令的來源路徑是相對於 Docker build context 的。
# 在您的 docker-compose.yml 中，db 服務的 build context 是 ../ (即專案根目錄 napp-gemini/)
# 因此，這裡的 database/init.sql 指的是 napp-gemini/database/init.sql
COPY database/init.sql /docker-entrypoint-initdb.d/

# 暴露 MySQL 預設端口 3306
EXPOSE 3306

# CMD 指令由基礎映像檔 (mysql:8.0) 提供，無需在此處額外指定。