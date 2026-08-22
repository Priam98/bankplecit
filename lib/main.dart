import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'models/debitur.dart';
import 'models/debitur_summary.dart';
import 'models/kasbon.dart';
import 'models/pembayaran.dart';
import 'models/riwayat_transaksi.dart';
import 'services/debitur_repository.dart';

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

  double get totalPiutang {
    return debitur.fold(0.0, (total, item) => total + item.sisa);
  }

  @override
  void initState() {
    super.initState();
    _loadDebitur();
  }

  Future<void> _loadDebitur() async {
    try {
      final summaries = await DebiturRepository().getDebiturSummary();

      if (!mounted) return;

      setState(() {
        debitur
          ..clear()
          ..addAll(summaries.map(_debiturFromSummary));
      });

      debugPrint(
        'Supabase terhubung: ${summaries.length} data debitur_summary.',
      );
    } catch (error, stackTrace) {
      debugPrint('Gagal memuat debitur_summary: $error');
      debugPrintStack(stackTrace: stackTrace);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          selectedPageIndex == 0 ? 'Bank Plecit' : 'Riwayat Transaksi',
        ),
      ),

      body: selectedPageIndex == 0
          ? _buildDashboard()
          : const RiwayatTransaksiPage(),

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
        ],
      ),
    );
  }

  Widget _buildDashboard() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Total Piutang', style: TextStyle(fontSize: 16)),

          const SizedBox(height: 8),

          Text(
            'Rp ${totalPiutang.toStringAsFixed(0)}',
            style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 24),

          Text('${debitur.length} Debitur', style: TextStyle(fontSize: 18)),
          const SizedBox(height: 24),

          Expanded(
            child: ListView.builder(
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
                  subtitle: Text(item.sisa <= 0 ? 'Lunas' : 'Belum lunas'),
                  trailing: Text('Rp ${item.sisa.toStringAsFixed(0)}'),
                );
              },
            ),
          ),
          const Spacer(),

          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () async {
                final kasbonTersimpan = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(builder: (context) => const AddLoanPage()),
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
                    onPressed: () {
                      setState(() {
                        _riwayatFuture = _loadRiwayat();
                      });
                    },
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
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text('Belum ada riwayat transaksi.'),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            setState(() {
              _riwayatFuture = _loadRiwayat();
            });
            await _riwayatFuture;
          },
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: riwayat.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final item = riwayat[index];
              final color = item.isKasbon ? Colors.orange : Colors.green;
              final icon = item.isKasbon
                  ? Icons.arrow_upward
                  : Icons.arrow_downward;

              return ListTile(
                contentPadding: const EdgeInsets.symmetric(vertical: 6),
                leading: CircleAvatar(
                  backgroundColor: color.withAlpha(31),
                  foregroundColor: color,
                  child: Icon(icon),
                ),
                title: Text(item.namaDebitur),
                subtitle: Text(
                  '${_formatJenis(item.jenis)} - ${_formatTanggal(item.tanggal)}',
                ),
                trailing: Text(
                  'Rp ${_formatRupiah(item.nominal)}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
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
  if (jenis.isEmpty) {
    return 'Transaksi';
  }

  return jenis[0].toUpperCase() + jenis.substring(1).toLowerCase();
}

String _formatTanggal(DateTime tanggal) {
  if (tanggal.millisecondsSinceEpoch == 0) {
    return '-';
  }

  final day = tanggal.day.toString().padLeft(2, '0');
  final month = tanggal.month.toString().padLeft(2, '0');
  final year = tanggal.year.toString();
  final hour = tanggal.hour.toString().padLeft(2, '0');
  final minute = tanggal.minute.toString().padLeft(2, '0');

  return '$day/$month/$year $hour:$minute';
}

String _formatRupiah(double value) {
  final text = value.toStringAsFixed(0);
  final buffer = StringBuffer();

  for (var i = 0; i < text.length; i++) {
    final positionFromEnd = text.length - i;
    buffer.write(text[i]);

    if (positionFromEnd > 1 && positionFromEnd % 3 == 1) {
      buffer.write('.');
    }
  }

  return buffer.toString();
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
            decoration: const InputDecoration(
              labelText: 'Nominal',
              prefixText: 'Rp ',
            ),
          ),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Batal'),
            ),

            FilledButton(
              onPressed: () {
                final nilai = double.tryParse(controller.text);

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

    if (nominal != null) {
      try {
        await DebiturRepository().addPembayaran(
          debiturId: widget.debiturId,
          nominal: nominal,
        );

        if (!mounted) return;
        setState(() {
          _riwayatFuture = _loadRiwayat();
        });

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
      }
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
                      onPressed: () {
                        setState(() {
                          _riwayatFuture = _loadRiwayat();
                        });
                      },
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
          final kelebihanBayar = _kelebihanBayar(
            totalKasbon,
            totalPembayaran,
          );
          final status = _status(totalKasbon, totalPembayaran);

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.namaDebitur, style: const TextStyle(fontSize: 16)),
                const SizedBox(height: 16),
                _DetailAmount(
                  label: 'Total Kasbon',
                  value: 'Rp ${_formatRupiah(totalKasbon)}',
                  fontSize: 28,
                ),
                const SizedBox(height: 16),
                _DetailAmount(
                  label: 'Total Pembayaran',
                  value: 'Rp ${_formatRupiah(totalPembayaran)}',
                  fontSize: 22,
                ),
                const SizedBox(height: 16),
                _DetailAmount(
                  label: 'Sisa Piutang',
                  value: 'Rp ${_formatRupiah(sisaPiutang)}',
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
                    value: 'Rp ${_formatRupiah(kelebihanBayar)}',
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
                      ? const Center(
                          child: Text('Belum ada riwayat transaksi.'),
                        )
                      : ListView.separated(
                          itemCount: riwayat.length,
                          separatorBuilder: (context, index) =>
                              const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final item = riwayat[index];
                            final color = item.isKasbon
                                ? Colors.orange
                                : Colors.green;
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
                              trailing: Text(
                                'Rp ${_formatRupiah(item.nominal)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            );
                          },
                        ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: catatPembayaran,
                    icon: const Icon(Icons.payment),
                    label: const Text('Catat Pembayaran'),
                  ),
                ),
              ],
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

  @override
  void dispose() {
    namaController.dispose();
    nominalController.dispose();
    super.dispose();
  }

  Future<void> simpanKasbon() async {
    final nama = namaController.text.trim();
    final nominal = double.tryParse(nominalController.text);

    if (nama.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Nama debitur belum diisi')));
      return;
    }

    if (nominal == null || nominal <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nominal kasbon harus lebih dari Rp 0')),
      );
      return;
    }

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
            TextField(
              controller: namaController,
              decoration: const InputDecoration(
                labelText: 'Nama Debitur',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 16),

            TextField(
              controller: nominalController,
              keyboardType: TextInputType.number,
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
                onPressed: simpanKasbon,
                child: const Text('Simpan Kasbon'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
