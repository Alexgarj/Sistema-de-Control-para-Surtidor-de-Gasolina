import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/app_colors.dart';

class PosPage extends StatefulWidget {
  const PosPage({super.key});

  @override
  State<PosPage> createState() => _PosPageState();
}

class _PosPageState extends State<PosPage> {
  final _supabase = Supabase.instance.client;

  // Configuración inicial alineada con los surtidores reales de tu base de datos
  int _selectedSurtidor = 1;
  String _selectedCombustible = 'Gasolina Especial';
  String _montoPersonalizado = '';
  String _metodoPago =
      'Efectivo'; // Mantiene exactamente los valores del sistema

  final TextEditingController _placaController = TextEditingController();
  final TextEditingController _nitController = TextEditingController();

  bool _isProcessing = false;

  /// Obtiene el precio según el combustible seleccionado
  double get _precioPorUnidad {
    switch (_selectedCombustible.toLowerCase()) {
      case 'gasolina premium':
      case 'premium':
        return 4.79;
      case 'diesel olímpico':
      case 'diésel olímpico':
      case 'diesel':
      case 'diésel':
        return 3.72;
      case 'gnv':
        return 1.66;
      case 'gasolina especial':
      case 'especial':
      default:
        return 3.74;
    }
  }

  double get _litrosCalculados {
    final monto = double.tryParse(_montoPersonalizado) ?? 0.0;
    if (monto <= 0) return 0.0;
    return monto / _precioPorUnidad;
  }

  void _onKeypadTap(String value) {
    setState(() {
      if (value == 'C') {
        _montoPersonalizado = '';
      } else if (value == '←') {
        if (_montoPersonalizado.isNotEmpty) {
          _montoPersonalizado = _montoPersonalizado.substring(
            0,
            _montoPersonalizado.length - 1,
          );
        }
      } else {
        _montoPersonalizado += value;
      }
    });
  }

  void _procesarVenta() {
    final monto = double.tryParse(_montoPersonalizado) ?? 0.0;

    if (monto <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ingresa un monto válido para confirmar la venta.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_metodoPago == 'Código QR') {
      _mostrarDialogoQR(monto);
    } else {
      _guardarVentaEnSupabase(monto);
    }
  }

