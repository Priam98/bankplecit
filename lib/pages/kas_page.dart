import 'package:flutter/material.dart';

import '../models/transaksi_kas.dart';
import '../services/kas_repository.dart';

class KasPage extends StatefulWidget {
  const KasPage({super.key});

  @override
  State<KasPage> createState() => _KasPageState();
}

class _KasPageState extends State<KasPage> {
  final KasRepository _repository = KasRepository();

  late Future<List<TransaksiKas>> _transaksiFuture;

  @override
  void initState() {
    super.initState();
    _loadTransaksi();
  }

  void _loadTransaksi() {
    _transaksiFuture = _repository.getTransaksi();
  }

  double _hitungSaldo(List<TransaksiKas> transaksi) {
    return transaksi.fold(0, (saldo, item) {
      if (item.isMasuk) {
        return saldo + item.nominal;
      }

      return saldo - item.nominal;
    });
  }

  String _rupiah(double value) {
    final text = value.toStringAsFixed(0);
    final buffer = StringBuffer();

    for (var i = 0; i < text.length; i++) {
      final positionFromEnd = text.length - i;

      buffer.write(text[i]);

      if (positionFromEnd > 1 && positionFromEnd % 3 == 1) {
        buffer.write('.');
      }
    }

    return 'Rp $buffer';
  }

  Future<void> _tambahTransaksi() async {
    final nominalController = TextEditingController();
    final keteranganController = TextEditingController();

    String jenis = 'masuk';

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Tambah Transaksi'),

              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      initialValue: jenis,
                      decoration: const InputDecoration(
                        labelText: 'Jenis',
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'masuk',
                          child: Text('Kas Masuk'),
                        ),
                        DropdownMenuItem(
                          value: 'keluar',
                          child: Text('Kas Keluar'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() {
                            jenis = value;
                          });
                        }
                      },
                    ),

                    const SizedBox(height: 16),

                    TextField(
                      controller: nominalController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Nominal',
                        prefixText: 'Rp ',
                      ),
                    ),

                    const SizedBox(height: 16),

                    TextField(
                      controller: keteranganController,
                      decoration: const InputDecoration(
                        labelText: 'Keterangan',
                        hintText: 'Contoh: Cashback Agustus',
                      ),
                    ),
                  ],
                ),
              ),

              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context, false);
                  },
                  child: const Text('Batal'),
                ),

                FilledButton(
                  onPressed: () async {
                    final nominal = double.tryParse(
                      nominalController.text.replaceAll('.', ''),
                    );

                    if (nominal == null || nominal <= 0) {
                      return;
                    }

                    await _repository.tambahTransaksi(
                      jenis: jenis,
                      nominal: nominal,
                      keterangan: keteranganController.text.trim().isEmpty
                          ? null
                          : keteranganController.text.trim(),
                    );

                    if (context.mounted) {
                      Navigator.pop(context, true);
                    }
                  },
                  child: const Text('Simpan'),
                ),
              ],
            );
          },
        );
      },
    );

    nominalController.dispose();
    keteranganController.dispose();

    if (result == true && mounted) {
      setState(_loadTransaksi);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Transaksi berhasil disimpan.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kas Umum'),
      ),

      body: FutureBuilder<List<TransaksiKas>>(
        future: _transaksiFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 48,
                    ),

                    const SizedBox(height: 12),

                    const Text(
                      'Gagal memuat kas.',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      snapshot.error.toString(),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 16),

                    FilledButton.icon(
                      onPressed: () {
                        setState(_loadTransaksi);
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('Coba Lagi'),
                    ),
                  ],
                ),
              ),
            );
          }

          final transaksi = snapshot.data ?? [];
          final saldo = _hitungSaldo(transaksi);

          return RefreshIndicator(
            onRefresh: () async {
              setState(_loadTransaksi);
              await _transaksiFuture;
            },

            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Saldo Kas',
                          style: TextStyle(fontSize: 16),
                        ),

                        const SizedBox(height: 8),

                        Text(
                          _rupiah(saldo),
                          style: const TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                const Text(
                  'Riwayat Transaksi',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                if (transaksi.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(
                      child: Text('Belum ada transaksi.'),
                    ),
                  ),

                ...transaksi.map(
                  (item) => ListTile(
                    leading: CircleAvatar(
                      child: Icon(
                        item.isMasuk
                            ? Icons.arrow_downward
                            : Icons.arrow_upward,
                      ),
                    ),

                    title: Text(
                      item.keterangan ?? 'Tanpa keterangan',
                    ),

                    subtitle: Text(
                      item.isMasuk
                          ? 'Kas masuk'
                          : 'Kas keluar',
                    ),

                    trailing: Text(
                      '${item.isMasuk ? '+' : '-'}${_rupiah(item.nominal)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: item.isMasuk
                            ? Colors.green
                            : Colors.red,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: _tambahTransaksi,
        child: const Icon(Icons.add),
      ),
    );
  }
}