# backend/routes/users.py

from flask import Blueprint, request, jsonify, current_app
from models import User, db
from flask_jwt_extended import jwt_required, get_jwt_identity # 從 flask_jwt_extended 導入
from utils.auth_decorators import admin_required
from utils.email_service import send_email
import datetime
# import traceback

users_bp = Blueprint('users', __name__)

# 3-1. 列出所有使用者清單 (需要管理員權限)
@users_bp.route('/', methods=['GET', 'OPTIONS'])
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
                    'id': u.id, 'name': u.name, 'username': u.username,
                    'email': u.email, 'role': u.role
                })
        
        print(f"--- Returning {len(users_data)} users data to client ---")
        return jsonify({"users": users_data, "total": len(users_data)}), 200
    except Exception as e:
        print(f"--- ERROR in get_all_users: {e} ---")
        # traceback.print_exc()
        return jsonify({"message": "獲取使用者列表時發生伺服器內部錯誤", "error": str(e)}), 500

# 3-2. 新增使用者 (需要管理員權限)
@users_bp.route('/', methods=['POST', 'OPTIONS']) # <--- 添加 OPTIONS
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
            return jsonify({"message": "帳號已存在"}), 409
        if existing_user.email == email:
            return jsonify({"message": "電子郵件已存在"}), 409

    try:
        print(f"--- Creating new user: {username} ---")
        new_user = User(name=name, username=username, email=email, role=role)
        new_user.set_password(password) # <--- 使用 set_password 進行雜湊

        db.session.add(new_user)
        db.session.commit()
        print(f"--- User {username} created successfully. ID: {new_user.id} ---")

        try:
            send_email(to=new_user.email, subject='NAPP 系統：您的帳號已創建', template=f"帳號 {new_user.username} 已創建。")
        except Exception as email_e:
            print(f"--- Failed to send account creation email to {new_user.email}: {email_e} ---")

        return jsonify({"message": "使用者新增成功", "user": new_user.to_dict()}), 201
    except Exception as e:
        db.session.rollback()
        print(f"--- ERROR in create_user: {e} ---")
        # traceback.print_exc()
        return jsonify({"message": "新增使用者時發生伺服器內部錯誤", "error": str(e)}), 500

# 3-3. 獲取單一使用者資訊
@users_bp.route('/<int:user_id>', methods=['GET', 'OPTIONS'])
@jwt_required()
@admin_required()
def get_user(user_id):
    print(f"--- Request received at GET /api/users/{user_id} (inside get_user function) ---")
    user = User.query.get(user_id)
    if not user:
        return jsonify({"message": "找不到使用者"}), 404
    return jsonify(user.to_dict()), 200

# 3-3. 編輯使用者
@users_bp.route('/<int:user_id>', methods=['PUT', 'OPTIONS']) # <--- 添加 OPTIONS
@jwt_required()
@admin_required()
def update_user(user_id):
    print(f"--- Request received at PUT /api/users/{user_id} (inside update_user function) ---")
    user = User.query.get(user_id)
    if not user:
        return jsonify({"message": "找不到使用者"}), 404

    data = request.get_json()
    if not data:
        return jsonify({"message": "請求中未包含 JSON 資料"}), 400
    
    print(f"--- Attempting to update user ID: {user_id} with data: {data} ---")
    
    name = data.get('name')
    email = data.get('email')
    role = data.get('role')

    try:
        if email and email != user.email:
            existing_user_email = User.query.filter(User.email == email, User.id != user_id).first()
            if existing_user_email:
                return jsonify({"message": "電子郵件已存在"}), 409
            user.email = email
            print(f"--- User ID: {user_id}, email WILL BE updated to: {email} ---")

        if name:
            user.name = name
            print(f"--- User ID: {user_id}, name WILL BE updated to: {name} ---")
        if role:
            user.role = role
            print(f"--- User ID: {user_id}, role WILL BE updated to: {role} ---")
        
        db.session.commit()
        print(f"--- User {user.username} (ID: {user_id}) update committed to DB successfully. New name: {user.name} ---")
        return jsonify({"message": "使用者資訊更新成功", "user": user.to_dict()}), 200
    except Exception as e:
        db.session.rollback()
        print(f"--- ERROR in update_user for ID {user_id}: {e} ---")
        # traceback.print_exc()
        return jsonify({"message": "更新使用者時發生伺服器內部錯誤", "error": str(e)}), 500

# 4-1. 修改密碼
@users_bp.route('/change-password', methods=['PUT', 'OPTIONS']) # <--- 添加 OPTIONS
@jwt_required()
def change_password_route(): 
    print(f"--- Request received at PUT /api/users/change-password (inside change_password_route function) ---")
    data = request.get_json()
    if not data:
        return jsonify({"message": "請求中未包含 JSON 資料"}), 400

    old_password = data.get('oldPassword')
    new_password = data.get('newPassword')

    if not all([old_password, new_password]):
        return jsonify({"message": "請提供舊密碼和新密碼"}), 400

    current_user_id_str = get_jwt_identity()
    try:
        current_user_id = int(current_user_id_str)
    except ValueError:
        print(f"--- Invalid user identity in JWT for password change: {current_user_id_str} ---")
        return jsonify({"message": "無效的使用者身份"}), 422

    user = User.query.get(current_user_id)

    if not user:
        print(f"--- User with ID {current_user_id} not found for password change ---")
        return jsonify({"message": "找不到使用者或認證失敗"}), 404

    if not hasattr(user, 'verify_password') or not callable(getattr(user, 'verify_password')): # <--- 修正為 verify_password
         print(f"--- ERROR: User model is missing verify_password method for user {user.username} ---")
         return jsonify({"message": "伺服器配置錯誤：無法驗證密碼（開發者提示：User模型缺少verify_password）"}), 500
    
    if not user.verify_password(old_password): # <--- 修正為 verify_password
        print(f"--- Old password incorrect for user {user.username} ---")
        return jsonify({"message": "舊密碼不正確"}), 401
    
    if len(new_password) < current_app.config.get('MIN_PASSWORD_LENGTH', 6):
        return jsonify({"message": f"新密碼長度至少需要 {current_app.config.get('MIN_PASSWORD_LENGTH', 6)} 個字元"}), 400

    try:
        print(f"--- Setting new password for user {user.username} ---")
        user.set_password(new_password) # <--- 使用 set_password 進行雜湊
        
        db.session.commit()
        print(f"--- Password changed successfully for user {user.username} ---")

        try:
            send_email(to=user.email, subject='NAPP 系統：您的密碼已修改', template=f"您的密碼已成功修改。")
        except Exception as email_e:
            print(f"--- Failed to send password change email to {user.email}: {email_e} ---")

        return jsonify({"message": "密碼修改成功"}), 200
    except Exception as e:
        db.session.rollback()
        print(f"--- ERROR in change_password_route for user {user.username}: {e} ---")
        # traceback.print_exc()
        return jsonify({"message": "修改密碼時發生伺服器內部錯誤", "error": str(e)}), 500

# 刪除使用者
@users_bp.route('/<int:user_id>', methods=['DELETE', 'OPTIONS']) # <--- 添加 OPTIONS
@jwt_required()
@admin_required()
def delete_user(user_id):
    print(f"--- Request received at DELETE /api/users/{user_id} (inside delete_user function) ---")
    user = User.query.get(user_id)
    if not user:
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
        return jsonify({"message": "刪除使用者時發生伺服器內部錯誤", "