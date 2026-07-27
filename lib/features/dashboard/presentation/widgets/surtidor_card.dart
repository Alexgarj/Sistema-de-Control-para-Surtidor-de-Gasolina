import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class SurtidorCard extends StatelessWidget {
  final String id;
  final String
  tipoCombustible; // 'Especial', 'Premium', 'Diésel' o 'Gasolina Especial'
  final Color colorCombustible;
  final String
  estado; // 'Despachando', 'En espera', 'Mantenimiento', 'Fuera de servicio'
  final Color colorEstado;
  final double porcentajeTanque;
  final String litrosHoy;
  final String tiempo;

  const SurtidorCard({
    super.key,
    required this.id,
    required this.tipoCombustible,
    required this.colorCombustible,
    required this.estado,
    required this.colorEstado,
    required this.porcentajeTanque,
    required this.litrosHoy,
    required this.tiempo,
  });

  @override
  Widget build(BuildContext context) {
    // Evita el mensaje "#null" fallback
    final displayId = id.isEmpty || id == 'null' ? 'N/A' : id;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.circle, size: 10, color: colorEstado),
                  const SizedBox(width: 8),
                  Text(
                    'Surtidor #$displayId',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: colorEstado.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  estado,
                  style: TextStyle(
                    color: colorEstado,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: colorCombustible.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  tipoCombustible,
                  style: TextStyle(
                    color: colorCombustible,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Bs. 3.74/L',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
            ],
          ),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Tanque',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
              ),
              Text(
                '${(porcentajeTanque * 100).toInt()}%',
                style: TextStyle(
                  color: colorCombustible,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: porcentajeTanque.clamp(0.0, 1.0), // Evita desbordamientos
            backgroundColor: AppColors.background,
            valueColor: AlwaysStoppedAnimation<Color>(colorCombustible),
            minHeight: 6,
            borderRadius: BorderRadius.circular(3),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$litrosHoy L\nhoy',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  height: 1.2,
                ),
              ),
              Text(
                tiempo,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
