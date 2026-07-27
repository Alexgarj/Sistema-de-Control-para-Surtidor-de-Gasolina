import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/constants/app_colors.dart';

class CrearUsuarioDialog extends StatefulWidget {
  const CrearUsuarioDialog({super.key});

  @override
  State<CrearUsuarioDialog> createState() => _CrearUsuarioDialogState();
}

class _CrearUsuarioDialogState extends State<CrearUsuarioDialog> {
  final _nombreController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  String _rolSeleccionado = 'cajero'; // Permite elegir Cajero o Admin
  String _turnoSeleccionado = 'Mañana';
  bool _isLoading = false;

  Future<void> _crearUsuario() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor llena todos los campos')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final supabase = Supabase.instance.client;

      // 1. Crear en Supabase Auth
      final response = await supabase.auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (response.user != null) {
        // 2. Insertar en la tabla 'perfiles' con el ROL seleccionado
        await supabase.from('perfiles').insert({
          'id': response.user!.id,
          'nombre_completo': _nombreController.text.trim(),
          'rol': _rolSeleccionado, // Guardará 'admin' o 'cajero'
          'turno': _turnoSeleccionado,
        });

        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Usuario ($_rolSeleccionado) creado exitosamente'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al crear usuario: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text(
        'Crear Nuevo Usuario / Operario',
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nombreController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                prefixIcon: Icon(
                  Icons.person_outline,
                  color: AppColors.textSecondary,
                ),
                labelText: 'Nombre Completo',
                labelStyle: TextStyle(color: AppColors.textSecondary),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _emailController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                prefixIcon: Icon(
                  Icons.email_outlined,
                  color: AppColors.textSecondary,
                ),
                labelText: 'Correo Electrónico',
                labelStyle: TextStyle(color: AppColors.textSecondary),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _passwordController,
              obscureText: true,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                prefixIcon: Icon(
                  Icons.lock_outline,
                  color: AppColors.textSecondary,
                ),
                labelText: 'Contraseña',
                labelStyle: TextStyle(color: AppColors.textSecondary),
              ),
            ),
            const SizedBox(height: 16),

            // SELECTOR DE ROL (Admin / Cajero)
            DropdownButtonFormField<String>(
              value: _rolSeleccionado,
              dropdownColor: AppColors.surface,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Rol de Usuario',
                labelStyle: TextStyle(color: AppColors.textSecondary),
              ),
              items: const [
                DropdownMenuItem(
                  value: 'cajero',
                  child: Text('Cajero / Operario'),
                ),
                DropdownMenuItem(value: 'admin', child: Text('Administrador')),
              ],
              onChanged: (val) => setState(() => _rolSeleccionado = val!),
            ),
            const SizedBox(height: 12),

            // SELECTOR DE TURNO
            DropdownButtonFormField<String>(
              value: _turnoSeleccionado,
              dropdownColor: AppColors.surface,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Turno',
                labelStyle: TextStyle(color: AppColors.textSecondary),
              ),
              items: const [
                DropdownMenuItem(value: 'Mañana', child: Text('Mañana')),
                DropdownMenuItem(value: 'Tarde', child: Text('Tarde')),
                DropdownMenuItem(value: 'Noche', child: Text('Noche')),
              ],
              onChanged: (val) => setState(() => _turnoSeleccionado = val!),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(
            'Cancelar',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
          onPressed: _isLoading ? null : _crearUsuario,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text(
                  'Guardar Usuario',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
      ],
    );
  }
}
