import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants.dart';
import '../core/storage.dart';
import '../models/order.dart';

class OrderService {
  static Future<Map<String, String>> _headers() async {
    final token = await Storage.getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // Lấy order đang mở của bàn
  static Future<Order?> getOrderByTable(String tableId) async {
    final response = await http.get(
      Uri.parse('${AppConstants.baseUrl}/orders/table/$tableId'),
      headers: await _headers(),
    );

    if (response.statusCode == 200) {
      return Order.fromJson(jsonDecode(response.body));
    } else if (response.statusCode == 404) {
      return null; // Chưa có order
    } else {
      throw Exception('Không thể tải đơn hàng');
    }
  }

  // Lấy tất cả orders đang active (bếp & phục vụ dùng)
  static Future<List<Order>> getAllActiveOrders() async {
    final response = await http.get(
      Uri.parse('${AppConstants.baseUrl}/orders'),
      headers: await _headers(),
    );

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((e) => Order.fromJson(e)).toList();
    } else {
      throw Exception('Không thể tải danh sách đơn');
    }
  }

  // Khách thêm món vào order
  static Future<Order> addItems(String tableId, String customerId,
      List<Map<String, dynamic>> items) async {
    final response = await http.post(
      Uri.parse('${AppConstants.baseUrl}/orders/items'),
      headers: await _headers(),
      body: jsonEncode({
        'tableId': tableId,
        'customerId': customerId,
        'items': items,
      }),
    );

    if (response.statusCode == 201) {
      return Order.fromJson(jsonDecode(response.body));
    } else {
      final data = jsonDecode(response.body);
      throw Exception(data['message'] ?? 'Không thể thêm món');
    }
  }

  // Cập nhật trạng thái món (bếp / phục vụ)
  static Future<void> updateItemStatus(
      String orderId, String itemId, String status) async {
    final response = await http.put(
      Uri.parse('${AppConstants.baseUrl}/orders/items/$itemId/status'),
      headers: await _headers(),
      body: jsonEncode({'orderId': orderId, 'status': status}),
    );

    if (response.statusCode != 200) {
      final data = jsonDecode(response.body);
      throw Exception(data['message'] ?? 'Không thể cập nhật trạng thái');
    }
  }

  // Huỷ món (khách)
  static Future<void> cancelItem(String orderId, String itemId) async {
    final response = await http.delete(
      Uri.parse('${AppConstants.baseUrl}/orders/items/$itemId'),
      headers: await _headers(),
      body: jsonEncode({'orderId': orderId}),
    );

    if (response.statusCode != 200) {
      throw Exception('Không thể huỷ món');
    }
  }

  // Khoá order để xuất hoá đơn
  static Future<void> closeOrder(String orderId) async {
    final response = await http.put(
      Uri.parse('${AppConstants.baseUrl}/orders/$orderId/close'),
      headers: await _headers(),
    );

    if (response.statusCode != 200) {
      throw Exception('Không thể khoá đơn hàng');
    }
  }
}