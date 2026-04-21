// ============================================================
// MAIN - Entry Point Aplikasi
// Titik awal aplikasi dijalankan
// Mengatur routing, tema, dan inisialisasi awal
// ============================================================

import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart'; // Untuk inisialisasi format tanggal Indonesia
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'services/auth_service.dart';
import 'utils/app_theme.dart';

void main() async {
  // Pastikan Flutter engine siap sebelum menjalankan kode async
  WidgetsFlutterBinding.ensureInitialized();

  // Inisialisasi data format tanggal bahasa Indonesia (id_ID)
  // Wajib dipanggil sebelum menggunakan DateFormat dengan locale 'id_ID'
  await initializeDateFormatting('id_ID', null);

  runApp(const AkuntansiApp());
}

class AkuntansiApp extends StatelessWidget {
  const AkuntansiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Aplikasi Akuntansi',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      routes: {
        '/login': (_) => const LoginScreen(),
        '/dashboard': (_) => const DashboardScreen(),
      },
      home: const SplashRouter(),
    );
  }
}

// ============================================================
// SPLASH ROUTER
// Cek apakah user sudah pernah login sebelumnya
// Jika sudah → langsung ke Dashboard
// Jika belum → ke halaman Login
// ============================================================
class SplashRouter extends StatefulWidget {
  const SplashRouter({super.key});

  @override
  State<SplashRouter> createState() => _SplashRouterState();
}

class _SplashRouterState extends State<SplashRouter> {
  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    // Jeda singkat untuk splash screen
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;

    // Cek apakah ada sesi login yang tersimpan
    final loggedIn = await AuthService.isLoggedIn();
    if (!mounted) return;

    // Arahkan ke halaman yang sesuai
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) =>
            loggedIn ? const DashboardScreen() : const LoginScreen(),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Tampilan loading saat cek sesi
    return const Scaffold(
      backgroundColor: AppTheme.bgPage,
      body: Center(
        child: CircularProgressIndicator(
          color: AppTheme.primary,
          strokeWidth: 2.5,
        ),
      ),
    );
  }
}