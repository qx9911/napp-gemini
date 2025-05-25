// frontend/lib/screens/home_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // 用於日期時間格式化
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import 'login_screen.dart';
import 'user_management_screen.dart';
import 'change_password_screen.dart';
// import 'profile_screen.dart'; // 未來功能：個人資料頁面

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _currentTime = '';

  @override
  void initState() {
    super.initState();
    _updateTime();
    // 每秒更新一次時間 (可選，如果需要即時更新)
    // Timer.periodic(const Duration(seconds: 1), (Timer t) => _updateTime());
  }

  void _updateTime() {
    if (mounted) {
      setState(() {
        _currentTime = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());
      });
    }
  }

  void _handleMenuSelection(String value) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    if (value == 'profile') {
      // TODO: 導航到個人資料頁面
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('個人資料功能待實作')),
      );
      // Navigator.of(context).push(MaterialPageRoute(builder: (context) => const ProfileScreen()));
    } else if (value == 'change_password') {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => const ChangePasswordScreen()),
      );
    } else if (value == 'logout') {
      await authProvider.logout();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (Route<dynamic> route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final User? currentUser = authProvider.user;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text('NAPP 系統'),
            const Spacer(),
            Text(
              _currentTime,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        actions: [
          if (currentUser != null)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: PopupMenuButton<String>(
                onSelected: _handleMenuSelection,
                itemBuilder: (BuildContext context) {
                  return [
                    PopupMenuItem<String>(
                      value: 'profile',
                      child: ListTile(
                        leading: const Icon(Icons.account_circle_outlined),
                        title: Text(currentUser.name), // 顯示使用者名稱
                        subtitle: Text(currentUser.email), // 顯示 Email
                      ),
                    ),
                    const PopupMenuDivider(),
                    const PopupMenuItem<String>(
                      value: 'change_password',
                      child: ListTile(
                        leading: Icon(Icons.lock_outline),
                        title: Text('修改密碼'),
                      ),
                    ),
                    const PopupMenuItem<String>(
                      value: 'logout',
                      child: ListTile(
                        leading: Icon(Icons.exit_to_app, color: Colors.redAccent),
                        title: Text('登出', style: TextStyle(color: Colors.redAccent)),
                      ),
                    ),
                  ];
                },
                child: CircleAvatar(
                  backgroundColor: Colors.white70,
                  child: currentUser.name.isNotEmpty
                      ? Text(
                          currentUser.name[0].toUpperCase(),
                          style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold),
                        )
                      : const Icon(Icons.person, color: Colors.blueAccent),
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.login),
              onPressed: () {
                 Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const LoginScreen()),
                    (Route<dynamic> route) => false,
                );
              },
            ),
        ],
      ),
      drawer: Drawer( // Leftbar
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            UserAccountsDrawerHeader(
              accountName: Text(currentUser?.name ?? '未登入'),
              accountEmail: Text(currentUser?.email ?? ''),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
                child: currentUser?.name.isNotEmpty ?? false
                    ? Text(
                        currentUser!.name[0].toUpperCase(),
                        style: TextStyle(fontSize: 24.0, color: Theme.of(context).colorScheme.onSecondaryContainer),
                      )
                    : const Icon(Icons.person, size: 30.0),
              ),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home_outlined),
              title: const Text('首頁'),
              onTap: () {
                Navigator.pop(context); // 關閉 drawer
              },
            ),
            // --- 未來新增 App 之分類 Start ---
            const Divider(),
            const ListTile(
              title: Text('App 分類一', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
            ),
            ListTile(
              leading: const Icon(Icons.app_registration),
              title: const Text('App 1-1 (未來新增)'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('App 1-1 功能待實作')));
              },
            ),
            ListTile(
              leading: const Icon(Icons.app_settings_alt),
              title: const Text('App 1-2 (未來新增)'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('App 1-2 功能待實作')));
              },
            ),
            const Divider(),
            const ListTile(
              title: Text('App 分類二', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
            ),
            ListTile(
              leading: const Icon(Icons.apps_outlined),
              title: const Text('App 2-1 (未來新增)'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('App 2-1 功能待實作')));
              },
            ),
            // --- 未來新增 App 之分類 End ---
            if (authProvider.isAdmin) // 只有管理員才顯示
              Column(
                children: [
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.people_alt_outlined, color: Colors.orangeAccent),
                    title: const Text('使用者管理', style: TextStyle(color: Colors.orangeAccent)),
                    onTap: () {
                      Navigator.pop(context); // 關閉 drawer
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (context) => const UserManagementScreen()),
                      );
                    },
                  ),
                ],
              ),
          ],
        ),
      ),
      body: Center( // 主視窗
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start, // 內容靠上
            crossAxisAlignment: CrossAxisAlignment.stretch, // 內容撐滿寬度
            children: <Widget>[
              if (currentUser != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20.0),
                  child: Text(
                    '歡迎，${currentUser.name} (${currentUser.role == 'admin' ? '管理員' : '使用者'})',
                    style: Theme.of(context).textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                )
              else
                 Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20.0),
                  child: Text(
                    '您尚未登入',
                    style: Theme.of(context).textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                ),

              if (authProvider.isAdmin) // Admin 首頁的「使用者管理」按鈕
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.manage_accounts),
                    label: const Text('使用者管理'),
                    onPressed: () {
                       Navigator.of(context).push(
                        MaterialPageRoute(builder: (context) => const UserManagementScreen()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 15.0),
                      textStyle: const TextStyle(fontSize: 16)
                    ),
                  ),
                ),

              const SizedBox(height: 20),
              const Text(
                '主視窗區域 (未來新增各種App，按類別分組排列)',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              // TODO: 實作 App 列表，按類別分組排列
              // 例如，使用 ExpansionTile 和 GridView
              // Expanded(
              //   child: ListView(
              //     children: [
              //       ExpansionTile(
              //         title: Text('App 類別一'),
              //         children: [
              //           // GridView for apps in category one
              //         ],
              //       ),
              //       ExpansionTile(
              //         title: Text('App 類別二'),
              //         children: [
              //           // GridView for apps in category two
              //         ],
              //       ),
              //     ],
              //   ),
              // )
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomAppBar( // Footbar
        padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
        shape: const CircularNotchedRectangle(), // 可選，美化樣式
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Expanded(
              child: Tooltip(
                message: '最新公告：NAPP 系統 V1.0 現已發布！歡迎體驗新功能。',
                child: Row(
                  children: const [
                    Icon(Icons.campaign_outlined, size: 20, color: Colors.blueGrey),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '公告：系統 V1.0 已發布',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10), // 分隔
            Expanded(
              child: Tooltip(
                message: '您有 3 個會簽項目待處理，1 個已完成。',
                child: Row(
                  children: const [
                    Icon(Icons.assignment_turned_in_outlined, size: 20, color: Colors.blueGrey),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '會簽進度：3 個待辦',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}