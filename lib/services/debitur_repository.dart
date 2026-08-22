import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/debitur_summary.dart';
import '../models/riwayat_transaksi.dart';

class DebiturRepository {
  DebiturRepository([SupabaseClient? client])
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<List<DebiturSummary>> getDebiturSummary() async {
    final response = await _client.from('debitur_summary').select();

    return response.map((item) => DebiturSummary.fromMap(item)).toList();
  }

  Future<List<RiwayatTransaksi>> getRiwayatTransaksi() async {
    final response = await _client.from('riwayat_transaksi').select();

    final riwayat = response
        .map((item) => RiwayatTransaksi.fromMap(item))
        .toList();

    riwayat.sort((a, b) => b.tanggal.compareTo(a.tanggal));

    return riwayat;
  }

  Future<void> addKasbon({
    required String namaDebitur,
    required double nominal,
  }) async {
    final existingDebitur = await _client
        .from('debitur')
        .select('id')
        .eq('nama', namaDebitur)
        .maybeSingle();

    final debiturId =
        existingDebitur?['id'] as String? ??
        (await _client
                .from('debitur')
                .insert({'nama': namaDebitur})
                .select('id')
                .single())['id']
            as String;

    await _client.from('kasbon').insert({
      'debitur_id': debiturId,
      'nominal': nominal,
    });
  }

  Future<void> addPembayaran({
    required String debiturId,
    required double nominal,
  }) async {
    await _client.from('pembayaran').insert({
      'debitur_id': debiturId,
      'nominal': nominal,
    });
  }
Future<List<RiwayatTransaksi>> getRiwayatTransaksiByDebiturId(
  String debiturId,
) async {
  final response = await _client
      .from('riwayat_transaksi')
      .select()
      .eq('debitur_id', debiturId)
      .order('created_at', ascending: false);

  return response
      .map((item) => RiwayatTransaksi.fromMap(item))
      .toList();
}

}
