import 'package:flutter/material.dart';

import '../models/riwayat_transaksi.dart';
import '../services/debitur_repository.dart';
import '../utils/currency.dart';
import '../utils/date_format.dart';

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
    final controller = TextEditingController(text: formatRupiah(item.nominal));

    final nominal = await showDialog<double>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Edit ${formatJenis(item.jenis)}'),
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
          'Hapus ${formatJenis(item.jenis).toLowerCase()} '
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
                  '${formatJenis(item.jenis)} · ${formatTanggal(item.tanggal)}',
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
