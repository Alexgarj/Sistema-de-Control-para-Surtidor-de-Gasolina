import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  static const String supabaseUrl = 'https://bxhbfwvlwgqozrbhmfrx.supabase.co';
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJ4aGJmd3Zsd2dxb3pyYmhtZnJ4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODM0OTk2MzEsImV4cCI6MjA5OTA3NTYzMX0.ZgbmwKOnI_7uKzV4U1Zo6aX8xU3M8XFvLkzQ6PNDhTQ';

  final SupabaseClient supabase = Supabase.instance.client;

  // 🔑 1. INICIAR SESIÓN (Faltaba este método)
  Future<AuthResponse> iniciarSesion({
    required String email,
    required String password,
  }) async {
    final response = await supabase.auth.signInWithPassword(
      email: email.trim().toLowerCase(),
      password: password.trim(),
    );
    return response;
  }

  // 👤 2. OBTENIR PERFIL DEL USUARIO LOGUEADO
  Future<Map<String, dynamic>?> obtenerPerfil() async {
    final user = usuarioActual;
    if (user == null) return null;

    final data = await supabase
        .from('perfiles')
        .select()
        .eq('id', user.id)
        .maybeSingle();

    return data;
  }

  // 📝 3. REGISTRAR NUEVO USUARIO (Sin perder la sesión del Admin)
  Future<void> registrarUsuario({
    required String email,
    required String password,
    required String nombreCompleto,
    required String ci,
    required String rol,
    required String turno,
  }) async {
    final tempClient = SupabaseClient(supabaseUrl, supabaseAnonKey);

    try {
      final response = await tempClient.auth.signUp(
        email: email.trim().toLowerCase(),
        password: password,
        data: {
          'nombre_completo': nombreCompleto,
          'ci': ci,
          'rol': rol,
          'turno': turno,
        },
      );

      if (response.user == null) {
        throw Exception('No se pudo registrar el usuario en la base de datos.');
      }
    } finally {
      tempClient.dispose();
    }
  }

  // 🚪 4. CERRAR SESIÓN
  Future<void> cerrarSesion() async {
    await supabase.auth.signOut();
  }

  // ℹ️ USUARIO ACTUAL
  User? get usuarioActual => supabase.auth.currentUser;
}
