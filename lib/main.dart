import 'package:flutter/material.dart';

void main() {
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
  final List<Map<String, dynamic>> kasbon = [];

double get totalPiutang {
  return kasbon.fold(
    0.0,
    (total, item) {
      final daftarKasbon =
          (item['kasbon'] as List?)?.cast<num>() ?? [];

      final totalKasbon = daftarKasbon.fold(
        0.0,
        (subtotal, nominal) => subtotal + nominal,
      );

      return total + totalKasbon;
    },
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
  '${kasbon.length} Debitur',
              style: TextStyle(
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 24),

Expanded(
  child: ListView.builder(
    itemCount: kasbon.length,
    itemBuilder: (context, index) {
      final item = kasbon[index];

      return ListTile(
          onTap: () async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DetailDebiturPage(
          data: item,
        ),
      ),
    );

    setState(() {});
  },
        leading: const CircleAvatar(
          child: Icon(Icons.person),
        ),
        title: Text(item['nama']),
        subtitle: const Text('Belum lunas'),
        trailing: Builder(
          builder: (context) {
            final daftarKasbon =
                (item['kasbon'] as List?)?.cast<num>() ?? [];

            final total = daftarKasbon.fold(
              0.0,
                (sum, nominal) => sum + nominal,
          );

    return Text(
      'Rp ${total.toStringAsFixed(0)}',
    );
  },
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
          final hasil = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddLoanPage(),
            ),
         );  

          if (hasil != null) {
            setState(() {
              final indexDebitur = kasbon.indexWhere(
                (debitur) => debitur['nama'] == hasil['nama'],
              );
              final nominal = (hasil['kasbon'] as List).first as double;

              if (indexDebitur == -1) {
                kasbon.add(hasil);
              } else {
                final daftarKasbon = kasbon[indexDebitur]['kasbon'] as List<double>;
                daftarKasbon.add(nominal);
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
  final Map<String, dynamic> data;

  const DetailDebiturPage({
    super.key,
    required this.data,
  });

  @override
  State<DetailDebiturPage> createState() => _DetailDebiturPageState();
}

class _DetailDebiturPageState extends State<DetailDebiturPage> {
double get totalUtang {
  final daftarKasbon =
      (widget.data['kasbon'] as List?)?.cast<num>() ?? [];

  return daftarKasbon.fold(
    0.0,
    (total, nominal) => total + nominal,
  );
}
 double get totalBayar {
  final pembayaran =
      (widget.data['pembayaran'] as List?)?.cast<num>() ?? [];

  return pembayaran.fold(
    0.0,
    (total, nominal) => total + nominal,
  );
}
  double get sisa {
    final hasil = totalUtang - totalBayar;
    return hasil < 0 ? 0 : hasil;
  }
double get kelebihanBayar {
  return totalBayar > totalUtang
      ? totalBayar - totalUtang
      : 0;
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
    final pembayaran =
        widget.data['pembayaran'] ??= <double>[];

    pembayaran.add(nominal);
  });
}
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.data['nama']),
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
    {
      'nama': nama,
      'kasbon': <double>[nominal],
      'pembayaran': <double>[],
    },
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
