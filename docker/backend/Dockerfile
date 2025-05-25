# /opt/napp-gemini/docker/backend/Dockerfile
FROM python:3.9-slim-buster

WORKDIR /app

COPY backend/requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt
COPY backend/. .

# 如果您有需要在 Dockerfile 中設定的環境變數，可以在這裡添加
# 例如：
# ENV FLASK_APP=app.py
# ENV FLASK_RUN_PORT=5000
# 但通常這些會在 .env 檔案中管理，並透過 docker-compose.yml 的 env_file 傳入

EXPOSE 5000 # 假設 Flask 監聽 5000

# 恢復正常的 Flask 啟動命令
# 確保 app:create_app 與您 Flask 應用的實際入口點和工廠函式名稱一致
CMD ["flask", "--app", "app:create_app", "run", "--host=0.0.0.0", "--port=5000"]