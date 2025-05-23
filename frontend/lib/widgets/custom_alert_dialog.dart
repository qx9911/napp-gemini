// frontend/lib/widgets/custom_alert_dialog.dart

import 'package:flutter/material.dart'; // 引入 Flutter Material 設計

class CustomAlertDialog {
  // 靜態方法用於顯示自訂提示框
  static void show(BuildContext context, String title, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15.0), // 圓角邊框
          ),
          title: Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.blueAccent, // 標題顏色
            ),
          ),
          content: Text(
            message,
            style: const TextStyle(
              fontSize: 16.0,
              color: Colors.black87, // 內容顏色
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text(
                '確定',
                style: TextStyle(
                  color: Colors.blueAccent, // 按鈕顏色
                  fontWeight: FontWeight.bold,
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop(); // 關閉提示框
              },
            ),
          ],
        );
      },
    );
  }
}
