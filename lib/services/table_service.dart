import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants.dart';
import '../core/storage.dart';

class TableService {
  static Future<List<Map<String, dynamic>>> getAllTables() async {
    final token = await Storage.getToken();
    final response = await http.get(
      Uri.parse('${AppConstants.baseUrl}/tables'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    } else {
      throw Exception('Không thể tải danh sách bàn');
    }
  }
}