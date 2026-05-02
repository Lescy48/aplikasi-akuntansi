// ============================================================
// LAPORAN SCREEN
// Halaman untuk melihat laporan keuangan berdasarkan
// rentang tanggal yang dipilih user
//
// Fitur:
// - Filter rentang tanggal (dari - sampai)
// - Ringkasan total pemasukan, pengeluaran, selisih
// - Daftar transaksi dalam rentang tersebut
// - Export ke PDF
// - Export ke Excel
// ============================================================

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:excel/excel.dart' hide Border;
import '../../models/transaksi_model.dart';
import '../../services/database_service.dart';
import '../../utils/app_theme.dart';

class LaporanScreen extends StatefulWidget {
  const LaporanScreen({super.key});

  @override
  State<LaporanScreen> createState() => _LaporanScreenState();
}

class _LaporanScreenState extends State<LaporanScreen> {
  final _db = DatabaseService();

  // Rentang tanggal default: awal bulan ini sampai hari ini
  DateTime _dari = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime _sampai = DateTime.now();

  // Data laporan
  List<Transaksi> _transaksiList = [];
  double _totalPemasukan = 0;
  double _totalPengeluaran = 0;
  bool _isLoading = false;
  bool _sudahFilter = false; // Apakah user sudah pernah menekan tombol filter

  // Status export
  bool _isExportingPdf = false;
  bool _isExportingExcel = false;

  // Format tanggal dan mata uang
  final _dateFormat = DateFormat('d MMM yyyy', 'id_ID');
  final _dateFormatFull = DateFormat('EEEE, d MMMM yyyy', 'id_ID');
  final _currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  // ============================================================
  // LOAD DATA LAPORAN
  // Ambil transaksi dalam rentang tanggal yang dipilih
  // ============================================================
  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    // Ambil transaksi dalam rentang tanggal
    final list = await _db.getTransaksiByRentang(_dari, _sampai);

    // Hitung total pemasukan dan pengeluaran dari hasil filter
    double pemasukan = 0;
    double pengeluaran = 0;
    for (final t in list) {
      if (t.jenis == 'pemasukan') {
        pemasukan += t.nominal;
      } else {
        pengeluaran += t.nominal;
      }
    }

