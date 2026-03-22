import 'order_item.dart';

class Order {
  final String id;
  final String tableId;
  final List<OrderItem> items;
  String status; // open | closed | paid
  final double totalAmount;
  final DateTime createdAt;

  Order({
    required this.id,
    required this.tableId,
    required this.items,
    required this.status,
    required this.totalAmount,
    required this.createdAt,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    final table = json['table'];
    return Order(
      id: json['id'] ?? '',
      tableId: table is Map ? table['id'] ?? '' : table ?? '',
      items: (json['items'] as List<dynamic>? ?? [])
          .map((i) => OrderItem.fromJson(i))
          .toList(),
      status: json['status'] ?? 'open',
      totalAmount: (json['totalAmount'] ?? 0).toDouble(),
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
    );
  }
}