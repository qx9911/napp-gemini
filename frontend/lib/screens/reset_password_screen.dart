// frontend/lib/screens/reset_password_screen.dart

import 'package:flutter/material.dart'; // 引入 Flutter Material 設計
import 'package:provider/provider.dart'; // 引入 Provider
import '../providers/auth_provider.dart'; // 引入 AuthProvider
import '../widgets/custom_alert_dialog.dart'; // 引入自訂提示框
import 'login_screen.dart'; // 引入登入頁面

class ResetPasswordScreen extends StatefulWidget {
  final String? token; // 接收從 URL 傳遞過來的 token

  const ResetPasswordScreen({super.key, this.token});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>(); // 用於表單驗證的 Key
  final TextEditingController _tokenController = TextEditingController(); // Token 輸入控制器
  final TextEditingController _newPasswordController = TextEditingController(); // 新密碼輸入控制器
  final TextEditingController _confirmNewPasswordController = TextEditingController(); // 確認新密碼輸入控制器

  bool _obscureNewPassword = true; // 控制新密碼顯示/隱藏
  bool _obscureConfirmNewPassword = true; // 控制確認新密碼顯示/隱藏

  @override
  void initState() {
    super.initState();
    // 如果有從 URL 傳遞過來的 token，則自動填入
    if (widget.token != null) {
      _tokenController.text = widget.token!;
    }
  }

  @override
  void dispose() {
    _tokenController.dispose();
    _newPasswordController.dispose();
    _confirmNewPasswordController.dispose();
    super.dispose();
  }

  // 處理重設密碼邏輯
  Future<void> _handleResetPassword() async {
    if (_formKey.currentState!.validate()) { // 驗證表單
      final authProvider = Provider.of<AuthProvider>(context, listen: false); // 獲取 AuthProvider 實例
      final errorMessage = await authProvider.resetPassword(
        context,
        _tokenController.text,
        _newPasswordController.text,
      );

      if (errorMessage == null) {
        // 密碼重設成功，清空輸入框並導航回登入頁面
        _tokenController.clear();
        _newPasswordController.clear();
        _confirmNewPasswordController.clear();
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (Route<dynamic> route) => false,
        );
      }
      // 錯誤訊息已在 AuthProvider 中透過 CustomAlertDialog 顯示
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context); // 監聽 AuthProvider 的 isLoading 狀態

    return Scaffold(
      appBar: AppBar(
        title: const Text('重設密碼'),
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
                const Text(
                  '輸入 Token 並設定新密碼',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueAccent,
                  ),
                ),
                const SizedBox(height: 40.0),

                // Token 輸入框
                TextFormField(
                  controller: _tokenController,
                  decoration: InputDecoration(
                    labelText: '密碼重設 Token',
                    hintText: '請輸入您收到的重設 Token',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    prefixIcon: const Icon(Icons.vpn_key),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '請輸入密碼重設 Token';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20.0),

                // 新密碼輸入框
                TextFormField(
                  controller: _newPasswordController,
                  obscureText: _obscureNewPassword,
                  decoration: InputDecoration(
                    labelText: '新密碼',
                    hintText: '請輸入您的新密碼',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureNewPassword ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureNewPassword = !_obscureNewPassword;
                        });
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '請輸入新密碼';
                    }
                    if (value.length < 6) {
                      return '密碼長度至少為 6 個字元';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20.0),

                // 確認新密碼輸入框
                TextFormField(
                  controller: _confirmNewPasswordController,
                  obscureText: _obscureConfirmNewPassword,
                  decoration: InputDecoration(
                    labelText: '確認新密碼',
                    hintText: '請再次輸入新密碼',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmNewPassword ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureConfirmNewPassword = !_obscureConfirmNewPassword;
                        });
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '請確認新密碼';
                    }
                    if (value != _newPasswordController.text) {
                      return '兩次輸入的密碼不一致';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 30.0),

                // 重設密碼按鈕
                ElevatedButton(
                  onPressed: authProvider.isLoading ? null : _handleResetPassword,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 15.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    backgroundColor: Colors.blueAccent,
                    foregroundColor: Colors.white,
                  ),
                  child: authProvider.isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          '重設密碼',
                          style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
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
