// frontend/lib/screens/user_management_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../api/api_service.dart'; // 確保此檔案存在且路徑正確
import '../providers/auth_provider.dart'; // User 模型現在定義在 auth_provider.dart 中
import '../widgets/custom_alert_dialog.dart'; // 確保此檔案存在且路徑正確

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  List<User> _users = []; // 用於儲存使用者列表
  bool _isLoading = false; // 載入狀態
  String? _errorMessage; // 錯誤訊息

  @override
  void initState() {
    super.initState();
    _fetchUsers(); // 頁面初始化時獲取使用者列表
  }

  // 獲取使用者列表
  Future<void> _fetchUsers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final response = await ApiService.get('users'); // 呼叫 API 獲取使用者列表
      if (mounted) { // 異步操作後檢查 widget 是否還在樹中
        setState(() {
          // 解析回應為 User 列表, 確保 response['users'] 是列表且元素是 Map
          if (response != null && response['users'] is List) {
            _users = (response['users'] as List)
                .map((json) => User.fromJson(json as Map<String, dynamic>))
                .toList();
          } else {
            _users = []; // 如果回應格式不對或沒有使用者資料，則清空
             _errorMessage = '無法獲取使用者資料或格式不正確';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceFirst('Exception: ', ''); // 儲存錯誤訊息
        });
        showDialog( // 修改 CustomAlertDialog 的呼叫方式
          context: context,
          builder: (ctx) => CustomAlertDialog(
            title: '錯誤',
            content: _errorMessage!,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // 顯示新增/編輯使用者的表單
  Future<void> _showUserForm({User? user}) async {
    final TextEditingController nameController = TextEditingController(text: user?.name);
    final TextEditingController usernameController = TextEditingController(text: user?.username);
    final TextEditingController emailController = TextEditingController(text: user?.email);
    final TextEditingController passwordController = TextEditingController();
    String? selectedRole = user?.role ?? 'user'; // 如果是新增，預設為 'user'

    final formKey = GlobalKey<FormState>(); // 表單驗證 Key (移到這裡，每次打開 dialog 都是新的 key)
    bool obscureText = true; // 密碼顯示/隱藏 (移到這裡)

    await showDialog(
      context: context,
      barrierDismissible: false, // 點擊外部不關閉對話框
      builder: (BuildContext dialogContext) { // 使用不同的 context 名稱
        return StatefulBuilder( // 使用 StatefulBuilder 來更新 Dialog 內部狀態
          builder: (context, setStateSB) {
            return AlertDialog(
              title: Text(user == null ? '新增使用者' : '編輯使用者資訊'),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey, // 使用這裡的 formKey
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: nameController,
                        decoration: const InputDecoration(labelText: '姓名'),
                        validator: (value) {
                          if (value == null || value.isEmpty) return '請輸入姓名';
                          return null;
                        },
                      ),
                      TextFormField(
                        controller: usernameController,
                        decoration: const InputDecoration(labelText: '帳號'),
                        readOnly: user != null, // 編輯時帳號通常不可修改
                        validator: (value) {
                          if (value == null || value.isEmpty) return '請輸入帳號';
                          return null;
                        },
                      ),
                      TextFormField(
                        controller: emailController,
                        decoration: const InputDecoration(labelText: 'Email'),
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.isEmpty) return '請輸入 Email';
                          if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) return '請輸入有效的 Email';
                          return null;
                        },
                      ),
                      if (user == null) // 新增時才需要輸入密碼
                        TextFormField(
                          controller: passwordController,
                          obscureText: obscureText,
                          decoration: InputDecoration(
                            labelText: '密碼',
                            suffixIcon: IconButton(
                              icon: Icon(obscureText ? Icons.visibility : Icons.visibility_off),
                              onPressed: () {
                                setStateSB(() {
                                  obscureText = !obscureText;
                                });
                              },
                            ),
                          ),
                          validator: (value) {
                            if (user == null && (value == null || value.isEmpty)) return '請輸入密碼';
                            if (user == null && value != null && value.length < 6) return '密碼至少需要6個字元';
                            return null;
                          },
                        ),
                      DropdownButtonFormField<String>(
                        value: selectedRole,
                        decoration: const InputDecoration(labelText: '權限'),
                        items: const [
                          DropdownMenuItem(value: 'user', child: Text('使用者')),
                          DropdownMenuItem(value: 'admin', child: Text('管理員')),
                        ],
                        onChanged: (value) {
                          setStateSB(() {
                            selectedRole = value;
                          });
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) return '請選擇權限';
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(), // 使用 dialogContext
                  child: const Text('取消'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (formKey.currentState!.validate()) {
                      final Map<String, dynamic> userData = {
                        'name': nameController.text,
                        'username': usernameController.text,
                        'email': emailController.text,
                        'role': selectedRole,
                      };
                      if (user == null) { // 新增使用者
                        userData['password'] = passwordController.text;
                      }

                      _setLoading(true); // 開始執行異步操作前設定 loading
                      try {
                        if (user == null) {
                          await ApiService.post('users', userData);
                          if (mounted) {
                             showDialog(
                                context: context, // 這裡用 widget 的 context
                                builder: (ctx) => const CustomAlertDialog(title: '成功', content: '使用者新增成功！')
                             );
                          }
                        } else {
                          await ApiService.put('users/${user.id}', userData);
                           if (mounted) {
                             showDialog(
                                context: context, // 這裡用 widget 的 context
                                builder: (ctx) => const CustomAlertDialog(title: '成功', content: '使用者資訊更新成功！')
                             );
                          }
                        }
                        Navigator.of(dialogContext).pop(); // 使用 dialogContext 關閉表單
                        _fetchUsers(); // 重新整理使用者列表
                      } catch (e) {
                        if (mounted) {
                          showDialog(
                            context: context, // 這裡用 widget 的 context
                            builder: (ctx) => CustomAlertDialog(
                              title: '操作失敗',
                              content: e.toString().replaceFirst('Exception: ', ''),
                            ),
                          );
                        }
                      } finally {
                         _setLoading(false); // 異步操作結束後設定 loading
                      }
                    }
                  },
                  child: Text(user == null ? '新增' : '儲存'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // 刪除使用者
  Future<void> _deleteUser(int userId) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) { // 使用不同的 context 名稱
        return AlertDialog(
          title: const Text('確認刪除'),
          content: const Text('您確定要刪除此使用者嗎？此操作無法復原。'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('刪除'),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      _setLoading(true);
      try {
        await ApiService.delete('users/$userId');
        if (mounted) {
          showDialog(
            context: context,
            builder: (ctx) => const CustomAlertDialog(
              title: '成功',
              content: '使用者已成功刪除！',
            ),
          );
        }
        _fetchUsers();
      } catch (e) {
        if (mounted) {
          showDialog(
            context: context,
            builder: (ctx) => CustomAlertDialog(
              title: '刪除失敗',
              content: e.toString().replaceFirst('Exception: ', ''),
            ),
          );
        }
      } finally {
        _setLoading(false);
      }
    }
  }

  void _setLoading(bool value) {
     if (!mounted) return; // 如果 widget 已被 dispose，則不執行 setState
    setState(() {
      _isLoading = value;
    });
  }


  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false); // listen: false 通常用於 initState 或按鈕回呼

    if (!authProvider.isAdmin) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('使用者管理'),
          backgroundColor: Colors.redAccent,
        ),
        body: const Center(
          child: Text(
            '您沒有權限訪問此頁面。',
            style: TextStyle(fontSize: 20, color: Colors.red),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('使用者管理'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _fetchUsers, // 載入時禁用
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _isLoading ? null : () => _showUserForm(), // 載入時禁用
          ),
        ],
      ),
      body: _isLoading && _users.isEmpty // 初始載入時顯示進度條
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('載入失敗: $_errorMessage', style: const TextStyle(color: Colors.red, fontSize: 16)),
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.refresh),
                          label: const Text('重試'),
                          onPressed: _fetchUsers,
                        )
                      ],
                    ),
                  )
                )
              : _users.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('沒有使用者資料。', style: TextStyle(fontSize: 16)),
                          const SizedBox(height: 20),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.refresh),
                            label: const Text('重新整理'),
                            onPressed: _fetchUsers,
                          )
                        ],
                      )
                    )
                  : RefreshIndicator( // 添加下拉刷新
                      onRefresh: _fetchUsers,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(8.0),
                        itemCount: _users.length,
                        itemBuilder: (context, index) {
                          final user = _users[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 8.0),
                            elevation: 3.0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10.0),
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Theme.of(context).colorScheme.secondary,
                                child: Text(
                                  user.username.isNotEmpty ? user.username[0].toUpperCase() : 'U',
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                              title: Text(
                                user.name,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('帳號: ${user.username}'),
                                  Text('Email: ${user.email}'),
                                  Text('權限: ${user.role == 'admin' ? '管理員' : '使用者'}'),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: Icon(Icons.edit, color: Theme.of(context).colorScheme.primary),
                                    tooltip: '編輯',
                                    onPressed: _isLoading ? null : () => _showUserForm(user: user),
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.delete, color: Theme.of(context).colorScheme.error),
                                    tooltip: '刪除',
                                    onPressed: _isLoading ? null : () => _deleteUser(user.id),
                                  ),
                                ],
                              ),
                              onTap: _isLoading ? null : () => _showUserForm(user: user), // 點擊列表項也可編輯
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}