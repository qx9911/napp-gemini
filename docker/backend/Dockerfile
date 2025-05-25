<<<<<<< HEAD
# docker/backend/Dockerfile

# 使用 Node.js 18 的 Alpine Linux 版本作為基礎映像檔
# Alpine 版本更小，適合用於生產環境
FROM node:18-alpine

# 設定工作目錄為 /app
# 所有的應用程式檔案都將會放在這個目錄下
WORKDIR /app

# 將 package.json 和 package-lock.json (如果存在) 複製到工作目錄
# 這樣可以利用 Docker 的層快取，如果依賴沒有改變，就不會重新執行 npm install
COPY backend/package*.json ./

# 安裝 Node.js 依賴
# --omit=dev 參數表示不安裝開發依賴，只安裝生產依賴，減少映像檔大小
RUN npm install --omit=dev

# 將後端應用程式的所有程式碼複製到工作目錄
# 注意：這裡複製的是整個 backend 目錄的內容
COPY backend/. .

# 設定環境變數 PORT，這是後端伺服器監聽的端口
# 可以透過 Docker Compose 或 Docker run 命令覆寫
ENV PORT=3000

# 暴露端口 3000，表示容器內的應用程式將監聽此端口
EXPOSE 3000

# 定義容器啟動時執行的命令
# 運行 npm start，它會執行 package.json 中定義的 "start" 腳本 (node server.js)
CMD ["npm", "start"]

=======
FROM python:3.9-slim-buster

WORKDIR /app

COPY backend/requirements.txt ./

RUN pip install --no-cache-dir -r requirements.txt

COPY backend/. .

ENV FLASK_RUN_PORT=5000
ENV FLASK_APP=app.py

EXPOSE 5000

# 移除 COPY entrypoint.sh 和相關的 RUN chmod +x / RUN dos2unix
# 移除 ENTRYPOINT 指令

# 更明確地指定 Flask 應用程式的載入方式
CMD ["flask", "--app", "app:create_app", "run", "--host=0.0.0.0", "--port=5000"]
>>>>>>> 2fde534 (Add comprehensive .gitignore and initial project files)
