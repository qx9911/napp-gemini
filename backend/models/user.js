// backend/models/user.js

const { DataTypes } = require('sequelize');
const sequelize = require('../config/database'); // 引入資料庫連線實例
const bcrypt = require('bcrypt'); // 引入 bcrypt 用於密碼雜湊

// 定義 User 模型
const User = sequelize.define('User', {
  id: {
    type: DataTypes.INTEGER,
    primaryKey: true,
    autoIncrement: true,
    allowNull: false // 不允許為空
  },
  name: {
    type: DataTypes.STRING(255), // 姓名，字串類型，最大長度255
    allowNull: false // 不允許為空
  },
  username: {
    type: DataTypes.STRING(255), // 帳號，字串類型，最大長度255
    allowNull: false, // 不允許為空
    unique: true // 必須唯一
  },
  email: {
    type: DataTypes.STRING(255), // 電子郵件，字串類型，最大長度255
    allowNull: false, // 不允許為空
    unique: true, // 必須唯一
    validate: {
      isEmail: true // 驗證是否為有效的電子郵件格式
    }
  },
  password: {
    type: DataTypes.STRING(255), // 密碼，字串類型，最大長度255 (儲存雜湊後的密碼)
    allowNull: false // 不允許為空
  },
  role: {
    type: DataTypes.ENUM('admin', 'user'), // 角色，枚舉類型，只能是 'admin' 或 'user'
    defaultValue: 'user', // 預設值為 'user'
    allowNull: false // 不允許為空
  },
  resetToken: {
    type: DataTypes.STRING(255), // 密碼重設令牌
    allowNull: true // 允許為空
  },
  resetTokenExpires: {
    type: DataTypes.DATE, // 密碼重設令牌過期時間
    allowNull: true // 允許為空
  }
}, {
  // 模型選項
  tableName: 'users', // 指定資料表名稱為 'users' (預設會是 'Users')
  timestamps: true,   // 自動添加 createdAt 和 updatedAt 欄位
  hooks: {
    // 在使用者建立或更新密碼前，自動對密碼進行雜湊處理
    beforeCreate: async (user) => {
      if (user.password) {
        const salt = await bcrypt.genSalt(10); // 生成鹽值
        user.password = await bcrypt.hash(user.password, salt); // 雜湊密碼
      }
    },
    beforeUpdate: async (user) => {
      // 只有當密碼被修改時才重新雜湊
      if (user.changed('password')) {
        const salt = await bcrypt.genSalt(10);
        user.password = await bcrypt.hash(user.password, salt);
      }
    }
  }
});

// 定義實例方法來比較密碼
User.prototype.comparePassword = async function(candidatePassword) {
  return await bcrypt.compare(candidatePassword, this.password);
};

// 導出 User 模型
module.exports = User;
