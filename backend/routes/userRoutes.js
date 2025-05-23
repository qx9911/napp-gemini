// backend/routes/userRoutes.js

const express = require('express');
const router = express.Router();
const bcrypt = require('bcrypt'); // 用於密碼雜湊
const { User } = require('../models'); // 引入 User 模型
const { authenticateToken, authorizeAdmin } = require('../middleware/auth'); // 引入認證中介軟體
const nodemailer = require('nodemailer'); // 用於發送郵件
require('dotenv').config(); // 載入 .env 檔案中的環境變數

// 郵件發送器設定 (與 authRoutes.js 中的設定相同，請確保 .env 配置正確)
const transporter = nodemailer.createTransport({
  host: process.env.EMAIL_HOST,
  port: process.env.EMAIL_PORT,
  secure: process.env.EMAIL_SECURE === 'true',
  auth: {
    user: process.env.EMAIL_USER,
    pass: process.env.EMAIL_PASS,
  },
});

// 3-1. 列出所有使用者清單 (需要管理員權限)
router.get('/', authenticateToken, authorizeAdmin, async (req, res) => {
  try {
    // 查詢所有使用者，排除密碼和敏感資訊
    const users = await User.findAll({
      attributes: ['id', 'name', 'username', 'email', 'role', 'createdAt', 'updatedAt']
    });
    res.json(users);
  } catch (error) {
    console.error('獲取使用者列表時發生錯誤:', error);
    res.status(500).json({ message: '伺服器錯誤' });
  }
});

// 3-2. 新增使用者 (需要管理員權限)
router.post('/', authenticateToken, authorizeAdmin, async (req, res) => {
  const { name, username, email, password, role } = req.body;

  try {
    // 檢查使用者名或電子郵件是否已存在
    const existingUser = await User.findOne({
      where: {
        [require('sequelize').Op.or]: [{ username }, { email }]
      }
    });

    if (existingUser) {
      if (existingUser.username === username) {
        return res.status(409).json({ message: '帳號已存在' });
      }
      if (existingUser.email === email) {
        return res.status(409).json({ message: '電子郵件已存在' });
      }
    }

    // 創建新使用者 (密碼會在 User 模型中自動雜湊)
    const newUser = await User.create({ name, username, email, password, role });

    // 發送帳號創建通知郵件 (可選)
    await transporter.sendMail({
      to: newUser.email,
      from: process.env.EMAIL_USER,
      subject: 'NAPP 系統：您的帳號已創建',
      html: `
        <p>您好 ${newUser.name},</p>
        <p>您的 NAPP 系統帳號已成功創建。</p>
        <p>帳號: ${newUser.username}</p>
        <p>請使用您設定的密碼登入。</p>
      `,
    });

    res.status(201).json({
      message: '使用者新增成功',
      user: {
        id: newUser.id,
        name: newUser.name,
        username: newUser.username,
        email: newUser.email,
        role: newUser.role,
      },
    });
  } catch (error) {
    console.error('新增使用者時發生錯誤:', error);
    res.status(500).json({ message: '伺服器錯誤' });
  }
});

// 3-3. 獲取單一使用者資訊 (用於編輯畫面，需要管理員權限)
router.get('/:id', authenticateToken, authorizeAdmin, async (req, res) => {
  try {
    const user = await User.findByPk(req.params.id, {
      attributes: ['id', 'name', 'username', 'email', 'role', 'createdAt', 'updatedAt']
    });

    if (!user) {
      return res.status(404).json({ message: '找不到使用者' });
    }
    res.json(user);
  } catch (error) {
    console.error('獲取單一使用者時發生錯誤:', error);
    res.status(500).json({ message: '伺服器錯誤' });
  }
});

// 3-3. 編輯使用者 (需要管理員權限)
router.put('/:id', authenticateToken, authorizeAdmin, async (req, res) => {
  const { name, username, email, role } = req.body; // 不允許直接在編輯時修改密碼

  try {
    const user = await User.findByPk(req.params.id);

    if (!user) {
      return res.status(404).json({ message: '找不到使用者' });
    }

    // 檢查新的使用者名或電子郵件是否與其他使用者衝突
    const existingUser = await User.findOne({
      where: {
        [require('sequelize').Op.or]: [{ username }, { email }],
        id: { [require('sequelize').Op.ne]: req.params.id } // 排除當前使用者
      }
    });

    if (existingUser) {
      if (existingUser.username === username) {
        return res.status(409).json({ message: '帳號已存在' });
      }
      if (existingUser.email === email) {
        return res.status(409).json({ message: '電子郵件已存在' });
      }
    }

    user.name = name || user.name;
    user.username = username || user.username;
    user.email = email || user.email;
    user.role = role || user.role; // 角色修改，需謹慎處理
    await user.save();

    res.json({ message: '使用者資訊更新成功', user });
  } catch (error) {
    console.error('更新使用者時發生錯誤:', error);
    res.status(500).json({ message: '伺服器錯誤' });
  }
});

// 4-1. 修改密碼 (登入使用者本人修改，需要認證)
router.put('/change-password', authenticateToken, async (req, res) => {
  const { oldPassword, newPassword } = req.body;
  const userId = req.user.id; // 從認證中介軟體獲取當前使用者 ID

  try {
    const user = await User.findByPk(userId);

    if (!user) {
      return res.status(404).json({ message: '找不到使用者' }); // 理論上不會發生，因為已通過認證
    }

    // 驗證舊密碼
    const isOldPasswordValid = await user.comparePassword(oldPassword);
    if (!isOldPasswordValid) {
      return res.status(401).json({ message: '舊密碼不正確' });
    }

    // 更新新密碼 (User 模型中的 hook 會自動雜湊)
    user.password = newPassword;
    await user.save();

    // 發送密碼修改成功通知郵件
    await transporter.sendMail({
      to: user.email,
      from: process.env.EMAIL_USER,
      subject: 'NAPP 系統：您的密碼已成功修改',
      html: `
        <p>您好 ${user.name},</p>
        <p>您的 NAPP 系統密碼已成功修改。</p>
        <p>如果您不是本人操作，請立即聯繫管理員。</p>
      `,
    });

    res.status(200).json({ message: '密碼修改成功' });

  } catch (error) {
    console.error('修改密碼時發生錯誤:', error);
    res.status(500).json({ message: '伺服器錯誤' });
  }
});

// 刪除使用者 (需要管理員權限)
router.delete('/:id', authenticateToken, authorizeAdmin, async (req, res) => {
  try {
    const user = await User.findByPk(req.params.id);

    if (!user) {
      return res.status(404).json({ message: '找不到使用者' });
    }

    await user.destroy();
    res.status(200).json({ message: '使用者刪除成功' });
  } catch (error) {
    console.error('刪除使用者時發生錯誤:', error);
    res.status(500).json({ message: '伺服器錯誤' });
  }
});


module.exports = router;
