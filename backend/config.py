# backend/config.py

import os
from dotenv import load_dotenv

# 載入專案根目錄的 .env 檔案中的環境變數
# 確保 .env 檔案位於 /opt/napp-gemini/
load_dotenv(os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '.env'))

class Config:
    # Flask 應用程式的密鑰，用於保護會話 (sessions) 和其他安全相關操作
    SECRET_KEY = os.environ.get('SECRET_KEY') or 'a_very_secret_key_that_should_be_changed'
    # Flask 運行模式 (development, production, testing)
    FLASK_ENV = os.environ.get('FLASK_ENV') or 'development'

    # 資料庫連線設定 (使用 PyMySQL 驅動)
    # 格式: mysql+pymysql://user:password@host:port/database_name
    SQLALCHEMY_DATABASE_URI = (
        f"mysql+pymysql://{os.environ.get('MYSQL_USER')}:"
        f"{os.environ.get('MYSQL_PASSWORD')}@{os.environ.get('DB_HOST', 'db')}:3306/"
        f"{os.environ.get('MYSQL_DATABASE')}"
    )
    SQLALCHEMY_TRACK_MODIFICATIONS = False # 禁用 SQLAlchemy 事件追蹤，減少記憶體消耗

    # Flask-JWT-Extended 配置
    JWT_SECRET_KEY = os.environ.get('JWT_SECRET_KEY') or 'super_secret_jwt_key_that_should_be_changed'
    JWT_ACCESS_TOKEN_EXPIRES = int(os.environ.get('JWT_ACCESS_TOKEN_EXPIRES', 3600)) # 預設 1 小時
    JWT_REFRESH_TOKEN_EXPIRES = int(os.environ.get('JWT_REFRESH_TOKEN_EXPIRES', 86400)) # 預設 1 天

    # Flask-Mail 郵件發送設定
    MAIL_SERVER = os.environ.get('MAIL_SERVER')
    MAIL_PORT = int(os.environ.get('MAIL_PORT', 587))
    MAIL_USE_TLS = os.environ.get('MAIL_USE_TLS', 'True').lower() == 'true'
    MAIL_USE_SSL = os.environ.get('MAIL_USE_SSL', 'False').lower() == 'true'
    MAIL_USERNAME = os.environ.get('MAIL_USERNAME')
    MAIL_PASSWORD = os.environ.get('MAIL_PASSWORD')
    MAIL_DEFAULT_SENDER = os.environ.get('MAIL_USERNAME') # 預設發件人與用戶名相同

    # 前端應用程式 URL (用於生成密碼重設連結)
    FRONTEND_URL = os.environ.get('FRONTEND_URL') or 'http://localhost:8000'

    # 預設管理員帳號 (由 server.py 讀取並創建)
    ADMIN_USERNAME = os.environ.get('ADMIN_USERNAME')
    ADMIN_PASSWORD = os.environ.get('ADMIN_PASSWORD')
    ADMIN_EMAIL = os.environ.get('ADMIN_EMAIL')

