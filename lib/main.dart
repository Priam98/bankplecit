import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'models/debitur.dart';
import 'models/kasbon.dart';
import 'models/pembayaran.dart';
import 'services/debitur_repository.dart';

const _supabaseUrl = String.fromEnvironment('SUPABASE_URL');
const _supabasePublishableKey =
    String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  debugPrint('URL kosong: ${_supabaseUrl.isEmpty}');
  debugPrint('Key kosong: ${_supabasePublishableKey.isEmpty}');
  debugPrint('URL: $_supabaseUrl');

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

    await _testReadDebiturSummary();
  }

  runApp(const BankPlecitApp());
}

Future<void> _testReadDebiturSummary() async {
  try {
    final summaries = await DebiturRepository().getDebiturSummary();
    debugPrint('Supabase terhubung: ${summaries.length} data debitur_summary.');
  } catch (error, stackTrace) {
    debugPrint('Gagal membaca debitur_summary: $error');
    debugPrintStack(stackTrace: stackTrace);
  }
}

class BankPlecitApp extends StatelessWidget {
  const BankPlecitApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Bank Plecit',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.green,
        ),
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

double get totalPiutang {
  return debitur.fold(
    0.0,
    (total, item) => total + item.totalKasbon,
  );
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bank Plecit'),
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Total Piutang',
              style: TextStyle(
                fontSize: 16,
              ),
            ),

            const SizedBox(height: 8),

            Text(
            'Rp ${totalPiutang.toStringAsFixed(0)}',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 24),

            Text(
  '${debitur.length} Debitur',
              style: TextStyle(
                fontSize: 18,
              ),
            ),
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
          debitur: item,
        ),
      ),
    );

    setState(() {});
  },
        leading: const CircleAvatar(
          child: Icon(Icons.person),
        ),
        title: Text(item.nama),
        subtitle: const Text('Belum lunas'),
        trailing: Text(
          'Rp ${item.totalKasbon.toStringAsFixed(0)}',
        ),
      );
    },
  ),
),
            const Spacer(),

            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
        onPressed: () async {
          final hasil = await Navigator.push<Debitur>(
            context,
            MaterialPageRoute(
              builder: (context) => const AddLoanPage(),
            ),
         );  

          if (hasil != null) {
            setState(() {
              final indexDebitur = debitur.indexWhere(
                (item) => item.nama.toLowerCase() == hasil.nama.toLowerCase(),
              );

              if (indexDebitur == -1) {
                debitur.add(hasil);
              } else {
                debitur[indexDebitur].kasbon.add(hasil.kasbon.first);
              }
            });
          }
        },
                icon: const Icon(Icons.add),
                label: const Text('Kasih Kasbon'),
              ),
            ),
          ],
        ),
      ),

      bottomNavigationBar: NavigationBar(
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.people),
            label: 'Debitur',
          ),
        ],
      ),
    );
  }
}

class DetailDebiturPage extends StatefulWidget {
  final Debitur debitur;

  const DetailDebiturPage({
    super.key,
    required this.debitur,
  });

  @override
  State<DetailDebiturPage> createState() => _DetailDebiturPageState();
}

class _DetailDebiturPageState extends State<DetailDebiturPage> {
double get totalUtang {
  return widget.debitur.totalKasbon;
}
 double get totalBayar {
  return widget.debitur.totalPembayaran;
}
  double get sisa {
    return widget.debitur.sisa;
  }
double get kelebihanBayar {
  return widget.debitur.kelebihanBayar;
}

String get status {
  if (totalBayar > totalUtang) {
    return 'LUNAS - KELEBIHAN BAYAR';
  }

  if (totalBayar == totalUtang) {
    return 'LUNAS';
  }

  return 'BELUM LUNAS';
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
              final nilai =
                  double.tryParse(controller.text);

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
  setState(() {
    widget.debitur.pembayaran.add(
      Pembayaran(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        nominal: nominal,
        tanggal: DateTime.now(),
      ),
    );
  });
}
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.debitur.nama),
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            const Text(
              'Total Utang',
              style: TextStyle(fontSize: 16),
            ),

            Text(
              'Rp ${totalUtang.toStringAsFixed(0)}',
              style: const TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
              ),
            ),
const SizedBox(height: 24),

const Text(
  'Status',
  style: TextStyle(fontSize: 16),
),

Text(
  status,
  style: const TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
  ),
),

if (kelebihanBayar > 0) ...[
  const SizedBox(height: 16),

  const Text(
    'Kelebihan Bayar',
    style: TextStyle(fontSize: 16),
  ),

  Text(
    'Rp ${kelebihanBayar.toStringAsFixed(0)}',
    style: const TextStyle(
      fontSize: 22,
      fontWeight: FontWeight.bold,
    ),
  ),
],


            const SizedBox(height: 24),

            const Text(
              'Sudah Dibayar',
              style: TextStyle(fontSize: 16),
            ),

            Text(
              'Rp ${totalBayar.toStringAsFixed(0)}',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 24),

            const Text(
              'Sisa Utang',
              style: TextStyle(fontSize: 16),
            ),

            Text(
              'Rp ${sisa.toStringAsFixed(0)}',
              style: const TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
              ),
            ),

            const Spacer(),

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
      ),
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

void simpanKasbon() {
  final nama = namaController.text.trim();
  final nominal = double.tryParse(nominalController.text);

  if (nama.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Nama debitur belum diisi'),
      ),
    );
    return;
  }

  if (nominal == null || nominal <= 0) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Nominal kasbon harus lebih dari Rp 0'),
      ),
    );
    return;
  }

  Navigator.pop(
    context,
    Debitur(
      id: 'debitur-${DateTime.now().microsecondsSinceEpoch}',
      nama: nama,
      kasbon: [
        Kasbon(
          id: 'kasbon-${DateTime.now().microsecondsSinceEpoch}',
          nominal: nominal,
          tanggal: DateTime.now(),
        ),
      ],
      pembayaran: [],
    ),
  );
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tambah Kasbon'),
      ),

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
