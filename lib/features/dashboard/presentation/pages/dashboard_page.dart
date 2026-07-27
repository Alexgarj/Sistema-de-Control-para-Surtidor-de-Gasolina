import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:surtidor_gasolina_app/features/control/presentation/services/pos_service.dart';

import '../../../../core/constants/app_colors.dart';
import '../widgets/kpi_card.dart';
import 'package:surtidor_gasolina_app/features/control/presentation/services/pos_service.dart'; // Asegúrate de ajustar esta ruta según la ubicación exacta de pos_service.dart

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => DashboardPageState();
}

class DashboardPageState extends State<DashboardPage> {
  final _supabase = Supabase.instance.client;
  final _posService = PosService();
  bool _isLoading = true;

  double _totalVentas = 0.0;
  int _alertasPendientes = 0;
  List<Map<String, dynamic>> _surtidores = [];

  @override
  void initState() {
    super.initState();
    loadDashboardData();
  }

  /// Método público para refrescar datos cuando crees o edites un surtidor
  Future<void> loadDashboardData() async {
    try {
      final user = _supabase.auth.currentUser;

      // 1. Obtener Surtidores
      final surtidoresRes = await _posService.getSurtidores();

      // 2. Obtener Alertas / Incidentes Pendientes
      final alertasCount = await _posService.getAlertasPendientesCount();

      // 3. Sumar Total de Ventas FILTRADO SOLO PARA EL USUARIO ACTUAL
      double totalV = 0.0;
      if (user != null) {
        final reportesRes = await _supabase
            .from('reportes_caja')
            .select('total_ventas')
            .eq(
              'cajero_id',
              user.id,
            ); // <--- Filtro exclusivo por ID del usuario

        for (var r in reportesRes) {
          totalV += (r['total_ventas'] as num? ?? 0.0).toDouble();
        }
      }

      if (mounted) {
        setState(() {
          _surtidores = surtidoresRes;
          _alertasPendientes = alertasCount;
          _totalVentas = totalV;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error al cargar datos del Dashboard: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Helper para determinar si el estado del surtidor se considera activo
  bool _esEstadoActivo(String estado) {
    final est = estado.toLowerCase().trim();
    return est == 'funcionando' || est == 'activo' || est == 'en espera';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    final Color emeraldColor = AppColors.emerald ?? const Color(0xFF10B981);
    final Color dangerColor = AppColors.danger ?? const Color(0xFFEF4444);
    final Color primaryColor = AppColors.primary ?? const Color(0xFF00A3FF);

    // Contamos los surtidores que no estén fuera de servicio o inactivos
    final surtidoresActivos = _surtidores.where((s) {
      final estado = (s['estado'] ?? 'funcionando').toString();
      return _esEstadoActivo(estado);
    }).length;

    return RefreshIndicator(
      onRefresh: loadDashboardData,
      color: AppColors.primary,
      backgroundColor: AppColors.surface,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // FILA DE KPICARDS
            Row(
              children: [
                Expanded(
                  child: KpiCard(
                    title: 'Ventas Totales',
                    value: 'Bs. ${_totalVentas.toStringAsFixed(2)}',
                    icon: LucideIcons.trendingUp,
                    iconColor: emeraldColor,
                    subtitle: 'Sincronizado hoy',
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: KpiCard(
                    title: 'Alertas Pendientes',
                    value: '$_alertasPendientes',
                    icon: LucideIcons.alertTriangle,
                    iconColor: dangerColor,
                    subtitle: _alertasPendientes > 0
                        ? 'Requiere atención'
                        : 'Sin alertas',
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: KpiCard(
                    title: 'Surtidores Activos',
                    value: '$surtidoresActivos/${_surtidores.length}',
                    icon: LucideIcons.gauge,
                    iconColor: primaryColor,
                    subtitle: 'En operación',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),

            // ENCABEZADO Y BOTÓN DE REFRESCAR
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Estado Actual de Surtidores',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: loadDashboardData,
                  icon: const Icon(
                    Icons.refresh,
                    color: AppColors.textSecondary,
                  ),
                  tooltip: 'Actualizar lista',
                ),
              ],
            ),
            const SizedBox(height: 12),

            // GRID DE SURTIDORES
            if (_surtidores.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Text(
                  'No hay surtidores registrados en la base de datos.',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              )
            else
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 280,
                  mainAxisExtent: 110,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: _surtidores.length,
                itemBuilder: (context, index) {
                  final s = _surtidores[index];
                  final String estado = (s['estado'] ?? 'funcionando')
                      .toString();
                  final bool estaOk = _esEstadoActivo(estado);

                  return Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Surtidor #${s['numero_surtidor'] ?? s['numero'] ?? ''}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            Icon(
                              Icons.circle,
                              size: 8,
                              color: estaOk ? emeraldColor : dangerColor,
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Combustible: ${s['tipo_combustible'] ?? 'G. Especial'}',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'ESTADO: ${estado.toUpperCase()}',
                          style: TextStyle(
                            color: estaOk ? emeraldColor : dangerColor,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
