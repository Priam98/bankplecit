import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/transaksi_kas.dart';

class KasRepository{
  final SupabaseClient _client = Supabase.instance.client;
  Future<List<TransaksiKas>> getTransaksi() async {
    final response = await _client
    .from('transaksi_kas')
    .select()
    .order('tanggal', ascending: false);

    return (response as List)
    .map((item) => TransaksiKas.fromMap(item))
    .toList();
  }

  Future<void> tambahTransaksi({
    required String jenis,
    required double nominal,
    String? keterangan,
    DateTime? tanggal,
  }) async {
    await
    _client.from('transaksi_kas').insert({
      'jenis': jenis,
      'nominal': nominal,
      'keterangan': keterangan,
      'tanggal': tanggal ?? DateTime.now().toIso8601String(),
    });
  }}
  