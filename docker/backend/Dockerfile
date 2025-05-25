# docker/backend/Dockerfile
FROM python:3.9-slim-buster

WORKDIR /app

# 複製 backend 目錄下的 requirements.txt 到容器的 /app/ 目錄
# 注意：COPY 指令的來源路徑是相對於 Docker build context 的。
# 如果您的 build context 是專案根目錄 (napp-gemini/)，
# 且 requirements.txt 在 napp-gemini/backend/requirements.txt，
# 則此處的 COPY backend/requirements.txt ./ 是正確的。
COPY backend/requirements.txt ./

RUN pip install --no-cache-dir -r requirements.txt

# 將 backend 目錄下的所有內容複製到容器的 /app/ 目錄
# 同樣，來源路徑相對於 build context。
COPY backend/. .

ENV FLASK_RUN_PORT=5000
ENV FLASK_APP=app.py # 確保您的 Flask 主檔案確實是 app.py，或者您在 CMD 中指定了

EXPOSE 5000

# 移除 COPY entrypoint.sh 和相關的 RUN chmod +x / RUN dos2unix (這些註解可以保留或刪除)
# 移除 ENTRYPOINT 指令 (這些註解可以保留或刪除)

# 更明確地指定 Flask 應用程式的載入方式
# 假設您的 app.py 中有一個名為 create_app 的工廠函式
CMD ["flask", "--app", "app:create_app", "run", "--host=0.0.0.0", "--port=5000"]