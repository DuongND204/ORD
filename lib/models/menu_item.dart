class MenuItem {
  final String id;
  final String name;
  final String description;
  final double price;
  final String category;
  final bool isAvailable;
  final int prepTimeMinutes;

  MenuItem({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.category,
    required this.isAvailable,
    required this.prepTimeMinutes,
  });

  factory MenuItem.fromJson(Map<String, dynamic> json) {
    return MenuItem(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      category: json['category'] ?? '',
      isAvailable: json['isAvailable'] ?? true,
      prepTimeMinutes: json['prepTimeMinutes'] ?? 15,
    );
  }
}