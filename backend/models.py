# backend/models.py

from flask_sqlalchemy import SQLAlchemy
from werkzeug.security import generate_password_hash, check_password_hash
from sqlalchemy.sql import func # 用於資料庫層面的預設時間戳
# import datetime # 如果使用 datetime.datetime.utcnow，則需要它

# 初始化 SQLAlchemy 實例，但不在這裡綁定 Flask app，而是在 app.py 中進行
db = SQLAlchemy()

class User(db.Model):
    __tablename__ = 'users' # 指定資料表名稱

    id = db.Column(db.Integer, primary_key=True, autoincrement=True)
    name = db.Column(db.String(255), nullable=False)
    username = db.Column(db.String(255), unique=True, nullable=False)
    email = db.Column(db.String(255), unique=True, nullable=False)
    password_hash = db.Column(db.String(255), nullable=False) # 儲存雜湊後的密碼
    role = db.Column(db.Enum('admin', 'user', name='user_roles_enum'), default='user', nullable=False) # 為 ENUM 指定一個名稱
    reset_token = db.Column(db.String(255), nullable=True)
    reset_token_expires = db.Column(db.DateTime, nullable=True)
    
    # 使用 SQLAlchemy 的 func.now() 或 server_default 來處理時間戳，由資料庫生成
    created_at = db.Column(db.DateTime, server_default=func.now())
    updated_at = db.Column(db.DateTime, server_default=func.now(), onupdate=func.now())

    def __repr__(self):
        return f'<User {self.username}>'

    # 設定密碼 (自動雜湊)
    @property
    def password(self):
        # 這個 getter 通常不直接使用，或者可以不定義，以防止嘗試讀取 'password' 屬性
        raise AttributeError('password is not a readable attribute and should not be accessed directly')

    @password.setter
    def password(self, password_plaintext):
        if not password_plaintext:
            raise ValueError("Password cannot be empty or None")
        self.password_hash = generate_password_hash(password_plaintext)

    # 驗證密碼
    def verify_password(self, password_plaintext):
        if not self.password_hash or not password_plaintext: # 確保兩者都存在
            return False
        return check_password_hash(self.password_hash, password_plaintext)

    # 序列化為字典 (用於 API 回應)
    def to_dict(self):
        return {
            'id': self.id,
            'name': self.name,
            'username': self.username,
            'email': self.email,
            'role': self.role,
            'created_at': self.created_at.isoformat() if self.created_at else None,
            'updated_at': self.updated_at.isoformat() if self.updated_at else None
            # 確保不返回 password_hash 或其他敏感資訊
        }

# 您可以在這裡定義其他的模型，例如與 NAPP 系統中特定 App 相關的模型
# class YourAppModel(db.Model):
#     __tablename__ = 'your_app_table_name'
#     id = db.Column(db.Integer, primary_key=True)
#     # ... 其他欄位 ...