import 'package:flutter_test/flutter_test.dart';
import 'package:proyecto_pokedex/datos/estadisticas_memorice.dart';
import 'package:proyecto_pokedex/datos/estadisticas_pokeguesser.dart';
import 'package:proyecto_pokedex/datos/progreso_jugador.dart';

void main() {
  group('ProgresoJugador', () {
    test('inicia con estadísticas vacías', () {
      final progreso = ProgresoJugador();

      expect(progreso.pokeGuesser.partidasJugadas, 0);
      expect(progreso.pokeGuesser.victorias, 0);
      expect(progreso.pokeGuesser.derrotas, 0);

      expect(progreso.memorice.sesionesJugadas, 0);
      expect(progreso.memorice.victorias, 0);
      expect(progreso.memorice.derrotas, 0);
    });

    test('permite utilizar estadísticas existentes', () {
      final pokeGuesser = EstadisticasPokeGuesser(
        partidasJugadas: 10,
        victorias: 6,
        derrotas: 4,
      );

      final memorice = EstadisticasMemorice(
        sesionesJugadas: 8,
        victorias: 5,
        derrotas: 3,
      );

      final progreso = ProgresoJugador(
        pokeGuesser: pokeGuesser,
        memorice: memorice,
      );

      expect(progreso.pokeGuesser.partidasJugadas, 10);
      expect(progreso.pokeGuesser.victorias, 6);
      expect(progreso.pokeGuesser.derrotas, 4);

      expect(progreso.memorice.sesionesJugadas, 8);
      expect(progreso.memorice.victorias, 5);
      expect(progreso.memorice.derrotas, 3);
    });

    test('se reconstruye correctamente desde datos serializados', () {
      final progreso = ProgresoJugador.fromJson({
        'pokeGuesser': {'partidasJugadas': 12, 'victorias': 7, 'derrotas': 5},
        'memorice': {'sesionesJugadas': 9, 'victorias': 4, 'derrotas': 5},
      });

      expect(progreso.pokeGuesser.partidasJugadas, 12);
      expect(progreso.pokeGuesser.victorias, 7);
      expect(progreso.pokeGuesser.derrotas, 5);

      expect(progreso.memorice.sesionesJugadas, 9);
      expect(progreso.memorice.victorias, 4);
      expect(progreso.memorice.derrotas, 5);
    });
  });
}
