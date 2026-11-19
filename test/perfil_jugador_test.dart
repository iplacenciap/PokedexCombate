import 'package:flutter_test/flutter_test.dart';
import 'package:proyecto_pokedex/datos/estadisticas_memorice.dart';
import 'package:proyecto_pokedex/datos/estadisticas_pokeguesser.dart';
import 'package:proyecto_pokedex/datos/perfil_jugador.dart';
import 'package:proyecto_pokedex/datos/progreso_jugador.dart';

void main() {
  group('PerfilJugador', () {
    test('inicia con valores predeterminados', () {
      final perfil = PerfilJugador();

      expect(perfil.nombreUsuario, 'Entrenador');
      expect(perfil.tituloSeleccionado, 'Entrenador Pokémon');
      expect(perfil.saldoMonedas, 0);

      expect(perfil.progreso.pokeGuesser.partidasJugadas, 0);
      expect(perfil.progreso.memorice.sesionesJugadas, 0);
    });

    test('permite cambiar el nombre del jugador', () {
      final perfil = PerfilJugador();

      final resultado = perfil.cambiarNombre('Nacho');

      expect(resultado, true);
      expect(perfil.nombreUsuario, 'Nacho');
    });

    test('elimina espacios innecesarios al cambiar el nombre', () {
      final perfil = PerfilJugador();

      final resultado = perfil.cambiarNombre('  Nacho  ');

      expect(resultado, true);
      expect(perfil.nombreUsuario, 'Nacho');
    });

    test('rechaza un nombre vacío', () {
      final perfil = PerfilJugador();

      final resultado = perfil.cambiarNombre('   ');

      expect(resultado, false);
      expect(perfil.nombreUsuario, 'Entrenador');
    });

    test('permite cambiar el título seleccionado', () {
      final perfil = PerfilJugador();

      perfil.cambiarTitulo('Maestro Pokémon');

      expect(perfil.tituloSeleccionado, 'Maestro Pokémon');
    });

    test('se reconstruye correctamente desde datos serializados', () {
      final perfilOriginal = PerfilJugador(
        nombreUsuario: 'Nacho',
        tituloSeleccionado: 'Entrenador Pokémon',
        progreso: ProgresoJugador(
          pokeGuesser: EstadisticasPokeGuesser(
            partidasJugadas: 10,
            victorias: 6,
            derrotas: 4,
          ),
          memorice: EstadisticasMemorice(
            sesionesJugadas: 5,
            victorias: 3,
            derrotas: 2,
          ),
        ),
        saldoMonedas: 200,
      );

      final datos = perfilOriginal.toJson();
      final perfilReconstruido = PerfilJugador.fromJson(datos);

      expect(perfilReconstruido.nombreUsuario, 'Nacho');
      expect(perfilReconstruido.tituloSeleccionado, 'Entrenador Pokémon');
      expect(perfilReconstruido.saldoMonedas, 200);

      expect(perfilReconstruido.progreso.pokeGuesser.partidasJugadas, 10);
      expect(perfilReconstruido.progreso.pokeGuesser.victorias, 6);
      expect(perfilReconstruido.progreso.pokeGuesser.derrotas, 4);

      expect(perfilReconstruido.progreso.memorice.sesionesJugadas, 5);
      expect(perfilReconstruido.progreso.memorice.victorias, 3);
      expect(perfilReconstruido.progreso.memorice.derrotas, 2);
    });

    test("suma cantidad de monedas positiva", () {
      final perfil = PerfilJugador(saldoMonedas: 200);

      perfil.sumarSaldoMonedas(140);

      expect(perfil.saldoMonedas, 340);
    });

    test("no suma cantidad de monedas negativa", () {
      final perfil = PerfilJugador(saldoMonedas: 200);

      perfil.sumarSaldoMonedas(-40);

      expect(perfil.saldoMonedas, 200);
    });

    test("resta monedas si hay saldo suficiente", () {
      final perfil = PerfilJugador(saldoMonedas: 500);

      final resultado = perfil.restarSaldoMonedas(400);

      expect(resultado, true);
      expect(perfil.saldoMonedas, 100);
    });

    test("no resta monedas si hay saldo insuficiente", () {
      final perfil = PerfilJugador(saldoMonedas: 300);

      final resultado = perfil.restarSaldoMonedas(400);

      expect(resultado, false);
      expect(perfil.saldoMonedas, 300);
    });

    test("no resta cantidad de monedas no positiva", () {
      final perfil = PerfilJugador(saldoMonedas: 600);

      final resultado = perfil.restarSaldoMonedas(-400);

      expect(resultado, false);
      expect(perfil.saldoMonedas, 600);
    });
  });
}
