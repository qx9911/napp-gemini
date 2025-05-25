// frontend/lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_strategy/url_strategy.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import 'providers/auth_provider.dart'; // 導入 AuthProvider
import 'screens/login_screen.dart';   // 導入 LoginScreen
import 'screens/home_screen.dart';     // 導入 HomeScreen
import 'screens/reset_password_screen.dart'; // 導入 ResetPasswordScreen

void main() {
  if (kIsWeb) {
    setPathUrlStrategy();
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: Consumer<AuthProvider>(
        builder: (context, auth, child) {
          return MaterialApp(
            title: 'NAPP System',
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              primarySwatch: Colors.blue,
              visualDensity: VisualDensity.adaptivePlatformDensity,
              appBarTheme: const AppBarTheme(
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
                elevation: 4,
              ),
              elevatedButtonTheme: ElevatedButtonThemeData(
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  textStyle: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              inputDecorationTheme: InputDecorationTheme(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.blueAccent, width: 2),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade400),
                ),
              ),
            ),
            home: auth.isAuthenticated ? const HomeScreen() : const LoginScreen(),
            onGenerateRoute: (settings) {
              if (settings.name != null) {
                final uri = Uri.parse(settings.name!);
                if (uri.path == '/reset-password') {
                  final token = uri.queryParameters['token'];
                  if (token != null) {
                    return MaterialPageRoute(
                      builder: (context) => ResetPasswordScreen(token: token),
                    );
                  }
                }
              }
              // 如果沒有匹配的命名路由，則根據認證狀態決定顯示主頁或登入頁
              // （雖然 'home' 屬性已經處理了初始路由）
              return MaterialPageRoute(
                builder: (context) => auth.isAuthenticated ? const HomeScreen() : const LoginScreen()
              );
            },
          );
        },
      ),
    );
  }
}