import 'package:flutter_test/flutter_test.dart';
import 'package:proyecto_pokedex/datos/estadisticas_pokeguesser.dart';

void main() {
  group('EstadisticasPokeGuesser', () {
    test('comienza con las estadísticas en cero', () {
      final estadisticas = EstadisticasPokeGuesser();

      expect(estadisticas.partidasJugadas, 0);
      expect(estadisticas.victorias, 0);
      expect(estadisticas.derrotas, 0);
    });

    test('registrar una victoria actualiza las estadísticas', () {
      final estadisticas = EstadisticasPokeGuesser();

      estadisticas.registrarVictoria();

      expect(estadisticas.partidasJugadas, 1);
      expect(estadisticas.victorias, 1);
      expect(estadisticas.derrotas, 0);
    });

    test('registrar una derrota actualiza las estadísticas', () {
      final estadisticas = EstadisticasPokeGuesser();

      estadisticas.registrarDerrota();

      expect(estadisticas.partidasJugadas, 1);
      expect(estadisticas.victorias, 0);
      expect(estadisticas.derrotas, 1);
    });
  });
}
