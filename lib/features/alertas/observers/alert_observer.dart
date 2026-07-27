import 'package:flutter/foundation.dart';

// Interfaz para los observadores (Suscriptores)
abstract class SurtidorObserver {
  void onNivelCriticoDetectado(
    int numeroSurtidor,
    String combustible,
    double nivelPorcentaje,
  );
}

// Sujeto observado (Publisher)
class TanqueMonitorSubject {
  final List<SurtidorObserver> _observers = [];

  void agregarObservador(SurtidorObserver observer) {
    _observers.add(observer);
  }

  void removerObservador(SurtidorObserver observer) {
    _observers.remove(observer);
  }

  /// Evalúa la telemetría enviada por la BD o el hardware
  void evaluarNivelTanque({
    required int numeroSurtidor,
    required String combustible,
    required double nivelActual,
    required double capacidadTotal,
  }) {
    final porcentaje = (nivelActual / capacidadTotal);

    // Si el nivel es menor al 15%, notificar a todos los observadores registrados
    if (porcentaje <= 0.15) {
      for (var observer in _observers) {
        observer.onNivelCriticoDetectado(
          numeroSurtidor,
          combustible,
          porcentaje * 100,
        );
      }
    }
  }
}

// Implementación concreta de un observador que imprime/registra alertas
class ConsoleAlertObserver implements SurtidorObserver {
  @override
  void onNivelCriticoDetectado(
    int numeroSurtidor,
    String combustible,
    double nivelPorcentaje,
  ) {
    debugPrint(
      '⚠️ ALERTA CRÍTICA [Observer]: Surtidor #$numeroSurtidor ($combustible) al ${nivelPorcentaje.toStringAsFixed(1)}% de capacidad.',
    );
  }
}
