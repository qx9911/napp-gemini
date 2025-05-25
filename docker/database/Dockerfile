# /opt/napp-gemini/docker/database/Dockerfile
FROM mysql:8.0

# 將本地的 init.sql 腳本複製到 Docker 映像檔的指定目錄
# COPY 指令的來源路徑是相對於 Docker build context 的。
# 在您的 docker-compose.yml 中，db 服務的 build context 是 ../ (即專案根目錄 napp-gemini/)
# 因此，這裡的 database/init.sql 指的是 napp-gemini/database/init.sql
COPY database/init.sql /docker-entrypoint-initdb.d/

EXPOSE 3306