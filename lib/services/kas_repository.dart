import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/transaksi_kas.dart';

class KasRepository {
  KasRepository([SupabaseClient? client])
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<List<TransaksiKas>> getTransaksi() async {
    final response = await _client
        .from('transaksi_kas')
        .select()
        .order('tanggal', ascending: false);

    return (response as List)
        .map((item) => TransaksiKas.fromMap(item as Map<String, dynamic>))
        .toList();
  }

  Future<void> tambahTransaksi({
    required String jenis,
    required double nominal,
    String? keterangan,
    DateTime? tanggal,
  }) async {
    await _client.from('transaksi_kas').insert({
      'jenis': jenis,
      'nominal': nominal,
      'keterangan': keterangan,
      'tanggal': (tanggal ?? DateTime.now()).toIso8601String(),
    });
  }

  Future<void> updateTransaksi({
    required String id,
    required String jenis,
    required double nominal,
    String? keterangan,
  }) async {
    await _client.from('transaksi_kas').update({
      'jenis': jenis,
      'nominal': nominal,
      'keterangan': keterangan,
    }).eq('id', id);
  }

  Future<void> deleteTransaksi(String id) async {
    await _client.from('transaksi_kas').delete().eq('id', id);
  }
}
