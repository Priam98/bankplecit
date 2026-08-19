import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/debitur_summary.dart';

class DebiturRepository {
  DebiturRepository([SupabaseClient? client])
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<List<DebiturSummary>> getDebiturSummary() async {
    final response = await _client.from('debitur_summary').select();

    return response.map((item) => DebiturSummary.fromMap(item)).toList();
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
}
