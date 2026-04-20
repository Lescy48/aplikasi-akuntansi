import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const String _keyIsLoggedIn = 'is_logged_in';
  static const String _keyUsername = 'username';

  // Kredensial admin default
  static const String _adminUsername = 'admin';
  static const String _adminPassword = 'admin123';
  static const String _adminEmail = 'admin@akuntansi.com';

  /// Login: cek username/email + password
  static Future<Map<String, dynamic>> login({
    required String identifier, // bisa username atau email
    required String password,
  }) async {
    await Future.delayed(const Duration(milliseconds: 800)); // simulasi network

    final isValidUser =
        (identifier.trim() == _adminUsername || identifier.trim() == _adminEmail);
    final isValidPass = password == _adminPassword;

    if (isValidUser && isValidPass) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyIsLoggedIn, true);
      await prefs.setString(_keyUsername, _adminUsername);
      return {'success': true, 'message': 'Login berhasil'};
    }

    return {'success': false, 'message': 'Username atau password salah'};
  }

  /// Cek apakah sudah login (untuk splash / auto-login)
  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyIsLoggedIn) ?? false;
  }

  /// Ambil nama user yang sedang login
  static Future<String> getUsername() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUsername) ?? 'Admin';
  }

  /// Logout
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyIsLoggedIn);
    await prefs.remove(_keyUsername);
  }
}