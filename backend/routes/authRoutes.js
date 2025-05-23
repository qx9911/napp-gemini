// backend/routes/authRoutes.js

const express = require('express');
const router = express.Router();
const jwt = require('jsonwebtoken');
const crypto = require('crypto'); // 用於生成隨機 token
const nodemailer = require('nodemailer'); // 用於發送郵件
const { User } = require('../models'); // 引入 User 模型
require('dotenv').config(); // 載入 .env 檔案中的環境變數

// JWT 密鑰和過期時間，從環境變數獲取
const JWT_SECRET = process.env.JWT_SECRET || 'your_jwt_secret_key';
const JWT_EXPIRES_IN = process.env.JWT_EXPIRES_IN || '1h'; // 例如 '1h', '7d'

// 郵件發送器設定 (請在 .env 中設定)
const transporter = nodemailer.createTransport({
  host: process.env.EMAIL_HOST,
  port: process.env.EMAIL_PORT,
  secure: process.env.EMAIL_SECURE === 'true', // true for 465, false for other ports
  auth: {
    user: process.env.EMAIL_USER,
    pass: process.env.EMAIL_PASS,
  },
});

// 1-1. 登入路由
router.post('/login', async (req, res) => {
  const { username, password } = req.body;

  try {
    // 1. 查詢使用者是否存在
    const user = await User.findOne({ where: { username } });

    if (!user) {
      return res.status(401).json({ message: '帳號或密碼錯誤' });
    }

    // 2. 比較密碼
    const isPasswordValid = await user.comparePassword(password); // 使用 User 模型中的方法

    if (!isPasswordValid) {
      return res.status(401).json({ message: '帳號或密碼錯誤' });
    }

    // 3. 產生 JWT
    const token = jwt.sign(
      { id: user.id, username: user.username, role: user.role },
      JWT_SECRET,
      { expiresIn: JWT_EXPIRES_IN }
    );

    // 4. 返回成功訊息和 token
    res.json({
      message: '登入成功',
      token,
      user: {
        id: user.id,
        name: user.name,
        username: user.username,
        email: user.email,
        role: user.role,
      },
    });
  } catch (error) {
    console.error('登入時發生錯誤:', error);
    res.status(500).json({ message: '伺服器錯誤' });
  }
});

// 5-1. 忘記密碼 / 請求重設密碼 (寄送重設連結)
router.post('/forgot-password', async (req, res) => {
  const { email } = req.body;

  try {
    const user = await User.findOne({ where: { email } });

    if (!user) {
      // 為了安全，即使電子郵件不存在，也給出一個模糊的成功訊息，避免暴露用戶帳號
      return res.status(200).json({ message: '如果電子郵件存在，密碼重設連結已發送。' });
    }

    // 生成一個唯一的重設令牌
    const resetToken = crypto.randomBytes(32).toString('hex');
    const resetTokenExpires = Date.now() + 3600000; // 令牌有效期為 1 小時 (毫秒)

    // 將令牌和過期時間儲存到使用者記錄中
    user.resetToken = resetToken;
    user.resetTokenExpires = new Date(resetTokenExpires);
    await user.save();

    // 構建重設密碼連結 (前端會接收此 token，並導航到重設頁面)
    // 請注意：這個連結是給前端去處理的，前端會根據這個 token 發送重設密碼請求
    // 這裡我們假設前端重設密碼頁面路徑為 /reset-password?token=
    const resetUrl = `${process.env.FRONTEND_URL}/reset-password?token=${resetToken}`;

    // 發送郵件
    await transporter.sendMail({
      to: user.email,
      from: process.env.EMAIL_USER, // 發件人郵箱
      subject: 'NAPP 系統：密碼重設請求',
      html: `
        <p>您好 ${user.name},</p>
        <p>您收到了來自 NAPP 系統的密碼重設請求。</p>
        <p>請點擊以下連結重設您的密碼：</p>
        <a href="${resetUrl}">${resetUrl}</a>
        <p>此連結將於 1 小時後失效。</p>
        <p>如果您沒有請求重設密碼，請忽略此郵件。</p>
      `,
    });

    res.status(200).json({ message: '密碼重設連結已發送至您的電子郵件。' });

  } catch (error) {
    console.error('忘記密碼請求錯誤:', error);
    res.status(500).json({ message: '伺服器錯誤，無法發送郵件。' });
  }
});

// 5-2. 重設密碼
router.post('/reset-password/:token', async (req, res) => {
  const { token } = req.params;
  const { newPassword } = req.body;

  try {
    // 1. 查找匹配的令牌且未過期的使用者
    const user = await User.findOne({
      where: {
        resetToken: token,
        resetTokenExpires: {
          [require('sequelize').Op.gt]: new Date() // 令牌過期時間必須大於當前時間
        }
      }
    });

    if (!user) {
      return res.status(400).json({ message: '密碼重設令牌無效或已過期。' });
    }

    // 2. 更新密碼
    user.password = newPassword; // User 模型中的 hook 會自動雜湊
    user.resetToken = null; // 清除重設令牌
    user.resetTokenExpires = null; // 清除令牌過期時間
    await user.save();

    // 3. 發送密碼重設成功通知郵件 (可選)
    await transporter.sendMail({
      to: user.email,
      from: process.env.EMAIL_USER,
      subject: 'NAPP 系統：您的密碼已成功重設',
      html: `
        <p>您好 ${user.name},</p>
        <p>您的 NAPP 系統密碼已成功重設。</p>
        <p>如果您不是本人操作，請立即聯繫管理員。</p>
      `,
    });

    res.status(200).json({ message: '密碼已成功重設。' });

  } catch (error) {
    console.error('重設密碼錯誤:', error);
    res.status(500).json({ message: '伺服器錯誤' });
  }
});

module.exports = router;
