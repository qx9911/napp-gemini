# backend/app.py

from flask import Flask, jsonify
from config import Config
from models import db, User # 確保 User 模型有 set_password 和 check_password 方法
from utils.email_service import mail
from flask_jwt_extended import JWTManager
from flask_cors import CORS # 導入 CORS
from routes.auth import auth_bp
from routes.users import users_bp
import os
import time

def create_app():
    app = Flask(__name__)
    app.config.from_object(Config)

    # 初始化 CORS - 這是關鍵的添加/修改位置
    # 允許來自 'http://172.20.50.102:8000' (您的 Flutter Web 前端源) 的所有 /api/* 路徑請求
    # 或者在開發時使用更寬鬆的 CORS(app)
    CORS(app, resources={r"/api/*": {"origins": "http://172.20.50.102:8000"}})
    # 或者，如果您想先用最簡單的方式測試 (允許所有來源):
    # CORS(app)

    db.init_app(app)
    mail.init_app(app)
    jwt = JWTManager(app)

    @jwt.unauthorized_loader
    def unauthorized_response(callback):
        return jsonify({"message": "缺少身份驗證令牌"}), 401
    
    @jwt.invalid_token_loader
    def invalid_token_response(callback):
        return jsonify({"message": "無效的身份驗證令牌"}), 403 # 通常用 422 Unprocessable Entity 或 401
    
    @jwt.expired_token_loader
    def expired_token_response(jwt_header, jwt_payload): # 修改了參數以匹配新版 flask_jwt_extended
        return jsonify({"message": "身份驗證令牌已過期"}), 401
    
    @jwt.revoked_token_loader
    def revoked_token_response(jwt_header, jwt_payload): # 修改了參數
        return jsonify({"message": "身份驗證令牌已被撤銷"}), 401

    # 註冊藍圖 (Blueprint)
    app.register_blueprint(auth_bp, url_prefix='/api/auth')
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
                    # 在生產環境中，這裡可能需要更健壯的錯誤處理或退出機制
                    # raise # 重新拋出異常可能會導致應用啟動失敗

        admin_username = app.config.get('ADMIN_USERNAME', 'admin') # 從環境變數或配置獲取
        admin_password = app.config.get('ADMIN_PASSWORD', 'admin123') # 從環境變數或配置獲取
        admin_email = app.config.get('ADMIN_EMAIL', 'admin@example.com') # 從環境變數或配置獲取

        if admin_username and admin_password and admin_email:
            admin_user = User.query.filter_by(username=admin_username).first()
            if not admin_user:
                try:
                    new_admin = User(name='Default Admin', username=admin_username, email=admin_email, role='admin')
                    # 重要：密碼需要被雜湊儲存
                    # 假設 User 模型中有一個 set_password 方法來處理雜湊
                    new_admin.set_password(admin_password) # 例如： self.password_hash = generate_password_hash(password)
                    db.session.add(new_admin)
                    db.session.commit()
                    print(f"已創建預設管理員帳號: {admin_username}")
                except Exception as e:
                    print(f"創建預設管理員時發生錯誤: {e}")
                    db.session.rollback() # 出錯時回滾
            else:
                print(f"預設管理員帳號 {admin_username} 已存在。")
        else:
            print("警告: 預設管理員帳號的環境變數未完全設定，將不會自動創建。")

    return app

if __name__ == '__main__':
    app = create_app()
    port = int(os.environ.get('FLASK_RUN_PORT', 5000))
    app.run(host='0.0.0.0', port=port) # 不需要重複呼叫 create_app()