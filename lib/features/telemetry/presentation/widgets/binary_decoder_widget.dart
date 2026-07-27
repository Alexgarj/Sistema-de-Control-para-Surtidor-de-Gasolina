import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../services/binary_decoder_service.dart';

class BinaryDecoderWidget extends StatefulWidget {
  const BinaryDecoderWidget({super.key});

  @override
  State<BinaryDecoderWidget> createState() => _BinaryDecoderWidgetState();
}

class _BinaryDecoderWidgetState extends State<BinaryDecoderWidget> {
  late int _rawFrame;
  ReporteVentaBinario? _reporteDecodificado;

  @override
  void initState() {
    super.initState();
    _generarNuevaTrama();
  }

  void _generarNuevaTrama() {
    // Genera una trama con valores de ejemplo
    _rawFrame = BinaryDecoderService.generarTramaSimulada(
      idSurtidor: 3,
      tipoCombustible: 0, // Gasolina Especial
      litros: 45.5,
      totalBs: 170.0,
      errorSensor: false,
      fuga: false,
    );
    _decodificar();
  }

  void _decodificar() {
    setState(() {
      _reporteDecodificado = BinaryDecoderService.decodificarTrama(_rawFrame);
    });
  }

  @override
  Widget build(BuildContext context) {
    final binaryString = _rawFrame.toRadixString(2).padLeft(32, '0');
    final hexString =
        '0x${_rawFrame.toRadixString(16).toUpperCase().padLeft(8, '0')}';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(LucideIcons.binary, color: Color(0xFF0EA5E9)),
                  SizedBox(width: 10),
                  Text(
                    'Decodificador de Tramas RS-485 / Telemetría Binaria',
                    style: TextStyle(
                      color: Color(0xFFF8FAFC),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF334155),
                ),
                onPressed: _generarNuevaTrama,
                icon: const Icon(
                  LucideIcons.refreshCw,
                  size: 14,
                  color: Colors.white,
                ),
                label: const Text(
                  'Simular Trama',
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Trama Raw
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'HEX: $hexString',
                  style: const TextStyle(
                    color: Color(0xFF10B981),
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                SelectableText(
                  'BIN: ${binaryString.substring(0, 4)} ${binaryString.substring(4, 6)} ${binaryString.substring(6, 20)} ${binaryString.substring(20, 30)} ${binaryString.substring(30, 32)}',
                  style: const TextStyle(
                    color: Color(0xFF0EA5E9),
                    fontFamily: 'monospace',
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Datos Decodificados
          if (_reporteDecodificado != null)
            Wrap(
              spacing: 16,
              runSpacing: 12,
              children: [
                _buildInfoChip(
                  'Surtidor ID',
                  '#${_reporteDecodificado!.idSurtidor}',
                  LucideIcons.fuel,
                ),
                _buildInfoChip(
                  'Combustible',
                  _reporteDecodificado!.nombreCombustible,
                  LucideIcons.droplet,
                ),
                _buildInfoChip(
                  'Litros',
                  '${_reporteDecodificado!.litrosDespachados} L',
                  LucideIcons.gauge,
                ),
                _buildInfoChip(
                  'Total Bs.',
                  'Bs. ${_reporteDecodificado!.totalBs.toStringAsFixed(2)}',
                  LucideIcons.dollarSign,
                ),
                _buildStatusChip(
                  'Sensor Flujo',
                  _reporteDecodificado!.errorSensorFlujo,
                ),
                _buildStatusChip(
                  'Alerta Fuga',
                  _reporteDecodificado!.fugaDetectada,
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: const Color(0xFF0EA5E9)),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10),
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
        ],
      ),
    );
  }

  Widget _buildStatusChip(String label, bool isError) {
    final color = isError ? const Color(0xFFEF4444) : const Color(0xFF10B981);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isError ? LucideIcons.alertTriangle : LucideIcons.checkCircle,
            size: 16,
            color: color,
          ),
          const SizedBox(width: 8),
          Text(
            '$label: ${isError ? "ERROR" : "OK"}',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
