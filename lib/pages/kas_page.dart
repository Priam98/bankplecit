import 'package:flutter/material.dart';

import '../models/transaksi_kas.dart';
import '../services/kas_repository.dart';
import '../utils/currency.dart';

/// Halaman Kas Umum — tanpa Scaffold/AppBar sendiri
/// karena sudah dibungkus DashboardPage (hindari double AppBar).
class KasPage extends StatefulWidget {
  const KasPage({super.key});

  @override
  State<KasPage> createState() => _KasPageState();
}

class _KasPageState extends State<KasPage> {
  final KasRepository _repository = KasRepository();

  late Future<List<TransaksiKas>> _transaksiFuture;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadTransaksi();
  }

  void _loadTransaksi() {
    _transaksiFuture = _repository.getTransaksi();
  }

  void _reload() {
    setState(_loadTransaksi);
  }

  double _hitungSaldo(List<TransaksiKas> transaksi) {
    return transaksi.fold(0.0, (saldo, item) {
      if (item.isMasuk) return saldo + item.nominal;
      return saldo - item.nominal;
    });
  }

  Future<void> _tambahAtauEditTransaksi({TransaksiKas? existing}) async {
    final nominalController = TextEditingController(
      text: existing != null ? formatRupiah(existing.nominal) : '',
    );
    final keteranganController = TextEditingController(
      text: existing?.keterangan ?? '',
    );

    String jenis = existing?.jenis ?? 'masuk';
    bool dialogSaving = false;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                existing == null ? 'Tambah Transaksi' : 'Edit Transaksi',
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      initialValue: jenis,
                      decoration: const InputDecoration(labelText: 'Jenis'),
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
                      onChanged: dialogSaving
                          ? null
                          : (value) {
                              if (value != null) {
                                setDialogState(() => jenis = value);
                              }
                            },
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: nominalController,
                      enabled: !dialogSaving,
                      keyboardType: TextInputType.number,
                      inputFormatters: [RupiahInputFormatter()],
                      decoration: const InputDecoration(
                        labelText: 'Nominal',
                        prefixText: 'Rp ',
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: keteranganController,
                      enabled: !dialogSaving,
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
                  onPressed:
                      dialogSaving ? null : () => Navigator.pop(context, false),
                  child: const Text('Batal'),
                ),
                FilledButton(
                  onPressed: dialogSaving
                      ? null
                      : () async {
                          final nominal = parseRupiah(nominalController.text);
                          if (nominal == null || nominal <= 0) return;

                          setDialogState(() => dialogSaving = true);

                          try {
                            if (existing == null) {
                              await _repository.tambahTransaksi(
                                jenis: jenis,
                                nominal: nominal,
                                keterangan:
                                    keteranganController.text.trim().isEmpty
                                        ? null
                                        : keteranganController.text.trim(),
                              );
                            } else {
                              await _repository.updateTransaksi(
                                id: existing.id,
                                jenis: jenis,
                                nominal: nominal,
                                keterangan:
                                    keteranganController.text.trim().isEmpty
                                        ? null
                                        : keteranganController.text.trim(),
                              );
                            }

                            if (context.mounted) {
                              Navigator.pop(context, true);
                            }
                          } catch (error, stackTrace) {
                            debugPrint('Gagal simpan transaksi kas: $error');
                            debugPrintStack(stackTrace: stackTrace);
                            setDialogState(() => dialogSaving = false);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Transaksi gagal disimpan.'),
                                ),
                              );
                            }
                          }
                        },
                  child: dialogSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Simpan'),
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
      _reload();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            existing == null
                ? 'Transaksi berhasil disimpan.'
                : 'Transaksi berhasil diubah.',
          ),
        ),
      );
    }
  }

  Future<void> _hapusTransaksi(TransaksiKas item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Transaksi'),
        content: Text(
          'Hapus ${item.isMasuk ? 'kas masuk' : 'kas keluar'} '
          '${formatRupiah(item.nominal, withSymbol: true)}'
          '${item.keterangan != null ? ' (${item.keterangan})' : ''}?',
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

    setState(() => _isSaving = true);
    try {
      await _repository.deleteTransaksi(item.id);
      if (!mounted) return;
      _reload();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Transaksi berhasil dihapus.')),
      );
    } catch (error, stackTrace) {
      debugPrint('Gagal hapus transaksi kas: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal menghapus transaksi.')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        FutureBuilder<List<TransaksiKas>>(
          future: _transaksiFuture,
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
                      const Icon(Icons.error_outline, size: 48),
                      const SizedBox(height: 12),
                      const Text(
                        'Gagal memuat kas.',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
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

            final transaksi = snapshot.data ?? [];
            final saldo = _hitungSaldo(transaksi);

            return RefreshIndicator(
              onRefresh: () async {
                _reload();
                await _transaksiFuture;
              },
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
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
                            formatRupiah(saldo, withSymbol: true),
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
                      child: Center(child: Text('Belum ada transaksi.')),
                    ),
                  ...transaksi.map(
                    (item) => ListTile(
                      leading: CircleAvatar(
                        backgroundColor: (item.isMasuk
                                ? Colors.green
                                : Colors.red)
                            .withAlpha(31),
                        foregroundColor:
                            item.isMasuk ? Colors.green : Colors.red,
                        child: Icon(
                          item.isMasuk
                              ? Icons.arrow_downward
                              : Icons.arrow_upward,
                        ),
                      ),
                      title: Text(item.keterangan ?? 'Tanpa keterangan'),
                      subtitle: Text(item.isMasuk ? 'Kas masuk' : 'Kas keluar'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${item.isMasuk ? '+' : '-'}'
                            '${formatRupiah(item.nominal, withSymbol: true)}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: item.isMasuk ? Colors.green : Colors.red,
                            ),
                          ),
                          PopupMenuButton<String>(
                            onSelected: (value) {
                              if (value == 'edit') {
                                _tambahAtauEditTransaksi(existing: item);
                              } else if (value == 'delete') {
                                _hapusTransaksi(item);
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
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton(
            onPressed: _isSaving ? null : () => _tambahAtauEditTransaksi(),
            child: const Icon(Icons.add),
          ),
        ),
      ],
    );
  }
}
