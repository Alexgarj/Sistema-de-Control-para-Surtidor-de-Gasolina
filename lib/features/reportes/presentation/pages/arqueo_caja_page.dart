import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/app_colors.dart';

class ArqueoCajaPage extends StatefulWidget {
  const ArqueoCajaPage({super.key});

  @override
  State<ArqueoCajaPage> createState() => _ArqueoCajaPageState();
}

class _ArqueoCajaPageState extends State<ArqueoCajaPage> {
  final _supabase = Supabase.instance.client;
  bool _isLoading = true;

  List<Map<String, dynamic>> _ventasDelDia = [];
  double _totalEfectivo = 0.0;
  double _totalQR = 0.0;
  double _montoTotalArqueo = 0.0;

  @override
  void initState() {
    super.initState();
    _cargarDatosArqueo();
  }

  Future<void> _cargarDatosArqueo() async {
    setState(() => _isLoading = true);

    try {
      // 1. Obtener rango del día actual en tiempo LOCAL y convertir a UTC ISO String
      final now = DateTime.now();

      final inicioDiaLocal = DateTime(now.year, now.month, now.day, 0, 0, 0);
      final finDiaLocal = DateTime(
        now.year,
        now.month,
        now.day,
        23,
        59,
        59,
        999,
      );

      final inicioDiaIso = inicioDiaLocal.toUtc().toIso8601String();
      final finDiaIso = finDiaLocal.toUtc().toIso8601String();

      // 2. Consultar ventas registradas en el día
      final response = await _supabase
          .from('ventas')
          .select()
          .gte('created_at', inicioDiaIso)
          .lte('created_at', finDiaIso)
          .order('created_at', ascending: false);

      final List<Map<String, dynamic>> lista = List<Map<String, dynamic>>.from(
        response,
      );

      double efec = 0.0;
      double qr = 0.0;

      for (var v in lista) {
        // Tolerancia a diferentes nombres de columna en Supabase
        final num rawMonto =
            (v['monto_total'] ?? v['monto_bs'] ?? v['monto'] ?? 0);
        final double monto = rawMonto.toDouble();

        final String metodo = (v['metodo_pago'] ?? '').toString().toLowerCase();

        if (metodo.contains('efectivo')) {
          efec += monto;
        } else {
          qr += monto;
        }
      }

      setState(() {
        _ventasDelDia = lista;
        _totalEfectivo = efec;
        _totalQR = qr;
        _montoTotalArqueo = efec + qr;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar arqueo: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Reporte de Arqueo Diario'),
        backgroundColor: AppColors.surface,
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.refreshCw),
            onPressed: _cargarDatosArqueo,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // TARJETAS DE RESUMEN DEL ARQUEO
                  Row(
                    children: [
                      _buildResumenCard(
                        'Total Efectivo',
                        'Bs. ${_totalEfectivo.toStringAsFixed(2)}',
                        Colors.green,
                      ),
                      const SizedBox(width: 12),
                      _buildResumenCard(
                        'Total QR',
                        'Bs. ${_totalQR.toStringAsFixed(2)}',
                        Colors.blue,
                      ),
                      const SizedBox(width: 12),
                      _buildResumenCard(
                        'Monto Total',
                        'Bs. ${_montoTotalArqueo.toStringAsFixed(2)}',
                        Colors.amber,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  const Text(
                    'DETALLE DE COMPRAS / VENTAS REGISTRADAS',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      letterSpacing: 1.1,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // LISTA DETALLADA
                  Expanded(
                    child: _ventasDelDia.isEmpty
                        ? const Center(
                            child: Text(
                              'No hay transacciones registradas hoy.',
                              style: TextStyle(color: Colors.white54),
                            ),
                          )
                        : ListView.separated(
                            itemCount: _ventasDelDia.length,
                            separatorBuilder: (_, __) =>
                                const Divider(color: AppColors.cardBorder),
                            itemBuilder: (context, index) {
                              final item = _ventasDelDia[index];
                              final num rawMonto =
                                  (item['monto_total'] ??
                                  item['monto_bs'] ??
                                  item['monto'] ??
                                  0.0);
                              final double monto = rawMonto.toDouble();

                              final String metodoPago =
                                  (item['metodo_pago'] ?? '').toString();
                              final bool esQR = metodoPago
                                  .toLowerCase()
                                  .contains('qr');

                              // Formateo de Hora Local
                              String hora = '--:--';
                              if (item['created_at'] != null) {
                                try {
                                  final dt = DateTime.parse(
                                    item['created_at'],
                                  ).toLocal();
                                  hora =
                                      "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
                                } catch (_) {}
                              }

                              final String surtidor =
                                  item['surtidor_id'] != null
                                  ? '#${item['surtidor_id']}'
                                  : (item['numero_surtidor'] != null
                                        ? '#${item['numero_surtidor']}'
                                        : 'N/A');

                              return Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      backgroundColor: esQR
                                          ? Colors.blue.withOpacity(0.2)
                                          : Colors.green.withOpacity(0.2),
                                      child: Icon(
                                        esQR
                                            ? LucideIcons.qrCode
                                            : LucideIcons.banknote,
                                        color: esQR
                                            ? Colors.blue
                                            : Colors.green,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Surtidor $surtidor — ${item['tipo_combustible'] ?? 'Combustible'}',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Placa: ${item['placa'] ?? 'Sin Placa'} | Litros: ${item['litros'] ?? 0} Lts. | Hora: $hora',
                                            style: const TextStyle(
                                              color: AppColors.textSecondary,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      'Bs. ${monto.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildResumenCard(String title, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
