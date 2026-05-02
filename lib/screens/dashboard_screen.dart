import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../utils/app_theme.dart';
import '../utils/theme_provider.dart';
import '../models/transaksi_model.dart';
import 'transaksi/form_transaksi_screen.dart';
import 'master/kategori_screen.dart';
import 'laporan/laporan_screen.dart';
import 'transaksi/list_transaksi_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _db = DatabaseService();
  int _currentIndex = 0;

  String _username = 'Admin';
  double _totalPemasukan = 0;
  double _totalPengeluaran = 0;
  List<Transaksi> _transaksiTerbaru = [];
  List<double> _chartPemasukan = List.filled(7, 0);
  List<double> _chartPengeluaran = List.filled(7, 0);
  bool _isLoading = true;

  final _currencyFormat = NumberFormat.currency(
      locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
  final _monthFormat = DateFormat('MMMM yyyy', 'id_ID');

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final now = DateTime.now();
    final results = await Future.wait([
      AuthService.getUsername(),
      _db.getTotalPemasukan(now.month, now.year),
      _db.getTotalPengeluaran(now.month, now.year),
      _db.getTransaksiTerbaru(limit: 5),
    ]);

    final chartIn = List.filled(7, 0.0);
    final chartOut = List.filled(7, 0.0);
    for (int i = 0; i < 7; i++) {
      final day = now.subtract(Duration(days: 6 - i));
      final dari = DateTime(day.year, day.month, day.day);
      final sampai = DateTime(day.year, day.month, day.day, 23, 59, 59);
      final list = await _db.getTransaksiByRentang(dari, sampai);
      for (final t in list) {
        if (t.jenis == 'pemasukan') chartIn[i] += t.nominal;
        else chartOut[i] += t.nominal;
      }
    }

    if (!mounted) return;
    setState(() {
      _username = results[0] as String;
      _totalPemasukan = results[1] as double;
      _totalPengeluaran = results[2] as double;
      _transaksiTerbaru = results[3] as List<Transaksi>;
      _chartPemasukan = chartIn;
      _chartPengeluaran = chartOut;
      _isLoading = false;
    });
  }

  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Yakin ingin keluar?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Logout', style: TextStyle(color: AppTheme.danger)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await AuthService.logout();
      if (mounted) Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  void _bukaFormTransaksi(String jenis) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => FormTransaksiScreen(jenisDibuka: jenis),
        transitionsBuilder: (_, anim, __, child) => SlideTransition(
          position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
              .animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
          child: child,
        ),
        transitionDuration: const Duration(milliseconds: 260),
      ),
    ).then((ok) { if (ok == true) _loadData(); });
  }

  void _showAddMenu(bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppTheme.surfaceDark : Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) {
        final textPrim = isDark ? AppTheme.textPrimDark : AppTheme.textPrimLight;
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 36, height: 4,
                  decoration: BoxDecoration(color: Colors.grey.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 20),
              Text('Tambah Transaksi',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: textPrim)),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(child: _addMenuBtn('Pemasukan', Icons.arrow_downward_rounded,
                    AppTheme.success, () { Navigator.pop(context); _bukaFormTransaksi('pemasukan'); })),
                const SizedBox(width: 12),
                Expanded(child: _addMenuBtn('Pengeluaran', Icons.arrow_upward_rounded,
                    AppTheme.danger, () { Navigator.pop(context); _bukaFormTransaksi('pengeluaran'); })),
              ]),
            ],
          ),
        );
      },
    );
  }

  Widget _addMenuBtn(String label, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(children: [
          Icon(icon, color: color, size: 26),
          const SizedBox(height: 6),
          Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 13)),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppTheme.bgDark : AppTheme.bgLight;
    final surfaceColor = isDark ? AppTheme.surfaceDark : AppTheme.surfaceLight;
    const borderColor = Colors.transparent;

    // 3 halaman: Beranda, Laporan, Kategori
    final pages = [
      _buildHome(isDark, bgColor, surfaceColor, borderColor),
      const LaporanScreen(),
      const KategoriScreen(),
    ];

    return Scaffold(
      backgroundColor: bgColor,
      body: IndexedStack(index: _currentIndex, children: pages),
      bottomNavigationBar: _buildBottomNav(isDark, surfaceColor, borderColor),
    );
  }

  // ── BOTTOM NAV (layout sesuai sketsa: Beranda | Laporan | [+] | Kategori ... 4 slot) ──
  Widget _buildBottomNav(bool isDark, Color surfaceColor, Color borderColor) {
    final textSec = isDark ? AppTheme.textSecDark : AppTheme.textSecLight;

    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
      ),
      child: SafeArea(
        child: SizedBox(
          height: 64,
          child: Row(
            children: [
              // Beranda
              _navItem(0, Icons.home_rounded, 'Beranda', isDark),
              // Laporan
              _navItem(1, Icons.bar_chart_rounded, 'Laporan', isDark),
              // Tombol + di tengah (lebih besar)
              Expanded(
                child: GestureDetector(
                  onTap: () => _showAddMenu(isDark),
                  child: Center(
                    child: Container(
                      width: 52, height: 52,
                      decoration: BoxDecoration(
                        color: AppTheme.primary,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [BoxShadow(
                          color: AppTheme.primary.withOpacity(0.3),
                          blurRadius: 12, offset: const Offset(0, 4),
                        )],
                      ),
                      child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
                    ),
                  ),
                ),
              ),
              // Kategori
              _navItem(2, Icons.category_rounded, 'Kategori', isDark),
              // Akun (logout)
              Expanded(
                child: GestureDetector(
                  onTap: _handleLogout,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.person_outline_rounded, color: AppTheme.danger, size: 24),
                      const SizedBox(height: 2),
                      Text('Akun', style: TextStyle(fontSize: 11, color: AppTheme.danger)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(int index, IconData icon, String label, bool isDark) {
    final isActive = _currentIndex == index;
    final color = isActive ? AppTheme.primary
        : (isDark ? AppTheme.textSecDark : AppTheme.textSecLight);
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _currentIndex = index),
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
              decoration: BoxDecoration(
                color: isActive ? AppTheme.primary.withOpacity(0.1) : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(fontSize: 11, color: color,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal)),
          ],
        ),
      ),
    );
  }

  // ── HALAMAN BERANDA ────────────────────────────────────────
  Widget _buildHome(bool isDark, Color bgColor, Color surfaceColor, Color borderColor) {
    final textPrim = isDark ? AppTheme.textPrimDark : AppTheme.textPrimLight;
    final textSec = isDark ? AppTheme.textSecDark : AppTheme.textSecLight;
    final selisih = _totalPemasukan - _totalPengeluaran;
    final isLaba = selisih >= 0;

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _loadData,
        color: AppTheme.primary,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
            : SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(children: [
                      Expanded(child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Halo, $_username 👋',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: textPrim)),
                          Text(_monthFormat.format(DateTime.now()),
                              style: TextStyle(fontSize: 12, color: textSec)),
                        ],
                      )),
                      ValueListenableBuilder<ThemeMode>(
                        valueListenable: themeProvider,
                        builder: (_, __, ___) => IconButton(
                          onPressed: themeProvider.toggleTheme,
                          icon: Icon(
                            themeProvider.isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                            color: textSec, size: 20,
                          ),
                        ),
                      ),
                    ]),

                    const SizedBox(height: 20),

                    // Kartu selisih
                    _cardSelisih(selisih, isLaba, isDark, surfaceColor, borderColor, textSec),

                    const SizedBox(height: 10),

                    // Stat pemasukan & pengeluaran
                    Row(children: [
                      Expanded(child: _statCard('Pemasukan', _totalPemasukan,
                          Icons.arrow_downward_rounded, AppTheme.success, isDark, surfaceColor, borderColor)),
                      const SizedBox(width: 10),
                      Expanded(child: _statCard('Pengeluaran', _totalPengeluaran,
                          Icons.arrow_upward_rounded, AppTheme.danger, isDark, surfaceColor, borderColor)),
                    ]),

                    const SizedBox(height: 20),

                    // Chart
                    _buildChart(isDark, textPrim, textSec, surfaceColor, borderColor),

                    const SizedBox(height: 20),

                    // Transaksi terbaru
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Transaksi Terbaru', style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w700, color: textPrim)),
                        GestureDetector(
                          onTap: () => Navigator.push(context, MaterialPageRoute(
                              builder: (_) => const ListTransaksiScreen()))
                              .then((_) => _loadData()),
                          child: Text('Lihat Semua', style: TextStyle(
                              fontSize: 12, color: AppTheme.primary, fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _listTransaksi(isDark, textPrim, textSec, surfaceColor, borderColor),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _cardSelisih(double selisih, bool isLaba, bool isDark, Color surfaceColor,
      Color borderColor, Color textSec) {
    final color = isLaba ? AppTheme.success : AppTheme.danger;
    final gradient = isLaba ? AppTheme.gradientSuccess : AppTheme.gradientDanger;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.35),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Selisih Kas Bulan Ini',
            style: TextStyle(
                fontSize: 12,
                color: Colors.white.withOpacity(0.85),
                fontWeight: FontWeight.w500)),
        const SizedBox(height: 6),
        Text(_currencyFormat.format(selisih.abs()),
            style: const TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: -1)),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(isLaba ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                size: 13, color: Colors.white),
            const SizedBox(width: 4),
            Text(isLaba ? 'Laba Bersih' : 'Rugi',
                style: const TextStyle(
                    fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white)),
          ]),
        ),
      ]),
    );
  }

  Widget _statCard(String label, double nominal, IconData icon, Color color,
      bool isDark, Color surfaceColor, Color borderColor) {
    final textPrim = isDark ? AppTheme.textPrimDark : AppTheme.textPrimLight;
    final textSec = isDark ? AppTheme.textSecDark : AppTheme.textSecLight;
    return ElevatedCard(
      padding: const EdgeInsets.all(14),
      radius: 16,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 28, height: 28,
            decoration: BoxDecoration(color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: color, size: 15),
          ),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(fontSize: 11, color: textSec)),
        ]),
        const SizedBox(height: 8),
        Text(_currencyFormat.format(nominal),
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: textPrim),
            maxLines: 1, overflow: TextOverflow.ellipsis),
      ]),
    );
  }

  Widget _buildChart(bool isDark, Color textPrim, Color textSec,
      Color surfaceColor, Color borderColor) {
    final now = DateTime.now();
    final labels = List.generate(7,
        (i) => DateFormat('E', 'id_ID').format(now.subtract(Duration(days: 6 - i))));
    final maxVal = [..._chartPemasukan, ..._chartPengeluaran]
        .fold(0.0, (a, b) => a > b ? a : b);

    return ElevatedCard(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('7 Hari Terakhir',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: textPrim)),
          Row(children: [
            _legend(AppTheme.success, 'Masuk'),
            const SizedBox(width: 10),
            _legend(AppTheme.danger, 'Keluar'),
          ]),
        ]),
        const SizedBox(height: 16),
        SizedBox(
          height: 150,
          child: maxVal == 0
              ? Center(child: Text('Belum ada data',
                  style: TextStyle(color: textSec, fontSize: 12)))
              : BarChart(BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: maxVal * 1.3,
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipColor: (_) => isDark ? AppTheme.surfaceDark : Colors.white,
                      getTooltipItem: (group, _, rod, rodIndex) => BarTooltipItem(
                        '${rodIndex == 0 ? 'Masuk' : 'Keluar'}\n${_currencyFormat.format(rod.toY)}',
                        TextStyle(
                          color: rodIndex == 0 ? AppTheme.success : AppTheme.danger,
                          fontSize: 10, fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, _) {
                        final i = value.toInt();
                        return i >= 0 && i < 7
                            ? Text(labels[i], style: TextStyle(fontSize: 10, color: textSec))
                            : const SizedBox();
                      },
                    )),
                    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: FlGridData(
                    drawVerticalLine: false,
                    horizontalInterval: maxVal / 3,
                    getDrawingHorizontalLine: (_) => FlLine(
                      color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.04),
                      strokeWidth: 1,
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: List.generate(7, (i) => BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(toY: _chartPemasukan[i], color: AppTheme.success,
                          width: 8, borderRadius: const BorderRadius.vertical(top: Radius.circular(4))),
                      BarChartRodData(toY: _chartPengeluaran[i], color: AppTheme.danger,
                          width: 8, borderRadius: const BorderRadius.vertical(top: Radius.circular(4))),
                    ],
                  )),
                )),
        ),
      ]),
    );
  }

  Widget _legend(Color color, String label) => Row(children: [
    Container(width: 8, height: 8,
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
    const SizedBox(width: 4),
    Text(label, style: const TextStyle(fontSize: 10)),
  ]);

  Widget _listTransaksi(bool isDark, Color textPrim, Color textSec,
      Color surfaceColor, Color borderColor) {
    final textHint = isDark ? AppTheme.textHintDark : AppTheme.textHintLight;
    if (_transaksiTerbaru.isEmpty) {
      return ElevatedCard(
        padding: const EdgeInsets.all(24),
        radius: 16,
        child: Center(child: Column(children: [
          Icon(Icons.receipt_long_outlined, color: textHint, size: 36),
          const SizedBox(height: 8),
          Text('Belum ada transaksi', style: TextStyle(color: textSec, fontSize: 13)),
        ])),
      );
    }
    return ElevatedCard(
      padding: EdgeInsets.zero,
      radius: 16,
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _transaksiTerbaru.length,
        separatorBuilder: (_, __) => Divider(height: 1,
            color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05)),
        itemBuilder: (_, i) {
          final t = _transaksiTerbaru[i];
          final isMasuk = t.jenis == 'pemasukan';
          return ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            leading: Container(
              width: 38, height: 38,
              decoration: BoxDecoration(
                color: (isMasuk ? AppTheme.success : AppTheme.danger).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(isMasuk ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                  color: isMasuk ? AppTheme.success : AppTheme.danger, size: 18),
            ),
            title: Text(t.deskripsi, style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.w600, color: textPrim)),
            subtitle: Text('${t.kategori} • ${DateFormat('d MMM', 'id_ID').format(t.tanggal)}',
                style: TextStyle(fontSize: 11, color: textSec)),
            trailing: Text(
              '${isMasuk ? '+' : '-'}${_currencyFormat.format(t.nominal)}',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                  color: isMasuk ? AppTheme.success : AppTheme.danger),
            ),
          );
        },
      ),
    );
  }
}