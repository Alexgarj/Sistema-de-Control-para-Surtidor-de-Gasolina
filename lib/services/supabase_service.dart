// TODO Implement this library.
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  // Configuración del proyecto de Supabase
  // Reemplaza estas cadenas con tus credenciales reales del Dashboard de Supabase
  static const String _supabaseUrl = 'https://bxhbfwvlwgqozrbhmfrx.supabase.co';
  static const String _supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJ4aGJmd3Zsd2dxb3pyYmhtZnJ4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODM0OTk2MzEsImV4cCI6MjA5OTA3NTYzMX0.ZgbmwKOnI_7uKzV4U1Zo6aX8xU3M8XFvLkzQ6PNDhTQ';

  /// Inicializa el cliente de Supabase antes de ejecutar la aplicación.
  static Future<void> initialize() async {
    try {
      await Supabase.initialize(url: _supabaseUrl, anonKey: _supabaseAnonKey);
      debugPrint('⚡ Supabase inicializado correctamente.');
    } catch (e) {
      debugPrint('❌ Error al inicializar Supabase: $e');
    }
  }

  /// Getter global para acceder al cliente de Supabase en cualquier adaptador o servicio.
  static SupabaseClient get client => Supabase.instance.client;
}
