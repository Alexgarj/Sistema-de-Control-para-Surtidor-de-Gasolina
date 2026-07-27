import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/supabase_service.dart';
import 'database_adapter.dart';

class SupabaseAdapter implements DatabaseAdapter {
  final SupabaseClient _client = SupabaseService.client;

  @override
  Future<List<Map<String, dynamic>>> getSurtidores() async {
    final response = await _client
        .from('surtidores')
        .select()
        .order('numero_surtidor');
    return List<Map<String, dynamic>>.from(response);
  }

  @override
  Future<void> insertSurtidor(Map<String, dynamic> data) async {
    await _client.from('surtidores').insert(data);
  }

  @override
  Future<void> updateSurtidor(int id, Map<String, dynamic> data) async {
    await _client.from('surtidores').update(data).eq('id', id);
  }

  @override
  Future<void> deleteSurtidor(int id) async {
    await _client.from('surtidores').delete().eq('id', id);
  }

  @override
  Stream<List<Map<String, dynamic>>> streamSurtidores() {
    return _client
        .from('surtidores')
        .stream(primaryKey: ['id'])
        .order('numero_surtidor', ascending: true);
  }
}
