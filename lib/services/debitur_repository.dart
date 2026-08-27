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

  /// Daftar nama debitur unik (untuk autocomplete), diurutkan A–Z.
  Future<List<String>> getDebiturNames() async {
    final summaries = await getDebiturSummary();
    final names =
        summaries.map((e) => e.nama.trim()).where((n) => n.isNotEmpty);
    final unique = names.toSet().toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return unique;
  }

  Future<List<RiwayatTransaksi>> getRiwayatTransaksi() async {
    final response = await _client.from('riwayat_transaksi').select();

    final riwayat =
        response.map((item) => RiwayatTransaksi.fromMap(item)).toList();
    riwayat.sort((a, b) => b.tanggal.compareTo(a.tanggal));
    return riwayat;
  }

  Future<List<RiwayatTransaksi>> getRiwayatTransaksiByDebiturId(
    String debiturId,
  ) async {
    final response = await _client
        .from('riwayat_transaksi')
        .select()
        .eq('debitur_id', debiturId)
        .order('created_at', ascending: false);

    return response.map((item) => RiwayatTransaksi.fromMap(item)).toList();
  }

  Future<void> addKasbon({
    required String namaDebitur,
    required double nominal,
  }) async {
    final nama = namaDebitur.trim();
    if (nama.isEmpty) {
      throw ArgumentError('Nama debitur tidak boleh kosong');
    }

    // Cari debitur existing (case-insensitive).
    final existingList = await _client.from('debitur').select('id, nama');
    String? debiturId;
    for (final row in existingList) {
      final rowNama = (row['nama'] as String?)?.trim() ?? '';
      if (rowNama.toLowerCase() == nama.toLowerCase()) {
        debiturId = row['id'] as String;
        break;
      }
    }

    debiturId ??=
        (await _client
                .from('debitur')
                .insert({'nama': nama})
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

  Future<void> updateKasbon({
    required String id,
    required double nominal,
  }) async {
    await _client.from('kasbon').update({'nominal': nominal}).eq('id', id);
  }

  Future<void> deleteKasbon(String id) async {
    await _client.from('kasbon').delete().eq('id', id);
  }

  Future<void> updatePembayaran({
    required String id,
    required double nominal,
  }) async {
    await _client.from('pembayaran').update({'nominal': nominal}).eq('id', id);
  }

  Future<void> deletePembayaran(String id) async {
    await _client.from('pembayaran').delete().eq('id', id);
  }

  /// Update nominal transaksi berdasarkan jenis (kasbon / pembayaran).
  Future<void> updateTransaksi({
    required RiwayatTransaksi item,
    required double nominal,
  }) async {
    if (item.isKasbon) {
      await updateKasbon(id: item.id, nominal: nominal);
    } else if (item.isPembayaran) {
      await updatePembayaran(id: item.id, nominal: nominal);
    } else {
      throw StateError('Jenis transaksi tidak dikenali: ${item.jenis}');
    }
  }

  /// Hapus transaksi berdasarkan jenis (kasbon / pembayaran).
  Future<void> deleteTransaksi(RiwayatTransaksi item) async {
    if (item.isKasbon) {
      await deleteKasbon(item.id);
    } else if (item.isPembayaran) {
      await deletePembayaran(item.id);
    } else {
      throw StateError('Jenis transaksi tidak dikenali: ${item.jenis}');
    }
  }
}
