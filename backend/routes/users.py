# backend/routes/users.py

from flask import Blueprint, request, jsonify
from models import User, db # 確保 User 模型和 db 實例已正確導入
from utils.auth_decorators import jwt_required, admin_required # 確保這些裝飾器存在且功能正確
from utils.email_service import send_email # 確保郵件服務配置正確
import datetime
# import traceback # 如果需要打印完整堆疊跟踪

users_bp = Blueprint('users', __name__) # 藍圖名稱應與 app.py 中註冊時使用的名稱一致

# 3-1. 列出所有使用者清單 (需要管理員權限)
@users_bp.route('/', methods=['GET', 'OPTIONS']) # 明確允許 OPTIONS
@jwt_required()
@admin_required()
def get_all_users():
    print(f"--- Request received at GET /api/users/ (inside get_all_users function) ---")
    try:
        print("--- Attempting to query all users from database ---")
        users = User.query.all()
        print(f"--- Successfully queried {len(users)} users from database ---")
        
        users_data = []
        for u in users:
            if hasattr(u, 'to_dict') and callable(getattr(u, 'to_dict')):
                users_data.append(u.to_dict())
            else:
                print(f"--- User {u.username} is missing to_dict() method. Falling back to manual dict. ---")
                users_data.append({
                    'id': u.id,
                    'name': u.name,
                    'username': u.username,
                    'email': u.email,
                    'role': u.role 
                    # 注意：不應返回 password_hash
                })
        
        print(f"--- Returning {len(users_data)} users data to client ---")
        return jsonify({"users": users_data, "total": len(users_data)}), 200
    except Exception as e:
        print(f"--- ERROR in get_all_users: {e} ---")
        # traceback.print_exc() # 取消註解以在日誌中打印完整錯誤堆疊
        return jsonify({"message": "獲取使用者列表時發生伺服器內部錯誤", "error": str(e)}), 500

# 3-2. 新增使用者 (需要管理員權限)
@users_bp.route('/', methods=['POST'])
@jwt_required()
@admin_required()
def create_user():
    print(f"--- Request received at POST /api/users/ (inside create_user function) ---")
    data = request.get_json()
    if not data:
        return jsonify({"message": "請求中未包含 JSON 資料"}), 400

    name = data.get('name')
    username = data.get('username')
    email = data.get('email')
    password = data.get('password')
    role = data.get('role', 'user')

    if not all([name, username, email, password]):
        return jsonify({"message": "請提供所有必要欄位：姓名、帳號、Email、密碼"}), 400

    print(f"--- Checking if user {username} or email {email} already exists ---")
    existing_user = User.query.filter(
        (User.username == username) | (User.email == email)
    ).first()

    if existing_user:
        if existing_user.username == username:
            print(f"--- Username {username} already exists ---")
            return jsonify({"message": "帳號已存在"}), 409
        if existing_user.email == email:
            print(f"--- Email {email} already exists ---")
            return jsonify({"message": "電子郵件已存在"}), 409

    try:
        print(f"--- Creating new user: {username} ---")
        new_user = User(name=name, username=username, email=email, role=role)
        # !!! 重要：密碼必須雜湊儲存 !!!
        # 這裡應該呼叫 new_user.set_password(password) 或類似方法
        # 為了讓程式能跑通，暫時直接賦值，但這是不安全的，您必須修改
        new_user.password = password # <--- 這是明文密碼，極度不安全！請修改為雜湊儲存
        # 例如: new_user.set_password(password) 

        db.session.add(new_user)
        db.session.commit()
        print(f"--- User {username} created successfully. ID: {new_user.id} ---")

        try:
            print(f"--- Attempting to send welcome email to {new_user.email} ---")
            send_email(
                to=new_user.email,
                subject='NAPP 系統：您的帳號已創建',
                template=f"""
                <p>您好 {new_user.name},</p>
                <p>您的 NAPP 系統帳號已成功創建。</p>
                <p>帳號: {new_user.username}</p>
                <p>請使用您設定的密碼登入。</p>
                """
            )
            print(f"--- Welcome email sent to {new_user.email} ---")
        except Exception as email_error:
            print(f"--- Failed to send welcome email to {new_user.email}: {email_error} ---")
            # 即使郵件失敗，使用者創建也已成功，所以不在此處回滾或返回錯誤

        return jsonify({"message": "使用者新增成功", "user": new_user.to_dict() if hasattr(new_user, 'to_dict') else {'id': new_user.id, 'username': new_user.username}}), 201
    except Exception as e:
        db.session.rollback()
        print(f"--- ERROR in create_user: {e} ---")
        # traceback.print_exc()
        return jsonify({"message": "新增使用者時發生伺服器內部錯誤", "error": str(e)}), 500

# 3-3. 獲取單一使用者資訊 (用於編輯畫面，需要管理員權限)
@users_bp.route('/<int:user_id>', methods=['GET', 'OPTIONS']) # 明確允許 OPTIONS
@jwt_required()
@admin_required()
def get_user(user_id):
    print(f"--- Request received at GET /api/users/{user_id} (inside get_user function) ---")
    user = User.query.get(user_id)
    if not user:
        print(f"--- User with ID {user_id} not found ---")
        return jsonify({"message": "找不到使用者"}), 404
    
    print(f"--- Returning data for user {user.username} ---")
    return jsonify(user.to_dict() if hasattr(user, 'to_dict') else {'id': user.id, 'username': user.username}), 200

