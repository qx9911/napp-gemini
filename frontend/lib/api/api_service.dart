// frontend/lib/api/api_service.dart

import 'dart:convert'; // 用於 JSON 編碼和解碼
import 'package:http/http.dart' as http; // 引入 http 套件
import 'package:shared_preferences/shared_preferences.dart'; // 用於本地儲存

class ApiService {
  // 後端 API 的基礎 URL
  // 請確保這個 URL 與您的後端伺服器實際運行的地址和端口一致
  // 如果在 Docker 環境中，且前端在瀏覽器中運行，這裡應該是後端的公共可訪問地址
  // 例如：http://localhost:3000 (開發環境) 或 http://your_backend_ip:3000
  static const String _baseUrl = 'http://localhost:3000/api'; // TODO: 請根據您的後端實際地址修改

  // 獲取儲存的 JWT Token
  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('jwt_token');
  }

  // 建立帶有認證頭的 HTTP 請求頭
  static Future<Map<String, String>> _getHeaders({bool includeAuth = true}) async {
    Map<String, String> headers = {
      'Content-Type': 'application/json', // 預設內容類型為 JSON
      'Accept': 'application/json',     // 接受 JSON 回應
    };

    if (includeAuth) {
      final token = await _getToken();
      if (token != null) {
        headers['Authorization'] = 'Bearer $token'; // 如果有 token，則添加認證頭
      }
    }
    return headers;
  }

  // 處理 HTTP GET 請求
  static Future<Map<String, dynamic>> get(String endpoint) async {
    final uri = Uri.parse('$_baseUrl/$endpoint'); // 構建完整的 URL
    final headers = await _getHeaders(); // 獲取請求頭

    try {
      final response = await http.get(uri, headers: headers); // 發送 GET 請求
      return _handleResponse(response); // 處理回應
    } catch (e) {
      throw Exception('網路請求失敗: $e'); // 拋出網路請求異常
    }
  }

  // 處理 HTTP POST 請求
  static Future<Map<String, dynamic>> post(String endpoint, Map<String, dynamic> data) async {
    final uri = Uri.parse('$_baseUrl/$endpoint'); // 構建完整的 URL
    final headers = await _getHeaders(); // 獲取請求頭

    try {
      final response = await http.post(
        uri,
        headers: headers,
        body: json.encode(data), // 將資料編碼為 JSON 字串
      );
      return _handleResponse(response); // 處理回應
    } catch (e) {
      throw Exception('網路請求失敗: $e'); // 拋出網路請求異常
    }
  }

  // 處理 HTTP PUT 請求
  static Future<Map<String, dynamic>> put(String endpoint, Map<String, dynamic> data) async {
    final uri = Uri.parse('$_baseUrl/$endpoint'); // 構建完整的 URL
    final headers = await _getHeaders(); // 獲取請求頭

    try {
      final response = await http.put(
        uri,
        headers: headers,
        body: json.encode(data), // 將資料編碼為 JSON 字串
      );
      return _handleResponse(response); // 處理回應
    } catch (e) {
      throw Exception('網路請求失敗: $e'); // 拋出網路請求異常
    }
  }

  // 處理 HTTP DELETE 請求
  static Future<Map<String, dynamic>> delete(String endpoint) async {
    final uri = Uri.parse('$_baseUrl/$endpoint'); // 構建完整的 URL
    final headers = await _getHeaders(); // 獲取請求頭

    try {
      final response = await http.delete(uri, headers: headers); // 發送 DELETE 請求
      return _handleResponse(response); // 處理回應
    } catch (e) {
      throw Exception('網路請求失敗: $e'); // 拋出網路請求異常
    }
  }

  // 處理 HTTP 回應的通用方法
  static Map<String, dynamic> _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      // 成功回應 (2xx 狀態碼)
      if (response.body.isNotEmpty) {
        return json.decode(response.body); // 解析 JSON 回應
      }
      return {'message': '操作成功，無回應內容'}; // 如果沒有內容，返回預設成功訊息
    } else {
      // 錯誤回應 (非 2xx 狀態碼)
      String errorMessage = '伺服器錯誤: ${response.statusCode}';
      if (response.body.isNotEmpty) {
        try {
          final errorData = json.decode(response.body);
          errorMessage = errorData['message'] ?? errorMessage; // 嘗試從回應中獲取錯誤訊息
        } catch (e) {
          // 如果回應不是 JSON 格式，則使用原始回應內容
          errorMessage = '伺服器錯誤: ${response.statusCode}, 回應: ${response.body}';
        }
      }
      throw Exception(errorMessage); // 拋出帶有錯誤訊息的異常
    }
  }
}
