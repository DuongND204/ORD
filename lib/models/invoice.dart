class InvoiceItem {
  final String name;
  final int quantity;
  final double price;
  final double subtotal;

  InvoiceItem({
    required this.name,
    required this.quantity,
    required this.price,
    required this.subtotal,
  });

  factory InvoiceItem.fromJson(Map<String, dynamic> json) {
    return InvoiceItem(
      name: json['name'] ?? '',
      quantity: json['quantity'] ?? 1,
      price: (json['price'] ?? 0).toDouble(),
      subtotal: (json['subtotal'] ?? 0).toDouble(),
    );
  }
}

class Invoice {
  final String id;
  final String tableId;
  final List<InvoiceItem> items;
  final double subtotal;
  final double totalAmount;
  final double discountAmount;
  final double taxAmount;
  String status; // pending | paid
  final String? qrImageUrl;

  Invoice({
    required this.id,
    required this.tableId,
    required this.items,
    required this.subtotal,
    required this.totalAmount,
    required this.discountAmount,
    required this.taxAmount,
    required this.status,
    this.qrImageUrl,
  });

  factory Invoice.fromJson(Map<String, dynamic> json) {
    final table = json['table'];
    return Invoice(
      id: json['id'] ?? '',
      tableId: table is Map ? table['id'] ?? '' : table ?? '',
      items: (json['items'] as List<dynamic>? ?? [])
          .map((i) => InvoiceItem.fromJson(i))
          .toList(),
      subtotal: (json['subtotal'] ?? 0).toDouble(),
      totalAmount: (json['totalAmount'] ?? 0).toDouble(),
      discountAmount: (json['discountAmount'] ?? 0).toDouble(),
      taxAmount: (json['taxAmount'] ?? 0).toDouble(),
      status: json['status'] ?? 'pending',
      qrImageUrl: json['qrImageUrl'],
    );
  }
}