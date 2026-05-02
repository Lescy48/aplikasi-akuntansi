// ============================================================
// THEME PROVIDER
// Mengelola state dark mode / light mode di seluruh aplikasi
// Menggunakan ValueNotifier agar ringan tanpa perlu package state management
// ============================================================

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ValueNotifier<ThemeMode> {
  static const String _key = 'theme_mode';

  ThemeProvider() : super(ThemeMode.system) {
    _loadTheme(); // Muat preferensi tema saat pertama kali dibuat
  }

  // Apakah saat ini dalam dark mode
  bool get isDark => value == ThemeMode.dark;

  // Muat preferensi tema dari storage
  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_key);
    if (saved == 'dark') {
      value = ThemeMode.dark;
    } else if (saved == 'light') {
      value = ThemeMode.light;
    } else {
      value = ThemeMode.system;
    }
  }

  // Toggle antara dark dan light mode
  Future<void> toggleTheme() async {
    value = isDark ? ThemeMode.light : ThemeMode.dark;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, isDark ? 'dark' : 'light');
  }
}

// Instance global yang bisa diakses dari mana saja
final themeProvider = ThemeProvider();