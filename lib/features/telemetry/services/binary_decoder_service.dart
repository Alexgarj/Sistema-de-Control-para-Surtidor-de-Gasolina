/// Clase que representa los datos decodificados de una trama binaria/hexadecimal de un surtidor.
class ReporteVentaBinario {
  final int idSurtidor;
  final int
  tipoCombustibleCode; // 00: Especial, 01: Premium, 10: Diesel, 11: GNV
  final double litrosDespachados;
  final double totalBs;
  final bool errorSensorFlujo;
  final bool fugaDetectada;

  ReporteVentaBinario({
    required this.idSurtidor,
    required this.tipoCombustibleCode,
    required this.litrosDespachados,
    required this.totalBs,
    required this.errorSensorFlujo,
    required this.fugaDetectada,
  });

  String get nombreCombustible {
    switch (tipoCombustibleCode) {
      case 0:
        return 'Gasolina Especial';
      case 1:
        return 'Gasolina Premium';
      case 2:
        return 'Diesel Olíptico';
      case 3:
        return 'GNV';
      default:
        return 'Desconocido';
    }
  }
}

class BinaryDecoderService {
  /// Decodifica una trama de 32 bits (4 bytes) recibida del hardware del surtidor.
  ///
  /// Estructura de la trama de 32 bits:
  /// - Bits 31..28 (4 bits): ID del surtidor (0 - 15)
  /// - Bits 27..26 (2 bits): Código de Combustible (00..11)
  /// - Bits 25..12 (14 bits): Volumen en décimas de litro (Ej: 154 = 15.4 L)
  /// - Bits 11..2  (10 bits): Precio total en Bs (entero)
  /// - Bit 1       (1 bit) : Alerta sensor de flujo (1 = Error, 0 = OK)
  /// - Bit 0       (1 bit) : Alerta de fuga (1 = Fuga, 0 = OK)
  static ReporteVentaBinario decodificarTrama(int rawFrame32Bit) {
    // 1. Extraer ID del surtidor: Desplazar 28 bits a la derecha y aplicar máscara 0xF (4 bits)
    final int idSurtidor = (rawFrame32Bit >> 28) & 0x0F;

    // 2. Extraer tipo de combustible: Desplazar 26 bits y aplicar máscara 0x03 (2 bits)
    final int tipoCombustible = (rawFrame32Bit >> 26) & 0x03;

    // 3. Extraer volumen: Desplazar 12 bits y aplicar máscara 0x3FFF (14 bits)
    final int decimasLitros = (rawFrame32Bit >> 12) & 0x3FFF;
    final double litros = decimasLitros / 10.0;

    // 4. Extraer total Bs: Desplazar 2 bits y aplicar máscara 0x03FF (10 bits)
    final int totalBs = (rawFrame32Bit >> 2) & 0x03FF;

    // 5. Extraer banderas de error (Bitwise AND)
    final bool errorSensor = ((rawFrame32Bit >> 1) & 0x01) == 1;
    final bool fuga = (rawFrame32Bit & 0x01) == 1;

    return ReporteVentaBinario(
      idSurtidor: idSurtidor,
      tipoCombustibleCode: tipoCombustible,
      litrosDespachados: litros,
      totalBs: totalBs.toDouble(),
      errorSensorFlujo: errorSensor,
      fugaDetectada: fuga,
    );
  }

  /// Genera una trama binaria de prueba simulando el firmware del surtidor.
  static int generarTramaSimulada({
    required int idSurtidor,
    required int tipoCombustible,
    required double litros,
    required double totalBs,
    bool errorSensor = false,
    bool fuga = false,
  }) {
    final int decimasLitros = (litros * 10).toInt() & 0x3FFF;
    final int totalBsInt = totalBs.toInt() & 0x03FF;
    final int flagSensor = errorSensor ? 1 : 0;
    final int flagFuga = fuga ? 1 : 0;

    int frame = 0;
    frame |= (idSurtidor & 0x0F) << 28;
    frame |= (tipoCombustible & 0x03) << 26;
    frame |= decimasLitros << 12;
    frame |= totalBsInt << 2;
    frame |= flagSensor << 1;
    frame |= flagFuga;

    return frame;
  }
}
