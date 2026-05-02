// ============================================================
// MODEL KATEGORI
// Representasi data kategori transaksi
// Kategori digunakan untuk mengelompokkan transaksi
// Contoh: Kategori pemasukan = Gaji, Bonus, Penjualan
//         Kategori pengeluaran = Makan, Transport, Listrik
// ============================================================

class Kategori {
  final int? id;
  final String nama;
  final String jenis;
  final String icon; // codepoint IconData sebagai string, misal '0xe25a'

  Kategori({
    this.id,
    required this.nama,
    required this.jenis,
    this.icon = '0xe867', // default: label_rounded
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nama': nama,
      'jenis': jenis,
      'icon': icon,
    };
  }

  factory Kategori.fromMap(Map<String, dynamic> map) {
    return Kategori(
      id: map['id'],
      nama: map['nama'],
      jenis: map['jenis'],
      icon: map['icon'] ?? '0xe867',
    );
  }
}