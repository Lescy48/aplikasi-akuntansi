// ============================================================
// DASHBOARD SCREEN
// Halaman utama setelah user berhasil login
// Menampilkan:
// - Ringkasan keuangan bulan ini (pemasukan, pengeluaran, selisih)
// - Daftar 5 transaksi terbaru
// - Navigasi ke menu lain (Transaksi, Laporan, dll)
// ============================================================

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../utils/app_theme.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // Service database untuk mengambil data transaksi
  final _db = DatabaseService();

  // State untuk menyimpan data yang ditampilkan di dashboard
  String _username = 'Admin';
  double _totalPemasukan = 0;
  double _totalPengeluaran = 0;
  bool _isLoading = true; // Tampilkan loading saat data sedang diambil

  // Format mata uang Rupiah: Rp 1.000.000
  final _currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  // Format nama bulan: Januari 2025
  final _monthFormat = DateFormat('MMMM yyyy', 'id_ID');

  @override
  void initState() {
    super.initState();
    // Muat data saat halaman pertama kali dibuka
    _loadData();
  }

  // ============================================================
  // LOAD DATA DASHBOARD
  // Mengambil semua data yang dibutuhkan secara bersamaan
  // menggunakan Future.wait agar lebih efisien
  // ============================================================
  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final now = DateTime.now();

    // Ambil semua data secara paralel (lebih cepat daripada satu per satu)
    final results = await Future.wait([
      AuthService.getUsername(),
      _db.getTotalPemasukan(now.month, now.year),
      _db.getTotalPengeluaran(now.month, now.year),
    ]);

    if (!mounted) return;

    setState(() {
      _username = results[0] as String;
      _totalPemasukan = results[1] as double;
      _totalPengeluaran = results[2] as double;
      _isLoading = false;
    });
  }

  // ============================================================
  // LOGOUT
  // Tampilkan dialog konfirmasi sebelum logout
  // ============================================================
  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Konfirmasi Logout'),
        content: const Text('Apakah kamu yakin ingin keluar?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.danger,
              minimumSize: const Size(80, 40),
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await AuthService.logout();
      if (mounted) Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Hitung selisih: positif = laba, negatif = rugi
    final selisih = _totalPemasukan - _totalPengeluaran;
    final isLaba = selisih >= 0;
    final now = DateTime.now();

    return Scaffold(
      backgroundColor: AppTheme.bgPage,

      // ── APP BAR ──────────────────────────────────────────────
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Akuntansi',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
            fontSize: 18,
          ),
        ),
        actions: [
          // Tombol logout di pojok kanan atas
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: TextButton.icon(
              onPressed: _handleLogout,
              icon: const Icon(Icons.logout, size: 16, color: AppTheme.danger),
              label: const Text(
                'Logout',
                style: TextStyle(color: AppTheme.danger, fontSize: 13),
              ),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppTheme.border),
        ),
      ),

      body: _isLoading
          // Tampilkan loading spinner saat data sedang dimuat
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primary))
          : RefreshIndicator(
              // Tarik ke bawah untuk refresh data
              onRefresh: _loadData,
              color: AppTheme.primary,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── SAPAAN ───────────────────────────────────
                    Text(
                      'Halo, $_username 👋',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    Text(
                      'Ringkasan ${_monthFormat.format(now)}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppTheme.textSecondary,
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ── KARTU RINGKASAN KEUANGAN ──────────────────
                    // Menampilkan pemasukan, pengeluaran, dan selisih
                    _buildRingkasanKeuangan(selisih, isLaba),

                    const SizedBox(height: 24),

                    // ── MENU NAVIGASI CEPAT ───────────────────────
                    const Text(
                      'Menu',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildMenuGrid(),

                    const SizedBox(height: 24),

                    // ── TRANSAKSI TERBARU ─────────────────────────
                    const Text(
                      'Transaksi Terbaru',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildTransaksiTerbaru(),
                  ],
                ),
              ),
            ),
    );
  }

  // ============================================================
  // WIDGET: KARTU RINGKASAN KEUANGAN
  // Menampilkan total pemasukan, pengeluaran, dan selisih (laba/rugi)
  // ============================================================
  Widget _buildRingkasanKeuangan(double selisih, bool isLaba) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        // Gradient biru sebagai background kartu utama
        gradient: const LinearGradient(
          colors: [AppTheme.primary, AppTheme.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label laba atau rugi
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              isLaba ? '✅ Laba' : '⚠️ Rugi',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Nominal selisih (laba/rugi)
          Text(
            _currencyFormat.format(selisih.abs()),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const Text(
            'Selisih Kas Bulan Ini',
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),

          const SizedBox(height: 16),
          const Divider(color: Colors.white24),
          const SizedBox(height: 12),

          // Baris pemasukan & pengeluaran
          Row(
            children: [
              // Kolom pemasukan
              Expanded(
                child: _buildKolomRingkasan(
                  label: 'Pemasukan',
                  nominal: _totalPemasukan,
                  icon: Icons.arrow_downward_rounded,
                  warna: Colors.greenAccent,
                ),
              ),
              // Garis pemisah vertikal
              Container(width: 1, height: 40, color: Colors.white24),
              // Kolom pengeluaran
              Expanded(
                child: _buildKolomRingkasan(
                  label: 'Pengeluaran',
                  nominal: _totalPengeluaran,
                  icon: Icons.arrow_upward_rounded,
                  warna: Colors.redAccent.shade100,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Widget kolom kecil di dalam kartu ringkasan (pemasukan/pengeluaran)
  Widget _buildKolomRingkasan({
    required String label,
    required double nominal,
    required IconData icon,
    required Color warna,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: warna, size: 14),
              const SizedBox(width: 4),
              Text(label,
                  style: const TextStyle(color: Colors.white70, fontSize: 11)),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            _currencyFormat.format(nominal),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // WIDGET: GRID MENU NAVIGASI
  // Shortcut ke fitur-fitur utama aplikasi
  // ============================================================
  Widget _buildMenuGrid() {
    // Daftar menu yang tersedia
    final menus = [
      {
        'label': 'Pemasukan',
        'icon': Icons.add_circle_outline_rounded,
        'warna': AppTheme.success,
        'bg': const Color(0xFFDCFCE7),
      },
      {
        'label': 'Pengeluaran',
        'icon': Icons.remove_circle_outline_rounded,
        'warna': AppTheme.danger,
        'bg': const Color(0xFFFEE2E2),
      },
      {
        'label': 'Laporan',
        'icon': Icons.bar_chart_rounded,
        'warna': AppTheme.warning,
        'bg': const Color(0xFFFEF3C7),
      },
      {
        'label': 'Kategori',
        'icon': Icons.category_outlined,
        'warna': AppTheme.primary,
        'bg': AppTheme.primaryLight,
      },
    ];

    return GridView.builder(
      shrinkWrap: true, // Menyesuaikan tinggi dengan konten
      physics: const NeverScrollableScrollPhysics(), // Scroll dihandle parent
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4, // 4 menu dalam satu baris
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 0.85,
      ),
      itemCount: menus.length,
      itemBuilder: (_, i) {
        final menu = menus[i];
        return GestureDetector(
          onTap: () {
            // TODO: Navigasi ke halaman masing-masing menu
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${menu['label']} coming soon!'),
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 1),
              ),
            );
          },
          child: Container(
            decoration: BoxDecoration(
              color: menu['bg'] as Color,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(menu['icon'] as IconData,
                    color: menu['warna'] as Color, size: 28),
                const SizedBox(height: 6),
                Text(
                  menu['label'] as String,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: menu['warna'] as Color,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // WIDGET: DAFTAR TRANSAKSI TERBARU
  // Mengambil 5 transaksi terbaru dari database
  // ============================================================
  Widget _buildTransaksiTerbaru() {
    return FutureBuilder<List>(
      // Ambil 5 transaksi terbaru dari database
      future: _db.getTransaksiTerbaru(limit: 5),
      builder: (context, snapshot) {
        // Saat data sedang diambil
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        // Jika tidak ada transaksi sama sekali
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.border),
            ),
            child: const Center(
              child: Column(
                children: [
                  Icon(Icons.receipt_long_outlined,
                      color: AppTheme.textHint, size: 40),
                  SizedBox(height: 8),
                  Text(
                    'Belum ada transaksi',
                    style: TextStyle(color: AppTheme.textSecondary),
                  ),
                  Text(
                    'Tambah transaksi pertamamu!',
                    style:
                        TextStyle(color: AppTheme.textHint, fontSize: 12),
                  ),
                ],
              ),
            ),
          );
        }

        // Tampilkan daftar transaksi
        final transaksiList = snapshot.data!;
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.border),
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: transaksiList.length,
            separatorBuilder: (_, __) =>
                const Divider(height: 1, color: AppTheme.border),
            itemBuilder: (_, i) {
              final t = transaksiList[i];
              final isPemasukan = t.jenis == 'pemasukan';

              return ListTile(
                // Ikon berbeda untuk pemasukan dan pengeluaran
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isPemasukan
                        ? const Color(0xFFDCFCE7)
                        : const Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    isPemasukan
                        ? Icons.arrow_downward_rounded
                        : Icons.arrow_upward_rounded,
                    color: isPemasukan ? AppTheme.success : AppTheme.danger,
                    size: 20,
                  ),
                ),
                title: Text(
                  t.deskripsi,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  '${t.kategori} • ${DateFormat('d MMM', 'id_ID').format(t.tanggal)}',
                  style: const TextStyle(
                      fontSize: 11, color: AppTheme.textSecondary),
                ),
                // Nominal dengan warna hijau untuk pemasukan, merah untuk pengeluaran
                trailing: Text(
                  '${isPemasukan ? '+' : '-'}${_currencyFormat.format(t.nominal)}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isPemasukan ? AppTheme.success : AppTheme.danger,
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}