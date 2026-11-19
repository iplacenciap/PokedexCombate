import 'package:proyecto_pokedex/logica/enums/dificultad_memorice.dart';

/// Resultados y récord de combo de una dificultad concreta de Memorice.
class EstadisticasDificultadMemorice {
  int victorias;
  int derrotas;
  int mejorCombo;

  EstadisticasDificultadMemorice({
    this.victorias = 0,
    this.derrotas = 0,
    this.mejorCombo = 0,
  });

  void registrarResultado({required bool victoria, required int comboPartida}) {
    if (victoria) {
      victorias++;
    } else {
      derrotas++;
    }

    // El combo más alto se conserva aunque se haya perdido la sesión.
    if (comboPartida > mejorCombo) {
      mejorCombo = comboPartida;
    }
  }

  Map<String, dynamic> toJson() => {
    'victorias': victorias,
    'derrotas': derrotas,
    'mejorCombo': mejorCombo,
  };

  factory EstadisticasDificultadMemorice.fromJson(Map<String, dynamic> json) {
    return EstadisticasDificultadMemorice(
      victorias: json['victorias'] ?? 0,
      derrotas: json['derrotas'] ?? 0,
      mejorCombo: json['mejorCombo'] ?? 0,
    );
  }
}

class EstadisticasMemorice {
  // Totales existentes: incluyen también las sesiones guardadas antes de esta task.
  int sesionesJugadas;
  int victorias;
  int derrotas;

  // Solo las sesiones que entregaron su dificultad se contabilizan aquí.
  final Map<DificultadMemorice, EstadisticasDificultadMemorice> porDificultad;

  EstadisticasMemorice({
    this.sesionesJugadas = 0,
    this.victorias = 0,
    this.derrotas = 0,
    Map<DificultadMemorice, EstadisticasDificultadMemorice>? porDificultad,
  }) : porDificultad = {
         for (final dificultad in DificultadMemorice.values)
           dificultad:
               porDificultad?[dificultad] ?? EstadisticasDificultadMemorice(),
       };

  EstadisticasDificultadMemorice obtenerPorDificultad(
    DificultadMemorice dificultad,
  ) => porDificultad[dificultad]!;

  void registrarSesion({
    required bool victoria,
    DificultadMemorice? dificultad,
    int mejorCombo = 0,
  }) {
    sesionesJugadas++;

    if (victoria) {
      victorias++;
    } else {
      derrotas++;
    }

    // Mantiene compatibilidad con llamadas antiguas sin dificultad.
    // Nunca se atribuyen sesiones antiguas a una dificultad inventada.
    if (dificultad != null) {
      obtenerPorDificultad(dificultad)
          .registrarResultado(victoria: victoria, comboPartida: mejorCombo);
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'sesionesJugadas': sesionesJugadas,
      'victorias': victorias,
      'derrotas': derrotas,
      'porDificultad': {
        for (final dificultad in DificultadMemorice.values)
          dificultad.name: obtenerPorDificultad(dificultad).toJson(),
      },
    };
  }

  factory EstadisticasMemorice.fromJson(Map<String, dynamic> json) {
    final datosDificultades = json['porDificultad'];
    final Map<String, dynamic> registros = datosDificultades is Map
        ? Map<String, dynamic>.from(datosDificultades)
        : <String, dynamic>{};

    return EstadisticasMemorice(
      sesionesJugadas: json['sesionesJugadas'] ?? 0,
      victorias: json['victorias'] ?? 0,
      derrotas: json['derrotas'] ?? 0,
      porDificultad: {
        for (final dificultad in DificultadMemorice.values)
          dificultad: registros[dificultad.name] is Map
              ? EstadisticasDificultadMemorice.fromJson(
                  Map<String, dynamic>.from(registros[dificultad.name] as Map),
                )
              : EstadisticasDificultadMemorice(),
      },
    );
  }
}
