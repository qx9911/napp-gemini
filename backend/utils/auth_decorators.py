# backend/utils/auth_decorators.py

from functools import wraps
from flask import request, jsonify # 導入 request 以便檢查 request.method
from flask_jwt_extended import get_jwt_identity
# 假設 User 模型在 backend/models.py 中，並且 Python 的導入路徑已正確設定
# 如果 models.py 與 utils 在同一 backend/ 目錄下，可以直接 from models import User
from models import User

def admin_required():
    """
    自訂的管理員權限裝飾器。
    用於保護只有管理員才能訪問的路由。
    此裝飾器應在 flask_jwt_extended 的 @jwt_required 之後使用。
    """
    def wrapper(fn):
        @wraps(fn)
        def decorator(*args, **kwargs):
            # 對於 OPTIONS 預檢請求，瀏覽器不會發送 Authorization 標頭，
            # 也不期望進行身份驗證或授權檢查。
            # Flask-CORS 應該會處理 OPTIONS 請求並返回適當的 CORS 標頭。
            # 此處添加判斷是為了確保如果 OPTIONS 請求意外地執行到此裝飾器，
            # 它不會因為嘗試 get_jwt_identity() 而出錯。
            # 更理想的情況是，@jwt_required() 裝飾器（來自 flask-jwt-extended）
            # 和 Flask-CORS 會正確處理 OPTIONS 請求，使其不執行此處的邏輯。
            if request.method == 'OPTIONS':
                # 通常 Flask-CORS 會在請求到達視圖函數之前就回應 OPTIONS 請求。
                # 如果執行到這裡，直接調用原函數可能不是最佳選擇，
                # 因為原函數可能不是為處理 OPTIONS 設計的。
                # 但如果 Flask-CORS 期望 OPTIONS 請求能 "通過" 裝飾器鏈到達一個能處理它的點，
                # 或者我們期望 Flask-CORS 已經處理完並返回，這個檢查可以防止後續錯誤。
                # 為了安全，如果 OPTIONS 請求到達這裡，可能最好是讓 Flask-CORS 處理。
                # 但如果裝飾器順序導致 OPTIONS 執行到這裡，我們需要避免 get_jwt_identity()。
                # 實際上，如果 @jwt_required() 在此之前，它應該已經正確處理了 OPTIONS。
                # 這個判斷更多的是一種防禦性措施。
                return fn(*args, **kwargs) # 或者，如果確認 Flask-CORS 會處理，這裡可以不執行任何操作或提前返回一個標準響應。


            # 假設 @jwt_required() 已經先執行並驗證了 JWT，所以這裡可以安全地獲取 identity。
            current_user_id = get_jwt_identity()
            if current_user_id is None:
                # 這種情況理論上不應該發生，如果 @jwt_required() 正確工作的話。
                # 但作為額外檢查。
                print(f"--- Admin access DENIED: No JWT identity found after @jwt_required. This is unexpected. ---")
                return jsonify({"message": "未授權的訪問：缺少身份資訊"}), 401

            user = User.query.get(current_user_id)

            if user and user.role == 'admin':
                return fn(*args, **kwargs)
            else:
                user_role_for_log = user.role if user else "UserNotFoundInDB"
                print(f"--- Admin access DENIED for user_id: {current_user_id}, role: {user_role_for_log}. Attempted to access: {request.endpoint} ---")
                return jsonify({"message": "無權限訪問，需要管理員權限"}), 403
        return decorator
    return wrapper

# 自訂的 jwt_required() 裝飾器已被移除。
# 請在您的路由檔案中直接使用 from flask_jwt_extended import jwt_required。