// ============================================================
// FORM TRANSAKSI SCREEN - Updated dengan tema baru
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../models/transaksi_model.dart';
import '../../models/kategori_model.dart';
import '../../services/database_service.dart';
import '../../utils/app_theme.dart';

// Formatter untuk otomatis tambah titik ribuan saat mengetik nominal
class ThousandsSeparatorInputFormatter extends TextInputFormatter {
  final NumberFormat _fmt = NumberFormat('#,###', 'id_ID');

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final digitsOnly = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digitsOnly.isEmpty) return newValue.copyWith(text: '');
    final formatted = _fmt.format(int.parse(digitsOnly));
    return newValue.copyWith(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class FormTransaksiScreen extends StatefulWidget {
  final String jenisDibuka;
  final Transaksi? transaksiEdit; // null = tambah baru, isi = mode edit
  const FormTransaksiScreen({super.key, this.jenisDibuka = 'pemasukan', this.transaksiEdit});

  @override
  State<FormTransaksiScreen> createState() => _FormTransaksiScreenState();
}

class _FormTransaksiScreenState extends State<FormTransaksiScreen> {
  final _formKey = GlobalKey<FormState>();
  final _deskripsiController = TextEditingController();
  final _nominalController = TextEditingController();
  final _catatanController = TextEditingController();
  final _db = DatabaseService();

  late String _jenis;
  DateTime _tanggal = DateTime.now();
  String? _kategoriDipilih;
  String _metodeBayar = 'Cash';
  List<Kategori> _daftarKategori = [];
  bool _isLoading = false;

  final _dateFormat = DateFormat('EEEE, d MMMM yyyy', 'id_ID');
  final _currencyFormat = NumberFormat.currency(
      locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  final List<String> _metodeBayarList = [
    'Cash', 'Transfer Bank', 'Kartu Debit', 'Kartu Kredit',
    'Dompet Digital', 'Lainnya',
  ];

  @override
  void initState() {
    super.initState();
    _jenis = widget.jenisDibuka;
    // Mode edit: isi field dengan data transaksi yang ada
    if (widget.transaksiEdit != null) {
      final t = widget.transaksiEdit!;
      _jenis = t.jenis;
      _tanggal = t.tanggal;
      _metodeBayar = t.metodeBayar;
      _deskripsiController.text = t.deskripsi;
      _nominalController.text = NumberFormat('#,###', 'id_ID').format(t.nominal.toInt());
      _catatanController.text = t.catatan ?? '';
      _kategoriDipilih = t.kategori;
    }
    _loadKategori();
  }

  @override
  void dispose() {
    _deskripsiController.dispose();
    _nominalController.dispose();
    _catatanController.dispose();
    super.dispose();
  }

  Future<void> _loadKategori() async {
    final list = await _db.getKategoriByJenis(_jenis);
    setState(() {
      _daftarKategori = list;
      // Mode tambah baru: pilih kategori pertama sebagai default
      // Mode edit: pertahankan kategori dari transaksi
      if (_kategoriDipilih == null) {
        _kategoriDipilih = list.isNotEmpty ? list.first.nama : null;
      }
    });
  }

  void _gantiJenis(String jenis) {
    if (_jenis == jenis) return;
    setState(() {
      _jenis = jenis;
      _kategoriDipilih = null;
    });
    _loadKategori();
  }

  Future<void> _pilihTanggal() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _tanggal,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      locale: const Locale('id', 'ID'),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: AppTheme.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _tanggal = picked);
  }

  Future<void> _simpan() async {
    if (!_formKey.currentState!.validate()) return;
    if (_kategoriDipilih == null) {
      _showSnackbar('Pilih kategori terlebih dahulu', isError: true);
      return;
    }
    setState(() => _isLoading = true);

    // Hapus titik pemisah ribuan sebelum parse ke angka
    final nominalBersih = _nominalController.text
        .replaceAll(RegExp(r'[^0-9]'), '').trim();

    final transaksi = Transaksi(
      id: widget.transaksiEdit?.id, // pertahankan ID saat edit
      jenis: _jenis,
      nominal: double.parse(nominalBersih),
      kategori: _kategoriDipilih!,
      deskripsi: _deskripsiController.text.trim(),
      metodeBayar: _metodeBayar,
      catatan: _catatanController.text.trim().isEmpty
          ? null : _catatanController.text.trim(),
      tanggal: _tanggal,
    );

    if (widget.transaksiEdit != null) {
      await _db.updateTransaksi(transaksi);
    } else {
      await _db.tambahTransaksi(transaksi);
    }
    if (!mounted) return;
    setState(() => _isLoading = false);
    _showSnackbar(widget.transaksiEdit != null
        ? 'Transaksi berhasil diperbarui ✓'
        : 'Transaksi berhasil disimpan ✓');
    await Future.delayed(const Duration(milliseconds: 600));
    if (mounted) Navigator.pop(context, true);
  }

  void _showSnackbar(String pesan, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(pesan),
      backgroundColor: isError ? AppTheme.danger : AppTheme.success,
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 2),
    ));
  }

  @override
  Widget build(BuildContext context) {
    // Ambil warna dari tema aktif (light/dark)
    final isDark = context.isDark;
    final textPrim = AppTheme.textPrim(context);
    final textSec = AppTheme.textSec(context);
    final textHint = AppTheme.textHint(context);
    final borderColor = isDark
        ? Colors.white.withOpacity(0.1)
        : Colors.indigo.withOpacity(0.12);
    final bgColor = AppTheme.bg(context);

    final isPemasukan = _jenis == 'pemasukan';
    final warnaUtama = isPemasukan ? AppTheme.success : AppTheme.danger;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: AppTheme.bg(context),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textPrim),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(widget.transaksiEdit != null ? 'Edit Transaksi' : 'Tambah Transaksi',
            style: TextStyle(fontWeight: FontWeight.w700, color: textPrim, fontSize: 18)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: borderColor),
        ),
      ),
      bottomNavigationBar: Container(
        color: AppTheme.bg(context),
        padding: EdgeInsets.fromLTRB(
            16, 12, 16, MediaQuery.of(context).viewInsets.bottom + 16),
        child: ElevatedButton(
          onPressed: _isLoading ? null : _simpan,
          style: ElevatedButton.styleFrom(
            backgroundColor: warnaUtama,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 52),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            elevation: 0,
          ),
          child: _isLoading
              ? const SizedBox(height: 20, width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : Text(widget.transaksiEdit != null
                  ? 'Perbarui ${isPemasukan ? 'Pemasukan' : 'Pengeluaran'}'
                  : 'Simpan ${isPemasukan ? 'Pemasukan' : 'Pengeluaran'}',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Tab jenis transaksi
              _buildTabJenis(textSec),
              const SizedBox(height: 20),

              _buildLabel('Tanggal', textPrim),
              const SizedBox(height: 6),
              _buildTanggalPicker(textPrim, textHint, borderColor),
              const SizedBox(height: 16),

              _buildLabel('Nominal', textPrim),
              const SizedBox(height: 6),
              TextFormField(
                controller: _nominalController,
                keyboardType: TextInputType.number,
                inputFormatters: [ThousandsSeparatorInputFormatter()],
                style: TextStyle(
                    fontSize: 20, fontWeight: FontWeight.w700, color: warnaUtama),
                decoration: InputDecoration(
                  hintText: '0',
                  prefixText: 'Rp ',
                  prefixStyle: TextStyle(
                      color: warnaUtama,
                      fontWeight: FontWeight.w700,
                      fontSize: 16),
                ),
                validator: (val) {
                  if (val == null || val.isEmpty) return 'Nominal wajib diisi';
                  final clean = val.replaceAll(RegExp(r'[^0-9]'), '');
                  final parsed = int.tryParse(clean);
                  if (parsed == null || parsed <= 0) {
                    return 'Nominal harus lebih dari 0';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              _buildLabel('Kategori', textPrim),
              const SizedBox(height: 6),
              _buildDropdownKategori(textHint),
              const SizedBox(height: 16),

              _buildLabel('Deskripsi', textPrim),
              const SizedBox(height: 6),
              TextFormField(
                controller: _deskripsiController,
                decoration: const InputDecoration(
                    hintText: 'Contoh: Gaji bulan Januari'),
                textCapitalization: TextCapitalization.sentences,
                validator: (val) => val == null || val.trim().isEmpty
                    ? 'Deskripsi wajib diisi' : null,
              ),
              const SizedBox(height: 16),

              _buildLabel('Metode Bayar', textPrim),
              const SizedBox(height: 6),
              _buildDropdownMetodeBayar(textHint),
              const SizedBox(height: 16),

              _buildLabel('Catatan (Opsional)', textPrim),
              const SizedBox(height: 6),
              TextFormField(
                controller: _catatanController,
                maxLines: 3,
                decoration: const InputDecoration(
                    hintText: 'Tambahkan catatan jika ada...'),
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabJenis(Color textSec) {
    return Container(
      decoration: BoxDecoration(
        color: context.isDark
            ? Colors.white.withOpacity(0.08)
            : Colors.black.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => _gantiJenis('pemasukan'),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  gradient: _jenis == 'pemasukan'
                      ? AppTheme.gradientSuccess : null,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.arrow_downward_rounded, size: 16,
                        color: _jenis == 'pemasukan' ? Colors.white : textSec),
                    const SizedBox(width: 6),
                    Text('Pemasukan',
                        style: TextStyle(
                            color: _jenis == 'pemasukan'
                                ? Colors.white : textSec,
                            fontWeight: FontWeight.w600,
                            fontSize: 14)),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => _gantiJenis('pengeluaran'),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  gradient: _jenis == 'pengeluaran'
                      ? AppTheme.gradientDanger : null,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.arrow_upward_rounded, size: 16,
                        color: _jenis == 'pengeluaran'
                            ? Colors.white : textSec),
                    const SizedBox(width: 6),
                    Text('Pengeluaran',
                        style: TextStyle(
                            color: _jenis == 'pengeluaran'
                                ? Colors.white : textSec,
                            fontWeight: FontWeight.w600,
                            fontSize: 14)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTanggalPicker(Color textPrim, Color textHint, Color borderColor) {
    return GestureDetector(
      onTap: _pilihTanggal,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppTheme.surface(context),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today_outlined,
                color: AppTheme.primary, size: 18),
            const SizedBox(width: 10),
            Text(_dateFormat.format(_tanggal),
                style: TextStyle(fontSize: 14, color: textPrim)),
            const Spacer(),
            Icon(Icons.chevron_right, color: textHint, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdownKategori(Color textHint) {
    if (_daftarKategori.isEmpty) {
      return Text('Memuat kategori...', style: TextStyle(color: textHint));
    }
    final isDark = context.isDark;
    final textPrim = AppTheme.textPrim(context);

    final selectedKat = _daftarKategori.firstWhere(
      (k) => k.nama == _kategoriDipilih,
      orElse: () => _daftarKategori.first,
    );
    final cp = int.tryParse(
          selectedKat.icon.startsWith('0x')
              ? selectedKat.icon.substring(2) : selectedKat.icon,
          radix: 16) ?? 0xe867;

    return DropdownButtonFormField<String>(
      value: _kategoriDipilih,
      dropdownColor: isDark ? AppTheme.surfaceDark : AppTheme.surfaceLight,
      style: TextStyle(color: textPrim, fontSize: 14),
      decoration: InputDecoration(
        prefixIcon: Icon(
          IconData(cp, fontFamily: 'MaterialIcons'),
          color: textHint, size: 20,
        ),
      ),
      items: _daftarKategori.map((k) {
        final icp = int.tryParse(
              k.icon.startsWith('0x') ? k.icon.substring(2) : k.icon,
              radix: 16) ?? 0xe867;
        return DropdownMenuItem(
          value: k.nama,
          child: Row(children: [
            Icon(IconData(icp, fontFamily: 'MaterialIcons'),
                color: textHint, size: 20),
            const SizedBox(width: 10),
            Text(k.nama, style: TextStyle(color: textPrim, fontSize: 14)),
          ]),
        );
      }).toList(),
      onChanged: (val) => setState(() => _kategoriDipilih = val),
      validator: (val) =>
          val == null ? 'Pilih kategori terlebih dahulu' : null,
    );
  }

  Widget _buildDropdownMetodeBayar(Color textHint) {
    return DropdownButtonFormField<String>(
      value: _metodeBayar,
      decoration: InputDecoration(
        prefixIcon: Icon(Icons.payment_outlined, color: textHint, size: 20),
      ),
      items: _metodeBayarList
          .map((m) => DropdownMenuItem(value: m, child: Text(m)))
          .toList(),
      onChanged: (val) => setState(() => _metodeBayar = val!),
    );
  }

  Widget _buildLabel(String text, Color color) {
    return Text(text,
        style: TextStyle(
            fontSize: 13, fontWeight: FontWeight.w600, color: color));
  }
}