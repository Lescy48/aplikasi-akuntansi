// ============================================================
// DATABASE SERVICE
// Mengelola semua operasi database SQLite:
// - Membuat & inisialisasi database
// - CRUD transaksi (Create, Read, Update, Delete)
// - CRUD kategori
// - Query khusus untuk dashboard (total per bulan, dll)
//
// Menggunakan pola Singleton agar hanya ada 1 instance
// database yang aktif selama aplikasi berjalan
// ============================================================

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/transaksi_model.dart';
import '../models/kategori_model.dart';

class DatabaseService {
  // Instance tunggal (Singleton pattern)
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  // Objek database yang akan digunakan di seluruh aplikasi
  static Database? _database;

  // Getter untuk mengakses database
  // Jika belum ada, inisialisasi terlebih dahulu
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  // ============================================================
  // INISIALISASI DATABASE
  // Membuat file database SQLite di storage device
  // ============================================================
  Future<Database> _initDatabase() async {
    // Mendapatkan path direktori penyimpanan database di device
    final dbPath = await getDatabasesPath();

    // Gabungkan path dengan nama file database
    final path = join(dbPath, 'akuntansi.db');

    // Buka (atau buat baru jika belum ada) database
    return await openDatabase(
      path,
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute(
          "ALTER TABLE kategori ADD COLUMN icon TEXT NOT NULL DEFAULT '0xe867'");
    }
  }

  // ============================================================
  // BUAT TABEL
  // Dijalankan sekali saat database pertama kali dibuat
  // ============================================================
  Future<void> _onCreate(Database db, int version) async {
    // Tabel KATEGORI: menyimpan daftar kategori transaksi
    await db.execute('''
      CREATE TABLE kategori (
        id        INTEGER PRIMARY KEY AUTOINCREMENT,
        nama      TEXT NOT NULL,
        jenis     TEXT NOT NULL CHECK(jenis IN ('pemasukan', 'pengeluaran')),
        icon      TEXT NOT NULL DEFAULT '0xe867'
      )
    ''');

    // Tabel TRANSAKSI: menyimpan semua data transaksi keuangan
    await db.execute('''
      CREATE TABLE transaksi (
        id           INTEGER PRIMARY KEY AUTOINCREMENT,
        jenis        TEXT NOT NULL CHECK(jenis IN ('pemasukan', 'pengeluaran')),
        nominal      REAL NOT NULL,
        kategori     TEXT NOT NULL,
        deskripsi    TEXT NOT NULL,
        metode_bayar TEXT NOT NULL,
        catatan      TEXT,
        tanggal      TEXT NOT NULL
      )
    ''');

    // Masukkan kategori default agar aplikasi tidak kosong saat pertama dibuka
    await _insertKategoriDefault(db);
  }

  // ============================================================
  // KATEGORI DEFAULT
  // Data awal yang langsung tersedia saat install
  // ============================================================
  Future<void> _insertKategoriDefault(Database db) async {
    final pemasukan = [
      {'nama': 'Gaji',       'icon': '0xe8d6'}, // work
      {'nama': 'Bonus',      'icon': '0xe838'}, // star
      {'nama': 'Penjualan',  'icon': '0xea12'}, // storefront
      {'nama': 'Investasi',  'icon': '0xe6e1'}, // show_chart
      {'nama': 'Lainnya',    'icon': '0xe867'}, // label
    ];
    for (final k in pemasukan) {
      await db.insert('kategori', {'nama': k['nama'], 'jenis': 'pemasukan', 'icon': k['icon']});
    }

    final pengeluaran = [
      {'nama': 'Belanja',       'icon': '0xf1cc'}, // shopping_bag
      {'nama': 'Hiburan',       'icon': '0xe02c'}, // movie
      {'nama': 'Kesehatan',     'icon': '0xe87d'}, // favorite
      {'nama': 'Lainnya',       'icon': '0xe867'}, // label
      {'nama': 'Listrik & Air', 'icon': '0xea23'}, // bolt
      {'nama': 'Makan & Minum', 'icon': '0xe56c'}, // restaurant
      {'nama': 'Transport',     'icon': '0xe1d0'}, // directions_car
    ];
    for (final k in pengeluaran) {
      await db.insert('kategori', {'nama': k['nama'], 'jenis': 'pengeluaran', 'icon': k['icon']});
    }
  }

  // ============================================================
  // CRUD TRANSAKSI
  // ============================================================

