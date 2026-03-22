import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants.dart';
import '../models/menu_item.dart';

class MenuService {
  // Lấy toàn bộ menu, có thể filter theo category
  static Future<List<MenuItem>> getMenu({String? category}) async {
    String url = '${AppConstants.baseUrl}/menu?available=true';
    if (category != null) url += '&category=$category';

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((e) => MenuItem.fromJson(e)).toList();
    } else {
      throw Exception('Không thể tải menu');
    }
  }

  // Lấy danh sách categories
  static Future<List<String>> getCategories() async {
    final response = await http.get(
      Uri.parse('${AppConstants.baseUrl}/menu/categories'),
    );

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.cast<String>();
    } else {
      throw Exception('Không thể tải danh mục');
    }
  }
}