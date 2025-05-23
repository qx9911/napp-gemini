// frontend/lib/providers/auth_provider.dart

import 'package:flutter/material.dart'; // 引入 Flutter Material 設計
import 'package:shared_preferences/shared_preferences.dart'; // 用於本地儲存 JWT Token
import '../api/api_service.dart'; // 引入 API 服務
import '../widgets/custom_alert_dialog.dart'; // 引入自訂提示框

// 定義使用者模型 (簡化版，只包含必要資訊)
class User {
  final int id;
  final String name;
  final String username;
  final String email;
  final String role;

  User({
    required this.id,
    required this.name,
    required this.username,
    required this.email,
    required this.role,
  });

  // 從 JSON 創建 User 實例的工廠方法
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      username: json['username'],
      email: json['email'],
      role: json['role'],
    );
  }
}

// 認證狀態管理 Provider
class AuthProvider with ChangeNotifier {
  User? _user; // 當前登入的使用者資訊
  String? _token; // JWT Token
  bool _isLoading = false; // 載入狀態

  User? get user => _user;
  String? get token => _token;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _user != null && _token != null; // 判斷是否已登入
  bool get isAdmin => _user?.role == 'admin'; // 判斷是否為管理員

  // 初始化時載入本地儲存的 token 和使用者資訊
  AuthProvider() {
    _loadUserFromPrefs();
  }

  // 從 SharedPreferences 載入使用者資訊和 token
  Future<void> _loadUserFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('jwt_token');
    final userJson = prefs.getString('user_info');
    if (_token != null && userJson != null) {
      _user = User.fromJson(json.decode(userJson));
    }
    notifyListeners(); // 通知所有監聽器狀態已更新
  }

  // 登入功能
  Future<String?> login(BuildContext context, String username, String password) async {
    _setLoading(true); // 設定載入狀態為 true
    try {
      // 呼叫 API 服務進行登入
      final response = await ApiService.post('auth/login', {
        'username': username,
        'password': password,
      });

      // 儲存 token 和使用者資訊
      _token = response['token'];
      _user = User.fromJson(response['user']);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('jwt_token', _token!);
      await prefs.setString('user_info', json.encode(_user!.toJson()));

      notifyListeners(); // 通知所有監聽器狀態已更新
      return null; // 登入成功，返回 null (無錯誤)
    } catch (e) {
      // 登入失敗，顯示錯誤訊息
      CustomAlertDialog.show(context, '登入失敗', e.toString().replaceFirst('Exception: ', ''));
      return e.toString(); // 返回錯誤訊息
    } finally {
      _setLoading(false); // 設定載入狀態為 false
    }
  }

  // 登出功能
  Future<void> logout(BuildContext context) async {
    _user = null; // 清除使用者資訊
    _token = null; // 清除 token
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token'); // 從本地儲存中移除 token
    await prefs.remove('user_info'); // 從本地儲存中移除使用者資訊
    notifyListeners(); // 通知所有監聽器狀態已更新

    // 導航回登入頁面 (假設登入頁是根路由)
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginScreen()), // 替換為您的登入頁面
      (Route<dynamic> route) => false,
    );
  }

  // 修改密碼功能
  Future<String?> changePassword(BuildContext context, String oldPassword, String newPassword) async {
    _setLoading(true);
    try {
      await ApiService.put('users/change-password', {
        'oldPassword': oldPassword,
        'newPassword': newPassword,
      });
      CustomAlertDialog.show(context, '成功', '密碼已成功修改。');
      return null; // 成功，返回 null
    } catch (e) {
      CustomAlertDialog.show(context, '修改密碼失敗', e.toString().replaceFirst('Exception: ', ''));
      return e.toString(); // 返回錯誤訊息
    } finally {
      _setLoading(false);
    }
  }

  // 忘記密碼功能 (請求發送重設連結)
  Future<String?> forgotPassword(BuildContext context, String email) async {
    _setLoading(true);
    try {
      final response = await ApiService.post('auth/forgot-password', {
        'email': email,
      });
      CustomAlertDialog.show(context, '請求成功', response['message'] ?? '密碼重設連結已發送。');
      return null;
    } catch (e) {
      CustomAlertDialog.show(context, '請求失敗', e.toString().replaceFirst('Exception: ', ''));
      return e.toString();
    } finally {
      _setLoading(false);
    }
  }

  // 重設密碼功能
  Future<String?> resetPassword(BuildContext context, String token, String newPassword) async {
    _setLoading(true);
    try {
      final response = await ApiService.post('auth/reset-password/$token', {
        'newPassword': newPassword,
      });
      CustomAlertDialog.show(context, '成功', response['message'] ?? '密碼已成功重設。');
      return null;
    } catch (e) {
      CustomAlertDialog.show(context, '重設密碼失敗', e.toString().replaceFirst('Exception: ', ''));
      return e.toString();
    } finally {
      _setLoading(false);
    }
  }

  // 設定載入狀態
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners(); // 通知監聽器載入狀態已改變
  }
}

// User 模型的擴展，用於 toJson 方法
extension UserToJson on User {
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'username': username,
      'email': email,
      'role': role,
    };
  }
}

// 引入登入頁面，避免循環依賴
import '../screens/login_screen.dart';
