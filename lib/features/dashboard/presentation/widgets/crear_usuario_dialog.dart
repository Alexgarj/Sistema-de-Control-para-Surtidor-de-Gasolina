import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../auth/data/auth_service.dart'; // Importación única y limpia

class CrearUsuarioDialog extends StatefulWidget {
  const CrearUsuarioDialog({super.key});

  @override
  State<CrearUsuarioDialog> createState() => _CrearUsuarioDialogState();
}

class _CrearUsuarioDialogState extends State<CrearUsuarioDialog> {
  final _nombreController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _ciController = TextEditingController();

  final _authService = AuthService();

  String _rolSeleccionado = 'Cajero';
  String _turnoSeleccionado = 'Mañana';
  bool _isLoading = false;

  @override
  void dispose() {
    _nombreController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _ciController.dispose();
    super.dispose();
  }

  Future<void> _crearUsuario() async {
    final email = _emailController.text.trim().toLowerCase();
    final password = _passwordController.text.trim();
    final nombre = _nombreController.text.trim();
    final ci = _ciController.text.trim();

    if (nombre.isEmpty || email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor llena los campos requeridos'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _authService.registrarUsuario(
        email: email,
        password: password,
        nombreCompleto: nombre,
        ci: ci,
        rol: _rolSeleccionado,
        turno: _turnoSeleccionado,
      );

      if (mounted) {
        Navigator.pop(
          context,
          true,
        ); // Retornamos true para refrescar la lista si hace falta
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Usuario $_rolSeleccionado creado con éxito'),
            backgroundColor: AppColors.success,
          ),
        );
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
      title: const Text(
        'Crear Nuevo Usuario',
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
      content: SingleChildScrollView(
        child: SizedBox(
          width: 380,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nombreController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Nombre Completo',
                  labelStyle: TextStyle(color: AppColors.textSecondary),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _ciController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'C.I. / Documento',
                  labelStyle: TextStyle(color: AppColors.textSecondary),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _emailController,
                style: const TextStyle(color: Colors.white),
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
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
                  labelText: 'Contraseña Asignada',
                  labelStyle: TextStyle(color: AppColors.textSecondary),
                ),
              ),
              const SizedBox(height: 16),

              // Rol Dropdown
              DropdownButtonFormField<String>(
                value: _rolSeleccionado,
                dropdownColor: AppColors.surface,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Rol del Sistema',
                  labelStyle: TextStyle(color: AppColors.textSecondary),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'Administrador',
                    child: Text('Administrador'),
                  ),
                  DropdownMenuItem(
                    value: 'Cajero',
                    child: Text('Cajero / Operador'),
                  ),
                  DropdownMenuItem(
                    value: 'Supervisión',
                    child: Text('Supervisión'),
                  ),
                ],
                onChanged: (v) {
                  if (v != null) setState(() => _rolSeleccionado = v);
                },
              ),
              const SizedBox(height: 12),

              // Turno Dropdown
              DropdownButtonFormField<String>(
                value: _turnoSeleccionado,
                dropdownColor: AppColors.surface,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Turno Asignado',
                  labelStyle: TextStyle(color: AppColors.textSecondary),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'Mañana',
                    child: Text('Turno Mañana'),
                  ),
                  DropdownMenuItem(value: 'Tarde', child: Text('Turno Tarde')),
                  DropdownMenuItem(value: 'Noche', child: Text('Turno Noche')),
                ],
                onChanged: (v) {
                  if (v != null) setState(() => _turnoSeleccionado = v);
                },
              ),
            ],
          ),
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
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : const Text('Guardar Usuario'),
        ),
      ],
    );
  }
}
