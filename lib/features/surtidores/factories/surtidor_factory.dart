import 'package:flutter/material.dart';

/// Enum de Tipos de Combustible estandarizados
enum TipoCombustible { especial, premium, diesel, gnv }

extension TipoCombustibleExtension on TipoCombustible {
  String get nombreFormateado {
    switch (this) {
      case TipoCombustible.especial:
        return 'Gasolina Especial';
      case TipoCombustible.premium:
        return 'Gasolina Premium';
      case TipoCombustible.diesel:
        return 'Diesel Olímpico'; // Corregido: 'Olipico' -> 'Diesel Olímpico'
      case TipoCombustible.gnv:
        return 'GNV';
    }
  }

  double get precioRegulado {
    switch (this) {
      case TipoCombustible.especial:
        return 3.74;
      case TipoCombustible.premium:
        return 4.79;
      case TipoCombustible.diesel:
        return 3.72;
      case TipoCombustible.gnv:
        return 1.66;
    }
  }
}

/// Enum para gestionar los estados oficiales del surtidor
enum EstadoSurtidor { despachando, enEspera, mantenimiento, fueraDeServicio }

extension EstadoSurtidorExtension on EstadoSurtidor {
  /// Representación en base de datos / UI
  String get valor {
    switch (this) {
      case EstadoSurtidor.despachando:
        return 'Despachando';
      case EstadoSurtidor.enEspera:
        return 'En espera';
      case EstadoSurtidor.mantenimiento:
        return 'Mantenimiento';
      case EstadoSurtidor.fueraDeServicio:
        return 'Fuera de servicio';
    }
  }

  /// Color semántico neutro/adecuado para no saturar la vista de tarjetas
  Color get color {
    switch (this) {
      case EstadoSurtidor.despachando:
        return const Color(0xFF10B981); // Verde esmeralda
      case EstadoSurtidor.enEspera:
        return const Color(0xFF3B82F6); // Azul neutro
      case EstadoSurtidor.mantenimiento:
        return const Color(0xFFF59E0B); // Ámbar/Naranja
      case EstadoSurtidor.fueraDeServicio:
        return const Color(0xFFEF4444); // Rojo
    }
  }

  static EstadoSurtidor desdeString(String str) {
    final normalizado = str.toLowerCase().replaceAll('_', ' ').trim();
    if (normalizado.contains('despach')) return EstadoSurtidor.despachando;
    if (normalizado.contains('manten')) return EstadoSurtidor.mantenimiento;
    if (normalizado.contains('fuera')) return EstadoSurtidor.fueraDeServicio;
    return EstadoSurtidor.enEspera;
  }
}

class SurtidorModel {
  final int? id;
  final int numeroSurtidor;
  final String tipoCombustible;
  final double capacidadTotalLitros;
  final double nivelActualLitros;
  final double precioPorLitro;
  final String estado;

  SurtidorModel({
    this.id,
    required this.numeroSurtidor,
    required this.tipoCombustible,
    required this.capacidadTotalLitros,
    required this.nivelActualLitros,
    required this.precioPorLitro,
    this.estado = 'En espera',
  });

  /// Crea una instancia desde un Map proviniente de Supabase
  factory SurtidorModel.fromMap(Map<String, dynamic> map) {
    return SurtidorModel(
      id: map['id'] as int?,
      numeroSurtidor: map['numero_surtidor'] ?? map['id'] ?? 0,
      tipoCombustible: map['tipo_combustible'] ?? 'Gasolina Especial',
      capacidadTotalLitros:
          (map['capacidad_total_litros'] as num?)?.toDouble() ?? 10000.0,
      nivelActualLitros:
          (map['nivel_actual_litros'] as num?)?.toDouble() ?? 0.0,
      precioPorLitro: (map['precio_por_litro'] as num?)?.toDouble() ?? 3.74,
      estado: map['estado'] ?? 'En espera',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'numero_surtidor': numeroSurtidor,
      'tipo_combustible': tipoCombustible,
      'capacidad_total_litros': capacidadTotalLitros,
      'nivel_actual_litros': nivelActualLitros,
      'precio_por_litro': precioPorLitro,
      'estado': estado,
    };
  }
}

class SurtidorFactory {
  /// Fabrica una instancia con la configuración reglamentaria según el tipo
  static SurtidorModel crearSurtidor({
    required int numeroSurtidor,
    required TipoCombustible tipo,
    double? nivelInicial,
    EstadoSurtidor estadoInicial = EstadoSurtidor.enEspera,
  }) {
    switch (tipo) {
      case TipoCombustible.especial:
        return SurtidorModel(
          numeroSurtidor: numeroSurtidor,
          tipoCombustible: tipo.nombreFormateado,
          capacidadTotalLitros: 10000.0,
          nivelActualLitros: nivelInicial ?? 10000.0,
          precioPorLitro: tipo.precioRegulado,
          estado: estadoInicial.valor,
        );

      case TipoCombustible.premium:
        return SurtidorModel(
          numeroSurtidor: numeroSurtidor,
          tipoCombustible: tipo.nombreFormateado,
          capacidadTotalLitros: 8000.0,
          nivelActualLitros: nivelInicial ?? 8000.0,
          precioPorLitro: tipo.precioRegulado,
          estado: estadoInicial.valor,
        );

      case TipoCombustible.diesel:
        return SurtidorModel(
          numeroSurtidor: numeroSurtidor,
          tipoCombustible: tipo.nombreFormateado,
          capacidadTotalLitros: 12000.0,
          nivelActualLitros: nivelInicial ?? 12000.0,
          precioPorLitro: tipo.precioRegulado,
          estado: estadoInicial.valor,
        );

      case TipoCombustible.gnv:
        return SurtidorModel(
          numeroSurtidor: numeroSurtidor,
          tipoCombustible: tipo.nombreFormateado,
          capacidadTotalLitros: 5000.0,
          nivelActualLitros: nivelInicial ?? 5000.0,
          precioPorLitro: tipo.precioRegulado,
          estado: estadoInicial.valor,
        );
    }
  }
}
