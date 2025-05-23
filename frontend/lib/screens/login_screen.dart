// frontend/lib/screens/login_screen.dart

import 'package:flutter/material.dart'; // 引入 Flutter Material 設計
import 'package:provider/provider.dart'; // 引入 Provider
import '../providers/auth_provider.dart'; // 引入 AuthProvider
import '../widgets/custom_alert_dialog.dart'; // 引入自訂提示框
import 'home_screen.dart'; // 引入首頁
import 'forgot_password_screen.dart'; // 引入忘記密碼頁面

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key}); // 構造函數

  @override
  State<LoginScreen> createState() => _LoginScreenState(); // 創建狀態
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>(); // 用於表單驗證的 Key
  final TextEditingController _usernameController = TextEditingController(); // 帳號輸入控制器
  final TextEditingController _passwordController = TextEditingController(); // 密碼輸入控制器
  bool _obscureText = true; // 控制密碼顯示/隱藏

  @override
  void dispose() {
    _usernameController.dispose(); // 釋放控制器資源
    _passwordController.dispose();
    super.dispose();
  }

  // 處理登入邏輯
  Future<void> _handleLogin() async {
    if (_formKey.currentState!.validate()) { // 驗證表單
      final authProvider = Provider.of<AuthProvider>(context, listen: false); // 獲取 AuthProvider 實例
      final errorMessage = await authProvider.login(
        context,
        _usernameController.text,
        _passwordController.text,
      );

      if (errorMessage == null) {
        // 登入成功，導航到首頁並移除所有之前的路由
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const HomeScreen()),
          (Route<dynamic> route) => false,
        );
      }
      // 錯誤訊息已在 AuthProvider 中透過 CustomAlertDialog 顯示
    }
  }

  @override
  Widget build(BuildContext context) {
    // 監聽 AuthProvider 的 isLoading 狀態，用於顯示載入指示器
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('NAPP 系統登入'),
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                // 標題
                const Text(
                  '歡迎登入',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueAccent,
                  ),
                ),
                const SizedBox(height: 40.0),

                // 帳號輸入框
                TextFormField(
                  controller: _usernameController,
                  decoration: InputDecoration(
                    labelText: '帳號',
                    hintText: '請輸入您的帳號',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    prefixIcon: const Icon(Icons.person),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '請輸入帳號';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20.0),

                // 密碼輸入框
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscureText, // 控制密碼顯示/隱藏
                  decoration: InputDecoration(
                    labelText: '密碼',
                    hintText: '請輸入您的密碼',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureText ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureText = !_obscureText; // 切換密碼顯示狀態
                        });
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '請輸入密碼';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 30.0),

                // 登入按鈕
                ElevatedButton(
                  onPressed: authProvider.isLoading ? null : _handleLogin, // 載入時禁用按鈕
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 15.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    backgroundColor: Colors.blueAccent, // 按鈕背景色
                    foregroundColor: Colors.white, // 按鈕文字顏色
                  ),
                  child: authProvider.isLoading
                      ? const CircularProgressIndicator(
                          color: Colors.white,
                        ) // 載入時顯示進度條
                      : const Text(
                          '登入',
                          style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
                        ),
                ),
                const SizedBox(height: 15.0),

                // 忘記密碼連結
                TextButton(
                  onPressed: () {
                    // 導航到忘記密碼頁面
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => const ForgotPasswordScreen()),
                    );
                  },
                  child: const Text(
                    '忘記密碼？',
                    style: TextStyle(color: Colors.blueGrey, fontSize: 16.0),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
