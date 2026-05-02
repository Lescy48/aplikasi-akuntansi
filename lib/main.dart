// ============================================================
// MAIN - Entry Point Aplikasi
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'services/auth_service.dart';
import 'utils/app_theme.dart';
import 'utils/theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID', null);
  runApp(const AkuntansiApp());
}

class AkuntansiApp extends StatelessWidget {
  const AkuntansiApp({super.key});

  @override
  Widget build(BuildContext context) {
    // ValueListenableBuilder otomatis rebuild saat tema berubah
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeProvider,
      builder: (_, mode, __) {
        return MaterialApp(
          title: 'Aplikasi Akuntansi',
          debugShowCheckedModeBanner: false,
          themeMode: mode,
          theme: AppTheme.lightTheme,       // Tema light mode
          darkTheme: AppTheme.darkTheme,    // Tema dark mode
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('id', 'ID'),
            Locale('en', 'US'),
          ],
          routes: {
            '/login': (_) => const LoginScreen(),
            '/dashboard': (_) => const DashboardScreen(),
          },
          home: const SplashRouter(),
        );
      },
    );
  }
}

// ============================================================
// SPLASH ROUTER - Cek sesi login saat app dibuka
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
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    final loggedIn = await AuthService.isLoggedIn();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) =>
            loggedIn ? const DashboardScreen() : const LoginScreen(),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark
              ? AppTheme.gradientBgDark
              : AppTheme.gradientBg,
        ),
        child: const Center(
          child: CircularProgressIndicator(
            color: AppTheme.primary,
            strokeWidth: 2.5,
          ),
        ),
      ),
    );
  }
}