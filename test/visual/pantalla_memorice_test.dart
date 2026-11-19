import "dart:math";

import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:proyecto_pokedex/logica/sistema_recompensas.dart";
import "package:shared_preferences/shared_preferences.dart";
import "package:proyecto_pokedex/api/pokedex_session_cache_service.dart";
import "package:proyecto_pokedex/datos/almacenamiento_perfil.dart";
import "package:proyecto_pokedex/datos/perfil_jugador.dart";
import "package:proyecto_pokedex/datos/pokemon_resumen.dart";
import "package:proyecto_pokedex/logica/enums/dificultad_memorice.dart";
import "package:proyecto_pokedex/logica/gestor_progreso.dart";
import "package:proyecto_pokedex/logica/partida_memorice.dart";
import "package:proyecto_pokedex/pantallas/pantalla_memorice.dart";

void main() {
  List<PokemonResumen> crearPokemonsDePrueba(int cantidad) {
    return List.generate(
      cantidad,
      (i) => PokemonResumen(
        id: i + 1,
        nombre: "POKEMON_$i",
        urlImagen: "https://ejemplo.com/poke_$i.png",
        tipos: ["normal"],
        generacion: 1,
      ),
    );
  }

  PokemonSessionCacheService crearCacheMock() {
    return PokemonSessionCacheService(
      fetchPokemonList: () async => crearPokemonsDePrueba(20),
      preloadImage: (_) async {},
    );
  }

  Widget montarPantalla({
    PartidaMemorice? partida,
    PokemonSessionCacheService? cacheService,
    GestorProgreso? gestorProgreso,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: PantallaMemorice(
          partidaInyectada: partida,
          cacheService: cacheService ?? crearCacheMock(),
          gestorProgreso: gestorProgreso,
          imageBuilder: (pokemon) => Text("IMG_${pokemon.nombre}"),
        ),
      ),
    );
  }

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group("Pantalla Memorice - Widget Tests", () {
    testWidgets(
      "Muestra selector inicial amplio con las 4 dificultades y botón Comenzar",
      (tester) async {
        await tester.pumpWidget(montarPantalla());

        expect(find.text("Memorice Pokémon"), findsOneWidget);
        expect(
          find.byKey(const ValueKey("chip_dificultad_facil")),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey("chip_dificultad_normal")),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey("chip_dificultad_dificil")),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey("chip_dificultad_extremo")),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey("btn_comenzar_memorice")),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      "Renderiza todas las cartas en pantalla sin necesidad de scroll",
      (tester) async {
        final cache = crearCacheMock();
        final partida = PartidaMemorice(cacheService: cache, random: Random(1));

        await tester.pumpWidget(montarPantalla(partida: partida));

        // Seleccionar dificultad Extremo
        await tester.tap(find.byKey(const ValueKey("chip_dificultad_extremo")));
        await tester.pump();
        await tester.tap(find.byKey(const ValueKey("btn_comenzar_memorice")));
        await tester.pump();
        await tester.pump();

        // Las 24 cartas deben existir simultáneamente en el árbol sin hacer scroll
        for (int i = 0; i < 24; i++) {
          expect(find.byKey(ValueKey("carta_memorice_$i")), findsOneWidget);
        }

        partida.dispose();
      },
    );

    testWidgets(
      "Inicia en fase de memorización mostrando cartas boca arriba y luego las voltea",
      (tester) async {
        final cache = crearCacheMock();
        final partida = PartidaMemorice(cacheService: cache, random: Random(1));

        await tester.pumpWidget(montarPantalla(partida: partida));

        await tester.tap(find.byKey(const ValueKey("btn_comenzar_memorice")));
        await tester.pump();
        await tester.pump();

        // Durante memorización: muestra aviso "¡Memoriza!"
        expect(
          find.byKey(const ValueKey("hud_estado_memorizando")),
          findsOneWidget,
        );
        expect(find.byKey(const ValueKey("carta_frente_0")), findsOneWidget);
        expect(find.byKey(const ValueKey("carta_frente_11")), findsOneWidget);

        // Avanzar los segundos de memorización
        await tester.pump(
          Duration(seconds: DificultadMemorice.facil.segundosMemorizacion),
        );

        // En fase jugando: aparece el temporizador y las cartas están boca abajo
        expect(
          find.byKey(const ValueKey("hud_tiempo_restante")),
          findsOneWidget,
        );
        expect(find.byKey(const ValueKey("carta_frente_0")), findsNothing);
        expect(find.byKey(const ValueKey("carta_reverso")), findsNWidgets(12));

        partida.dispose();
      },
    );

    testWidgets(
      "Al desmontarse la pantalla con partida propia libera los timers correctamente",
      (tester) async {
        final cache = crearCacheMock();
        await tester.pumpWidget(montarPantalla(cacheService: cache));

        await tester.tap(find.byKey(const ValueKey("btn_comenzar_memorice")));
        await tester.pump();
        await tester.pump();
        await tester.pump(
          Duration(seconds: DificultadMemorice.facil.segundosMemorizacion),
        );

        expect(
          find.byKey(const ValueKey("grilla_cartas_memorice")),
          findsOneWidget,
        );

        // Desmontar el widget valida que no queden timers activos
        await tester.pumpWidget(const SizedBox());
      },
    );

    testWidgets(
      "Flujo completo de victoria tocando cartas, diálogo grande, guardado en perfil y retorno a Inicio",
      (tester) async {
        final perfil = PerfilJugador();
        final gestor = GestorProgreso(perfil: perfil);
        final cache = crearCacheMock();
        late final PartidaMemorice partida;
        partida = PartidaMemorice(
          cacheService: cache,
          random: Random(1),
          onPartidaFinalizada: (dificultad, victoria, _) {
            final recompensa = SistemaRecompensas.recompensaMemorice(
              victoria: victoria,
              intentosIncorrectos: partida.errores,
              dificultad: dificultad,
            );

            gestor.registrarSesionMemorice(
              victoria: victoria,
              recompensa: recompensa,
            );
          },
        );

        await tester.pumpWidget(
          montarPantalla(partida: partida, gestorProgreso: gestor),
        );
        await tester.tap(find.byKey(const ValueKey("btn_comenzar_memorice")));
        await tester.pump();
        await tester.pump();
        await tester.pump(
          Duration(seconds: DificultadMemorice.facil.segundosMemorizacion),
        );

        // Tocar cada par directamente en pantalla (sin scroll porque todas caben en pantalla)
        final nombres = partida.cartas.map((c) => c.pokemon.nombre).toSet();
        for (final nombre in nombres) {
          final indices = <int>[];
          for (int i = 0; i < partida.cartas.length; i++) {
            if (partida.cartas[i].pokemon.nombre == nombre) {
              indices.add(i);
            }
          }
          await tester.tap(
            find.byKey(ValueKey("carta_memorice_${indices[0]}")),
          );
          await tester.pump();
          await tester.tap(
            find.byKey(ValueKey("carta_memorice_${indices[1]}")),
          );
          await tester.pump();
        }

        await tester.pumpAndSettle();

        // Verifica el modal de fin de partida y las estadísticas guardadas
        expect(
          find.byKey(const ValueKey("memorice_dialogo_fin")),
          findsOneWidget,
        );
        expect(find.text("¡Victoria!"), findsOneWidget);
        expect(perfil.progreso.memorice.sesionesJugadas, 1);
        expect(perfil.progreso.memorice.victorias, 1);
        expect(perfil.saldoMonedas, DificultadMemorice.facil.recompensa);

        final perfilPersistido = await AlmacenamientoPerfil().cargarPerfil();
        expect(perfilPersistido.progreso.memorice.victorias, 1);
        expect(
          perfilPersistido.saldoMonedas,
          DificultadMemorice.facil.recompensa,
        );

        // Presionar botón "Inicio" devuelve a la vista de selección de dificultad
        final botonInicio = find.byKey(const ValueKey("btn_fin_inicio"));
        await tester.ensureVisible(botonInicio);
        await tester.tap(botonInicio);
        await tester.pumpAndSettle();

        expect(find.text("Memorice Pokémon"), findsOneWidget);
        expect(
          find.byKey(const ValueKey("btn_comenzar_memorice")),
          findsOneWidget,
        );

        partida.dispose();
      },
    );

    testWidgets(
      "El botón Salir detiene la partida en curso y regresa a la selección de dificultad",
      (tester) async {
        final cache = crearCacheMock();
        final partida = PartidaMemorice(cacheService: cache, random: Random(1));

        await tester.pumpWidget(montarPantalla(partida: partida));

        // Iniciar partida y pasar a la fase de juego activo
        await tester.tap(find.byKey(const ValueKey("btn_comenzar_memorice")));
        await tester.pump();
        await tester.pump();
        await tester.pump(
          Duration(seconds: DificultadMemorice.facil.segundosMemorizacion),
        );

        expect(
          find.byKey(const ValueKey("grilla_cartas_memorice")),
          findsOneWidget,
        );
        expect(find.byKey(const ValueKey("btn_salir_partida")), findsOneWidget);

        // Presionar el botón Salir durante la partida
        await tester.tap(find.byKey(const ValueKey("btn_salir_partida")));
        await tester.pump();

        // Verifica que regrese limpiamente al menú inicial y cancele los timers
        expect(find.text("Memorice Pokémon"), findsOneWidget);
        expect(
          find.byKey(const ValueKey("btn_comenzar_memorice")),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey("grilla_cartas_memorice")),
          findsNothing,
        );

        partida.dispose();
      },
    );
  });
}
