import 'package:flutter/material.dart';
import '../../models/order.dart';
import '../../models/invoice.dart';
import '../../services/order_service.dart';
import '../../services/invoice_service.dart';

class OrderScreen extends StatefulWidget {
  final String tableId; // nhận từ MenuScreen truyền vào

  const OrderScreen({super.key, required this.tableId});

  @override
  State<OrderScreen> createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrderScreen> {
  Order? _order;
  Invoice? _invoice;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadOrder();
  }

  Future<void> _loadOrder() async {
    setState(() => _isLoading = true);
    try {
      final order = await OrderService.getOrderByTable(widget.tableId);
      setState(() { _order = order; _isLoading = false; });

      // Nếu order đã closed/paid thì load hoá đơn
      if (order != null && order.status != 'open') {
        try {
          final invoice = await InvoiceService.getInvoiceByOrder(order.id);
          setState(() => _invoice = invoice);
        } catch (_) {}
      }
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint('Lỗi loadOrder: $e');
    }
  }

  String _formatPrice(double p) =>
      '${p.toStringAsFixed(0).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
            (m) => '${m[1]}.',
      )}đ';

  Color _statusColor(String s) {
    const map = {
      'pending':   Colors.grey,
      'confirmed': Colors.blue,
      'ready':     Colors.orange,
      'served':    Colors.green,
      'cancelled': Colors.red,
    };
    return map[s] ?? Colors.grey;
  }

  String _statusLabel(String s) {
    const map = {
      'pending':   'Chờ bếp',
      'confirmed': 'Đang nấu',
      'ready':     'Sẵn sàng',
      'served':    'Đã ra đồ',
      'cancelled': 'Đã huỷ',
    };
    return map[s] ?? s;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Đơn của tôi'),
        backgroundColor: const Color(0xFFE53935),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadOrder,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _order == null
          ? const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('Chưa có đơn hàng nào',
                style: TextStyle(color: Colors.grey, fontSize: 16)),
          ],
        ),
      )
          : ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Danh sách món
          ..._order!.items.map(
                (item) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: _statusColor(item.status),
                  child: Text(
                    '${item.quantity}',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                title: Text(item.name),
                subtitle: item.note.isNotEmpty
                    ? Text('Ghi chú: ${item.note}')
                    : null,
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _formatPrice(item.subtotal),
                      style: const TextStyle(
                          fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: _statusColor(item.status)
                            .withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _statusLabel(item.status),
                        style: TextStyle(
                            fontSize: 11,
                            color: _statusColor(item.status)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const Divider(height: 32),

          // Tổng tiền
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Tổng cộng',
                  style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
              Text(
                _formatPrice(_order!.totalAmount),
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFE53935)),
              ),
            ],
          ),

          // Hoá đơn & QR
          if (_invoice != null) ...[
            const SizedBox(height: 24),
            const Text('Thanh toán',
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            if (_invoice!.qrImageUrl != null)
              Center(
                child: Image.network(
                  _invoice!.qrImageUrl!,
                  width: 200,
                  height: 200,
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Text(
                    'Vui lòng gọi phục vụ để thanh toán',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}