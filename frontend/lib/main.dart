// frontend/lib/main.dart

import 'package:flutter/material.dart'; // 引入 Flutter Material 設計
import 'package:provider/provider.dart'; // 引入 Provider
import 'package:url_strategy/url_strategy.dart'; // 用於 Flutter Web URL 清理
import 'package:flutter/foundation.dart' show kIsWeb; // 判斷是否為 Web 環境

import 'providers/auth_provider.dart'; // 引入 AuthProvider
import 'screens/login_screen.dart'; // 引入登入頁面
import 'screens/home_screen.dart'; // 引入首頁
import 'screens/reset_password_screen.dart'; // 引入重設密碼頁面

void main() {
  // 對於 Flutter Web，移除 URL 中的 # 符號
  if (kIsWeb) {
    setPathUrlStrategy();
  }
  runApp(const MyApp()); // 運行應用程式
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // 提供 AuthProvider 實例給整個應用程式
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          // 根據認證狀態決定顯示哪個頁面
          Widget initialRoute;
          if (authProvider.isAuthenticated) {
            initialRoute = const HomeScreen(); // 如果已登入，顯示首頁
          } else {
            initialRoute = const LoginScreen(); // 如果未登入，顯示登入頁面
          }

          return MaterialApp(
            title: 'NAPP System', // 應用程式標題
            debugShowCheckedModeBanner: false, // 隱藏 debug 標籤
            theme: ThemeData(
              primarySwatch: Colors.blue, // 主要顏色設定
              visualDensity: VisualDensity.adaptivePlatformDensity, // 根據平台調整視覺密度
              appBarTheme: const AppBarTheme(
                backgroundColor: Colors.blueAccent, // AppBar 背景色
                foregroundColor: Colors.white, // AppBar 文字顏色
                elevation: 4, // AppBar 陰影
              ),
              elevatedButtonTheme: ElevatedButtonThemeData(
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8), // 按鈕圓角
                  ),
                  textStyle: const TextStyle(
                    fontWeight: FontWeight.bold, // 按鈕文字加粗
                  ),
                ),
              ),
              inputDecorationTheme: InputDecorationTheme(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8), // 輸入框圓角
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.blueAccent, width: 2), // 聚焦時邊框顏色
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade400), // 啟用時邊框顏色
                ),
              ),
            ),
            // 定義應用程式的路由
            // 這裡使用簡單的命名路由，用於處理忘記密碼的 URL 帶 token 情況
            onGenerateRoute: (settings) {
              if (settings.name == '/reset-password') {
                // 解析 URL 中的 token 參數
                final uri = Uri.parse(settings.name!);
                final token = uri.queryParameters['token'];
                return MaterialPageRoute(
                  builder: (context) => ResetPasswordScreen(token: token),
                );
              }
              // 預設路由
              return MaterialPageRoute(builder: (context) => initialRoute);
            },
            home: initialRoute, // 應用程式的起始頁面
          );
        },
      ),
    );
  }
}
