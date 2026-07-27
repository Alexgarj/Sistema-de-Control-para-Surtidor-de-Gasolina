import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/constants/app_colors.dart';

class CrearSurtidorDialog extends StatefulWidget {
  const CrearSurtidorDialog({super.key});

  @override
  State<CrearSurtidorDialog> createState() => _CrearSurtidorDialogState();
}

class _CrearSurtidorDialogState extends State<CrearSurtidorDialog> {
  final _numeroController = TextEditingController();
  String _combustibleSeleccionado = 'Gasolina Especial';
  String _estadoSeleccionado = 'En espera';
  bool _isLoading = false;

  final List<String> _tiposCombustible = [
    'Gasolina Especial',
    'Gasolina Premium',
    'Diésel',
    'GNV',
  ];

  final List<String> _estados = [
    'En espera',
    'Despachando',
    'Mantenimiento',
    'Fuera de servicio',
  ];

  @override
  void dispose() {
    _numeroController.dispose();
    super.dispose();
  }

  Future<void> _guardarSurtidor() async {
    final textoNumero = _numeroController.text.trim();

    if (textoNumero.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ingresa el número identificador del surtidor'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final int? numSurtidor = int.tryParse(textoNumero);
    if (numSurtidor == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('El número de surtidor debe ser numérico'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final supabase = Supabase.instance.client;

      // Convertimos el estado visible a la clave esperada por la Base de Datos
      String estadoBD;
      switch (_estadoSeleccionado) {
        case 'En espera':
          estadoBD =
              'en_espera'; // o 'Mantenimiento' / 'mantenimiento' según tu tabla
          break;
        case 'Despachando':
          estadoBD = 'despachando';
          break;
        case 'Mantenimiento':
          estadoBD = 'mantenimiento';
          break;
        case 'Fuera de servicio':
          estadoBD = 'fuera_de_servicio';
          break;
        default:
          estadoBD = _estadoSeleccionado.toLowerCase();
      }

      await supabase.from('surtidores').insert({
        'numero_surtidor': numSurtidor,
        'tipo_combustible': _combustibleSeleccionado,
        'estado': estadoBD, // 👈 Enviamos la clave válida
        'porcentaje_tanque': 1.0,
        'litros_hoy': 0,
        'capacidad_total_litros': 5000.0,
        'nivel_actual_litros': 5000.0,
      });

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Surtidor registrado correctamente'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } on PostgrestException catch (pgError) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error Supabase: ${pgError.message}'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error inesperado: $e'),
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
        'Registrar Nuevo Surtidor',
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _numeroController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Número / Código de Surtidor',
                hintText: 'Ej: 10',
                labelStyle: TextStyle(color: AppColors.textSecondary),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _combustibleSeleccionado,
              dropdownColor: AppColors.surface,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Tipo de Combustible',
                labelStyle: TextStyle(color: AppColors.textSecondary),
              ),
              items: _tiposCombustible.map((tipo) {
                return DropdownMenuItem(value: tipo, child: Text(tipo));
              }).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _combustibleSeleccionado = val);
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _estadoSeleccionado,
              dropdownColor: AppColors.surface,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Estado Inicial',
                labelStyle: TextStyle(color: AppColors.textSecondary),
              ),
              items: _estados.map((est) {
                return DropdownMenuItem(value: est, child: Text(est));
              }).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _estadoSeleccionado = val);
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text(
            'Cancelar',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
          onPressed: _isLoading ? null : _guardarSurtidor,
          icon: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : const Icon(Icons.save, size: 18),
          label: const Text('Guardar Surtidor'),
        ),
      ],
    );
  }
}
