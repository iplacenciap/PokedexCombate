import 'package:flutter_test/flutter_test.dart';
import 'package:proyecto_pokedex/datos/almacenamiento_perfil.dart';
import 'package:proyecto_pokedex/datos/perfil_jugador.dart';
import 'package:proyecto_pokedex/logica/enums/dificultad_memorice.dart';
import 'package:proyecto_pokedex/logica/gestor_progreso.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('GestorProgreso', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('registra y guarda una victoria de PokeGuesser', () async {
      final perfil = PerfilJugador();
      final gestor = GestorProgreso(perfil: perfil);
      bool victoria = true;
      await gestor.registrarResultadoPokeGuesser(victoria: victoria, recompensa: 1600);

      expect(perfil.saldoMonedas, 1600);

      expect(perfil.progreso.pokeGuesser.partidasJugadas, 1);
      expect(perfil.progreso.pokeGuesser.victorias, 1);
      expect(perfil.progreso.pokeGuesser.derrotas, 0);

      final perfilGuardado = await AlmacenamientoPerfil().cargarPerfil();

      expect(perfilGuardado.saldoMonedas, 1600);

      expect(perfilGuardado.progreso.pokeGuesser.partidasJugadas, 1);
      expect(perfilGuardado.progreso.pokeGuesser.victorias, 1);
      expect(perfilGuardado.progreso.pokeGuesser.derrotas, 0);
    });

    test('registra y guarda una derrota de PokeGuesser', () async {
      final perfil = PerfilJugador();
      final gestor = GestorProgreso(perfil: perfil);
      bool victoria = false;
      await gestor.registrarResultadoPokeGuesser(victoria: victoria, recompensa: 200);

      expect(perfil.saldoMonedas, 200);

      expect(perfil.progreso.pokeGuesser.partidasJugadas, 1);
      expect(perfil.progreso.pokeGuesser.victorias, 0);
      expect(perfil.progreso.pokeGuesser.derrotas, 1);

      final perfilGuardado = await AlmacenamientoPerfil().cargarPerfil();

      expect(perfilGuardado.saldoMonedas, 200);

      expect(perfilGuardado.progreso.pokeGuesser.partidasJugadas, 1);
      expect(perfilGuardado.progreso.pokeGuesser.victorias, 0);
      expect(perfilGuardado.progreso.pokeGuesser.derrotas, 1);
    });

    test(
      'registra y guarda una victoria de Memorice con dificultad y récord',
      () async {
        final perfil = PerfilJugador(nombreUsuario: 'nacho');
        final gestor = GestorProgreso(perfil: perfil);

        await gestor.registrarSesionMemorice(
          victoria: true,
          recompensa: 400,
          dificultad: DificultadMemorice.normal,
          mejorCombo: 7,
        );

        expect(perfil.saldoMonedas, 400);

        expect(perfil.progreso.memorice.sesionesJugadas, 1);
        expect(perfil.progreso.memorice.victorias, 1);
        expect(perfil.progreso.memorice.derrotas, 0);

        final perfilGuardado = await AlmacenamientoPerfil().cargarPerfil();
        final datos = perfilGuardado.progreso.memorice.obtenerPorDificultad(
          DificultadMemorice.normal,
        );

        expect(perfilGuardado.nombreUsuario, 'nacho');
        expect(perfilGuardado.progreso.memorice.sesionesJugadas, 1);
        expect(perfilGuardado.saldoMonedas, 400);
        expect(datos.victorias, 1);
        expect(datos.derrotas, 0);
        expect(datos.mejorCombo, 7);
      },
    );

    test('registra y guarda una derrota y conserva la mejor racha', () async {
      final perfil = PerfilJugador();
      final gestor = GestorProgreso(perfil: perfil);

      await gestor.registrarSesionMemorice(
        victoria: false,
        recompensa: 0,
        dificultad: DificultadMemorice.dificil,
        mejorCombo: 6,
      );

      await gestor.registrarSesionMemorice(
        victoria: true,
        recompensa: 400,
        dificultad: DificultadMemorice.dificil,
        mejorCombo: 2,
      );

      final perfilGuardado = await AlmacenamientoPerfil().cargarPerfil();
      final datos = perfilGuardado.progreso.memorice.obtenerPorDificultad(
        DificultadMemorice.dificil,
      );

      expect(perfilGuardado.saldoMonedas, 400);

      expect(perfilGuardado.progreso.memorice.sesionesJugadas, 2);
      expect(perfilGuardado.progreso.memorice.victorias, 1);
      expect(perfilGuardado.progreso.memorice.derrotas, 1);
      expect(datos.victorias, 1);
      expect(datos.derrotas, 1);
      expect(datos.mejorCombo, 6);
    });

    test('registra y guarda una derrota de Memorice', () async {
      final perfil = PerfilJugador();
      final gestor = GestorProgreso(perfil: perfil);

      await gestor.registrarSesionMemorice(victoria: false, recompensa: 0);

      expect(perfil.saldoMonedas, 0);

      expect(perfil.progreso.memorice.sesionesJugadas, 1);
      expect(perfil.progreso.memorice.victorias, 0);
      expect(perfil.progreso.memorice.derrotas, 1);

      final perfilGuardado = await AlmacenamientoPerfil().cargarPerfil();

      expect(perfil.saldoMonedas, 0);
      expect(perfilGuardado.saldoMonedas, 0);

      expect(perfilGuardado.progreso.memorice.sesionesJugadas, 1);
      expect(perfilGuardado.progreso.memorice.victorias, 0);
      expect(perfilGuardado.progreso.memorice.derrotas, 1);
    });
    test("cobra y guarda pokemonedas cuando el saldo es suficiente", () async {
      final perfil = PerfilJugador(saldoMonedas: 600);
      final gestor = GestorProgreso(perfil: perfil);

      final cobrado = await gestor.gastarPokemonedas(400);

      expect(cobrado, true);
      expect(perfil.saldoMonedas,200);

      final perfilGuardado = await AlmacenamientoPerfil().cargarPerfil();
      expect(perfilGuardado.saldoMonedas, 200); 
    });

    test("no cobra pokemonedas cuando el saldo es insuficiente", () async {
      final perfil = PerfilJugador(saldoMonedas: 300);
      final almacenamiento = AlmacenamientoPerfil();
      await almacenamiento.guardarPerfil(perfil);

      final gestor = GestorProgreso(perfil: perfil, almacenamiento: almacenamiento);

      final cobrado = await gestor.gastarPokemonedas(400);

      expect(cobrado, false);
      expect(perfil.saldoMonedas,300);

      final perfilGuardado = await AlmacenamientoPerfil().cargarPerfil();
      expect(perfilGuardado.saldoMonedas, 300); 
    });

    test('las dificultades no se mezclan al guardar y cargar', () async {
      final gestor = GestorProgreso(perfil: PerfilJugador());
      await gestor.registrarSesionMemorice(
        victoria: true,
        recompensa: 400,
        dificultad: DificultadMemorice.facil,
        mejorCombo: 5,
      );
      await gestor.registrarSesionMemorice(
        victoria: false,
        recompensa: 0,
        dificultad: DificultadMemorice.extremo,
        mejorCombo: 9,
      );

      final perfilGuardado = await AlmacenamientoPerfil().cargarPerfil();
      final memorice = perfilGuardado.progreso.memorice;
      expect(memorice.sesionesJugadas, 2);
      expect(
        memorice.obtenerPorDificultad(DificultadMemorice.facil).victorias,
        1,
      );
      expect(
        memorice.obtenerPorDificultad(DificultadMemorice.facil).derrotas,
        0,
      );
      expect(
        memorice.obtenerPorDificultad(DificultadMemorice.facil).mejorCombo,
        5,
      );
      expect(
        memorice.obtenerPorDificultad(DificultadMemorice.extremo).victorias,
        0,
      );
      expect(
        memorice.obtenerPorDificultad(DificultadMemorice.extremo).derrotas,
        1,
      );
      expect(
        memorice.obtenerPorDificultad(DificultadMemorice.extremo).mejorCombo,
        9,
      );
    });

    test('mantiene el método original sin dificultad para llamadas anteriores', () async {
        final gestor = GestorProgreso(perfil: PerfilJugador());
        await gestor.registrarSesionMemorice(victoria: true, recompensa: 0);
        final perfilGuardado = await AlmacenamientoPerfil().cargarPerfil();
        expect(perfilGuardado.progreso.memorice.sesionesJugadas, 1);
        expect(perfilGuardado.progreso.memorice.victorias, 1);
        expect(
          perfilGuardado.progreso.memorice
              .obtenerPorDificultad(DificultadMemorice.facil)
              .victorias,
          0,
        );
      },
    );

    test("reembolsa y guarda Pokemonedas", () async{
      final perfil = PerfilJugador(saldoMonedas: 100);
      final almacenamiento = AlmacenamientoPerfil();
      final gestor = GestorProgreso(perfil: perfil, almacenamiento: almacenamiento);

      await gestor.reembolsarPokemonedas(200);

      expect(perfil.saldoMonedas, 300);
      expect((await almacenamiento.cargarPerfil()).saldoMonedas, 300);
    });

    test("revielte el saldo si falla el guardado del reembolso", () async{
      final perfil = PerfilJugador(saldoMonedas: 100);
      final gestor = GestorProgreso(perfil: perfil, almacenamiento: _AlmacenamientoQueFalla());

      await expectLater(gestor.reembolsarPokemonedas(200), throwsStateError);

      expect(perfil.saldoMonedas, 100);
    });
  });
}

class _AlmacenamientoQueFalla extends AlmacenamientoPerfil{
  @override
  Future<void> guardarPerfil(PerfilJugador perfil){
    throw StateError("Fallo de prueba al guardar");
  }
}
