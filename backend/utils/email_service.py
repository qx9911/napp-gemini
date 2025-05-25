# backend/utils/email_service.py

from flask_mail import Mail, Message
from flask import current_app

# 初始化 Flask-Mail 實例，但不在這裡綁定 Flask app
mail = Mail()

def send_email(to, subject, template):
    """
    發送電子郵件的通用函數。

    Args:
        to (str): 收件人的電子郵件地址。
        subject (str): 郵件主題。
        template (str): 郵件內容 (HTML 或純文字)。
    """
    try:
        with current_app.app_context(): # 確保在應用程式上下文中發送郵件
            # 創建郵件訊息物件
            msg = Message(
                subject,
                sender=current_app.config['MAIL_DEFAULT_SENDER'],
                recipients=[to]
            )
            msg.html = template

            # 發送郵件
            mail.send(msg)
            print(f"郵件已成功發送至 {to}")
            return True
    except Exception as e:
        print(f"發送郵件至 {to} 失敗: {e}")
        return False