  void _mostrarDialogoQR(double monto) {
    final placaText = _placaController.text.trim().isEmpty
        ? 'S/N'
        : _placaController.text.trim().toUpperCase();

    final qrData =
        'PAGO_GASOLINA|BS:$monto|SURTIDOR:$_selectedSurtidor|PLACA:$placaText';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppColors.cardBorder),
          ),
          title: const Text(
            'Cobro con Código QR',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: SizedBox(
            width: 300,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Monto: Bs. ${monto.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: AppColors.secondary,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: RepaintBoundary(
                    child: QrImageView(
                      data: qrData,
                      version: QrVersions.auto,
                      size: 200.0,
                      gapless: false,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Escanea con la app bancaria para completar la transacción.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text(
                'Cancelar',
                style: TextStyle(color: Colors.red),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _guardarVentaEnSupabase(monto);
              },
              child: const Text(
                'Confirmar Pago',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _guardarVentaEnSupabase(double monto) async {
    setState(() => _isProcessing = true);

    try {
      final user = _supabase.auth.currentUser;
      final litrosCalculados =
          double.tryParse(_litrosCalculados.toStringAsFixed(2)) ?? 0.0;
      final placaTexto = _placaController.text.trim().isEmpty
          ? 'S/N'
          : _placaController.text.trim().toUpperCase();
      final nitTexto = _nitController.text.trim().isEmpty
          ? 'S/N'
          : _nitController.text.trim();

      final Map<String, dynamic> payload = {
        'surtidor_id': _selectedSurtidor,
        'tipo_combustible': _selectedCombustible,
        'litros': litrosCalculados,
        'precio_por_litro': _precioPorUnidad,
        'monto_total': monto,
        'monto_bs': monto,
        'metodo_pago': _metodoPago,
        'placa': placaTexto,
        'cliente_nit': nitTexto,
      };

      if (user != null) {
        payload['cajero_id'] = user.id;
      }

      await _supabase.from('ventas').insert(payload);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Venta registrada exitosamente.'),
            backgroundColor: Colors.green,
          ),
        );

        setState(() {
          _montoPersonalizado = '';
          _placaController.clear();
          _nitController.clear();
        });
      }
    } on PostgrestException catch (e) {
      if (mounted) {
        String mensaje = 'Error al registrar la venta.';
        if (e.code == '23503') {
          mensaje =
              'El Surtidor #$_selectedSurtidor no existe en el catálogo de la base de datos.';
        } else {
          mensaje = e.message;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(mensaje),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error inesperado: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  void dispose() {
    _placaController.dispose();
    _nitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // COLUMNA IZQUIERDA
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCardContainer(
                  title: 'SELECCIONAR SURTIDOR',
                  child: Row(
                    children: [
                      // Surtidor #1: Gasolina Especial
                      _buildSurtidorSelectCard(1, 'Gasolina Especial'),
                      const SizedBox(width: 8),
                      // Surtidor #2: Diesel Olímpico (con la denominación exacta del sistema)
                      _buildSurtidorSelectCard(2, 'Diesel Olímpico'),
                      const SizedBox(width: 8),
                      // Surtidor #3: Gasolina Premium
                      _buildSurtidorSelectCard(3, 'Gasolina Premium'),
                      const SizedBox(width: 8),
                      // Surtidor #8: GNV (ID real de la BD según el panel)
                      _buildSurtidorSelectCard(8, 'GNV'),
                    ],
                  ),
                ),

                _buildCardContainer(
                  title: 'MONTO RÁPIDO (BS.)',
                  child: Column(
                    children: [
                      Row(
                        children: [50, 100, 200, 500].map((m) {
                          return Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4.0,
                              ),
                              child: OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(
                                    color: AppColors.cardBorder,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                ),
                                onPressed: () => setState(
                                  () => _montoPersonalizado = m.toString(),
                                ),
                                child: Text(
                                  '$m',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.warning),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          icon: const Icon(
                            LucideIcons.droplet,
                            color: AppColors.warning,
                          ),
                          label: const Text(
                            'Tanque Lleno',
                            style: TextStyle(
                              color: AppColors.warning,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          onPressed: () => setState(() {
                            _montoPersonalizado = '250';
                          }),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                _buildCardContainer(
                  title: 'MONTO PERSONALIZADO',
                  child: Column(
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _montoPersonalizado.isEmpty
                              ? 'Ingresa el monto'
                              : 'Bs. $_montoPersonalizado',
                          style: TextStyle(
                            color: _montoPersonalizado.isEmpty
                                ? AppColors.textSecondary
                                : Colors.white,
                            fontSize: 18,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      GridView.count(
                        crossAxisCount: 3,
                        shrinkWrap: true,
                        childAspectRatio: 2.2,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        children:
                            [
                              '1',
                              '2',
                              '3',
                              '4',
                              '5',
                              '6',
                              '7',
                              '8',
                              '9',
                              'C',
                              '0',
                              '←',
                            ].map((key) {
                              final isDelete = key == 'C';
                              return ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isDelete
                                      ? Colors.red.withOpacity(0.2)
                                      : AppColors.surface,
                                  side: const BorderSide(
                                    color: AppColors.cardBorder,
                                  ),
                                ),
                                onPressed: () => _onKeypadTap(key),
                                child: Text(
                                  key,
                                  style: TextStyle(
                                    color: isDelete ? Colors.red : Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              );
                            }).toList(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 24),

          // COLUMNA DERECHA
          Expanded(
            flex: 2,
            child: Column(
              children: [
                _buildCardContainer(
                  title: 'DATOS DEL VEHÍCULO / CLIENTE',
                  child: Column(
                    children: [
                      TextField(
                        controller: _placaController,
                        onChanged: (_) => setState(() {}),
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          labelText: 'Placa / B-SISA',
                          hintText: 'EJ. 3452 ABC',
                          hintStyle: TextStyle(color: AppColors.textSecondary),
                          labelStyle: TextStyle(color: AppColors.textSecondary),
                          filled: true,
                          fillColor: AppColors.background,
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _nitController,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          labelText: 'NIT / CI (Facturación)',
                          hintText: 'Ej. 4567890',
                          hintStyle: TextStyle(color: AppColors.textSecondary),
                          labelStyle: TextStyle(color: AppColors.textSecondary),
                          filled: true,
                          fillColor: AppColors.background,
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                _buildCardContainer(
                  title: 'MÉTODO DE COBRO',
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildMetodoPagoCard(
                          'Efectivo',
                          LucideIcons.banknote,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildMetodoPagoCard(
                          'Código QR',
                          LucideIcons.qrCode,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                _buildCardContainer(
                  title: 'RESUMEN',
                  child: Column(
                    children: [
                      _buildResumenRow('Surtidor', '#$_selectedSurtidor'),
                      _buildResumenRow('Combustible', _selectedCombustible),
                      _buildResumenRow(
                        'Monto',
                        _montoPersonalizado.isEmpty
                            ? 'Bs. 0.00'
                            : 'Bs. $_montoPersonalizado',
                      ),
                      _buildResumenRow(
                        'Litros estimados',
                        '${_litrosCalculados.toStringAsFixed(2)} Lts.',
                      ),
                      _buildResumenRow('Pago', _metodoPago),
                      _buildResumenRow(
                        'Placa',
                        _placaController.text.trim().isEmpty
                            ? '—'
                            : _placaController.text.trim().toUpperCase(),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                          ),
                          icon: _isProcessing
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(
                                  LucideIcons.checkCircle2,
                                  color: Colors.white,
                                ),
                          label: Text(
                            _isProcessing ? 'Guardando...' : 'Confirmar Venta',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          onPressed: _isProcessing ? null : _procesarVenta,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardContainer({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  /// Construye la tarjeta del surtidor evitando colores llamativos de fondo que se confundan con los estados (Activo, Despachando, Mantenimiento)
  Widget _buildSurtidorSelectCard(int id, String comb) {
    final isSelected = _selectedSurtidor == id;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() {
          _selectedSurtidor = id;
          _selectedCombustible = comb;
        }),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary.withOpacity(0.15)
                : AppColors.background,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.cardBorder,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Text(
                '#$id',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              // Etiqueta de combustible neutralizada para no confundir con los estados
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary.withOpacity(0.2)
                      : Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  comb,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isSelected ? Colors.white : AppColors.textSecondary,
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetodoPagoCard(String label, IconData icon) {
    final isSelected = _metodoPago == label;
    return InkWell(
      onTap: () => setState(() => _metodoPago = label),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withOpacity(0.15)
              : AppColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.cardBorder,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.secondary : AppColors.textSecondary,
              size: 28,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : AppColors.textSecondary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResumenRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