  /// Tambah transaksi baru, kembalikan ID yang dibuat SQLite
  Future<int> tambahTransaksi(Transaksi transaksi) async {
    final db = await database;
    return await db.insert('transaksi', transaksi.toMap());
  }

  /// Ambil semua transaksi, diurutkan dari yang terbaru
  Future<List<Transaksi>> getAllTransaksi() async {
    final db = await database;
    final maps = await db.query(
      'transaksi',
      orderBy: 'tanggal DESC', // Terbaru di atas
    );
    return maps.map((map) => Transaksi.fromMap(map)).toList();
  }

  /// Ambil transaksi dalam rentang tanggal tertentu (untuk laporan)
  Future<List<Transaksi>> getTransaksiByRentang(
      DateTime dari, DateTime sampai) async {
    final db = await database;
    final maps = await db.query(
      'transaksi',
      where: 'tanggal BETWEEN ? AND ?',
      whereArgs: [
        dari.toIso8601String(),
        // Set jam ke 23:59:59 agar hari terakhir ikut terhitung
        DateTime(sampai.year, sampai.month, sampai.day, 23, 59, 59)
            .toIso8601String(),
      ],
      orderBy: 'tanggal DESC',
    );
    return maps.map((map) => Transaksi.fromMap(map)).toList();
  }

  /// Update data transaksi yang sudah ada
  Future<int> updateTransaksi(Transaksi transaksi) async {
    final db = await database;
    return await db.update(
      'transaksi',
      transaksi.toMap(),
      where: 'id = ?',
      whereArgs: [transaksi.id],
    );
  }

  /// Hapus transaksi berdasarkan ID
  Future<int> hapusTransaksi(int id) async {
    final db = await database;
    return await db.delete(
      'transaksi',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ============================================================
  // QUERY DASHBOARD
  // Fungsi khusus untuk menghitung ringkasan keuangan bulan ini
  // ============================================================

  /// Hitung total pemasukan pada bulan & tahun tertentu
  Future<double> getTotalPemasukan(int bulan, int tahun) async {
    final db = await database;

    // Tentukan rentang awal dan akhir bulan
    final awalBulan = DateTime(tahun, bulan, 1);
    final akhirBulan = DateTime(tahun, bulan + 1, 0, 23, 59, 59);

    final result = await db.rawQuery('''
      SELECT COALESCE(SUM(nominal), 0) as total
      FROM transaksi
      WHERE jenis = 'pemasukan'
        AND tanggal BETWEEN ? AND ?
    ''', [awalBulan.toIso8601String(), akhirBulan.toIso8601String()]);

    // Ambil nilai total, default 0 jika tidak ada data
    return (result.first['total'] as num).toDouble();
  }

  /// Hitung total pengeluaran pada bulan & tahun tertentu
  Future<double> getTotalPengeluaran(int bulan, int tahun) async {
    final db = await database;

    final awalBulan = DateTime(tahun, bulan, 1);
    final akhirBulan = DateTime(tahun, bulan + 1, 0, 23, 59, 59);

    final result = await db.rawQuery('''
      SELECT COALESCE(SUM(nominal), 0) as total
      FROM transaksi
      WHERE jenis = 'pengeluaran'
        AND tanggal BETWEEN ? AND ?
    ''', [awalBulan.toIso8601String(), akhirBulan.toIso8601String()]);

    return (result.first['total'] as num).toDouble();
  }

  /// Ambil 5 transaksi terbaru untuk ditampilkan di dashboard
  Future<List<Transaksi>> getTransaksiTerbaru({int limit = 5}) async {
    final db = await database;
    final maps = await db.query(
      'transaksi',
      orderBy: 'tanggal DESC',
      limit: limit,
    );
    return maps.map((map) => Transaksi.fromMap(map)).toList();
  }

  // ============================================================
  // CRUD KATEGORI
  // ============================================================

  /// Ambil semua kategori berdasarkan jenis ('pemasukan' / 'pengeluaran')
  Future<List<Kategori>> getKategoriByJenis(String jenis) async {
    final db = await database;
    final maps = await db.query(
      'kategori',
      where: 'jenis = ?',
      whereArgs: [jenis],
      orderBy: 'nama ASC',
    );
    return maps.map((map) => Kategori.fromMap(map)).toList();
  }

  /// Tambah kategori baru
  Future<int> tambahKategori(Kategori kategori) async {
    final db = await database;
    return await db.insert('kategori', kategori.toMap());
  }

  /// Hapus kategori berdasarkan ID
  Future<int> hapusKategori(int id) async {
    final db = await database;
    return await db.delete(
      'kategori',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}