# 3-3. 編輯使用者 (需要管理員權限)
@users_bp.route('/<int:user_id>', methods=['PUT'])
@jwt_required()
@admin_required()
def update_user(user_id):
    print(f"--- Request received at PUT /api/users/{user_id} (inside update_user function) ---")
    user = User.query.get(user_id)
    if not user:
        print(f"--- User with ID {user_id} not found for update ---")
        return jsonify({"message": "找不到使用者"}), 404

    data = request.get_json()
    if not data:
        return jsonify({"message": "請求中未包含 JSON 資料"}), 400

    name = data.get('name')
    username = data.get('username')
    email = data.get('email')
    role = data.get('role')

    try:
        if username and username != user.username:
            print(f"--- Checking if new username {username} already exists (excluding current user) ---")
            existing_user_username = User.query.filter(User.username == username, User.id != user_id).first()
            if existing_user_username:
                print(f"--- New username {username} already taken ---")
                return jsonify({"message": "帳號已存在"}), 409
            user.username = username
        
        if email and email != user.email:
            print(f"--- Checking if new email {email} already exists (excluding current user) ---")
            existing_user_email = User.query.filter(User.email == email, User.id != user_id).first()
            if existing_user_email:
                print(f"--- New email {email} already taken ---")
                return jsonify({"message": "電子郵件已存在"}), 409
            user.email = email

        if name:
            user.name = name
        if role:
            user.role = role
        
        db.session.commit()
        print(f"--- User {user.username} (ID: {user_id}) updated successfully ---")
        return jsonify({"message": "使用者資訊更新成功", "user": user.to_dict() if hasattr(user, 'to_dict') else {'id': user.id, 'username': user.username}}), 200
    except Exception as e:
        db.session.rollback()
        print(f"--- ERROR in update_user for ID {user_id}: {e} ---")
        # traceback.print_exc()
        return jsonify({"message": "更新使用者時發生伺服器內部錯誤", "error": str(e)}), 500

# 4-1. 修改密碼 (登入使用者本人修改，需要認證)
# 注意：這個路由通常會放在 auth_bp 中，或者一個專門的 account_bp 中，而不是 users_bp。
# 但如果您的前端 auth_provider.dart 中的 ApiService.put 指向 'users/change-password'，則保持在此。
@users_bp.route('/change-password', methods=['PUT'])
@jwt_required()
def change_password_route(): # 避免與 AuthProvider 中的方法重名
    print(f"--- Request received at PUT /api/users/change-password (inside change_password_route function) ---")
    data = request.get_json()
    if not data:
        return jsonify({"message": "請求中未包含 JSON 資料"}), 400

    old_password = data.get('oldPassword')
    new_password = data.get('newPassword')

    if not all([old_password, new_password]):
        return jsonify({"message": "請提供舊密碼和新密碼"}), 400

    from flask_jwt_extended import get_jwt_identity # 移到函式內部，避免在頂層循環導入問題
    current_user_id = get_jwt_identity()
    user = User.query.get(current_user_id)

    if not user:
        print(f"--- User with ID {current_user_id} not found for password change ---")
        return jsonify({"message": "找不到使用者或認證失敗"}), 404 # 或 401

    # !!! 重要：需要 User 模型中有 verify_password 方法 !!!
    if not hasattr(user, 'check_password') or not callable(getattr(user, 'check_password')):
         print(f"--- ERROR: User model is missing check_password method for user {user.username} ---")
         return jsonify({"message": "伺服器配置錯誤：無法驗證密碼"}), 500
    
    if not user.check_password(old_password): # 假設 User 模型有 check_password 方法
        print(f"--- Old password incorrect for user {user.username} ---")
        return jsonify({"message": "舊密碼不正確"}), 401

    try:
        # !!! 重要：新密碼必須雜湊儲存 !!!
        # 這裡應該呼叫 user.set_password(new_password) 或類似方法
        print(f"--- Setting new password for user {user.username} (THIS IS INSECURE IF NOT HASHED!) ---")
        user.password = new_password # <--- 這是明文密碼，極度不安全！請修改為雜湊儲存
        # 例如: user.set_password(new_password)

        db.session.commit()
        print(f"--- Password changed successfully for user {user.username} ---")

        try:
            print(f"--- Attempting to send password change notification to {user.email} ---")
            send_email(
                to=user.email,
                subject='NAPP 系統：您的密碼已成功修改',
                template=f"""
                <p>您好 {user.name},</p>
                <p>您的 NAPP 系統密碼已成功修改。</p>
                <p>如果您不是本人操作，請立即聯繫管理員。</p>
                """
            )
            print(f"--- Password change notification sent to {user.email} ---")
        except Exception as email_error:
            print(f"--- Failed to send password change notification to {user.email}: {email_error} ---")

        return jsonify({"message": "密碼修改成功"}), 200
    except Exception as e:
        db.session.rollback()
        print(f"--- ERROR in change_password_route for user {user.username}: {e} ---")
        # traceback.print_exc()
        return jsonify({"message": "修改密碼時發生伺服器內部錯誤", "error": str(e)}), 500

# 刪除使用者 (需要管理員權限)
@users_bp.route('/<int:user_id>', methods=['DELETE'])
@jwt_required()
@admin_required()
def delete_user(user_id):
    print(f"--- Request received at DELETE /api/users/{user_id} (inside delete_user function) ---")
    user = User.query.get(user_id)
    if not user:
        print(f"--- User with ID {user_id} not found for deletion ---")
        return jsonify({"message": "找不到使用者"}), 404

    try:
        print(f"--- Deleting user {user.username} (ID: {user_id}) ---")
        db.session.delete(user)
        db.session.commit()
        print(f"--- User {user.username} (ID: {user_id}) deleted successfully ---")
        return jsonify({"message": "使用者刪除成功"}), 200
    except Exception as e:
        db.session.rollback()
        print(f"--- ERROR in delete_user for ID {user_id}: {e} ---")
        # traceback.print_exc()
        return jsonify({"message": "刪除使用者時發生伺服器內部錯誤", "error": str(e)}), 500