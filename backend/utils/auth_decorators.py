# backend/utils/auth_decorators.py (推薦的 admin_required 版本)
from functools import wraps
from flask import jsonify
from flask_jwt_extended import get_jwt_identity # 不再需要 verify_jwt_in_request 於此
from models import User

def admin_required():
    """
    自訂的管理員權限裝飾器。
    用於保護只有管理員才能訪問的路由。
    此裝飾器必須在 flask_jwt_extended 的 @jwt_required 之後使用。
    """
    def wrapper(fn):
        @wraps(fn)
        def decorator(*args, **kwargs):
            current_user_id = get_jwt_identity() # @jwt_required 確保了這裡能拿到有效的 identity
            user = User.query.get(current_user_id)

            if user and user.role == 'admin':
                return fn(*args, **kwargs)
            else:
                user_role = user.role if user else "UserNotFoundOrTokenMismatch"
                print(f"--- Admin access DENIED for user_id: {current_user_id}, role: {user_role}. Attempted to access {fn.__name__} ---")
                return jsonify({"message": "無權限訪問，需要管理員權限"}), 403
        return decorator
    return wrapper