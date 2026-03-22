import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants.dart';
import '../core/storage.dart';
import '../models/user.dart';

class AuthService {
  // Đăng nhập — trả về User nếu thành công, throw lỗi nếu thất bại
  static Future<User> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('${AppConstants.baseUrl}/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      // Lưu token và user xuống máy
      await Storage.saveToken(data['token']);
      await Storage.saveUser(jsonEncode(data['user']));
      return User.fromJson(data['user']);
    } else {
      throw Exception(data['message'] ?? 'Đăng nhập thất bại');
    }
  }

  // Đăng xuất
  static Future<void> logout() async {
    await Storage.clear();
  }

  // Kiểm tra đã login chưa (dùng khi mở lại app)
  static Future<User?> getCurrentUser() async {
    final userJson = await Storage.getUser();
    if (userJson == null) return null;
    return User.fromJson(jsonDecode(userJson));
  }
}