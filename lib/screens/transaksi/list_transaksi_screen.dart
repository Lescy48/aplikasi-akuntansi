// ============================================================
// LIST TRANSAKSI SCREEN - dengan Filter, Search & Summary
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:intl/intl.dart';
import '../../models/transaksi_model.dart';
import '../../services/database_service.dart';
import '../../utils/app_theme.dart';
import 'form_transaksi_screen.dart';

class ListTransaksiScreen extends StatefulWidget {
  const ListTransaksiScreen({super.key});

  @override
  State<ListTransaksiScreen> createState() => _ListTransaksiScreenState();
}

class _ListTransaksiScreenState extends State<ListTransaksiScreen> {
  final _db = DatabaseService();
  final _searchController = TextEditingController();

  List<Transaksi> _allList = [];
  List<Transaksi> _filtered = [];
  bool _isLoading = true;

  // Filter state
  String _filterJenis = 'semua'; // 'semua' | 'pemasukan' | 'pengeluaran'
  String _sortBy = 'terbaru';    // 'terbaru' | 'terlama' | 'terbesar' | 'terkecil'

  final _currencyFormat = NumberFormat.currency(
      locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
  final _dateFormat = DateFormat('d MMM yyyy', 'id_ID');

  @override
  void initState() {
    super.initState();
    _loadData();
    _searchController.addListener(_applyFilter);
  }

  @override
  void dispose() {
    _searchController.removeListener(_applyFilter);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final list = await _db.getAllTransaksi();
    _allList = list;
    _applyFilter();
    setState(() => _isLoading = false);
  }

  void _applyFilter() {
    final query = _searchController.text.toLowerCase().trim();
    List<Transaksi> result = _allList;

    // Filter jenis
    if (_filterJenis != 'semua') {
      result = result.where((t) => t.jenis == _filterJenis).toList();
    }

    // Filter search
    if (query.isNotEmpty) {
      result = result.where((t) =>
        t.deskripsi.toLowerCase().contains(query) ||
        t.kategori.toLowerCase().contains(query) ||
        (t.catatan?.toLowerCase().contains(query) ?? false) ||
        t.metodeBayar.toLowerCase().contains(query),
      ).toList();
    }

    // Sort
    switch (_sortBy) {
      case 'terbaru':
        result.sort((a, b) => b.tanggal.compareTo(a.tanggal));
        break;
      case 'terlama':
        result.sort((a, b) => a.tanggal.compareTo(b.tanggal));
        break;
      case 'terbesar':
        result.sort((a, b) => b.nominal.compareTo(a.nominal));
        break;
      case 'terkecil':
        result.sort((a, b) => a.nominal.compareTo(b.nominal));
        break;
    }

    setState(() => _filtered = result);
  }

  // Summary dari data yang sedang difilter
  double get _totalPemasukan => _filtered
      .where((t) => t.jenis == 'pemasukan')
      .fold(0, (s, t) => s + t.nominal);

  double get _totalPengeluaran => _filtered
      .where((t) => t.jenis == 'pengeluaran')
      .fold(0, (s, t) => s + t.nominal);

  Future<void> _editTransaksi(Transaksi transaksi) async {
    final ok = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => FormTransaksiScreen(
          jenisDibuka: transaksi.jenis,
          transaksiEdit: transaksi,
        ),
      ),
    );
    if (ok == true) _loadData();
  }

  Future<void> _hapusTransaksi(Transaksi transaksi) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hapus Transaksi?'),
        content: Text('Transaksi "${transaksi.deskripsi}" akan dihapus permanen.'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.danger, minimumSize: const Size(80, 40)),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirm == true && transaksi.id != null) {
      await _db.hapusTransaksi(transaksi.id!);
      _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Transaksi berhasil dihapus'),
          backgroundColor: AppTheme.danger,
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }

  Future<void> _bukaFormTambah(String jenis) async {
    final ok = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => FormTransaksiScreen(jenisDibuka: jenis)),
    );
    if (ok == true) _loadData();
  }

  void _showSortSheet() {
    final isDark = context.isDark;
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppTheme.surfaceDark : Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) {
        final textPrim = isDark ? AppTheme.textPrimDark : AppTheme.textPrimLight;
        final options = [
          ('terbaru', Icons.arrow_downward_rounded, 'Terbaru'),
          ('terlama', Icons.arrow_upward_rounded, 'Terlama'),
          ('terbesar', Icons.trending_up_rounded, 'Nominal Terbesar'),
          ('terkecil', Icons.trending_down_rounded, 'Nominal Terkecil'),
        ];
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 36, height: 4,
                  decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 16),
              Text('Urutkan', style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w700, color: textPrim)),
              const SizedBox(height: 12),
              ...options.map((opt) {
                final isActive = _sortBy == opt.$1;
                return ListTile(
                  leading: Icon(opt.$2,
                      color: isActive ? AppTheme.primary : AppTheme.textSec(context)),
                  title: Text(opt.$3, style: TextStyle(
                      fontWeight: isActive ? FontWeight.w700 : FontWeight.normal,
                      color: isActive ? AppTheme.primary : textPrim)),
                  trailing: isActive
                      ? const Icon(Icons.check_rounded, color: AppTheme.primary)
                      : null,
                  onTap: () {
                    setState(() => _sortBy = opt.$1);
                    _applyFilter();
                    Navigator.pop(context);
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final textPrim = AppTheme.textPrim(context);
    final textSec = AppTheme.textSec(context);
    final textHint = AppTheme.textHint(context);
    final borderColor = isDark
        ? Colors.white.withOpacity(0.1) : Colors.indigo.withOpacity(0.12);

    return Scaffold(
      backgroundColor: AppTheme.bg(context),
      appBar: AppBar(
        backgroundColor: AppTheme.bg(context),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textPrim),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Transaksi',
            style: TextStyle(
                fontWeight: FontWeight.w700, color: textPrim, fontSize: 18)),
        actions: [
          IconButton(
            icon: Icon(Icons.sort_rounded, color: textSec),
            tooltip: 'Urutkan',
            onPressed: _showSortSheet,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: borderColor),
        ),
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.extended(
            heroTag: 'fab_pengeluaran',
            onPressed: () => _bukaFormTambah('pengeluaran'),
            backgroundColor: AppTheme.dangerDeep,
            icon: const Icon(Icons.arrow_upward_rounded, color: Colors.white),
            label: const Text('Pengeluaran',
                style: TextStyle(color: Colors.white, fontSize: 13)),
            elevation: 4,
          ),
          const SizedBox(height: 8),
          FloatingActionButton.extended(
            heroTag: 'fab_pemasukan',
            onPressed: () => _bukaFormTambah('pemasukan'),
            backgroundColor: AppTheme.successDeep,
            icon: const Icon(Icons.arrow_downward_rounded, color: Colors.white),
            label: const Text('Pemasukan',
                style: TextStyle(color: Colors.white, fontSize: 13)),
            elevation: 4,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : Column(
              children: [
                // ── SEARCH & FILTER BAR ─────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Column(
                    children: [
                      // Search field
                      TextField(
                        controller: _searchController,
                        style: TextStyle(color: textPrim, fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'Cari deskripsi, kategori, catatan...',
                          hintStyle: TextStyle(color: textHint, fontSize: 13),
                          prefixIcon: Icon(Icons.search_rounded,
                              color: textHint, size: 20),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: Icon(Icons.clear_rounded,
                                      color: textHint, size: 18),
                                  onPressed: () {
                                    _searchController.clear();
                                    _applyFilter();
                                  },
                                )
                              : null,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          isDense: true,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Filter chip jenis
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Expanded(child: _filterChip('semua', 'Semua', null, textPrim)),
                          const SizedBox(width: 8),
                          Expanded(child: _filterChip('pemasukan', 'Pemasukan', AppTheme.success, textPrim)),
                          const SizedBox(width: 8),
                          Expanded(child: _filterChip('pengeluaran', 'Pengeluaran', AppTheme.danger, textPrim)),
                        ],
                      ),
                    ],
                  ),
                ),

                // ── SUMMARY BAR ─────────────────────────────
                if (_filtered.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppTheme.surface(context),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: borderColor),
                    ),
                    child: Row(
                      children: [
                        Expanded(child: _summaryItem(
                            'Masuk', _totalPemasukan, AppTheme.success)),
                        Container(width: 1, height: 28,
                            color: borderColor),
                        Expanded(child: _summaryItem(
                            'Keluar', _totalPengeluaran, AppTheme.danger)),
                        Container(width: 1, height: 28,
                            color: borderColor),
                        Expanded(child: _summaryItem(
                            'Selisih',
                            _totalPemasukan - _totalPengeluaran,
                            _totalPemasukan >= _totalPengeluaran
                                ? AppTheme.primary : AppTheme.warning)),

                      ],
                    ),
                  ),

                // ── LIST ────────────────────────────────────
                Expanded(
                  child: _filtered.isEmpty
                      ? _buildKosong(textSec, textHint)
                      : RefreshIndicator(
                          onRefresh: _loadData,
                          color: AppTheme.primary,
                          child: ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
                            itemCount: _filtered.length,
                            itemBuilder: (_, i) => _buildItem(
                                _filtered[i], textPrim, textSec, textHint),
                          ),
                        ),
                ),
              ],
            ),
    );
  }

  Widget _filterChip(String value, String label, Color? color, Color textPrim) {
    final isActive = _filterJenis == value;
    final activeColor = color ?? AppTheme.primary;
    return GestureDetector(
      onTap: () {
        setState(() => _filterJenis = value);
        _applyFilter();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? activeColor.withOpacity(0.15) : AppTheme.surface(context),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? activeColor : AppTheme.divider(context),
            width: isActive ? 1.5 : 1,
          ),
        ),
        child: Text(label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isActive ? FontWeight.w700 : FontWeight.normal,
              color: isActive ? activeColor : AppTheme.textSec(context),
            )),
      ),
    );
  }

  Widget _summaryItem(String label, double nominal, Color color) {
    return Column(
      children: [
        Text(label, style: TextStyle(fontSize: 10, color: AppTheme.textSec(context))),
        const SizedBox(height: 2),
        Text(
          _currencyFormat.format(nominal.abs()),
          style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w700, color: color),
          maxLines: 1, overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildItem(Transaksi transaksi, Color textPrim, Color textSec, Color textHint) {
    final isPemasukan = transaksi.jenis == 'pemasukan';
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Slidable(
        endActionPane: ActionPane(
          motion: const DrawerMotion(),
          extentRatio: 0.5,
          children: [
            SlidableAction(
              onPressed: (_) => _editTransaksi(transaksi),
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              icon: Icons.edit_outlined,
              label: 'Edit',
              borderRadius: BorderRadius.circular(16),
            ),
            SlidableAction(
              onPressed: (_) => _hapusTransaksi(transaksi),
              backgroundColor: AppTheme.danger,
              foregroundColor: Colors.white,
              icon: Icons.delete_outline_rounded,
              label: 'Hapus',
              borderRadius: BorderRadius.circular(16),
            ),
          ],
        ),
        child: GlassCard(
          padding: const EdgeInsets.all(14),
          borderRadius: 16,
          child: Row(
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  gradient: isPemasukan
                      ? AppTheme.gradientSuccess : AppTheme.gradientDanger,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isPemasukan
                      ? Icons.arrow_downward_rounded
                      : Icons.arrow_upward_rounded,
                  color: Colors.white, size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(transaksi.deskripsi,
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w600,
                            color: textPrim),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 3),
                    Text('${transaksi.kategori} • ${transaksi.metodeBayar}',
                        style: TextStyle(fontSize: 11, color: textSec)),
                    Text(_dateFormat.format(transaksi.tanggal),
                        style: TextStyle(fontSize: 11, color: textHint)),
                    if (transaksi.catatan != null && transaksi.catatan!.isNotEmpty)
                      Text('📝 ${transaksi.catatan!}',
                          style: TextStyle(fontSize: 11, color: textHint,
                              fontStyle: FontStyle.italic),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              Text(
                '${isPemasukan ? '+' : '-'}${_currencyFormat.format(transaksi.nominal)}',
                style: TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w700,
                  color: isPemasukan ? AppTheme.success : AppTheme.danger,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKosong(Color textSec, Color textHint) {
    final isEmpty = _allList.isEmpty;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(isEmpty ? Icons.receipt_long_outlined : Icons.search_off_rounded,
              size: 64, color: textHint),
          const SizedBox(height: 16),
          Text(isEmpty ? 'Belum ada transaksi' : 'Tidak ada hasil',
              style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w600, color: textSec)),
          const SizedBox(height: 6),
          Text(
            isEmpty
                ? 'Tekan tombol di bawah untuk\nmenambah transaksi pertama'
                : 'Coba ubah kata kunci atau filter',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: textHint),
          ),
          if (!isEmpty) ...[
            const SizedBox(height: 12),
            TextButton(
              onPressed: () {
                _searchController.clear();
                setState(() => _filterJenis = 'semua');
                _applyFilter();
              },
              child: const Text('Reset Filter'),
            ),
          ]
        ],
      ),
    );
  }
}