// backend/models/index.js

const sequelize = require('../config/database'); // 引入資料庫連線實例
const User = require('./user'); // 引入 User 模型

// 定義模型關聯 (如果有的話，例如 User 和其他模型的關係)
// 例如：如果未來有一個 Post 模型，且 Post 屬於 User
// User.hasMany(Post, { foreignKey: 'userId', as: 'posts' });
// Post.belongsTo(User, { foreignKey: 'userId', as: 'author' });

// 將所有模型匯出
const db = {};
db.sequelize = sequelize; // 導出 sequelize 實例
db.User = User;       // 導出 User 模型

// 同步所有模型到資料庫 (僅在開發環境中使用，生產環境請謹慎)
// 這會根據模型定義創建資料表，如果資料表已存在，則不會重複創建
// 如果您需要更新資料表結構，可能需要使用 migration 工具
// db.sequelize.sync({ force: false }) // force: true 會刪除現有資料表再重建
//   .then(() => {
//     console.log('資料庫同步完成！');
//   })
//   .catch(err => {
//     console.error('資料庫同步失敗:', err);
//   });

module.exports = db;

