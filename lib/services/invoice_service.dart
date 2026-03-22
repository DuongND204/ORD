import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants.dart';
import '../core/storage.dart';
import '../models/invoice.dart';

class InvoiceService {
  static Future<Map<String, String>> _headers() async {
    final token = await Storage.getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // Tạo hoá đơn
  static Future<Invoice> generateInvoice(String orderId) async {
    final response = await http.post(
      Uri.parse('${AppConstants.baseUrl}/invoices/generate'),
      headers: await _headers(),
      body: jsonEncode({'orderId': orderId}),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      return Invoice.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Không thể tạo hoá đơn');
    }
  }

  // Lấy hoá đơn theo orderId
  static Future<Invoice> getInvoiceByOrder(String orderId) async {
    final response = await http.get(
      Uri.parse('${AppConstants.baseUrl}/invoices/order/$orderId'),
      headers: await _headers(),
    );

    if (response.statusCode == 200) {
      return Invoice.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Không tìm thấy hoá đơn');
    }
  }

  // Xác nhận thanh toán
  static Future<Invoice> markAsPaid(String invoiceId) async {
    final response = await http.put(
      Uri.parse('${AppConstants.baseUrl}/invoices/$invoiceId/pay'),
      headers: await _headers(),
    );

    if (response.statusCode == 200) {
      return Invoice.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Không thể xác nhận thanh toán');
    }
  }
}