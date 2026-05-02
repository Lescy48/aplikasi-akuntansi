// ============================================================
// KATEGORI SCREEN - Updated dengan tema baru
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../../models/kategori_model.dart';
import '../../services/database_service.dart';
import '../../utils/app_theme.dart';

class KategoriScreen extends StatefulWidget {
  const KategoriScreen({super.key});

  @override
  State<KategoriScreen> createState() => _KategoriScreenState();
}

class _KategoriScreenState extends State<KategoriScreen>
    with SingleTickerProviderStateMixin {
  final _db = DatabaseService();
  late TabController _tabController;
  List<Kategori> _kategoriPemasukan = [];
  List<Kategori> _kategoriPengeluaran = [];
  bool _isLoading = true;

  final List<String> _kategoriDefault = [
    'Gaji', 'Bonus', 'Penjualan', 'Investasi',
    'Makan & Minum', 'Transport', 'Listrik & Air',
    'Belanja', 'Kesehatan', 'Hiburan', 'Lainnya',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final results = await Future.wait([
      _db.getKategoriByJenis('pemasukan'),
      _db.getKategoriByJenis('pengeluaran'),
    ]);
    setState(() {
      _kategoriPemasukan = results[0];
      _kategoriPengeluaran = results[1];
      _isLoading = false;
    });
  }

  // Daftar icon yang bisa dipilih user
  static List<Map<String, dynamic>> get _iconOptions => [
    // Pekerjaan & Keuangan
    {'icon': Icons.payments_rounded.codePoint,           'label': 'Gaji'},
    {'icon': Icons.card_giftcard_rounded.codePoint,      'label': 'Bonus'},
    {'icon': Icons.account_balance_wallet_rounded.codePoint, 'label': 'Dompet'},
    {'icon': Icons.storefront_rounded.codePoint,         'label': 'Toko'},
    {'icon': Icons.trending_up_rounded.codePoint,        'label': 'Grafik'},
    {'icon': Icons.savings_rounded.codePoint,            'label': 'Tabungan'},
    {'icon': Icons.sell_rounded.codePoint,               'label': 'Jual'},
    {'icon': Icons.account_balance_rounded.codePoint,    'label': 'Bank'},
    // Makanan & Minuman
    {'icon': Icons.restaurant_rounded.codePoint,         'label': 'Makan'},
    {'icon': Icons.local_cafe_rounded.codePoint,         'label': 'Kafe'},
    {'icon': Icons.local_grocery_store_rounded.codePoint,'label': 'Groceri'},
    {'icon': Icons.local_atm_rounded.codePoint,          'label': 'ATM'},
    // Transport
    {'icon': Icons.directions_car_rounded.codePoint,     'label': 'Mobil'},
    {'icon': Icons.directions_bus_rounded.codePoint,     'label': 'Bus'},
    {'icon': Icons.flight_rounded.codePoint,             'label': 'Pesawat'},
    {'icon': Icons.two_wheeler_rounded.codePoint,        'label': 'Motor'},
    // Rumah & Utilitas
    {'icon': Icons.home_rounded.codePoint,               'label': 'Rumah'},
    {'icon': Icons.bolt_rounded.codePoint,               'label': 'Listrik'},
    {'icon': Icons.wifi_rounded.codePoint,               'label': 'Wifi'},
    {'icon': Icons.water_drop_rounded.codePoint,         'label': 'Air'},
    // Belanja & Gaya Hidup
    {'icon': Icons.shopping_bag_rounded.codePoint,       'label': 'Belanja'},
    {'icon': Icons.checkroom_rounded.codePoint,          'label': 'Pakaian'},
    {'icon': Icons.sports_esports_rounded.codePoint,     'label': 'Games'},
    {'icon': Icons.movie_rounded.codePoint,              'label': 'Film'},
    {'icon': Icons.music_note_rounded.codePoint,         'label': 'Musik'},
    // Kesehatan & Pendidikan
    {'icon': Icons.favorite_rounded.codePoint,           'label': 'Kesehatan'},
    {'icon': Icons.medical_services_rounded.codePoint,   'label': 'Medis'},
    {'icon': Icons.fitness_center_rounded.codePoint,     'label': 'Gym'},
    {'icon': Icons.school_rounded.codePoint,             'label': 'Sekolah'},
    {'icon': Icons.label_rounded.codePoint,              'label': 'Lainnya'},
  ];

  Future<void> _tambahKategori() async {
    final jenis = _tabController.index == 0 ? 'pemasukan' : 'pengeluaran';
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();
    String selectedIcon = '0xe867';

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            final isDark = ctx.isDark;
            final bgColor = isDark ? AppTheme.surfaceDark : Colors.white;
            final textPrim = AppTheme.textPrim(ctx);
            final textSec = AppTheme.textSec(ctx);
            final isGreen = jenis == 'pemasukan';
            final gradient = isGreen ? AppTheme.gradientSuccess : AppTheme.gradientDanger;
            final accentColor = isGreen ? AppTheme.success : AppTheme.danger;

            return Container(
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: EdgeInsets.fromLTRB(
                  20, 0, 20, MediaQuery.of(ctx).viewInsets.bottom + 24),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Handle bar
                    Center(
                      child: Container(
                        margin: const EdgeInsets.only(top: 12, bottom: 20),
                        width: 40, height: 4,
                        decoration: BoxDecoration(
                          color: AppTheme.textHint(ctx).withOpacity(0.4),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),

                    // Header
                    Row(children: [
                      Container(
                        width: 44, height: 44,
                        decoration: BoxDecoration(
                          gradient: gradient,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          IconData(int.parse(selectedIcon.startsWith('0x') ? selectedIcon.substring(2) : selectedIcon, radix: selectedIcon.startsWith('0x') ? 16 : 10), fontFamily: 'MaterialIcons'),
                          color: Colors.white, size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('Tambah Kategori',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: textPrim)),
                        Text(isGreen ? 'Pemasukan' : 'Pengeluaran',
                            style: TextStyle(fontSize: 12, color: accentColor, fontWeight: FontWeight.w500)),
                      ]),
                    ]),

                    const SizedBox(height: 20),

                    // Input nama
                    TextFormField(
                      controller: controller,
                      autofocus: true,
                      textCapitalization: TextCapitalization.words,
                      style: TextStyle(color: textPrim),
                      decoration: const InputDecoration(
                        labelText: 'Nama Kategori',
                        hintText: 'Contoh: Freelance, Parkir, dll',
                        prefixIcon: Icon(Icons.label_outline, color: AppTheme.primary, size: 20),
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) return 'Nama kategori wajib diisi';
                        if (val.trim().length < 2) return 'Minimal 2 karakter';
                        final existingList = jenis == 'pemasukan'
                            ? _kategoriPemasukan : _kategoriPengeluaran;
                        final sudahAda = existingList.any(
                            (k) => k.nama.toLowerCase() == val.trim().toLowerCase());
                        if (sudahAda) return 'Kategori ini sudah ada';
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    // Label icon
                    Text('Pilih Icon',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textPrim)),
                    const SizedBox(height: 10),

                    // Icon grid picker
                    SizedBox(
                      height: 220,
                      child: GridView.builder(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 6,
                          mainAxisSpacing: 8,
                          crossAxisSpacing: 8,
                        ),
                        itemCount: _iconOptions.length,
                        itemBuilder: (_, i) {
                          final opt = _iconOptions[i];
                          final codepoint = opt['icon'] as int;
                          final codepointStr = '0x${codepoint.toRadixString(16)}';
                          final isSelected = selectedIcon == codepointStr;
                          return GestureDetector(
                            onTap: () => setModalState(() => selectedIcon = codepointStr),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? accentColor.withOpacity(0.15)
                                    : (isDark ? AppTheme.surface2Dark : const Color(0xFFF5F7FF)),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isSelected ? accentColor : Colors.transparent,
                                  width: 2,
                                ),
                              ),
                              child: Icon(
                                IconData(codepoint, fontFamily: 'MaterialIcons'),
                                color: isSelected ? accentColor : textSec,
                                size: 20,
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Tombol simpan
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: gradient,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: ElevatedButton(
                        onPressed: () async {
                          if (!formKey.currentState!.validate()) return;
                          final kategori = Kategori(
                            nama: controller.text.trim(),
                            jenis: jenis,
                            icon: selectedIcon,
                          );
                          await _db.tambahKategori(kategori);
                          if (mounted) {
                            Navigator.pop(context);
                            _loadData();
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text('Kategori "${kategori.nama}" berhasil ditambahkan'),
                              backgroundColor: AppTheme.success,
                              behavior: SnackBarBehavior.floating,
                            ));
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 52),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: const Text('Simpan Kategori',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _hapusKategori(Kategori kategori) async {
    if (_kategoriDefault.contains(kategori.nama)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Kategori default tidak bisa dihapus'),
        backgroundColor: AppTheme.warning,
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hapus Kategori?'),
        content: Text('Kategori "${kategori.nama}" akan dihapus.'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Batal')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.danger,
                minimumSize: const Size(80, 40)),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirm == true && kategori.id != null) {
      await _db.hapusKategori(kategori.id!);
      _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Kategori "${kategori.nama}" dihapus'),
          backgroundColor: AppTheme.danger,
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final textPrim = AppTheme.textPrim(context);
    final textSec = AppTheme.textSec(context);
    final bgColor = AppTheme.bg(context);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: AppTheme.bg(context),
        automaticallyImplyLeading: false,
        title: Text('Master Kategori',
            style: TextStyle(
                fontWeight: FontWeight.w700, color: textPrim, fontSize: 18)),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primary,
          unselectedLabelColor: textSec,
          indicatorColor: AppTheme.primary,
          indicatorWeight: 3,
          tabs: const [
            Tab(text: 'Pemasukan'),
            Tab(text: 'Pengeluaran'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _tambahKategori,
        backgroundColor: AppTheme.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Tambah',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primary))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildDaftarKategori(
                    _kategoriPemasukan, 'pemasukan', isDark, textSec),
                _buildDaftarKategori(
                    _kategoriPengeluaran, 'pengeluaran', isDark, textSec),
              ],
            ),
    );
  }

  Widget _buildDaftarKategori(
      List<Kategori> list, String jenis, bool isDark, Color textSec) {
    final isPemasukan = jenis == 'pemasukan';
    final textPrim = AppTheme.textPrim(context);
    final textHint = AppTheme.textHint(context);

    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.category_outlined, size: 56, color: textHint),
            const SizedBox(height: 12),
            Text('Belum ada kategori',
                style: TextStyle(color: textSec, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text('Tekan tombol + untuk menambahkan',
                style: TextStyle(color: textHint, fontSize: 12)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: list.length,
      itemBuilder: (_, i) {
        final kategori = list[i];
        final isDefault = _kategoriDefault.contains(kategori.nama);

        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Slidable(
            endActionPane: ActionPane(
              motion: const DrawerMotion(),
              extentRatio: 0.25,
              children: [
                SlidableAction(
                  onPressed: (_) => _hapusKategori(kategori),
                  backgroundColor:
                      isDefault ? Colors.grey : AppTheme.danger,
                  foregroundColor: Colors.white,
                  icon: isDefault ? Icons.lock_outline : Icons.delete_outline,
                  label: isDefault ? 'Default' : 'Hapus',
                  borderRadius: BorderRadius.circular(16),
                ),
              ],
            ),
            child: GlassCard(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              borderRadius: 16,
              child: Row(
                children: [
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      gradient: isPemasukan
                          ? AppTheme.gradientSuccess : AppTheme.gradientDanger,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      IconData(int.parse(kategori.icon.startsWith('0x') ? kategori.icon.substring(2) : kategori.icon, radix: kategori.icon.startsWith('0x') ? 16 : 10), fontFamily: 'MaterialIcons'),
                      color: Colors.white, size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(kategori.nama,
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: textPrim)),
                  ),
                  if (isDefault)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withOpacity(0.1)
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                            color: isDark
                                ? Colors.white.withOpacity(0.15)
                                : Colors.grey.shade300),
                      ),
                      child: Text('Default',
                          style: TextStyle(
                              fontSize: 10,
                              color: textSec,
                              fontWeight: FontWeight.w500)),
                    ),
                  if (!isDefault)
                    Icon(Icons.swipe_left_outlined,
                        color: textHint, size: 16),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}