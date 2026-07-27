import 'package:flutter/material.dart';

class AppColors {
  // Fondos y Contenedores
  static const Color background = Color(0xFF0F172A); // Fondo oscuro principal
  static const Color sidebar = Color(0xFF131C2E); // Fondo del sidebar
  static const Color surface = Color(
    0xFF1E293B,
  ); // Fondo de cards y contenedores
  static const Color surfaceLight = Color(0xFF334155); // Fondo secundario claro

  // Bordes
  static const Color cardBorder = Color(0xFF334155); // Bordes sutiles
  static const Color border = Color(
    0xFF334155,
  ); // <--- CORREGIDO: Ya no es null

  // Colores Principales
  static const Color primary = Color(0xFF0284C7); // Azul principal
  static const Color secondary = Color(0xFF38BDF8); // Cyan/Azul claro

  // Colores por Combustible
  static const Color especial = Color(0xFF0284C7); // Badge Especial (Azul)
  static const Color premium = Color(0xFFA855F7); // Badge Premium (Morado)
  static const Color diesel = Color(0xFFF59E0B);
  static const Color gnv = Color(0xFF00BCD4); // Badge GNV (Celeste)

  // Estados y Alertas
  static const Color success = Color(0xFF10B981); // Verde éxito
  static const Color emerald = Color(
    0xFF10B981,
  ); // <--- CORREGIDO: Alias de éxito
  static const Color warning = Color(0xFFF59E0B); // Mantenimiento / Nivel bajo
  static const Color danger = Color(0xFFEF4444); // Fuera de servicio / Alertas

  // Tipografía / Textos
  static const Color textPrimary = Color(
    0xFFFFFFFF,
  ); // <--- CORREGIDO: Blanco principal
  static const Color textSecondary = Color(0xFF94A3B8); // Gris secundario
  static const Color textMuted = Color(
    0xFF64748B,
  ); // <--- CORREGIDO: Gris apagado
}
