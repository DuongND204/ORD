import 'package:flutter/material.dart';
import '../../models/order.dart';
import '../../models/order_item.dart';
import '../../services/auth_service.dart';
import '../../services/order_service.dart';
import '../../services/invoice_service.dart';
import '../../services/socket_service.dart';
import '../login_screen.dart';

class WaiterScreen extends StatefulWidget {
  const WaiterScreen({super.key});

  @override
  State<WaiterScreen> createState() => _WaiterScreenState();
}

class _WaiterScreenState extends State<WaiterScreen> {
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
    setState(() { _orders = orders; _isLoading = false; });
  }

  void _connectSocket() {
    SocketService.connect();
    SocketService.joinWaiter();
    // Có món ready → reload + thông báo
    SocketService.onItemReady((data) {
      _loadOrders();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Bàn ${data['tableNumber']}: ${data['itemName']} sẵn sàng ra đồ!'),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 4),
        ),
      );
    });
  }

  Future<void> _serveItem(String orderId, String itemId) async {
    try {
      await OrderService.updateItemStatus(orderId, itemId, 'served');
      _loadOrders();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _generateInvoice(Order order) async {
    try {
      await OrderService.closeOrder(order.id);
      final invoice = await InvoiceService.generateInvoice(order.id);
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Hoá đơn'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ...invoice.items.map((i) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(child: Text('${i.quantity}x ${i.name}')),
                        Text(_formatPrice(i.subtotal)),
                      ],
                    ),
                  )),
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Tổng cộng',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(
                    _formatPrice(invoice.totalAmount),
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFE53935),
                        fontSize: 16),
                  ),
                ],
              ),
              if (invoice.qrImageUrl != null) ...[
                const SizedBox(height: 16),
                Center(
                  child: Image.network(invoice.qrImageUrl!,
                      width: 160, height: 160),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Đóng'),
            ),
            ElevatedButton(
              onPressed: () async {
                await InvoiceService.markAsPaid(invoice.id);
                if (!mounted) return;
                Navigator.pop(context);
                _loadOrders();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Đã thanh toán!'),
                      backgroundColor: Colors.green),
                );
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE53935)),
              child: const Text('Xác nhận thanh toán',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
    }
  }

  String _formatPrice(double p) =>
      '${p.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}đ';

  @override
  void dispose() {
    SocketService.off('order:itemReady');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Phục vụ'),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadOrders),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await AuthService.logout();
              SocketService.disconnect();
              if (!mounted) return;
              Navigator.pushReplacement(context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()));
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _orders.isEmpty
              ? const Center(child: Text('Không có đơn hàng nào'))
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _orders.length,
                  itemBuilder: (_, i) {
                    final order = _orders[i];
                    final readyItems = order.items
                        .where((item) => item.status == 'ready')
                        .toList();
                    final allServed = order.items
                        .where((item) => item.status != 'cancelled')
                        .every((item) => item.status == 'served');

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                            decoration: const BoxDecoration(
                              color: Color(0xFF1565C0),
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(12),
                                topRight: Radius.circular(12),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Bàn ${order.tableId}',
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16),
                                ),
                                Text(
                                  '${readyItems.length} món sẵn sàng',
                                  style: const TextStyle(
                                      color: Colors.orangeAccent),
                                ),
                              ],
                            ),
                          ),

                          // Danh sách món ready
                          ...readyItems.map((item) => ListTile(
                                leading: const Icon(Icons.dining,
                                    color: Colors.orange),
                                title: Text('x${item.quantity} ${item.name}'),
                                subtitle: item.note.isNotEmpty
                                    ? Text(item.note)
                                    : null,
                                trailing: ElevatedButton(
                                  onPressed: () =>
                                      _serveItem(order.id, item.id),
                                  style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green),
                                  child: const Text('Ra đồ',
                                      style: TextStyle(color: Colors.white)),
                                ),
                              )),

                          // Nút xuất hoá đơn nếu tất cả đã served
                          if (allServed && order.status == 'open')
                            Padding(
                              padding: const EdgeInsets.all(12),
                              child: SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: () => _generateInvoice(order),
                                  icon: const Icon(Icons.receipt),
                                  label: const Text('Xuất hoá đơn'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFE53935),
                                    foregroundColor: Colors.white,
                                    minimumSize: const Size(0, 44),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}