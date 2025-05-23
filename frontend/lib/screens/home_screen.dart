// frontend/lib/screens/home_screen.dart

import 'package:flutter/material.dart'; // 引入 Flutter Material 設計
import 'package:provider/provider.dart'; // 引入 Provider
import 'package:intl/intl.dart'; // 引入 intl 用於日期格式化
import '../providers/auth_provider.dart'; // 引入 AuthProvider
import 'user_management_screen.dart'; // 引入使用者管理頁面
import 'change_password_screen.dart'; // 引入修改密碼頁面
// import 'profile_screen.dart'; // 未來可能需要的個人資料頁面

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _currentTime = ''; // 用於顯示當前時間

  @override
  void initState() {
    super.initState();
    // 每秒更新一次時間
    _updateTime();
    // 使用 Timer.periodic 定期更新時間
    // Timer.periodic(const Duration(seconds: 1), (Timer t) => _updateTime());
    // 為了避免在非必要時持續更新，這裡只在 initState 時獲取一次，
    // 實際應用中可以考慮使用 StreamBuilder 或其他方式實現實時更新
  }

  void _updateTime() {
    setState(() {
      _currentTime = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context); // 獲取 AuthProvider 實例
    final user = authProvider.user; // 獲取當前登入的使用者資訊

    return Scaffold(
      appBar: AppBar(
        title: Text('NAPP 系統 - $_currentTime'), // 顯示日期時間
        actions: [
          if (user != null)
            PopupMenuButton<String>(
              icon: CircleAvatar(
                backgroundColor: Colors.blueGrey.shade700,
                child: Text(
                  user.username[0].toUpperCase(), // 顯示使用者名稱的第一個字母
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              onSelected: (value) {
                switch (value) {
                  case 'change_password':
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => const ChangePasswordScreen()),
                    );
                    break;
                  case 'profile':
                    // TODO: 導航到個人資料頁面 (目前未實作)
                    // Navigator.of(context).push(
                    //   MaterialPageRoute(builder: (context) => const ProfileScreen()),
                    // );
                    break;
                  case 'logout':
                    authProvider.logout(context); // 執行登出邏輯
                    break;
                }
              },
              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                const PopupMenuItem<String>(
                  value: 'change_password',
                  child: Text('修改密碼'),
                ),
                const PopupMenuItem<String>(
                  value: 'profile',
                  child: Text('個人資料'),
                ),
                const PopupMenuItem<String>(
                  value: 'logout',
                  child: Text('登出'),
                ),
              ],
            ),
          const SizedBox(width: 16),
        ],
      ),
      drawer: Drawer( // Leftbar
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.blueAccent.shade700,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'NAPP 系統',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '歡迎, ${user?.name ?? '使用者'}',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            // 只有管理員才能看到使用者管理選項
            if (authProvider.isAdmin)
              ListTile(
                leading: const Icon(Icons.people),
                title: const Text('使用者管理'),
                onTap: () {
                  Navigator.of(context).pop(); // 關閉抽屜
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => const UserManagementScreen()),
                  );
                },
              ),
            // TODO: 未來新增 App 的分類
            ExpansionTile(
              leading: const Icon(Icons.apps),
              title: const Text('應用程式'),
              children: <Widget>[
                ListTile(
                  title: const Text('App 1.1 (範例)'),
                  onTap: () {
                    // TODO: 導航到 App 1.1
                    Navigator.of(context).pop();
                  },
                ),
                ListTile(
                  title: const Text('App 1.2 (範例)'),
                  onTap: () {
                    // TODO: 導航到 App 1.2
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
          ],
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              '歡迎，${user?.name ?? '使用者'}！', // 顯示歡迎訊息
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            if (authProvider.isAdmin) // 只有管理員才顯示使用者管理按鈕
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => const UserManagementScreen()),
                  );
                },
                icon: const Icon(Icons.people, size: 28),
                label: const Text(
                  '使用者管理',
                  style: TextStyle(fontSize: 20),
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                ),
              ),
            const SizedBox(height: 20),
            const Text(
              '這是 NAPP 系統的首頁。',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            const Text(
              '更多應用程式將在此處顯示。',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomAppBar( // Footbar
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                '公告消息: 系統維護通知，將於每日凌晨 2:00 - 3:00 進行。', // 範例公告
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              SizedBox(height: 4),
              Text(
                '會簽進度: 文件 A 待審核，文件 B 已完成。', // 範例會簽進度
                style: TextStyle(fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
