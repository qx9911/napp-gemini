// frontend/lib/providers/auth_provider.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http; // 確保 http 套件已在 pubspec.yaml 中並 pub get
import 'package:shared_preferences/shared_preferences.dart';

// 假設您的 ApiService 檔案路徑如下，如果目前未使用或路徑不同，則 login 等方法會直接使用 http.post
// 如果 ApiService 存在且封裝了 baseUrl 和 token 處理，您可以取消註解並調整 login 等方法
// import '../api/api_service.dart'; 
import '../widgets/custom_alert_dialog.dart'; // 確保此路徑和檔案存在且 CustomAlertDialog 已按建議修改

// User Model
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

  factory User.fromJson(Map<String, dynamic> jsonMap) {
    return User(
      id: jsonMap['id'] as int,
      name: jsonMap['name'] as String,
      username: jsonMap['username'] as String,
      email: jsonMap['email'] as String,
      role: jsonMap['role'] as String,
    );
  }

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

class AuthProvider with ChangeNotifier {
  String? _token;
  User? _user;
  bool _isLoading = false;

  // API Base URL - 非常重要: 請根據您的後端位址修改!
  // 如果 Flutter Web 和 Docker 在同一台機器，通常 'http://localhost:5000' 可以工作。
  // 您之前截圖顯示使用了 172.20.50.102，請確保它是您後端服務的可訪問 IP。
  static const String _apiBaseUrl = 'http://172.20.50.102:5000/api'; // 後端 API 的基礎 URL

  String? get token => _token;
  User? get user => _user;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _token != null && _user != null;
  bool get isAdmin => _user?.role == 'admin';

  AuthProvider() {
    _loadAuthDataFromPrefs();
  }

  void _setLoading(bool value) {
    if (_isLoading == value) return; // 避免不必要的通知
    _isLoading = value;
    notifyListeners();
  }

  Future<void> _loadAuthDataFromPrefs() async {
    _setLoading(true); // 開始時設定載入狀態
    try {
      final prefs = await SharedPreferences.getInstance();
      _token = prefs.getString('jwt_token');
      final userJsonString = prefs.getString('user_info');
      if (_token != null && userJsonString != null) {
        _user = User.fromJson(json.decode(userJsonString) as Map<String, dynamic>);
      } else {
        // 如果 token 或 user info 不存在，確保它們是 null
        _token = null;
        _user = null;
      }
    } catch (e) {
      // 如果從 prefs 載入時出錯 (例如 JSON 格式損壞)，清除它們
      await _clearAuthDataOnLogout(); // 使用一個內部方法來清除 prefs
      debugPrint("Error loading auth data from prefs, clearing stored data: $e");
    } finally {
      _setLoading(false); // 結束時設定載入狀態
      notifyListeners(); // 確保在 finally 中通知，因為 _token 和 _user 可能已改變
    }
  }

  Future<void> _saveAuthDataToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    if (_token != null) {
      await prefs.setString('jwt_token', _token!);
    } else {
      await prefs.remove('jwt_token');
    }
    if (_user != null) {
      await prefs.setString('user_info', json.encode(_user!.toJson()));
    } else {
      await prefs.remove('user_info');
    }
  }

  Future<void> _clearAuthDataOnLogout() async {
    _token = null;
    _user = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
    await prefs.remove('user_info');
  }

  Future<String?> login(BuildContext context, String username, String password) async {
    _setLoading(true);
    try {
      // 如果您使用 ApiService 類別，可以替換下面的 http.post
      // final responseMap = await ApiService.post('$_apiBaseUrl/auth/login', {
      final response = await http.post(
        Uri.parse('$_apiBaseUrl/auth/login'),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: json.encode({'username': username, 'password': password}),
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200 && responseData['token'] != null && responseData['user'] != null) {
        _token = responseData['token'] as String;
        _user = User.fromJson(responseData['user'] as Map<String, dynamic>);
        await _saveAuthDataToPrefs();
        notifyListeners(); // 狀態已改變，通知監聽者
        return null; // 成功
      } else {
        throw Exception(responseData['message'] ?? '登入失敗或伺服器回應錯誤');
      }
    } catch (e) {
      final errorMessage = e.toString().replaceFirst('Exception: ', '');
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (ctx) => CustomAlertDialog(title: '登入失敗', content: errorMessage),
        );
      }
      return errorMessage;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> logout() async { // 不需要 context 參數，因為導航應由 UI 層處理
    await _clearAuthDataOnLogout();
    notifyListeners();
    // UI 層應該監聽 isAuthenticated 的變化，並在變為 false 時執行導航。
  }

  Future<String?> changePassword(BuildContext context, String oldPassword, String newPassword) async {
    _setLoading(true);
    if (_token == null) {
      _setLoading(false);
      return "使用者未登入，無法修改密碼";
    }
    try {
      final response = await http.put( // 假設修改密碼是 PUT 請求
        Uri.parse('$_apiBaseUrl/users/change-password'), // 假設端點是這個
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $_token', // 附帶 Token
        },
        body: json.encode({'oldPassword': oldPassword, 'newPassword': newPassword}),
      );
      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        if (context.mounted) {
          showDialog(
            context: context,
            builder: (ctx) => const CustomAlertDialog(title: '成功', content: '密碼已成功修改。'),
          );
        }
        return null;
      } else {
        throw Exception(responseData['message'] ?? '修改密碼失敗');
      }
    } catch (e) {
      final errorMessage = e.toString().replaceFirst('Exception: ', '');
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (ctx) => CustomAlertDialog(title: '修改密碼失敗', content: errorMessage),
        );
      }
      return errorMessage;
    } finally {
      _setLoading(false);
    }
  }

  Future<String?> forgotPassword(BuildContext context, String email) async {
    _setLoading(true);
    try {
      final response = await http.post(
        Uri.parse('$_apiBaseUrl/auth/forgot-password'),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: json.encode({'email': email}),
      );
      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        final message = (responseData['message'] as String?) ?? '如果電子郵件存在，密碼重設連結已發送。';
        if (context.mounted) {
          showDialog(
            context: context,
            builder: (ctx) => CustomAlertDialog(title: '請求成功', content: message),
          );
        }
        return null;
      } else {
         throw Exception(responseData['message'] ?? '請求失敗');
      }
    } catch (e) {
      final errorMessage = e.toString().replaceFirst('Exception: ', '');
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (ctx) => CustomAlertDialog(title: '請求失敗', content: errorMessage),
        );
      }
      return errorMessage;
    } finally {
      _setLoading(false);
    }
  }

  Future<String?> resetPassword(BuildContext context, String resetToken, String newPassword) async {
    _setLoading(true);
    try {
      final response = await http.post(
        Uri.parse('$_apiBaseUrl/auth/reset-password/$resetToken'), // 假設 token 是路徑參數
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: json.encode({'newPassword': newPassword}),
      );
      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        final message = (responseData['message'] as String?) ?? '密碼已成功重設。';
        if (context.mounted) {
          showDialog(
            context: context,
            builder: (ctx) => CustomAlertDialog(title: '成功', content: message),
          );
        }
        // 登入成功後，可以考慮自動登入或提示使用者重新登入
        // logout(); // 清除舊狀態，讓使用者用新密碼登入
        return null;
      } else {
        throw Exception(responseData['message'] ?? '重設密碼失敗');
      }
    } catch (e) {
      final errorMessage = e.toString().replaceFirst('Exception: ', '');
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (ctx) => CustomAlertDialog(title: '重設密碼失敗', content: errorMessage),
        );
      }
      return errorMessage;
    } finally {
      _setLoading(false);
    }
  }
}