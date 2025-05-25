# backend/routes/users.py

from flask import Blueprint, request, jsonify
from models import User, db
from utils.auth_decorators import jwt_required, admin_required
from utils.email_service import send_email
import datetime

# 創建一個藍圖 (Blueprint) 來組織使用者管理相關的路由
users_bp = Blueprint('users', __name__)

# 3-1. 列出所有使用者清單 (需要管理員權限)
@users_bp.route('/', methods=['GET'])
@jwt_required()
@admin_required()
def get_all_users():
    try:
        users = User.query.all()
        users_data = [user.to_dict() for user in users]
        return jsonify(users_data), 200
    except Exception as e:
        print(f"獲取使用者列表時發生錯誤: {e}")
        return jsonify({"message": "伺服器錯誤", "error": str(e)}), 500

# 3-2. 新增使用者 (需要管理員權限)
@users_bp.route('/', methods=['POST'])
@jwt_required()
@admin_required()
def create_user():
    name = request.json.get('name', None)
    username = request.json.get('username', None)
    email = request.json.get('email', None)
    password = request.json.get('password', None)
    role = request.json.get('role', 'user')

    if not all([name, username, email, password]):
        return jsonify({"message": "請提供所有必要欄位：姓名、帳號、Email、密碼"}), 400

    existing_user = User.query.filter(
        (User.username == username) | (User.email == email)
    ).first()

    if existing_user:
        if existing_user.username == username:
            return jsonify({"message": "帳號已存在"}), 409
        if existing_user.email == email:
            return jsonify({"message": "電子郵件已存在"}), 409

    try:
        new_user = User(name=name, username=username, email=email, role=role)
        new_user.password = password
        db.session.add(new_user)
        db.session.commit()

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

        return jsonify({"message": "使用者新增成功", "user": new_user.to_dict()}), 201
    except Exception as e:
        db.session.rollback()
        print(f"新增使用者時發生錯誤: {e}")
        return jsonify({"message": "伺服器錯誤", "error": str(e)}), 500

# 3-3. 獲取單一使用者資訊 (用於編輯畫面，需要管理員權限)
@users_bp.route('/<int:user_id>', methods=['GET'])
@jwt_required()
@admin_required()
def get_user(user_id):
    user = User.query.get(user_id)
    if not user:
        return jsonify({"message": "找不到使用者"}), 404
    return jsonify(user.to_dict()), 200

# 3-3. 編輯使用者 (需要管理員權限)
@users_bp.route('/<int:user_id>', methods=['PUT'])
@jwt_required()
@admin_required()
def update_user(user_id):
    user = User.query.get(user_id)
    if not user:
        return jsonify({"message": "找不到使用者"}), 404

    name = request.json.get('name', None)
    username = request.json.get('username', None)
    email = request.json.get('email', None)
    role = request.json.get('role', None)

    try:
        existing_user = User.query.filter(
            ((User.username == username) | (User.email == email)) &
            (User.id != user_id)
        ).first()

        if existing_user:
            if existing_user.username == username:
                return jsonify({"message": "帳號已存在"}), 409
            if existing_user.email == email:
                return jsonify({"message": "電子郵件已存在"}), 409

        if name:
            user.name = name
        if username:
            user.username = username
        if email:
            user.email = email
        if role:
            user.role = role
        
        db.session.commit()
        return jsonify({"message": "使用者資訊更新成功", "user": user.to_dict()}), 200
    except Exception as e:
        db.session.rollback()
        print(f"更新使用者時發生錯誤: {e}")
        return jsonify({"message": "伺服器錯誤", "error": str(e)}), 500

# 4-1. 修改密碼 (登入使用者本人修改，需要認證)
@users_bp.route('/change-password', methods=['PUT'])
@jwt_required()
def change_password():
    old_password = request.json.get('oldPassword', None)
    new_password = request.json.get('newPassword', None)

    if not all([old_password, new_password]):
        return jsonify({"message": "請提供舊密碼和新密碼"}), 400

    current_user_id = get_jwt_identity()
    user = User.query.get(current_user_id)

    if not user:
            return jsonify({"message": "找不到使用者"}), 404

    if not user.verify_password(old_password):
        return jsonify({"message": "舊密碼不正確"}), 401

    try:
        user.password = new_password
        db.session.commit()

        send_email(
            to=user.email,
            subject='NAPP 系統：您的密碼已成功修改',
            template=f"""
            <p>您好 {user.name},</p>
            <p>您的 NAPP 系統密碼已成功修改。</p>
            <p>如果您不是本人操作，請立即聯繫管理員。</p>
            """
        )
        return jsonify({"message": "密碼修改成功"}), 200
    except Exception as e:
        db.session.rollback()
        print(f"修改密碼時發生錯誤: {e}")
        return jsonify({"message": "伺服器錯誤", "error": str(e)}), 500

# 刪除使用者 (需要管理員權限)
@users_bp.route('/<int:user_id>', methods=['DELETE'])
@jwt_required()
@admin_required()
def delete_user(user_id):
    user = User.query.get(user_id)
    if not user:
        return jsonify({"message": "找不到使用者"}), 404

    try:
        db.session.delete(user)
        db.session.commit()
        return jsonify({"message": "使用者刪除成功"}), 200
    except Exception as e:
        db.session.rollback()
        print(f"刪除使用者時發生錯誤: {e}")
        return jsonify({"message": "伺服器錯誤", "error": str(e)}), 500

