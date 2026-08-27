import 'package:flutter/material.dart';

import '../models/debitur.dart';
import '../models/debitur_summary.dart';
import '../models/kasbon.dart';
import '../models/pembayaran.dart';
import '../services/debitur_repository.dart';
import '../utils/currency.dart';
import '../widgets/status_chip.dart';
import 'add_loan_page.dart';
import 'detail_debitur_page.dart';
import 'kas_page.dart';
import 'riwayat_transaksi_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  /// Hanya debitur yang masih punya sisa (belum lunas).
  final List<Debitur> debiturAktif = [];
  int selectedPageIndex = 0;
  bool _isLoading = true;
  String? _loadError;

  double get totalPiutang {
    return debiturAktif.fold(0.0, (total, item) => total + item.sisa);
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

      final semua = summaries.map(_debiturFromSummary).toList();
      final aktif = semua.where((d) => d.sisa > 0).toList();

      setState(() {
        debiturAktif
          ..clear()
          ..addAll(aktif);
        _isLoading = false;
      });

      debugPrint('Supabase terhubung: ${aktif.length} debitur aktif.');
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
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'Riwayat',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_balance_wallet_outlined),
            selectedIcon: Icon(Icons.account_balance_wallet),
            label: 'Kas',
          ),
        ],
      ),
    );
  }

  Widget _buildDashboard() {
    if (_isLoading && debiturAktif.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_loadError != null && debiturAktif.isEmpty) {
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
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          Card(
            color: Theme.of(context).colorScheme.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total Piutang',
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context)
                          .colorScheme
                          .onPrimaryContainer
                          .withAlpha(200),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    formatRupiah(totalPiutang, withSymbol: true),
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${debiturAktif.length} debitur',
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context)
                          .colorScheme
                          .onPrimaryContainer
                          .withAlpha(200),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Text(
                'Daftar Debitur',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const Spacer(),
              Text(
                '${debiturAktif.length}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (debiturAktif.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 48),
              child: Center(child: Text('Belum ada debitur aktif.')),
            )
          else
            ...debiturAktif.map((item) {
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
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
                  leading: CircleAvatar(
                    backgroundColor: Theme.of(context)
                        .colorScheme
                        .secondaryContainer,
                    child: Icon(
                      Icons.person,
                      color: Theme.of(context)
                          .colorScheme
                          .onSecondaryContainer,
                    ),
                  ),
                  title: Text(item.nama),
                  subtitle: const Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: StatusChip(
                        label: 'Belum lunas',
                        positive: false,
                      ),
                    ),
                  ),
                  trailing: Text(
                    formatRupiah(item.sisa, withSymbol: true),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              );
            }),
          const SizedBox(height: 16),
          FilledButton.icon(
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
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
            icon: const Icon(Icons.add),
            label: const Text('Kasih Kasbon'),
          ),
        ],
      ),
    );
  }
}
