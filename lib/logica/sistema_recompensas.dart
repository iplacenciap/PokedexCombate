import 'package:proyecto_pokedex/logica/enums/dificultad_memorice.dart';

class SistemaRecompensas {
  static int recompensaPokeguesser({
    required bool victoria,
    required int intentosIncorrectos,
  }) {
    const int recompensaPorVictoria = 1600;
    const int descuentoRecompensa = 200;

    if (!victoria || intentosIncorrectos > 6 || intentosIncorrectos < 0) {
      return 200;
    } else {
      return recompensaPorVictoria -
          (intentosIncorrectos * descuentoRecompensa);
    }
  }

  static int recompensaMemorice({
    required bool victoria,
    required int intentosIncorrectos,
    required DificultadMemorice dificultad,
  }) {
    int recompensaPorVictoria = dificultad.recompensa;
    const int descuentoRecompensa = 20;
    const int cantidadDescuentosMax = 10;

    if (!victoria || intentosIncorrectos < 0) {
      return 0;
    } else if (intentosIncorrectos > cantidadDescuentosMax) {
      return recompensaPorVictoria -
          (cantidadDescuentosMax * descuentoRecompensa);
    } else {
      return recompensaPorVictoria -
          (intentosIncorrectos * descuentoRecompensa);
    }
  }
}
