import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/debitur_summary.dart';

class DebiturRepository {
  DebiturRepository([SupabaseClient? client])
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<List<DebiturSummary>> getDebiturSummary() async {
    final response =
        await _client.from('debitur_summary').select();

    return response
        .map((item) => DebiturSummary.fromMap(item))
        .toList();
  }
}