import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/riwayat_transaksi.dart';
import '../services/debitur_repository.dart';
import '../utils/currency.dart';
import '../utils/date_format.dart';
import '../widgets/detail_amount.dart';
import '../widgets/status_chip.dart';

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
  bool _isSavingKasbon = false;

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

  // View riwayat bisa mengembalikan pembayaran sebagai nominal negatif.
  // Pakai abs supaya total & sisa tidak salah (mis. 200 - (-200) = 400).
  double _totalKasbon(List<RiwayatTransaksi> riwayat) {
    return riwayat
        .where((item) => item.isKasbon)
        .fold(0.0, (total, item) => total + item.nominal.abs());
  }

  double _totalPembayaran(List<RiwayatTransaksi> riwayat) {
    return riwayat
        .where((item) => item.isPembayaran)
        .fold(0.0, (total, item) => total + item.nominal.abs());
  }

  double _sisaPiutang(double totalKasbon, double totalPembayaran) {
    final sisa = totalKasbon - totalPembayaran;
    return sisa < 0 ? 0 : sisa;
  }

  double _kelebihanBayar(double totalKasbon, double totalPembayaran) {
    return totalPembayaran > totalKasbon ? totalPembayaran - totalKasbon : 0;
  }

  bool _isLunas(double totalKasbon, double totalPembayaran) {
    return totalPembayaran >= totalKasbon;
  }

  Future<double?> _dialogNominal(String title) async {
    final controller = TextEditingController();
    final nominal = await showDialog<double>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            inputFormatters: [RupiahInputFormatter()],
            autofocus: true,
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
    return nominal;
  }

  Future<void> tambahKasbon() async {
    final nominal = await _dialogNominal('Tambah Kasbon');
    if (nominal == null) return;

    setState(() => _isSavingKasbon = true);
    try {
      await DebiturRepository().addKasbonByDebiturId(
        debiturId: widget.debiturId,
        nominal: nominal,
      );
      if (!mounted) return;
      _reload();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kasbon berhasil ditambahkan.')),
      );
    } catch (error, stackTrace) {
      debugPrint('Gagal menambah kasbon: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kasbon gagal disimpan.')),
      );
    } finally {
      if (mounted) setState(() => _isSavingKasbon = false);
    }
  }

  Future<void> catatPembayaran() async {
    final nominal = await _dialogNominal('Catat Pembayaran');
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
    final controller =
        TextEditingController(text: formatRupiah(item.nominal.abs()));

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
          '${formatRupiah(item.nominal.abs(), withSymbol: true)}?',
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
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(widget.namaDebitur)),
      body: FutureBuilder<List<RiwayatTransaksi>>(
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
          final lunas = _isLunas(totalKasbon, totalPembayaran);

          return RefreshIndicator(
            onRefresh: () async {
              _reload();
              await _riwayatFuture;
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
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                widget.namaDebitur,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            StatusChip(
                              label: lunas ? 'LUNAS' : 'BELUM LUNAS',
                              positive: lunas,
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        DetailAmount(
                          label: 'Total Kasbon',
                          value: formatRupiah(totalKasbon, withSymbol: true),
                          fontSize: 26,
                        ),
                        const SizedBox(height: 16),
                        DetailAmount(
                          label: 'Total Pembayaran',
                          value:
                              formatRupiah(totalPembayaran, withSymbol: true),
                          fontSize: 20,
                          valueColor: Colors.green.shade700,
                        ),
                        const SizedBox(height: 16),
                        DetailAmount(
                          label: 'Sisa Piutang',
                          value: formatRupiah(sisaPiutang, withSymbol: true),
                          fontSize: 26,
                          valueColor: sisaPiutang > 0
                              ? scheme.error
                              : Colors.green.shade700,
                        ),
                        if (kelebihanBayar > 0) ...[
                          const SizedBox(height: 16),
                          DetailAmount(
                            label: 'Kelebihan Bayar',
                            value: formatRupiah(
                              kelebihanBayar,
                              withSymbol: true,
                            ),
                            fontSize: 20,
                            valueColor: Colors.blue.shade700,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Riwayat Transaksi',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                if (riwayat.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 32),
                    child: Center(child: Text('Belum ada riwayat transaksi.')),
                  )
                else
                  ...riwayat.map((item) {
                    final color =
                        item.isKasbon ? Colors.orange : Colors.green;
                    final icon = item.isKasbon
                        ? Icons.arrow_upward
                        : Icons.arrow_downward;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: color.withAlpha(31),
                          foregroundColor: color,
                          child: Icon(icon),
                        ),
                        title: Text(formatJenis(item.jenis)),
                        subtitle: Text(formatTanggal(item.tanggal)),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              formatRupiah(
                                item.nominal.abs(),
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
                      ),
                    );
                  }),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: (_isSavingKasbon || _isSavingPembayaran)
                            ? null
                            : tambahKasbon,
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(48),
                        ),
                        icon: _isSavingKasbon
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.add),
                        label: Text(
                          _isSavingKasbon ? 'Menyimpan...' : 'Tambah Kasbon',
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: (_isSavingKasbon || _isSavingPembayaran)
                            ? null
                            : catatPembayaran,
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(48),
                        ),
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
                              : 'Catat Bayar',
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