    setState(() {
      _transaksiList = list;
      _totalPemasukan = pemasukan;
      _totalPengeluaran = pengeluaran;
      _isLoading = false;
      _sudahFilter = true;
    });
  }

  // ============================================================
  // PILIH TANGGAL
  // Tampilkan date picker untuk memilih tanggal awal atau akhir
  // ============================================================
  Future<void> _pilihTanggal({required bool isDari}) async {
    final picked = await showDatePicker(
      context: context,
      // Tampilkan tanggal yang sedang aktif sebagai awal
      initialDate: isDari ? _dari : _sampai,
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

    if (picked == null) return;

    setState(() {
      if (isDari) {
        _dari = picked;
        // Jika tanggal awal melewati tanggal akhir, sesuaikan tanggal akhir
        if (_dari.isAfter(_sampai)) _sampai = _dari;
      } else {
        _sampai = picked;
        // Jika tanggal akhir sebelum tanggal awal, sesuaikan tanggal awal
        if (_sampai.isBefore(_dari)) _dari = _sampai;
      }
    });
  }

  // ============================================================
  // EXPORT PDF
  // Buat file PDF berisi laporan keuangan dan share ke aplikasi lain
  // ============================================================
  Future<void> _exportPdf() async {
    if (_transaksiList.isEmpty) {
      _showSnackbar('Tidak ada data untuk diexport', isError: true);
      return;
    }

    setState(() => _isExportingPdf = true);

    try {
      // Buat dokumen PDF baru
      final pdf = pw.Document();

      // Tambahkan halaman ke dokumen PDF
      pdf.addPage(
        pw.MultiPage(
          // Ukuran kertas A4
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (pw.Context context) => [
            // ── HEADER LAPORAN ──────────────────────────────
            pw.Text(
              'LAPORAN KEUANGAN',
              style: pw.TextStyle(
                fontSize: 20,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              'Periode: ${_dateFormat.format(_dari)} - ${_dateFormat.format(_sampai)}',
              style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
            ),
            pw.Text(
              'Dicetak: ${_dateFormatFull.format(DateTime.now())}',
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
            ),

            pw.SizedBox(height: 20),
            pw.Divider(),
            pw.SizedBox(height: 12),

            // ── RINGKASAN KEUANGAN ───────────────────────────
            pw.Text(
              'RINGKASAN',
              style: pw.TextStyle(
                fontSize: 13,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 8),

            // Tabel ringkasan
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300),
              children: [
                _pdfTableRow('Total Pemasukan',
                    _currencyFormat.format(_totalPemasukan),
                    isHeader: false, color: PdfColors.green50),
                _pdfTableRow('Total Pengeluaran',
                    _currencyFormat.format(_totalPengeluaran),
                    isHeader: false, color: PdfColors.red50),
                _pdfTableRow(
                  'Selisih (Laba/Rugi)',
                  _currencyFormat
                      .format((_totalPemasukan - _totalPengeluaran).abs()),
                  isHeader: false,
                  color: (_totalPemasukan - _totalPengeluaran) >= 0
                      ? PdfColors.lightBlue50
                      : PdfColors.orange50,
                ),
              ],
            ),

            pw.SizedBox(height: 20),

            // ── DAFTAR TRANSAKSI ─────────────────────────────
            pw.Text(
              'DAFTAR TRANSAKSI (${_transaksiList.length} transaksi)',
              style: pw.TextStyle(
                fontSize: 13,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 8),

            // Header tabel transaksi
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300),
              columnWidths: {
                0: const pw.FlexColumnWidth(1.5), // Tanggal
                1: const pw.FlexColumnWidth(2),   // Deskripsi
                2: const pw.FlexColumnWidth(1.5), // Kategori
                3: const pw.FlexColumnWidth(1),   // Jenis
                4: const pw.FlexColumnWidth(2),   // Nominal
              },
              children: [
                // Baris header
                _pdfTableRow(
                  'Tanggal | Deskripsi | Kategori | Jenis | Nominal',
                  '',
                  isHeader: true,
                ),
                // Baris data transaksi
                ..._transaksiList.map((t) => pw.TableRow(
                      decoration: pw.BoxDecoration(
                        color: t.jenis == 'pemasukan'
                            ? PdfColors.green50
                            : PdfColors.red50,
                      ),
                      children: [
                        _pdfCell(DateFormat('d/M/yy').format(t.tanggal)),
                        _pdfCell(t.deskripsi),
                        _pdfCell(t.kategori),
                        _pdfCell(t.jenis == 'pemasukan' ? 'Masuk' : 'Keluar'),
                        _pdfCell(
                          '${t.jenis == 'pemasukan' ? '+' : '-'}${_currencyFormat.format(t.nominal)}',
                        ),
                      ],
                    )),
              ],
            ),
          ],
        ),
      );

      // Simpan file PDF ke direktori sementara
      final dir = await getTemporaryDirectory();
      final fileName =
          'Laporan_${DateFormat('ddMMyyyy').format(_dari)}-${DateFormat('ddMMyyyy').format(_sampai)}.pdf';
      final file = File('${dir.path}/$fileName');
      await file.writeAsBytes(await pdf.save());

      // Share file PDF ke aplikasi lain (WhatsApp, Email, Drive, dll)
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'Laporan Keuangan $fileName',
      );
    } catch (e) {
      if (mounted) _showSnackbar('Gagal export PDF: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isExportingPdf = false);
    }
  }

  // ============================================================
  // EXPORT EXCEL
  // Buat file Excel berisi laporan keuangan dan share
  // ============================================================
  Future<void> _exportExcel() async {
    if (_transaksiList.isEmpty) {
      _showSnackbar('Tidak ada data untuk diexport', isError: true);
      return;
    }

    setState(() => _isExportingExcel = true);

    try {
      // Buat workbook Excel baru
      final excel = Excel.createExcel();

      // Hapus sheet default dan buat sheet baru
      excel.delete('Sheet1');
      final sheet = excel['Laporan Keuangan'];

      // ── HEADER LAPORAN ────────────────────────────────────
      // Gaya teks tebal untuk header
      final boldStyle = CellStyle(
        bold: true,
        backgroundColorHex: ExcelColor.fromHexString('#1A56DB'),
        fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
      );

      // Baris judul
      sheet.cell(CellIndex.indexByString('A1')).value =
          TextCellValue('LAPORAN KEUANGAN');
      sheet.cell(CellIndex.indexByString('A1')).cellStyle =
          CellStyle(bold: true, fontSize: 14);

      sheet.cell(CellIndex.indexByString('A2')).value = TextCellValue(
          'Periode: ${_dateFormat.format(_dari)} - ${_dateFormat.format(_sampai)}');

      sheet.cell(CellIndex.indexByString('A3')).value = TextCellValue(
          'Dicetak: ${_dateFormatFull.format(DateTime.now())}');

      // Baris kosong pemisah
      sheet.cell(CellIndex.indexByString('A4')).value =
          TextCellValue('');

      // ── RINGKASAN ─────────────────────────────────────────
      sheet.cell(CellIndex.indexByString('A5')).value =
          TextCellValue('RINGKASAN');
      sheet.cell(CellIndex.indexByString('A5')).cellStyle =
          CellStyle(bold: true);

      sheet.cell(CellIndex.indexByString('A6')).value =
          TextCellValue('Total Pemasukan');
      sheet.cell(CellIndex.indexByString('B6')).value =
          DoubleCellValue(_totalPemasukan);

      sheet.cell(CellIndex.indexByString('A7')).value =
          TextCellValue('Total Pengeluaran');
      sheet.cell(CellIndex.indexByString('B7')).value =
          DoubleCellValue(_totalPengeluaran);

      sheet.cell(CellIndex.indexByString('A8')).value =
          TextCellValue('Selisih (Laba/Rugi)');
      sheet.cell(CellIndex.indexByString('B8')).value =
          DoubleCellValue(_totalPemasukan - _totalPengeluaran);
      sheet.cell(CellIndex.indexByString('A8')).cellStyle =
          CellStyle(bold: true);
      sheet.cell(CellIndex.indexByString('B8')).cellStyle =
          CellStyle(bold: true);

      // Baris kosong pemisah
      sheet.cell(CellIndex.indexByString('A9')).value =
          TextCellValue('');

      // ── HEADER TABEL TRANSAKSI ────────────────────────────
      final headers = [
        'No', 'Tanggal', 'Jenis', 'Kategori',
        'Deskripsi', 'Nominal', 'Metode Bayar', 'Catatan'
      ];
      final headerCols = ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H'];

      for (int i = 0; i < headers.length; i++) {
        final cell = sheet.cell(CellIndex.indexByString('${headerCols[i]}10'));
        cell.value = TextCellValue(headers[i]);
        cell.cellStyle = boldStyle;
      }

      // ── DATA TRANSAKSI ────────────────────────────────────
      for (int i = 0; i < _transaksiList.length; i++) {
        final t = _transaksiList[i];
        final row = i + 11; // Mulai dari baris 11

        // Warna baris: hijau untuk pemasukan, merah muda untuk pengeluaran
        final rowColor = t.jenis == 'pemasukan'
            ? ExcelColor.fromHexString('#DCFCE7')
            : ExcelColor.fromHexString('#FEE2E2');

        void setCell(String col, CellValue val) {
          final cell =
              sheet.cell(CellIndex.indexByString('$col$row'));
          cell.value = val;
          cell.cellStyle = CellStyle(backgroundColorHex: rowColor);
        }

        setCell('A', IntCellValue(i + 1));
        setCell('B',
            TextCellValue(DateFormat('d/M/yyyy').format(t.tanggal)));
        setCell('C',
            TextCellValue(t.jenis == 'pemasukan' ? 'Pemasukan' : 'Pengeluaran'));
        setCell('D', TextCellValue(t.kategori));
        setCell('E', TextCellValue(t.deskripsi));
        setCell('F', DoubleCellValue(t.nominal));
        setCell('G', TextCellValue(t.metodeBayar));
        setCell('H', TextCellValue(t.catatan ?? '-'));
      }

      // Simpan file Excel ke direktori sementara
      final dir = await getTemporaryDirectory();
      final fileName =
          'Laporan_${DateFormat('ddMMyyyy').format(_dari)}-${DateFormat('ddMMyyyy').format(_sampai)}.xlsx';
      final file = File('${dir.path}/$fileName');
      final bytes = excel.encode();
      if (bytes == null) throw Exception('Gagal encode Excel');
      await file.writeAsBytes(bytes);

      // Share file Excel
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'Laporan Keuangan $fileName',
      );
    } catch (e) {
      if (mounted) _showSnackbar('Gagal export Excel: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isExportingExcel = false);
    }
  }

  // ── HELPER PDF ───────────────────────────────────────────────

  /// Buat baris tabel PDF (digunakan untuk header dan ringkasan)
  pw.TableRow _pdfTableRow(String label, String value,
      {bool isHeader = false, PdfColor color = PdfColors.white}) {
    if (isHeader) {
      // Baris header: latar biru, teks putih, tebal
      final cols = label.split(' | ');
      return pw.TableRow(
        decoration: const pw.BoxDecoration(color: PdfColors.blue800),
        children: cols
            .map((col) => pw.Padding(
                  padding: const pw.EdgeInsets.all(6),
                  child: pw.Text(
                    col,
                    style: pw.TextStyle(
                      color: PdfColors.white,
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 9,
                    ),
                  ),
                ))
            .toList(),
      );
    }
    return pw.TableRow(
      decoration: pw.BoxDecoration(color: color),
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.all(6),
          child: pw.Text(label,
              style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold, fontSize: 10)),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.all(6),
          child: pw.Text(value, style: const pw.TextStyle(fontSize: 10)),
        ),
      ],
    );
  }

  /// Buat cell tabel PDF
  pw.Widget _pdfCell(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(5),
      child: pw.Text(text, style: const pw.TextStyle(fontSize: 8)),
    );
  }

  void _showSnackbar(String pesan, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(pesan),
        backgroundColor: isError ? AppTheme.danger : AppTheme.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Deteksi tema aktif untuk menyesuaikan warna
    final isDark = context.isDark;
    final selisih = _totalPemasukan - _totalPengeluaran;
    final isLaba = selisih >= 0;

    return Scaffold(
      backgroundColor: AppTheme.bg(context),

      // ── APP BAR ───────────────────────────────────────────
      appBar: AppBar(
        backgroundColor: AppTheme.bg(context),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back,
              color: AppTheme.textPrim(context)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Laporan Keuangan',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrim(context),
            fontSize: 18,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
              height: 1,
              color: isDark
                  ? Colors.white.withOpacity(0.08)
                  : Colors.black.withOpacity(0.06)),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── FILTER RENTANG TANGGAL ────────────────────────
            Text(
              'Rentang Tanggal',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrim(context),
              ),
            ),
            const SizedBox(height: 10),

            // Baris pilih tanggal dari & sampai
            Row(
              children: [
                // Tombol pilih tanggal "Dari"
                Expanded(
                  child: _buildTanggalButton(
                    label: 'Dari',
                    tanggal: _dari,
                    onTap: () => _pilihTanggal(isDari: true),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Icon(Icons.arrow_forward,
                      color: AppTheme.textHint(context), size: 18),
                ),
                // Tombol pilih tanggal "Sampai"
                Expanded(
                  child: _buildTanggalButton(
                    label: 'Sampai',
                    tanggal: _sampai,
                    onTap: () => _pilihTanggal(isDari: false),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Tombol tampilkan laporan
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _loadData,
              icon: _isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.search, size: 18),
              label:
                  Text(_isLoading ? 'Memuat...' : 'Tampilkan Laporan'),
            ),

            // Tampilkan hasil hanya jika sudah filter
            if (_sudahFilter) ...[
              const SizedBox(height: 24),

              // ── RINGKASAN HASIL ─────────────────────────────
              Text(
                'Ringkasan',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrim(context),
                ),
              ),
              const SizedBox(height: 10),

              // Tiga kartu ringkasan
              Row(
                children: [
                  Expanded(
                    child: _buildKartuRingkasan(
                      label: 'Pemasukan',
                      nominal: _totalPemasukan,
                      warna: AppTheme.success,
                      bg: const Color(0xFFDCFCE7),
                      icon: Icons.arrow_downward_rounded,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildKartuRingkasan(
                      label: 'Pengeluaran',
                      nominal: _totalPengeluaran,
                      warna: AppTheme.danger,
                      bg: const Color(0xFFFEE2E2),
                      icon: Icons.arrow_upward_rounded,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _buildKartuRingkasan(
                label: isLaba ? 'Laba Bersih' : 'Rugi',
                nominal: selisih.abs(),
                warna: isLaba ? AppTheme.primary : AppTheme.warning,
                bg: isLaba
                    ? AppTheme.primary.withOpacity(0.15)
                    : const Color(0xFFFEF3C7),
                icon: isLaba
                    ? Icons.trending_up_rounded
                    : Icons.trending_down_rounded,
                isFullWidth: true,
              ),

              const SizedBox(height: 20),

              // ── TOMBOL EXPORT ────────────────────────────────
              Text(
                'Export Laporan',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrim(context),
                ),
              ),
              const SizedBox(height: 10),

              Row(
                children: [
                  // Tombol Export PDF
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed:
                          _isExportingPdf || _transaksiList.isEmpty
                              ? null
                              : _exportPdf,
                      icon: _isExportingPdf
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppTheme.danger),
                            )
                          : const Icon(Icons.picture_as_pdf_outlined,
                              color: AppTheme.danger),
                      label: Text(
                        _isExportingPdf ? 'Membuat...' : 'Export PDF',
                        style: const TextStyle(color: AppTheme.danger),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppTheme.danger),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Tombol Export Excel
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed:
                          _isExportingExcel || _transaksiList.isEmpty
                              ? null
                              : _exportExcel,
                      icon: _isExportingExcel
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppTheme.success),
                            )
                          : const Icon(Icons.table_chart_outlined,
                              color: AppTheme.success),
                      label: Text(
                        _isExportingExcel ? 'Membuat...' : 'Export Excel',
                        style: const TextStyle(color: AppTheme.success),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppTheme.success),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // ── DAFTAR TRANSAKSI ─────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Daftar Transaksi',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrim(context),
                    ),
                  ),
                  // Badge jumlah transaksi
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${_transaksiList.length} transaksi',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Pesan jika tidak ada transaksi di rentang ini
              if (_transaksiList.isEmpty)
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.divider(context)),
                  ),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.search_off_rounded,
                            size: 40, color: AppTheme.textHint(context)),
                        const SizedBox(height: 8),
                        Text(
                          'Tidak ada transaksi',
                          style:
                              TextStyle(color: AppTheme.textSec(context)),
                        ),
                        Text(
                          'Coba ubah rentang tanggal',
                          style: TextStyle(
                              color: AppTheme.textHint(context), fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                )
              else
                // Daftar transaksi hasil filter
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.divider(context)),
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _transaksiList.length,
                    separatorBuilder: (_, __) =>
                        Divider(height: 1, color: AppTheme.divider(context)),
                    itemBuilder: (_, i) {
                      final t = _transaksiList[i];
                      final isPemasukan = t.jenis == 'pemasukan';
                      return ListTile(
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
                            color: isPemasukan
                                ? AppTheme.success
                                : AppTheme.danger,
                            size: 20,
                          ),
                        ),
                        title: Text(
                          t.deskripsi,
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrim(context)),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${t.kategori} • ${_dateFormat.format(t.tanggal)}',
                              style: TextStyle(fontSize: 11,
                                  color: AppTheme.textSec(context)),
                            ),
                            if (t.catatan != null && t.catatan!.isNotEmpty)
                              Text('📝 ${t.catatan!}',
                                  style: TextStyle(fontSize: 11,
                                      color: AppTheme.textHint(context),
                                      fontStyle: FontStyle.italic),
                                  maxLines: 1, overflow: TextOverflow.ellipsis),
                          ],
                        ),
                        trailing: Text(
                          '${isPemasukan ? '+' : '-'}${_currencyFormat.format(t.nominal)}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: isPemasukan
                                ? AppTheme.success
                                : AppTheme.danger,
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // WIDGET: TOMBOL PILIH TANGGAL
  // ============================================================
  Widget _buildTanggalButton({
    required String label,
    required DateTime tanggal,
    required VoidCallback onTap,
  }) {
    return Builder(builder: (context) {
      final dark = Theme.of(context).brightness == Brightness.dark;
      final textPrim = dark ? AppTheme.textPrimDark : AppTheme.textPrimLight;
      final textHint = dark ? AppTheme.textHintDark : AppTheme.textHintLight;
      final borderColor = dark
          ? Colors.white.withOpacity(0.1)
          : Colors.indigo.withOpacity(0.12);
      final bgColor = dark ? const Color(0xFF1E293B) : Colors.white;

      return GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 10, color: textHint)),
              const SizedBox(height: 3),
              Row(
                children: [
                  const Icon(Icons.calendar_today_outlined,
                      size: 13, color: AppTheme.primary),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      _dateFormat.format(tanggal),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: textPrim,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    });
  }

  // ============================================================
  // WIDGET: KARTU RINGKASAN NOMINAL
  // ============================================================
  Widget _buildKartuRingkasan({
    required String label,
    required double nominal,
    required Color warna,
    required Color bg,
    required IconData icon,
    bool isFullWidth = false,
  }) {
    return Container(
      width: isFullWidth ? double.infinity : null,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: warna.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: warna, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: warna,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  _currencyFormat.format(nominal),
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: warna,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}