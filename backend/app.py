# backend/app.py

from flask import Flask, jsonify
from config import Config
from models import db, User
from utils.email_service import mail
from flask_jwt_extended import JWTManager
from routes.auth import auth_bp
from routes.users import users_bp
import os
import time

def create_app():
    app = Flask(__name__)
    app.config.from_object(Config)
    db.init_app(app)
    mail.init_app(app)
    jwt = JWTManager(app)

    @jwt.unauthorized_loader
    def unauthorized_response(callback):
        return jsonify({"message": "缺少身份驗證令牌"}), 401
    @jwt.invalid_token_loader
    def invalid_token_response(callback):
        return jsonify({"message": "無效的身份驗證令牌"}), 403
    @jwt.expired_token_loader
    def expired_token_response(callback):
        return jsonify({"message": "身份驗證令牌已過期"}), 401
    @jwt.revoked_token_loader
    def revoked_token_response(callback):
        return jsonify({"message": "身份驗證令牌已被撤銷"}), 401

    # 註冊藍圖 (Blueprint)
    # 確保這裡的 url_prefix 與前端和 Nginx 的代理路徑匹配
    app.register_blueprint(auth_bp, url_prefix='/api/auth') # 前端請求的是 /api/auth/login
    app.register_blueprint(users_bp, url_prefix='/api/users')
    
    @app.route('/')
    def index():
        return jsonify({"message": "NAPP System Backend API is running!"}), 200

    with app.app_context():
        max_retries = 30
        retry_delay = 5
        for i in range(max_retries):
            try:
                print(f"嘗試連接資料庫並創建資料表 (第 {i+1}/{max_retries} 次)...")
                db.create_all()
                print("資料庫連線成功並已創建所有資料表！")
                break
            except Exception as e:
                print(f"資料庫連線失敗: {e}")
                if i < max_retries - 1:
                    print(f"等待 {retry_delay} 秒後重試...")
                    time.sleep(retry_delay)
                else:
                    print("達到最大重試次數，無法連接資料庫。")
                    raise

        admin_username = app.config.get('ADMIN_USERNAME')
        admin_password = app.config.get('ADMIN_PASSWORD')
        admin_email = app.config.get('ADMIN_EMAIL')

        if admin_username and admin_password and admin_email:
            admin_user = User.query.filter_by(username=admin_username).first()
            if not admin_user:
                new_admin = User(name='Default Admin', username=admin_username, email=admin_email, role='admin')
                new_admin.password = admin_password
                db.session.add(new_admin)
                db.session.commit()
                print(f"已創建預設管理員帳號: {admin_username}")
            else:
                print(f"預設管理員帳號 {admin_username} 已存在。")
        else:
            print("警告: 預設管理員帳號的環境變數未完全設定，將不會自動創建。")

    return app

if __name__ == '__main__':
    app = create_app()
    port = int(os.environ.get('FLASK_RUN_PORT', 5000))
    app.run(host='0.0.0.0', port=port)

