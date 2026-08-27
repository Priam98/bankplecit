import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'models/debitur.dart';
import 'models/debitur_summary.dart';
import 'models/kasbon.dart';
import 'models/pembayaran.dart';
import 'models/riwayat_transaksi.dart';
import 'pages/kas_page.dart';
import 'services/debitur_repository.dart';
import 'utils/currency.dart';

const _supabaseUrl = String.fromEnvironment(
  'SUPABASE_URL',
  defaultValue: 'https://ieufwoxrrrundyumdygv.supabase.co',
);
const _supabasePublishableKey = String.fromEnvironment(
  'SUPABASE_PUBLISHABLE_KEY',
  defaultValue: 'sb_publishable_JHN7ZjfynBrh0ftxPrguLg_L7TkBpKS',
);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (_supabaseUrl.isEmpty || _supabasePublishableKey.isEmpty) {
    debugPrint(
      'Supabase belum diinisialisasi. Isi SUPABASE_URL dan '
      'SUPABASE_PUBLISHABLE_KEY melalui --dart-define untuk menjalankan test baca.',
    );
  } else {
    await Supabase.initialize(
      url: _supabaseUrl,
      publishableKey: _supabasePublishableKey,
    );
  }

  runApp(const BankPlecitApp());
}

class BankPlecitApp extends StatelessWidget {
  const BankPlecitApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Bank Plecit',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: const DashboardPage(),
    );
  }
}

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final List<Debitur> debitur = [];
  int selectedPageIndex = 0;
  bool _isLoading = true;
  String? _loadError;

  double get totalPiutang {
    return debitur.fold(0.0, (total, item) => total + item.sisa);
  }

  @override
  void initState() {
    super.initState();
    _loadDebitur();
  }

  Future<void> _loadDebitur() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    try {
      final summaries = await DebiturRepository().getDebiturSummary();

      if (!mounted) return;

      setState(() {
        debitur
          ..clear()
          ..addAll(summaries.map(_debiturFromSummary));
        _isLoading = false;
      });

      debugPrint(
        'Supabase terhubung: ${summaries.length} data debitur_summary.',
      );
    } catch (error, stackTrace) {
      debugPrint('Gagal memuat debitur_summary: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _loadError = error.toString();
      });
    }
  }

  Debitur _debiturFromSummary(DebiturSummary summary) {
    final now = DateTime.now();

    return Debitur(
      id: summary.id,
      nama: summary.nama,
      kasbon: [
        Kasbon(
          id: 'summary-kasbon-${summary.id}',
          nominal: summary.totalKasbon,
          tanggal: now,
        ),
      ],
      pembayaran: [
        Pembayaran(
          id: 'summary-pembayaran-${summary.id}',
          nominal: summary.totalPembayaran,
          tanggal: now,
        ),
      ],
    );
  }

  String get _appBarTitle {
    switch (selectedPageIndex) {
      case 1:
        return 'Riwayat Transaksi';
      case 2:
        return 'Kas Umum';
      default:
        return 'Bank Plecit';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_appBarTitle)),
      body: selectedPageIndex == 0
          ? _buildDashboard()
          : selectedPageIndex == 1
              ? const RiwayatTransaksiPage()
              : const KasPage(),
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedPageIndex,
        onDestinationSelected: (index) {
          setState(() {
            selectedPageIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long),
            label: 'Riwayat',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_balance_wallet),
            label: 'Kas',
          ),
        ],
      ),
    );
  }

  Widget _buildDashboard() {
    if (_isLoading && debitur.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_loadError != null && debitur.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 40),
              const SizedBox(height: 12),
              const Text(
                'Gagal memuat data debitur.',
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              SelectableText(_loadError!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _loadDebitur,
                icon: const Icon(Icons.refresh),
                label: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadDebitur,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Total Piutang', style: TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            Text(
              formatRupiah(totalPiutang, withSymbol: true),
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            Text('${debitur.length} Debitur', style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 12),
            Expanded(
              child: debitur.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: const [
                        SizedBox(height: 80),
                        Center(child: Text('Belum ada debitur.')),
                      ],
                    )
                  : ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: debitur.length,
                      itemBuilder: (context, index) {
                        final item = debitur[index];

                        return ListTile(
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => DetailDebiturPage(
                                  debiturId: item.id,
                                  namaDebitur: item.nama,
                                ),
                              ),
                            );
                            await _loadDebitur();
                          },
                          leading: const CircleAvatar(child: Icon(Icons.person)),
                          title: Text(item.nama),
                          subtitle: Text(
                            item.sisa <= 0 ? 'Lunas' : 'Belum lunas',
                          ),
                          trailing: Text(
                            formatRupiah(item.sisa, withSymbol: true),
                          ),
                        );
                      },
                    ),
            ),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () async {
                  final kasbonTersimpan = await Navigator.push<bool>(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AddLoanPage(),
                    ),
                  );

                  if (kasbonTersimpan == true) {
                    await _loadDebitur();
                  }
                },
                icon: const Icon(Icons.add),
                label: const Text('Kasih Kasbon'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class RiwayatTransaksiPage extends StatefulWidget {
  const RiwayatTransaksiPage({super.key});

  @override
  State<RiwayatTransaksiPage> createState() => _RiwayatTransaksiPageState();
}

class _RiwayatTransaksiPageState extends State<RiwayatTransaksiPage> {
  late Future<List<RiwayatTransaksi>> _riwayatFuture;

  @override
  void initState() {
    super.initState();
    _riwayatFuture = _loadRiwayat();
  }

  Future<List<RiwayatTransaksi>> _loadRiwayat() {
    return DebiturRepository().getRiwayatTransaksi();
  }

  void _reload() {
    setState(() {
      _riwayatFuture = _loadRiwayat();
    });
  }

  Future<void> _editTransaksi(RiwayatTransaksi item) async {
    final controller = TextEditingController(
      text: formatRupiah(item.nominal),
    );

    final nominal = await showDialog<double>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Edit ${_formatJenis(item.jenis)}'),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            inputFormatters: [RupiahInputFormatter()],
            decoration: const InputDecoration(
              labelText: 'Nominal',
              prefixText: 'Rp ',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () {
                final nilai = parseRupiah(controller.text);
                if (nilai != null && nilai > 0) {
                  Navigator.pop(context, nilai);
                }
              },
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );

    controller.dispose();
    if (nominal == null) return;

    try {
      await DebiturRepository().updateTransaksi(item: item, nominal: nominal);
      if (!mounted) return;
      _reload();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Transaksi berhasil diubah.')),
      );
    } catch (error, stackTrace) {
      debugPrint('Gagal edit transaksi: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal mengubah transaksi.')),
      );
    }
  }

  Future<void> _deleteTransaksi(RiwayatTransaksi item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Transaksi'),
        content: Text(
          'Hapus ${_formatJenis(item.jenis).toLowerCase()} '
          '${formatRupiah(item.nominal, withSymbol: true)} '
          'untuk ${item.namaDebitur}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await DebiturRepository().deleteTransaksi(item);
      if (!mounted) return;
      _reload();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Transaksi berhasil dihapus.')),
      );
    } catch (error, stackTrace) {
      debugPrint('Gagal hapus transaksi: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal menghapus transaksi.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<RiwayatTransaksi>>(
      future: _riwayatFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          debugPrint('Gagal memuat riwayat_transaksi: ${snapshot.error}');
          debugPrintStack(stackTrace: snapshot.stackTrace);

          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 40),
                  const SizedBox(height: 12),
                  const Text(
                    'Riwayat transaksi gagal dimuat.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  SelectableText(
                    snapshot.error.toString(),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: _reload,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Coba Lagi'),
                  ),
                ],
              ),
            ),
          );
        }

        final riwayat = snapshot.data ?? [];

        if (riwayat.isEmpty) {
          return RefreshIndicator(
            onRefresh: () async {
              _reload();
              await _riwayatFuture;
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: const [
                SizedBox(height: 120),
                Center(child: Text('Belum ada riwayat transaksi.')),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            _reload();
            await _riwayatFuture;
          },
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: riwayat.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final item = riwayat[index];
              final color = item.isKasbon ? Colors.orange : Colors.green;
              final icon =
                  item.isKasbon ? Icons.arrow_upward : Icons.arrow_downward;

              return ListTile(
                contentPadding: const EdgeInsets.symmetric(vertical: 6),
                leading: CircleAvatar(
                  backgroundColor: color.withAlpha(31),
                  foregroundColor: color,
                  child: Icon(icon),
                ),
                title: Text(item.namaDebitur),
                subtitle: Text(
                  '${_formatJenis(item.jenis)} · ${_formatTanggal(item.tanggal)}',
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      formatRupiah(item.nominal, withSymbol: true),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'edit') {
                          _editTransaksi(item);
                        } else if (value == 'delete') {
                          _deleteTransaksi(item);
                        }
                      },
                      itemBuilder: (context) => const [
                        PopupMenuItem(value: 'edit', child: Text('Edit')),
                        PopupMenuItem(value: 'delete', child: Text('Hapus')),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}

String _formatJenis(String jenis) {
  if (jenis.isEmpty) return 'Transaksi';
  return jenis[0].toUpperCase() + jenis.substring(1).toLowerCase();
}

String _formatTanggal(DateTime tanggal) {
  if (tanggal.millisecondsSinceEpoch == 0) return '-';

  final day = tanggal.day.toString().padLeft(2, '0');
  final month = tanggal.month.toString().padLeft(2, '0');
  final year = tanggal.year.toString();
  final hour = tanggal.hour.toString().padLeft(2, '0');
  final minute = tanggal.minute.toString().padLeft(2, '0');

  return '$day/$month/$year $hour:$minute';
}

class DetailDebiturPage extends StatefulWidget {
  final String debiturId;
  final String namaDebitur;

  const DetailDebiturPage({
    super.key,
    required this.debiturId,
    required this.namaDebitur,
  });

  @override
  State<DetailDebiturPage> createState() => _DetailDebiturPageState();
}

class _DetailDebiturPageState extends State<DetailDebiturPage> {
  late Future<List<RiwayatTransaksi>> _riwayatFuture;
  bool _isSavingPembayaran = false;

  @override
  void initState() {
    super.initState();
    _riwayatFuture = _loadRiwayat();
  }

  Future<List<RiwayatTransaksi>> _loadRiwayat() {
    return DebiturRepository().getRiwayatTransaksiByDebiturId(
      widget.debiturId,
    );
  }

  void _reload() {
    setState(() {
      _riwayatFuture = _loadRiwayat();
    });
  }

  double _totalKasbon(List<RiwayatTransaksi> riwayat) {
    return riwayat
        .where((item) => item.isKasbon)
        .fold(0.0, (total, item) => total + item.nominal);
  }

  double _totalPembayaran(List<RiwayatTransaksi> riwayat) {
    return riwayat
        .where((item) => item.isPembayaran)
        .fold(0.0, (total, item) => total + item.nominal);
  }

  // Perbaikan bug: sisa = kasbon - pembayaran (bukan penjumlahan).
  double _sisaPiutang(double totalKasbon, double totalPembayaran) {
    final sisa = totalKasbon - totalPembayaran;
    return sisa < 0 ? 0 : sisa;
  }

  double _kelebihanBayar(double totalKasbon, double totalPembayaran) {
    return totalPembayaran > totalKasbon ? totalPembayaran - totalKasbon : 0;
  }

  String _status(double totalKasbon, double totalPembayaran) {
    return totalPembayaran >= totalKasbon ? 'LUNAS' : 'BELUM LUNAS';
  }

  Future<void> catatPembayaran() async {
    final controller = TextEditingController();

    final nominal = await showDialog<double>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Catat Pembayaran'),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            inputFormatters: [RupiahInputFormatter()],
            decoration: const InputDecoration(
              labelText: 'Nominal',
              prefixText: 'Rp ',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () {
                final nilai = parseRupiah(controller.text);
                if (nilai != null && nilai > 0) {
                  Navigator.pop(context, nilai);
                }
              },
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );

    controller.dispose();
    if (nominal == null) return;

    setState(() => _isSavingPembayaran = true);

    try {
      await DebiturRepository().addPembayaran(
        debiturId: widget.debiturId,
        nominal: nominal,
      );

      if (!mounted) return;
      _reload();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pembayaran berhasil disimpan.')),
      );
    } on PostgrestException catch (error, stackTrace) {
      debugPrint(
        'INSERT pembayaran gagal:\n'
        'message: ${error.message}\n'
        'code: ${error.code}\n'
        'details: ${error.details}\n'
        'hint: ${error.hint}',
      );
      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pembayaran gagal disimpan.')),
      );
    } catch (error, stackTrace) {
      debugPrint('Gagal menyimpan pembayaran: $error');
      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pembayaran gagal disimpan.')),
      );
    } finally {
      if (mounted) setState(() => _isSavingPembayaran = false);
    }
  }

  Future<void> _editTransaksi(RiwayatTransaksi item) async {
    final controller = TextEditingController(
      text: formatRupiah(item.nominal),
    );

    final nominal = await showDialog<double>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Edit ${_formatJenis(item.jenis)}'),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            inputFormatters: [RupiahInputFormatter()],
            decoration: const InputDecoration(
              labelText: 'Nominal',
              prefixText: 'Rp ',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () {
                final nilai = parseRupiah(controller.text);
                if (nilai != null && nilai > 0) {
                  Navigator.pop(context, nilai);
                }
              },
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );

    controller.dispose();
    if (nominal == null) return;

    try {
      await DebiturRepository().updateTransaksi(item: item, nominal: nominal);
      if (!mounted) return;
      _reload();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Transaksi berhasil diubah.')),
      );
    } catch (error, stackTrace) {
      debugPrint('Gagal edit transaksi: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal mengubah transaksi.')),
      );
    }
  }

  Future<void> _deleteTransaksi(RiwayatTransaksi item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Transaksi'),
        content: Text(
          'Hapus ${_formatJenis(item.jenis).toLowerCase()} '
          '${formatRupiah(item.nominal, withSymbol: true)}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await DebiturRepository().deleteTransaksi(item);
      if (!mounted) return;
      _reload();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Transaksi berhasil dihapus.')),
      );
    } catch (error, stackTrace) {
      debugPrint('Gagal hapus transaksi: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal menghapus transaksi.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.namaDebitur)),
      body: FutureBuilder<List<RiwayatTransaksi>>(
        future: _riwayatFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            debugPrint('Gagal memuat detail debitur: ${snapshot.error}');
            debugPrintStack(stackTrace: snapshot.stackTrace);

            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, size: 40),
                    const SizedBox(height: 12),
                    const Text(
                      'Detail debitur gagal dimuat.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    SelectableText(
                      snapshot.error.toString(),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: _reload,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Coba Lagi'),
                    ),
                  ],
                ),
              ),
            );
          }

          final riwayat = snapshot.data ?? [];
          final totalKasbon = _totalKasbon(riwayat);
          final totalPembayaran = _totalPembayaran(riwayat);
          final sisaPiutang = _sisaPiutang(totalKasbon, totalPembayaran);
          final kelebihanBayar = _kelebihanBayar(totalKasbon, totalPembayaran);
          final status = _status(totalKasbon, totalPembayaran);

          return RefreshIndicator(
            onRefresh: () async {
              _reload();
              await _riwayatFuture;
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.namaDebitur, style: const TextStyle(fontSize: 16)),
                  const SizedBox(height: 16),
                  _DetailAmount(
                    label: 'Total Kasbon',
                    value: formatRupiah(totalKasbon, withSymbol: true),
                    fontSize: 28,
                  ),
                  const SizedBox(height: 16),
                  _DetailAmount(
                    label: 'Total Pembayaran',
                    value: formatRupiah(totalPembayaran, withSymbol: true),
                    fontSize: 22,
                  ),
                  const SizedBox(height: 16),
                  _DetailAmount(
                    label: 'Sisa Piutang',
                    value: formatRupiah(sisaPiutang, withSymbol: true),
                    fontSize: 28,
                  ),
                  const SizedBox(height: 16),
                  const Text('Status', style: TextStyle(fontSize: 16)),
                  Text(
                    status,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (kelebihanBayar > 0) ...[
                    const SizedBox(height: 16),
                    _DetailAmount(
                      label: 'Kelebihan Bayar',
                      value: formatRupiah(kelebihanBayar, withSymbol: true),
                      fontSize: 22,
                    ),
                  ],
                  const SizedBox(height: 24),
                  const Text(
                    'Riwayat Transaksi',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: riwayat.isEmpty
                        ? ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: const [
                              SizedBox(height: 40),
                              Center(child: Text('Belum ada riwayat transaksi.')),
                            ],
                          )
                        : ListView.separated(
                            physics: const AlwaysScrollableScrollPhysics(),
                            itemCount: riwayat.length,
                            separatorBuilder: (context, index) =>
                                const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final item = riwayat[index];
                              final color =
                                  item.isKasbon ? Colors.orange : Colors.green;
                              final icon = item.isKasbon
                                  ? Icons.arrow_upward
                                  : Icons.arrow_downward;

                              return ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: CircleAvatar(
                                  backgroundColor: color.withAlpha(31),
                                  foregroundColor: color,
                                  child: Icon(icon),
                                ),
                                title: Text(_formatJenis(item.jenis)),
                                subtitle: Text(_formatTanggal(item.tanggal)),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      formatRupiah(
                                        item.nominal,
                                        withSymbol: true,
                                      ),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    PopupMenuButton<String>(
                                      onSelected: (value) {
                                        if (value == 'edit') {
                                          _editTransaksi(item);
                                        } else if (value == 'delete') {
                                          _deleteTransaksi(item);
                                        }
                                      },
                                      itemBuilder: (context) => const [
                                        PopupMenuItem(
                                          value: 'edit',
                                          child: Text('Edit'),
                                        ),
                                        PopupMenuItem(
                                          value: 'delete',
                                          child: Text('Hapus'),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _isSavingPembayaran ? null : catatPembayaran,
                      icon: _isSavingPembayaran
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.payment),
                      label: Text(
                        _isSavingPembayaran
                            ? 'Menyimpan...'
                            : 'Catat Pembayaran',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _DetailAmount extends StatelessWidget {
  final String label;
  final String value;
  final double fontSize;

  const _DetailAmount({
    required this.label,
    required this.value,
    required this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 16)),
        Text(
          value,
          style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

class AddLoanPage extends StatefulWidget {
  const AddLoanPage({super.key});

  @override
  State<AddLoanPage> createState() => _AddLoanPageState();
}

class _AddLoanPageState extends State<AddLoanPage> {
  final namaController = TextEditingController();
  final nominalController = TextEditingController();

  List<String> _debiturNames = [];
  bool _isLoadingNames = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadNames();
  }

  Future<void> _loadNames() async {
    try {
      final names = await DebiturRepository().getDebiturNames();
      if (!mounted) return;
      setState(() {
        _debiturNames = names;
        _isLoadingNames = false;
      });
    } catch (error, stackTrace) {
      debugPrint('Gagal memuat nama debitur: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (!mounted) return;
      setState(() => _isLoadingNames = false);
    }
  }

  @override
  void dispose() {
    namaController.dispose();
    nominalController.dispose();
    super.dispose();
  }

  Future<void> simpanKasbon() async {
    final nama = namaController.text.trim();
    final nominal = parseRupiah(nominalController.text);

    if (nama.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nama debitur belum diisi')),
      );
      return;
    }

    if (nominal == null || nominal <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nominal kasbon harus lebih dari Rp 0')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      await DebiturRepository().addKasbon(namaDebitur: nama, nominal: nominal);

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (error, stackTrace) {
      debugPrint('Gagal menyimpan kasbon: $error');
      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kasbon gagal disimpan. Silakan coba lagi.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tambah Kasbon')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (_isLoadingNames)
              const LinearProgressIndicator()
            else
              const SizedBox(height: 4),
            const SizedBox(height: 8),
            Autocomplete<String>(
              optionsBuilder: (textEditingValue) {
                final query = textEditingValue.text.trim().toLowerCase();
                if (query.isEmpty) {
                  return _debiturNames;
                }
                return _debiturNames.where(
                  (name) => name.toLowerCase().contains(query),
                );
              },
              onSelected: (selection) {
                namaController.text = selection;
                namaController.selection = TextSelection.collapsed(
                  offset: selection.length,
                );
              },
              fieldViewBuilder: (
                context,
                textEditingController,
                focusNode,
                onFieldSubmitted,
              ) {
                // Sinkronkan nilai ke controller utama.
                textEditingController.addListener(() {
                  if (namaController.text != textEditingController.text) {
                    namaController.value = textEditingController.value;
                  }
                });

                return TextField(
                  controller: textEditingController,
                  focusNode: focusNode,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Nama Debitur',
                    hintText: 'Ketik atau pilih debitur yang sudah ada',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person_search),
                  ),
                  onSubmitted: (_) => onFieldSubmitted(),
                );
              },
              optionsViewBuilder: (context, onSelected, options) {
                return Align(
                  alignment: Alignment.topLeft,
                  child: Material(
                    elevation: 4,
                    borderRadius: BorderRadius.circular(8),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 240),
                      child: ListView.builder(
                        padding: EdgeInsets.zero,
                        shrinkWrap: true,
                        itemCount: options.length,
                        itemBuilder: (context, index) {
                          final option = options.elementAt(index);
                          return ListTile(
                            dense: true,
                            title: Text(option),
                            onTap: () => onSelected(option),
                          );
                        },
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: nominalController,
              keyboardType: TextInputType.number,
              inputFormatters: [RupiahInputFormatter()],
              decoration: const InputDecoration(
                labelText: 'Nominal',
                prefixText: 'Rp ',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _isSaving ? null : simpanKasbon,
                child: _isSaving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Simpan Kasbon'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
