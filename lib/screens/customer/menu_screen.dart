import 'package:flutter/material.dart';
import '../../models/menu_item.dart';
import '../../models/user.dart';
import '../../services/auth_service.dart';
import '../../services/menu_service.dart';
import '../../services/order_service.dart';
import '../../services/socket_service.dart';
import '../../services/table_service.dart';
import '../login_screen.dart';
import 'order_screen.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  List<MenuItem> _menuItems = [];
  List<String> _categories = [];
  String _selectedCategory = 'Tất cả';
  bool _isLoading = true;
  User? _currentUser;
  String? _tableId; // ID thật của bàn, lấy từ API

  final Map<String, Map<String, dynamic>> _cart = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      // 1. Lấy thông tin user hiện tại
      _currentUser = await AuthService.getCurrentUser();

      // 2. Tìm bàn có account.id == user.id
      await _loadTableId();

      // 3. Load menu
      final items = await MenuService.getMenu();
      final cats  = await MenuService.getCategories();

      setState(() {
        _menuItems  = items;
        _categories = ['Tất cả', ...cats];
        _isLoading  = false;
      });

      // 4. Connect socket sau khi đã có tableId
      _connectSocket();
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint('Lỗi loadData: $e');
    }
  }

  Future<void> _loadTableId() async {
    if (_currentUser == null) return;
    try {
      final tables = await TableService.getAllTables();
      final myTable = tables.firstWhere(
            (t) =>
        t['account'] != null &&
            t['account']['id'] == _currentUser!.id,
        orElse: () => {},
      );
      if (myTable.isNotEmpty) {
        _tableId = myTable['id'];
        debugPrint('✅ Tìm thấy bàn: $_tableId');
      } else {
        debugPrint('⚠️ Không tìm thấy bàn cho user: ${_currentUser!.id}');
      }
    } catch (e) {
      debugPrint('Lỗi loadTableId: $e');
    }
  }

  void _connectSocket() {
    SocketService.connect();

    // Join room bàn nếu có tableId
    if (_tableId != null) {
      SocketService.joinTable(_tableId!);
    }

    // Lắng nghe cập nhật trạng thái món
    SocketService.onItemStatusChanged((data) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${data['itemName']}: ${_statusLabel(data['status'])}'),
          backgroundColor: _statusColor(data['status']),
        ),
      );
    });

    // Lắng nghe hoá đơn
    SocketService.onInvoiceGenerated((data) {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Hoá đơn đã sẵn sàng'),
          content: Text(
            'Tổng tiền: ${_formatPrice((data['totalAmount'] as num).toDouble())}',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Đóng'),
            ),
          ],
        ),
      );
    });
  }

  List<MenuItem> get _filteredItems {
    if (_selectedCategory == 'Tất cả') return _menuItems;
    return _menuItems.where((i) => i.category == _selectedCategory).toList();
  }

  int get _cartCount =>
      _cart.values.fold(0, (sum, e) => sum + (e['quantity'] as int));

  void _addToCart(MenuItem item) {
    setState(() {
      if (_cart.containsKey(item.id)) {
        _cart[item.id]!['quantity']++;
      } else {
        _cart[item.id] = {'item': item, 'quantity': 1, 'note': ''};
      }
    });
  }

  void _removeFromCart(String itemId) {
    setState(() {
      if (_cart[itemId]!['quantity'] > 1) {
        _cart[itemId]!['quantity']--;
      } else {
        _cart.remove(itemId);
      }
    });
  }

  Future<void> _submitOrder() async {
    if (_cart.isEmpty) return;

    if (_currentUser == null || _tableId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không tìm thấy thông tin bàn, vui lòng đăng nhập lại'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final items = _cart.values.map((e) {
      final item = e['item'] as MenuItem;
      return {
        'menuItemId': item.id,
        'quantity':   e['quantity'],
        'note':       e['note'],
      };
    }).toList();

    try {
      await OrderService.addItems(_tableId!, _currentUser!.id, items);
      setState(() => _cart.clear());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã gửi đơn vào bếp!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _formatPrice(double price) {
    return '${price.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]}.',
    )}đ';
  }

  String _statusLabel(String status) {
    const map = {
      'confirmed': 'Bếp đã nhận',
      'ready':     'Sẵn sàng ra đồ',
      'served':    'Đã mang ra bàn',
      'cancelled': 'Đã huỷ',
    };
    return map[status] ?? status;
  }

  Color _statusColor(String status) {
    const map = {
      'confirmed': Colors.blue,
      'ready':     Colors.orange,
      'served':    Colors.green,
      'cancelled': Colors.red,
    };
    return map[status] ?? Colors.grey;
  }

  @override
  void dispose() {
    SocketService.off('order:itemStatusChanged');
    SocketService.off('invoice:generated');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_tableId != null ? 'Thực đơn' : 'Thực đơn'),
        backgroundColor: const Color(0xFFE53935),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.receipt_long),
            onPressed: _tableId == null
                ? null
                : () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => OrderScreen(tableId: _tableId!),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await AuthService.logout();
              SocketService.disconnect();
              if (!mounted) return;
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          // Hiển thị cảnh báo nếu không tìm thấy bàn
          if (_tableId == null)
            Container(
              width: double.infinity,
              color: Colors.orange.shade100,
              padding: const EdgeInsets.all(8),
              child: const Text(
                '⚠️ Không tìm thấy bàn. Vui lòng đăng nhập bằng tài khoản bàn.',
                style: TextStyle(color: Colors.orange),
                textAlign: TextAlign.center,
              ),
            ),

          // Tab categories
          SizedBox(
            height: 48,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 8),
              itemCount: _categories.length,
              itemBuilder: (_, i) {
                final cat = _categories[i];
                final isSelected = cat == _selectedCategory;
                return GestureDetector(
                  onTap: () =>
                      setState(() => _selectedCategory = cat),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding:
                    const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFFE53935)
                          : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      cat,
                      style: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : Colors.black87,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Danh sách món
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _filteredItems.length,
              itemBuilder: (_, i) {
                final item = _filteredItems[i];
                final inCart = _cart[item.id];
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.fastfood,
                              color: Colors.orange),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                            CrossAxisAlignment.start,
                            children: [
                              Text(item.name,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15)),
                              if (item.description.isNotEmpty)
                                Text(item.description,
                                    style: const TextStyle(
                                        color: Colors.grey,
                                        fontSize: 12)),
                              const SizedBox(height: 4),
                              Text(
                                _formatPrice(item.price),
                                style: const TextStyle(
                                    color: Color(0xFFE53935),
                                    fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                        if (inCart == null)
                          IconButton(
                            icon: const Icon(Icons.add_circle,
                                color: Color(0xFFE53935), size: 32),
                            onPressed: () => _addToCart(item),
                          )
                        else
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(
                                    Icons.remove_circle_outline),
                                onPressed: () =>
                                    _removeFromCart(item.id),
                              ),
                              Text('${inCart['quantity']}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16)),
                              IconButton(
                                icon: const Icon(Icons.add_circle,
                                    color: Color(0xFFE53935)),
                                onPressed: () => _addToCart(item),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),

      // Nút gửi — chỉ hiện khi có món và có tableId
      bottomNavigationBar: _cartCount > 0 && _tableId != null
          ? SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton.icon(
            onPressed: _submitOrder,
            icon: const Icon(Icons.send),
            label: Text('Gửi vào bếp ($_cartCount món)'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE53935),
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      )
          : null,
    );
  }
}