// ============================================================
// MODEL TRANSAKSI
// Representasi data satu transaksi keuangan (pemasukan/pengeluaran)
// Setiap field di sini sesuai dengan kolom di tabel 'transaksi' di SQLite
// ============================================================

class Transaksi {
  final int? id;           // Primary key (auto increment dari SQLite)
  final String jenis;      // 'pemasukan' atau 'pengeluaran'
  final double nominal;    // Jumlah uang transaksi
  final String kategori;   // Nama kategori (misal: Gaji, Makan, dll)
  final String deskripsi;  // Keterangan singkat transaksi
  final String metodeBayar;// Metode pembayaran (Cash, Transfer, dll)
  final String? catatan;   // Catatan tambahan (opsional)
  final DateTime tanggal;  // Tanggal transaksi

  Transaksi({
    this.id,
    required this.jenis,
    required this.nominal,
    required this.kategori,
    required this.deskripsi,
    required this.metodeBayar,
    this.catatan,
    required this.tanggal,
  });

  // Konversi dari object Transaksi ke Map (untuk disimpan ke SQLite)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'jenis': jenis,
      'nominal': nominal,
      'kategori': kategori,
      'deskripsi': deskripsi,
      'metode_bayar': metodeBayar,
      'catatan': catatan,
      // Simpan tanggal sebagai string format ISO 8601
      'tanggal': tanggal.toIso8601String(),
    };
  }

  // Konversi dari Map (hasil query SQLite) ke object Transaksi
  factory Transaksi.fromMap(Map<String, dynamic> map) {
    return Transaksi(
      id: map['id'],
      jenis: map['jenis'],
      nominal: map['nominal'],
      kategori: map['kategori'],
      deskripsi: map['deskripsi'],
      metodeBayar: map['metode_bayar'],
      catatan: map['catatan'],
      tanggal: DateTime.parse(map['tanggal']),
    );
  }
}