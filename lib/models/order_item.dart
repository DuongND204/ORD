class OrderItem {
  final String id;
  final String menuItemId;
  final String name;
  final double price;
  final int quantity;
  final String note;
  String status; // pending | confirmed | ready | served | cancelled

  OrderItem({
    required this.id,
    required this.menuItemId,
    required this.name,
    required this.price,
    required this.quantity,
    required this.note,
    required this.status,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: json['id'] ?? '',
      menuItemId: json['menuItem'] is Map
          ? json['menuItem']['id'] ?? ''
          : json['menuItem'] ?? '',
      name: json['name'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      quantity: json['quantity'] ?? 1,
      note: json['note'] ?? '',
      status: json['status'] ?? 'pending',
    );
  }

  double get subtotal => price * quantity;
}