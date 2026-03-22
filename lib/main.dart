import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'services/auth_service.dart';
import 'screens/customer/menu_screen.dart';
import 'screens/kitchen/kitchen_screen.dart';
import 'screens/waiter/waiter_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nhà hàng ORD',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFE53935)),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}

// Màn hình splash — kiểm tra đã login chưa rồi chuyển đúng màn hình
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkLogin();
  }

  Future<void> _checkLogin() async {
    await Future.delayed(const Duration(milliseconds: 500));
    final user = await AuthService.getCurrentUser();

    if (!mounted) return;

    if (user == null) {
      Navigator.pushReplacement(context,
          MaterialPageRoute(builder: (_) => const LoginScreen()));
      return;
    }

    Widget screen;
    switch (user.role) {
      case 'kitchen':
        screen = const KitchenScreen();
        break;
      case 'waiter':
        screen = const WaiterScreen();
        break;
      default:
        screen = const MenuScreen();
    }

    Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.restaurant, size: 80, color: Color(0xFFE53935)),
            SizedBox(height: 16),
            Text('Nhà hàng ORD',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            SizedBox(height: 24),
            CircularProgressIndicator(color: Color(0xFFE53935)),
          ],
        ),
      ),
    );
  }
}