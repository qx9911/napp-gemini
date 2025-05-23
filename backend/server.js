// backend/server.js

const express = require('express');
const cors = require('cors'); // 引入 CORS 中介軟體
const dotenv = require('dotenv'); // 引入 dotenv 用於載入環境變數
const { sequelize } = require('./models'); // 引入 Sequelize 實例和所有模型
const authRoutes = require('./routes/authRoutes'); // 引入認證路由
const userRoutes = require('./routes/userRoutes'); // 引入使用者管理路由
const bcrypt = require('bcrypt'); // 引入 bcrypt 用於密碼雜湊
const { User } = require('./models'); // 再次引入 User 模型以創建預設管理員

dotenv.config(); // 載入 .env 檔案中的環境變數

const app = express();
const PORT = process.env.PORT || 3000; // 伺服器監聽端口，預設為 3000

// 中介軟體設定
app.use(cors()); // 啟用 CORS，允許跨域請求
app.use(express.json()); // 啟用 Express 內建的 JSON 解析，用於解析請求體中的 JSON 資料

// 路由設定
app.use('/api/auth', authRoutes); // 認證相關路由，前綴為 /api/auth
app.use('/api/users', userRoutes); // 使用者管理相關路由，前綴為 /api/users

// 測試根路由
app.get('/', (req, res) => {
  res.send('NAPP System Backend API is running!');
});

// 資料庫連接與伺服器啟動
const startServer = async () => {
  try {
    // 測試資料庫連線
    await sequelize.authenticate();
    console.log('資料庫連線成功！');

    // 同步所有模型到資料庫
    // 注意：在生產環境中，通常會使用資料庫遷移 (migrations) 工具，而不是 force: true
    // force: true 會刪除所有現有資料表並重新創建，這會導致資料丟失
    await sequelize.sync({ force: false }); // force: true for development, force: false for production
    console.log('資料庫模型同步完成！');

    // 檢查並創建預設管理員帳號
    const adminUsername = process.env.ADMIN_USERNAME || 'admin';
    const adminPassword = process.env.ADMIN_PASSWORD || 'admin123';
    const adminEmail = process.env.ADMIN_EMAIL || 'admin@example.com';

    let adminUser = await User.findOne({ where: { username: adminUsername } });

    if (!adminUser) {
      // 如果預設管理員不存在，則創建它
      // 密碼會在 User 模型中的 hook 自動雜湊
      adminUser = await User.create({
        name: 'Default Admin',
        username: adminUsername,
        email: adminEmail,
        password: adminPassword,
        role: 'admin'
      });
      console.log(`已創建預設管理員帳號: ${adminUsername}`);
    } else {
      console.log(`預設管理員帳號 ${adminUsername} 已存在。`);
    }

    // 啟動 Express 伺服器
    app.listen(PORT, () => {
      console.log(`NAPP Backend Server 運行於 http://localhost:${PORT}`);
    });

  } catch (error) {
    console.error('無法連接資料庫或啟動伺服器:', error);
    process.exit(1); // 退出應用程式
  }
};

startServer();

