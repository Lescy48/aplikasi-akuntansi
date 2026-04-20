// ============================================================
// MODEL KATEGORI
// Representasi data kategori transaksi
// Kategori digunakan untuk mengelompokkan transaksi
// Contoh: Kategori pemasukan = Gaji, Bonus, Penjualan
//         Kategori pengeluaran = Makan, Transport, Listrik
// ============================================================

class Kategori {
  final int? id;      // Primary key (auto increment dari SQLite)
  final String nama;  // Nama kategori (misal: Gaji, Makan, dll)
  final String jenis; // 'pemasukan' atau 'pengeluaran'

  Kategori({
    this.id,
    required this.nama,
    required this.jenis,
  });

  // Konversi dari object Kategori ke Map (untuk disimpan ke SQLite)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nama': nama,
      'jenis': jenis,
    };
  }

  // Konversi dari Map (hasil query SQLite) ke object Kategori
  factory Kategori.fromMap(Map<String, dynamic> map) {
    return Kategori(
      id: map['id'],
      nama: map['nama'],
      jenis: map['jenis'],
    );
  }
}