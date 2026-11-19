import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:proyecto_pokedex/api/pokedex_session_cache_service.dart';
import 'package:proyecto_pokedex/datos/almacenamiento_perfil.dart';
import 'package:proyecto_pokedex/datos/perfil_jugador.dart';
import 'package:proyecto_pokedex/datos/pokemon_resumen.dart';
import 'package:proyecto_pokedex/logica/enums/dificultad_memorice.dart';
import 'package:proyecto_pokedex/logica/gestor_progreso.dart';
import 'package:proyecto_pokedex/pantallas/pantalla_memorice.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('Memorice real registra una derrota en la dificultad jugada', (
    tester,
  ) async {
    final perfil = PerfilJugador();
    final gestor = GestorProgreso(perfil: perfil);
    final cache = PokemonSessionCacheService(
      fetchPokemonList: () async => List.generate(
        20,
        (i) => PokemonResumen(
          id: i + 1,
          nombre: 'POKEMON_$i',
          urlImagen: '',
          tipos: ['normal'],
          generacion: 1,
        ),
      ),
      preloadImage: (_) async {},
    );

    // No se inyecta PartidaMemorice: se usa su callback real desde PantallaMemorice.
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PantallaMemorice(
            cacheService: cache,
            gestorProgreso: gestor,
            imageBuilder: (pokemon) => Text(pokemon.nombre),
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('chip_dificultad_normal')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('btn_comenzar_memorice')));
    await tester.pump();
    await tester.pump();

    await tester.pump(
      Duration(seconds: DificultadMemorice.normal.segundosMemorizacion),
    );
    await tester.pump(
      Duration(seconds: DificultadMemorice.normal.segundosJuego),
    );
    await tester.pumpAndSettle();

    expect(find.text('¡Derrota!'), findsOneWidget);
    final guardado = await AlmacenamientoPerfil().cargarPerfil();
    final memorice = guardado.progreso.memorice;
    final normal = memorice.obtenerPorDificultad(DificultadMemorice.normal);
    final facil = memorice.obtenerPorDificultad(DificultadMemorice.facil);

    expect(memorice.sesionesJugadas, 1);
    expect(memorice.victorias, 0);
    expect(memorice.derrotas, 1);
    expect(normal.victorias, 0);
    expect(normal.derrotas, 1);
    expect(normal.mejorCombo, 0);
    expect(facil.derrotas, 0);

    // Volver al inicio no contabiliza la derrota una segunda vez.
    final botonInicio = find.byKey(const ValueKey('btn_fin_inicio'));

    // Confirmamos que el diálogo esté abierto.
    expect(find.byKey(const ValueKey('memorice_dialogo_fin')), findsOneWidget);

    // Desplazamos el diálogo hasta que el botón sea visible.
    await tester.ensureVisible(botonInicio);
    await tester.pumpAndSettle();

    // Comprobamos que realmente pueda recibir la pulsación.
    expect(botonInicio.hitTestable(), findsOneWidget);

    await tester.tap(botonInicio);
    await tester.pumpAndSettle();

    // Verificamos que el botón realmente cerró el diálogo
    // y devolvió el juego a la pantalla inicial.
    expect(find.byKey(const ValueKey('memorice_dialogo_fin')), findsNothing);
    expect(find.byKey(const ValueKey('btn_comenzar_memorice')), findsOneWidget);

    final guardadoDeNuevo = await AlmacenamientoPerfil().cargarPerfil();
    expect(guardadoDeNuevo.progreso.memorice.sesionesJugadas, 1);
    expect(
      guardadoDeNuevo.progreso.memorice
          .obtenerPorDificultad(DificultadMemorice.normal)
          .derrotas,
      1,
    );
  });
}
