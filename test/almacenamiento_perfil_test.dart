import 'package:flutter_test/flutter_test.dart';
import 'package:proyecto_pokedex/datos/almacenamiento_perfil.dart';
import 'package:proyecto_pokedex/datos/estadisticas_memorice.dart';
import 'package:proyecto_pokedex/datos/estadisticas_pokeguesser.dart';
import 'package:proyecto_pokedex/datos/perfil_jugador.dart';
import 'package:proyecto_pokedex/datos/progreso_jugador.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('AlmacenamientoPerfil', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('crea un perfil inicial cuando no existen datos guardados', () async {
      final almacenamiento = AlmacenamientoPerfil();

      final perfil = await almacenamiento.cargarPerfil();

      expect(perfil.nombreUsuario, 'Entrenador');
      expect(perfil.tituloSeleccionado, 'Entrenador Pokémon');

      expect(perfil.progreso.pokeGuesser.partidasJugadas, 0);
      expect(perfil.progreso.pokeGuesser.victorias, 0);
      expect(perfil.progreso.pokeGuesser.derrotas, 0);

      expect(perfil.progreso.memorice.sesionesJugadas, 0);
      expect(perfil.progreso.memorice.victorias, 0);
      expect(perfil.progreso.memorice.derrotas, 0);

      expect(perfil.saldoMonedas, 0);
    });

    test('guarda y recupera el perfil completo del jugador', () async {
      final almacenamiento = AlmacenamientoPerfil();

      final perfil = PerfilJugador(
        nombreUsuario: 'Nacho',
        tituloSeleccionado: 'Maestro Pokémon',
        progreso: ProgresoJugador(
          pokeGuesser: EstadisticasPokeGuesser(
            partidasJugadas: 10,
            victorias: 6,
            derrotas: 4,
          ),
          memorice: EstadisticasMemorice(
            sesionesJugadas: 8,
            victorias: 5,
            derrotas: 3,
          ),
        ),
        saldoMonedas: 200,
      );

      await almacenamiento.guardarPerfil(perfil);

      final perfilCargado = await almacenamiento.cargarPerfil();

      expect(perfilCargado.nombreUsuario, 'Nacho');
      expect(perfilCargado.tituloSeleccionado, 'Maestro Pokémon');

      expect(perfilCargado.progreso.pokeGuesser.partidasJugadas, 10);
      expect(perfilCargado.progreso.pokeGuesser.victorias, 6);
      expect(perfilCargado.progreso.pokeGuesser.derrotas, 4);

      expect(perfilCargado.progreso.memorice.sesionesJugadas, 8);
      expect(perfilCargado.progreso.memorice.victorias, 5);
      expect(perfilCargado.progreso.memorice.derrotas, 3);

      expect(perfilCargado.saldoMonedas, 200);
    });

    test('reemplaza los datos anteriores al guardar nuevamente', () async {
      final almacenamiento = AlmacenamientoPerfil();

      final primerPerfil = PerfilJugador(
        nombreUsuario: 'Nacho',
        tituloSeleccionado: 'Entrenador Pokémon',
      );

      await almacenamiento.guardarPerfil(primerPerfil);

      final segundoPerfil = PerfilJugador(
        nombreUsuario: 'Red',
        tituloSeleccionado: 'Maestro Pokémon',
      );

      await almacenamiento.guardarPerfil(segundoPerfil);

      final perfilCargado = await almacenamiento.cargarPerfil();

      expect(perfilCargado.nombreUsuario, 'Red');
      expect(perfilCargado.tituloSeleccionado, 'Maestro Pokémon');
    });
  });
}
