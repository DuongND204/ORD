import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../core/constants.dart';

class SocketService {
  static IO.Socket? _socket;

  static IO.Socket get socket {
    _socket ??= IO.io(
      AppConstants.socketUrl,
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .build(),
    );
    return _socket!;
  }

  // Kết nối socket
  static void connect() {
    socket.connect();
    socket.on('connect', (_) => print('✅ Socket connected'));
    socket.on('disconnect', (_) => print('🔌 Socket disconnected'));
  }

  // Ngắt kết nối
  static void disconnect() {
    socket.disconnect();
  }

  // Join room theo role
  static void joinKitchen() => socket.emit('join:kitchen');
  static void joinWaiter()  => socket.emit('join:waiter');
  static void joinTable(String tableId) =>
      socket.emit('join:table', {'tableId': tableId});

  // Lắng nghe events
  static void onNewItems(Function(dynamic) handler) =>
      socket.on('order:newItems', handler);

  static void onItemStatusChanged(Function(dynamic) handler) =>
      socket.on('order:itemStatusChanged', handler);

  static void onItemReady(Function(dynamic) handler) =>
      socket.on('order:itemReady', handler);

  static void onInvoiceGenerated(Function(dynamic) handler) =>
      socket.on('invoice:generated', handler);

  static void onQrUpdated(Function(dynamic) handler) =>
      socket.on('invoice:qrUpdated', handler);

  // Huỷ lắng nghe (gọi khi thoát màn hình)
  static void off(String event) => socket.off(event);
}