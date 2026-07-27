// TODO Implement this library.
import 'package:supabase_flutter/supabase_flutter.dart';

class PosService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Obtiene la suma total de ventas registradas en la tabla de ventas
  Future<double> getTotalVentas() async {
    try {
      final response = await _supabase.from('ventas').select('monto_bs');

      double total = 0.0;
      for (var item in response) {
        total += (item['monto_bs'] as num?)?.toDouble() ?? 0.0;
      }
      return total;
    } catch (e) {
      return 0.0;
    }
  }

  /// Obtiene el conteo de incidentes/alertas con estado 'pendiente'
  Future<int> getAlertasPendientesCount() async {
    try {
      final response = await _supabase
          .from('incidentes_surtidor')
          .select('id')
          .eq('estado', 'pendiente');

      return response.length;
    } catch (e) {
      return 0;
    }
  }

  /// Obtiene la lista completa de surtidores
  Future<List<Map<String, dynamic>>> getSurtidores() async {
    try {
      final response = await _supabase
          .from('surtidores')
          .select()
          .order('numero_surtidor', ascending: true);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  /// Registra una nueva venta POS en la base de datos
  Future<bool> registrarVenta({
    required int surtidorId,
    required String tipoCombustible,
    required double litros,
    required double montoBs,
    required String metodoPago,
    String? clienteNit,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      await _supabase.from('ventas').insert({
        'surtidor_id': surtidorId,
        'cajero_id': user?.id,
        'tipo_combustible': tipoCombustible,
        'litros': litros,
        'monto_bs': montoBs,
        'metodo_pago': metodoPago,
        'cliente_nit': clienteNit ?? 'S/N',
      });
      return true;
    } catch (e) {
      return false;
    }
  }
}
