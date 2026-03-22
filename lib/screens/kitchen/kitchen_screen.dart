import 'package:flutter/material.dart';
import '../../models/order.dart';
import '../../models/order_item.dart';
import '../../services/auth_service.dart';
import '../../services/order_service.dart';
import '../../services/socket_service.dart';
import '../login_screen.dart';

class KitchenScreen extends StatefulWidget {
  const KitchenScreen({super.key});

  @override
  State<KitchenScreen> createState() => _KitchenScreenState();
}

class _KitchenScreenState extends State<KitchenScreen> {
  List<Order> _orders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadOrders();
    _connectSocket();
  }

  Future<void> _loadOrders() async {
    setState(() => _isLoading = true);
    final orders = await OrderService.getAllActiveOrders();
    setState(() {
      _orders = orders;
      _isLoading = false;
    });
  }

  void _connectSocket() {
    SocketService.connect();
    SocketService.joinKitchen();

    // Có món mới → reload
    SocketService.onNewItems((_) => _loadOrders());

    // Món bị huỷ → reload
    SocketService.socket.on('order:itemCancelled', (_) => _loadOrders());
  }

  Future<void> _updateStatus(
    String orderId,
    String itemId,
    String status,
  ) async {
    try {
      await OrderService.updateItemStatus(orderId, itemId, status);
      _loadOrders();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
    }
  }

  String _statusLabel(String s) {
    const map = {
      'pending': 'Chờ nhận',
      'confirmed': 'Đang nấu',
      'ready': 'Xong',
    };
    return map[s] ?? s;
  }

  Color _statusColor(String s) {
    const map = {
      'pending': Colors.orange,
      'confirmed': Colors.blue,
      'ready': Colors.green,
    };
    return map[s] ?? Colors.grey;
  }

  // Nút action tiếp theo của bếp
  Widget _buildActionButton(Order order, OrderItem item) {
    if (item.status == 'pending') {
      return ElevatedButton(
        onPressed: () => _updateStatus(order.id, item.id, 'confirmed'),
        style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
        child: const Text('Nhận món', style: TextStyle(color: Colors.white)),
      );
    } else if (item.status == 'confirmed') {
      return ElevatedButton(
        onPressed: () => _updateStatus(order.id, item.id, 'ready'),
        style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
        child: const Text('Xong', style: TextStyle(color: Colors.white)),
      );
    }
    return const SizedBox.shrink();
  }

  @override
  void dispose() {
    SocketService.off('order:newItems');
    SocketService.off('order:itemCancelled');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Chỉ lấy món chưa xong (pending & confirmed)
    final activeOrders = _orders
        .where(
          (o) => o.items.any(
            (i) => i.status == 'pending' || i.status == 'confirmed',
          ),
        )
        .toList();

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF16213E),
        foregroundColor: Colors.white,
        title: const Text('Màn hình bếp'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadOrders),
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
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : activeOrders.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle, size: 72, color: Colors.green),
                  SizedBox(height: 16),
                  Text(
                    'Không có món chờ xử lý',
                    style: TextStyle(color: Colors.white70, fontSize: 18),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: activeOrders.length,
              itemBuilder: (_, i) {
                final order = activeOrders[i];
                final pendingItems = order.items
                    .where(
                      (item) =>
                          item.status == 'pending' ||
                          item.status == 'confirmed',
                    )
                    .toList();
                return Card(
                  color: const Color(0xFF16213E),
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header bàn
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        decoration: const BoxDecoration(
                          color: Color(0xFFE53935),
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(12),
                            topRight: Radius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Bàn ${order.tableId}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),

                      // Danh sách món
                      ...pendingItems.map(
                        (item) => Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: Row(
                            children: [
                              // Status badge
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: _statusColor(
                                    item.status,
                                  ).withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: _statusColor(item.status),
                                  ),
                                ),
                                child: Text(
                                  _statusLabel(item.status),
                                  style: TextStyle(
                                    color: _statusColor(item.status),
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),

                              // Tên & ghi chú
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'x${item.quantity}  ${item.name}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    if (item.note.isNotEmpty)
                                      Text(
                                        'Ghi chú: ${item.note}',
                                        style: const TextStyle(
                                          color: Colors.orange,
                                          fontSize: 12,
                                        ),
                                      ),
                                  ],
                                ),
                              ),

                              // Action button
                              _buildActionButton(order, item),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
