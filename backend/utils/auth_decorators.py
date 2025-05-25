# backend/utils/auth_decorators.py

from functools import wraps
from flask import request, jsonify
from flask_jwt_extended import verify_jwt_in_request, get_jwt_identity
from models import User # 修正: from backend.models -> from models

def jwt_required():
    """
    自訂的 JWT 認證裝飾器。
    用於保護需要登入才能訪問的路由。
    """
    def wrapper(fn):
        @wraps(fn)
        def decorator(*args, **kwargs):
            try:
                verify_jwt_in_request() # 驗證 JWT Access Token
                return fn(*args, **kwargs)
            except Exception as e:
                # Flask-JWT-Extended 錯誤處理會在此處拋出異常
                # 但為了一致性，可以在這裡捕捉並返回自訂訊息
                return jsonify({"message": "未提供身份驗證令牌或令牌無效", "error": str(e)}), 401
        return decorator
    return wrapper

def admin_required():
    """
    自訂的管理員權限裝飾器。
    用於保護只有管理員才能訪問的路由。
    此裝飾器必須在 jwt_required() 之後使用。
    """
    def wrapper(fn):
        @wraps(fn)
        def decorator(*args, **kwargs):
            # jwt_required() 已經驗證過 JWT
            # 這裡只獲取身份並檢查角色
            current_user_id = get_jwt_identity() # 獲取當前 JWT 中的使用者 ID

            user = User.query.get(current_user_id) # 從資料庫中獲取使用者物件

            if user and user.role == 'admin':
                return fn(*args, **kwargs)
            else:
                return jsonify({"message": "無權限訪問，需要管理員權限"}), 403
        return decorator
    return wrapper

