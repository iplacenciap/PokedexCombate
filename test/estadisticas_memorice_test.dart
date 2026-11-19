import 'package:flutter_test/flutter_test.dart';
import 'package:proyecto_pokedex/datos/estadisticas_memorice.dart';
import 'package:proyecto_pokedex/logica/enums/dificultad_memorice.dart';

void main() {
  group('EstadisticasMemorice', () {
    test('inicia sin sesiones ni estadísticas por dificultad', () {
      final estadisticas = EstadisticasMemorice();
      expect(estadisticas.sesionesJugadas, 0);
      expect(estadisticas.victorias, 0);
      expect(estadisticas.derrotas, 0);
      for (final dificultad in DificultadMemorice.values) {
        final datos = estadisticas.obtenerPorDificultad(dificultad);
        expect(datos.victorias, 0);
        expect(datos.derrotas, 0);
        expect(datos.mejorCombo, 0);
      }
    });

    test(
      'registra victoria, derrota y mejor combo en la dificultad correcta',
      () {
        final estadisticas = EstadisticasMemorice();

        estadisticas.registrarSesion(
          victoria: true,
          dificultad: DificultadMemorice.facil,
          mejorCombo: 4,
        );
        estadisticas.registrarSesion(
          victoria: false,
          dificultad: DificultadMemorice.facil,
          mejorCombo: 6,
        );
        estadisticas.registrarSesion(
          victoria: true,
          dificultad: DificultadMemorice.extremo,
          mejorCombo: 8,
        );

        expect(estadisticas.sesionesJugadas, 3);
        expect(estadisticas.victorias, 2);
        expect(estadisticas.derrotas, 1);

        final facil = estadisticas.obtenerPorDificultad(
          DificultadMemorice.facil,
        );
        expect(facil.victorias, 1);
        expect(facil.derrotas, 1);
        expect(facil.mejorCombo, 6); // Incluso tras una derrota.

        final extremo = estadisticas.obtenerPorDificultad(
          DificultadMemorice.extremo,
        );
        expect(extremo.victorias, 1);
        expect(extremo.derrotas, 0);
        expect(extremo.mejorCombo, 8);

        final normal = estadisticas.obtenerPorDificultad(
          DificultadMemorice.normal,
        );
        expect(normal.victorias, 0);
        expect(normal.mejorCombo, 0);
      },
    );

    test('una sesión con combo menor no reduce el récord previo', () {
      final estadisticas = EstadisticasMemorice();
      estadisticas.registrarSesion(
        victoria: true,
        dificultad: DificultadMemorice.dificil,
        mejorCombo: 9,
      );
      estadisticas.registrarSesion(
        victoria: false,
        dificultad: DificultadMemorice.dificil,
        mejorCombo: 3,
      );

      expect(
        estadisticas
            .obtenerPorDificultad(DificultadMemorice.dificil)
            .mejorCombo,
        9,
      );
    });

    test(
      'JSON conserva los récords y resultados de las cuatro dificultades',
      () {
        final estadisticas = EstadisticasMemorice();
        for (final dificultad in DificultadMemorice.values) {
          estadisticas.registrarSesion(
            victoria: dificultad != DificultadMemorice.extremo,
            dificultad: dificultad,
            mejorCombo: dificultad.pares - 1,
          );
        }

        final reconstruidas = EstadisticasMemorice.fromJson(
          estadisticas.toJson(),
        );
        expect(reconstruidas.sesionesJugadas, 4);
        expect(reconstruidas.victorias, 3);
        expect(reconstruidas.derrotas, 1);
        for (final dificultad in DificultadMemorice.values) {
          final antes = estadisticas.obtenerPorDificultad(dificultad);
          final despues = reconstruidas.obtenerPorDificultad(dificultad);
          expect(despues.victorias, antes.victorias);
          expect(despues.derrotas, antes.derrotas);
          expect(despues.mejorCombo, antes.mejorCombo);
        }
      },
    );

    test(
      'carga perfiles antiguos sin atribuir sus sesiones a dificultades',
      () {
        final estadisticas = EstadisticasMemorice.fromJson({
          'sesionesJugadas': 8,
          'victorias': 5,
          'derrotas': 3,
        });

        expect(estadisticas.sesionesJugadas, 8);
        expect(estadisticas.victorias, 5);
        expect(estadisticas.derrotas, 3);
        for (final dificultad in DificultadMemorice.values) {
          expect(estadisticas.obtenerPorDificultad(dificultad).victorias, 0);
          expect(estadisticas.obtenerPorDificultad(dificultad).derrotas, 0);
          expect(estadisticas.obtenerPorDificultad(dificultad).mejorCombo, 0);
        }

        estadisticas.registrarSesion(
          victoria: true,
          dificultad: DificultadMemorice.normal,
          mejorCombo: 7,
        );
        expect(estadisticas.sesionesJugadas, 9);
        expect(estadisticas.victorias, 6);
        expect(
          estadisticas
              .obtenerPorDificultad(DificultadMemorice.normal)
              .victorias,
          1,
        );
        expect(
          estadisticas
              .obtenerPorDificultad(DificultadMemorice.normal)
              .mejorCombo,
          7,
        );
      },
    );

    test('mantiene compatibilidad con llamadas antiguas sin dificultad', () {
      final estadisticas = EstadisticasMemorice();
      estadisticas.registrarSesion(victoria: true);
      estadisticas.registrarSesion(victoria: false);
      expect(estadisticas.sesionesJugadas, 2);
      expect(estadisticas.victorias, 1);
      expect(estadisticas.derrotas, 1);
      for (final dificultad in DificultadMemorice.values) {
        expect(estadisticas.obtenerPorDificultad(dificultad).victorias, 0);
        expect(estadisticas.obtenerPorDificultad(dificultad).derrotas, 0);
      }
    });
  });
}
