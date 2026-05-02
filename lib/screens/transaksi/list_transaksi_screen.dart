// ============================================================
// LIST TRANSAKSI SCREEN - Updated dengan tema baru
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
  List<Transaksi> _transaksiList = [];
  bool _isLoading = true;

  final _currencyFormat = NumberFormat.currency(
      locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
  final _dateFormat = DateFormat('d MMM yyyy', 'id_ID');

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final list = await _db.getAllTransaksi();
    setState(() {
      _transaksiList = list;
      _isLoading = false;
    });
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
    final berhasilSimpan = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => FormTransaksiScreen(jenisDibuka: jenis)),
    );
    if (berhasilSimpan == true) _loadData();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final textPrim = AppTheme.textPrim(context);
    final textSec = AppTheme.textSec(context);
    final textHint = AppTheme.textHint(context);
    final borderColor = isDark
        ? Colors.white.withOpacity(0.1) : Colors.indigo.withOpacity(0.12);
    final bgColor = AppTheme.bg(context);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: AppTheme.bg(context),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textPrim),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Transaksi',
            style: TextStyle(
                fontWeight: FontWeight.w700, color: textPrim, fontSize: 18)),
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
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primary))
          : _transaksiList.isEmpty
              ? _buildKosong(textSec, textHint)
              : RefreshIndicator(
                  onRefresh: _loadData,
                  color: AppTheme.primary,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
                    itemCount: _transaksiList.length,
                    itemBuilder: (_, i) =>
                        _buildItemTransaksi(_transaksiList[i], textPrim, textSec, textHint),
                  ),
                ),
    );
  }

  Widget _buildItemTransaksi(
      Transaksi transaksi, Color textPrim, Color textSec, Color textHint) {
    final isPemasukan = transaksi.jenis == 'pemasukan';
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Slidable(
        endActionPane: ActionPane(
          motion: const DrawerMotion(),
          extentRatio: 0.25,
          children: [
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
              // Ikon gradient
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: isPemasukan
                      ? AppTheme.gradientSuccess : AppTheme.gradientDanger,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isPemasukan
                      ? Icons.arrow_downward_rounded
                      : Icons.arrow_upward_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(transaksi.deskripsi,
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: textPrim),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 3),
                    Text(
                        '${transaksi.kategori} • ${transaksi.metodeBayar}',
                        style: TextStyle(fontSize: 11, color: textSec)),
                    Text(_dateFormat.format(transaksi.tanggal),
                        style: TextStyle(fontSize: 11, color: textHint)),
                    // Tampilkan catatan jika ada
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
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
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
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long_outlined, size: 64, color: textHint),
          const SizedBox(height: 16),
          Text('Belum ada transaksi',
              style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w600, color: textSec)),
          const SizedBox(height: 6),
          Text('Tekan tombol di bawah untuk\nmenambah transaksi pertama',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: textHint)),
        ],
      ),
    );
  }
}