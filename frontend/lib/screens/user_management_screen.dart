// frontend/lib/screens/user_management_screen.dart

import 'package:flutter/material.dart'; // 引入 Flutter Material 設計
import 'package:provider/provider.dart'; // 引入 Provider
import '../api/api_service.dart'; // 引入 API 服務
import '../providers/auth_provider.dart'; // 引入 AuthProvider
import '../widgets/custom_alert_dialog.dart'; // 引入自訂提示框

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
      setState(() {
        _users = (response as List).map((json) => User.fromJson(json)).toList(); // 解析回應為 User 列表
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', ''); // 儲存錯誤訊息
      });
      CustomAlertDialog.show(context, '錯誤', _errorMessage!); // 顯示錯誤提示
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // 顯示新增/編輯使用者的表單
  Future<void> _showUserForm({User? user}) async {
    final TextEditingController nameController = TextEditingController(text: user?.name);
    final TextEditingController usernameController = TextEditingController(text: user?.username);
    final TextEditingController emailController = TextEditingController(text: user?.email);
    final TextEditingController passwordController = TextEditingController(); // 新增時必填，編輯時可選
    String? selectedRole = user?.role; // 預設角色

    final _formKey = GlobalKey<FormState>(); // 表單驗證 Key
    bool _obscureText = true; // 密碼顯示/隱藏

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setStateSB) { // 使用 StatefulBuilder 來更新 Dialog 內部狀態
            return AlertDialog(
              title: Text(user == null ? '新增使用者' : '編輯使用者'),
              content: SingleChildScrollView(
                child: Form(
                  key: _formKey,
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
                        validator: (value) {
                          if (value == null || value.isEmpty) return '請輸入帳號';
                          return null;
                        },
                      ),
                      TextFormField(
                        controller: emailController,
                        decoration: const InputDecoration(labelText: 'Email'),
                        validator: (value) {
                          if (value == null || value.isEmpty) return '請輸入 Email';
                          if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) return '請輸入有效的 Email';
                          return null;
                        },
                      ),
                      if (user == null) // 新增時才顯示密碼欄位
                        TextFormField(
                          controller: passwordController,
                          obscureText: _obscureText,
                          decoration: InputDecoration(
                            labelText: '密碼',
                            suffixIcon: IconButton(
                              icon: Icon(_obscureText ? Icons.visibility : Icons.visibility_off),
                              onPressed: () {
                                setStateSB(() { // 更新 StatefulBuilder 的狀態
                                  _obscureText = !_obscureText;
                                });
                              },
                            ),
                          ),
                          validator: (value) {
                            if (user == null && (value == null || value.isEmpty)) return '請輸入密碼';
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
                          setStateSB(() { // 更新 StatefulBuilder 的狀態
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
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('取消'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      try {
                        if (user == null) {
                          // 新增使用者
                          await ApiService.post('users', {
                            'name': nameController.text,
                            'username': usernameController.text,
                            'email': emailController.text,
                            'password': passwordController.text,
                            'role': selectedRole,
                          });
                          CustomAlertDialog.show(context, '成功', '使用者新增成功！');
                        } else {
                          // 編輯使用者
                          await ApiService.put('users/${user.id}', {
                            'name': nameController.text,
                            'username': usernameController.text,
                            'email': emailController.text,
                            'role': selectedRole,
                          });
                          CustomAlertDialog.show(context, '成功', '使用者資訊更新成功！');
                        }
                        Navigator.of(context).pop(); // 關閉表單
                        _fetchUsers(); // 重新整理使用者列表
                      } catch (e) {
                        CustomAlertDialog.show(context, '操作失敗', e.toString().replaceFirst('Exception: ', ''));
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
    // 顯示確認對話框
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('確認刪除'),
          content: const Text('您確定要刪除此使用者嗎？此操作無法復原。'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('刪除'),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      setState(() {
        _isLoading = true;
      });
      try {
        await ApiService.delete('users/$userId'); // 呼叫 API 刪除使用者
        CustomAlertDialog.show(context, '成功', '使用者已成功刪除！');
        _fetchUsers(); // 重新整理使用者列表
      } catch (e) {
        CustomAlertDialog.show(context, '刪除失敗', e.toString().replaceFirst('Exception: ', ''));
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // 獲取 AuthProvider 實例，用於判斷是否為管理員
    final authProvider = Provider.of<AuthProvider>(context);

    // 如果不是管理員，直接顯示無權限訊息
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
            icon: const Icon(Icons.refresh), // 重新整理按鈕
            onPressed: _fetchUsers,
          ),
          IconButton(
            icon: const Icon(Icons.add), // 新增使用者按鈕
            onPressed: () => _showUserForm(),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator()) // 載入時顯示進度條
          : _errorMessage != null
              ? Center(child: Text('載入失敗: $_errorMessage')) // 顯示錯誤訊息
              : _users.isEmpty
                  ? const Center(child: Text('沒有使用者資料。')) // 沒有資料時顯示提示
                  : ListView.builder(
                      padding: const EdgeInsets.all(8.0),
                      itemCount: _users.length,
                      itemBuilder: (context, index) {
                        final user = _users[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 8.0),
                          elevation: 4.0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.blueAccent,
                              child: Text(
                                user.username[0].toUpperCase(),
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
                                  icon: const Icon(Icons.edit, color: Colors.blue),
                                  onPressed: () => _showUserForm(user: user), // 編輯使用者
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => _deleteUser(user.id), // 刪除使用者
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
    );
  }
}
