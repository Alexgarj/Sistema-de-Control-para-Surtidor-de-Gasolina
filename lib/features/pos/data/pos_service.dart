import 'package:supabase_flutter/supabase_flutter.dart';

class PosService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Obtiene la suma total de ventas registradas por el usuario actual
  Future<double> getTotalVentas() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return 0.0;

      final response = await _supabase
          .from('ventas')
          .select('monto_total')
          .eq('cajero_id', user.id);

      double total = 0.0;
      for (var item in response) {
        total += (item['monto_total'] as num?)?.toDouble() ?? 0.0;
      }
      return total;
    } catch (e) {
      return 0.0;
    }
  }

  /// Obtiene las alertas pendientes
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

  /// Obtiene los surtidores
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

  /// Registra la venta con los nombres EXACTOS de columnas en Supabase
  Future<bool> registrarVenta({
    required int surtidorId,
    required String tipoCombustible,
    required double litros,
    required double precioPorLitro,
    required double montoTotal,
    required String metodoPago,
    required String placa,
    String? clienteNit,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      await _supabase.from('ventas').insert({
        'surtidor_id': surtidorId,
        'cajero_id': user?.id,
        'tipo_combustible': tipoCombustible,
        'litros': litros,
        'precio_por_litro': precioPorLitro,
        'monto_total': montoTotal, // <--- Campo clave solucionado
        'metodo_pago': metodoPago,
        'placa': placa,
        'cliente_nit': clienteNit ?? 'S/N',
      });
      return true;
    } catch (e) {
      rethrow;
    }
  }
}
