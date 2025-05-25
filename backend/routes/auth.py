# backend/routes/auth.py

from flask import Blueprint, request, jsonify, current_app
from models import User, db
from utils.email_service import send_email
from flask_jwt_extended import create_access_token, create_refresh_token, jwt_required, get_jwt_identity, JWTManager
import datetime
import secrets

auth_bp = Blueprint('auth', __name__)

# 登入路由
@auth_bp.route('/login', methods=['POST'])
def login():
    username = request.json.get('username', None)
    password = request.json.get('password', None)

    if not username or not password:
        return jsonify({"message": "請提供帳號和密碼"}), 400

    user = User.query.filter_by(username=username).first()

    if not user or not user.verify_password(password):
        return jsonify({"message": "帳號或密碼錯誤"}), 401

    access_token = create_access_token(identity=user.id, expires_delta=datetime.timedelta(seconds=current_app.config['JWT_ACCESS_TOKEN_EXPIRES']))
    refresh_token = create_refresh_token(identity=user.id, expires_delta=datetime.timedelta(seconds=current_app.config['JWT_REFRESH_TOKEN_EXPIRES']))

    return jsonify({
        "message": "登入成功",
        "token": access_token,
        "refresh_token": refresh_token,
        "user": user.to_dict()
    }), 200

# 忘記密碼 / 請求重設密碼 (寄送重設連結)
@auth_bp.route('/forgot-password', methods=['POST'])
def forgot_password():
    email = request.json.get('email', None)

    if not email:
        return jsonify({"message": "請提供電子郵件"}), 400

    user = User.query.filter_by(email=email).first()

    if not user:
        return jsonify({"message": "如果電子郵件存在，密碼重設連結已發送。"}), 200

    reset_token = secrets.token_urlsafe(32)
    reset_token_expires = datetime.datetime.now() + datetime.timedelta(hours=1)

    user.reset_token = reset_token
    user.reset_token_expires = reset_token_expires
    db.session.add(user)
    db.session.commit()

    reset_url = f"{current_app.config['FRONTEND_URL']}/reset-password?token={reset_token}"

    email_sent = send_email(
        to=user.email,
        subject='NAPP 系統：密碼重設請求',
        template=f"""
        <p>您好 {user.name},</p>
        <p>您收到了來自 NAPP 系統的密碼重設請求。</p>
        <p>請點擊以下連結重設您的密碼：</p>
        <a href="{reset_url}">{reset_url}</a>
        <p>此連結將於 1 小時後失效。</p>
        <p>如果您沒有請求重設密碼，請忽略此郵件。</p>
        """
    )

    if email_sent:
        return jsonify({"message": "密碼重設連結已發送至您的電子郵件。"}), 200
    else:
        return jsonify({"message": "無法發送郵件，請檢查郵件服務設定或稍後再試。"}), 500

# 重設密碼
@auth_bp.route('/reset-password/<token>', methods=['POST'])
def reset_password(token):
    new_password = request.json.get('newPassword', None)

    if not new_password:
        return jsonify({"message": "請提供新密碼"}), 400

    user = User.query.filter_by(reset_token=token).filter(
        User.reset_token_expires > datetime.datetime.now()
    ).first()

    if not user:
        return jsonify({"message": "密碼重設令牌無效或已過期。"}), 400

    user.password = new_password
    user.reset_token = None
    user.reset_token_expires = None
    db.session.add(user)
    db.session.commit()

    send_email(
        to=user.email,
        subject='NAPP 系統：您的密碼已成功重設',
        template=f"""
        <p>您好 {user.name},</p>
        <p>您的 NAPP 系統密碼已成功重設。</p>
        <p>如果您不是本人操作，請立即聯繫管理員。</p>
        """
    )

    return jsonify({"message": "密碼已成功重設。"}), 200

