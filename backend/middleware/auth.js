// backend/middleware/auth.js

const jwt = require('jsonwebtoken'); // 引入 jsonwebtoken 用於驗證 JWT
const { User } = require('../models'); // 引入 User 模型
require('dotenv').config(); // 載入 .env 檔案中的環境變數

// JWT 密鑰，從環境變數中獲取
const JWT_SECRET = process.env.JWT_SECRET || 'your_jwt_secret_key'; // 預設值，請在 .env 中設定

// 認證中介軟體
const authenticateToken = (req, res, next) => {
  // 從請求頭中獲取 Authorization 字段
  const authHeader = req.headers['authorization'];
  // 檢查是否存在 Authorization 字段，並確保其格式為 "Bearer TOKEN"
  const token = authHeader && authHeader.startsWith('Bearer ') ? authHeader.split(' ')[1] : null;

  if (!token) {
    // 如果沒有提供 token，返回 401 Unauthorized
    return res.status(401).json({ message: '未提供身份驗證令牌' });
  }

  // 驗證 token
  jwt.verify(token, JWT_SECRET, async (err, user) => {
    if (err) {
      // 如果 token 無效或過期，返回 403 Forbidden
      return res.status(403).json({ message: '身份驗證令牌無效或已過期' });
    }

    try {
      // 根據 token 中的使用者 ID 查詢資料庫，確保使用者存在且有效
      const foundUser = await User.findByPk(user.id);
      if (!foundUser) {
        return res.status(403).json({ message: '使用者不存在或無效' });
      }

      // 將解碼後的使用者資訊附加到請求物件中，供後續路由使用
      req.user = foundUser;
      next(); // 繼續處理下一個中介軟體或路由
    } catch (dbError) {
      console.error('資料庫查詢錯誤:', dbError);
      res.status(500).json({ message: '伺服器錯誤' });
    }
  });
};

// 檢查是否為管理員權限的中介軟體
const authorizeAdmin = (req, res, next) => {
  // authenticateToken 已經將使用者資訊附加到 req.user
  if (req.user && req.user.role === 'admin') {
    next(); // 如果是管理員，繼續處理
  } else {
    // 如果不是管理員，返回 403 Forbidden
    res.status(403).json({ message: '無權限訪問，需要管理員權限' });
  }
};

// 導出中介軟體
module.exports = {
  authenticateToken,
  authorizeAdmin
};
