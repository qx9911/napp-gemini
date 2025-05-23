// frontend/lib/screens/forgot_password_screen.dart

import 'package:flutter/material.dart'; // 引入 Flutter Material 設計
import 'package:provider/provider.dart'; // 引入 Provider
import '../providers/auth_provider.dart'; // 引入 AuthProvider
import '../widgets/custom_alert_dialog.dart'; // 引入自訂提示框

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>(); // 用於表單驗證的 Key
  final TextEditingController _emailController = TextEditingController(); // 電子郵件輸入控制器

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  // 處理忘記密碼請求邏輯
  Future<void> _handleForgotPassword() async {
    if (_formKey.currentState!.validate()) { // 驗證表單
      final authProvider = Provider.of<AuthProvider>(context, listen: false); // 獲取 AuthProvider 實例
      final errorMessage = await authProvider.forgotPassword(
        context,
        _emailController.text,
      );

      if (errorMessage == null) {
        // 請求成功，清空輸入框並返回上一頁
        _emailController.clear();
        Navigator.of(context).pop();
      }
      // 錯誤訊息已在 AuthProvider 中透過 CustomAlertDialog 顯示
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context); // 監聽 AuthProvider 的 isLoading 狀態

    return Scaffold(
      appBar: AppBar(
        title: const Text('忘記密碼'),
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
                  '重設您的密碼',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueAccent,
                  ),
                ),
                const SizedBox(height: 40.0),

                // 電子郵件輸入框
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    hintText: '請輸入您的註冊 Email',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    prefixIcon: const Icon(Icons.email),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '請輸入 Email';
                    }
                    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                      return '請輸入有效的 Email 格式';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 30.0),

                // 發送重設連結按鈕
                ElevatedButton(
                  onPressed: authProvider.isLoading ? null : _handleForgotPassword,
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
                          '發送重設連結',
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
