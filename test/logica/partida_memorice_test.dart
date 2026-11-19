import "dart:math";
import "package:fake_async/fake_async.dart";
import "package:flutter_test/flutter_test.dart";
import "package:proyecto_pokedex/api/pokedex_session_cache_service.dart";
import "package:proyecto_pokedex/datos/pokemon_resumen.dart";
import "package:proyecto_pokedex/logica/enums/dificultad_memorice.dart";
import "package:proyecto_pokedex/logica/enums/estado_memorice.dart";
import "package:proyecto_pokedex/logica/partida_memorice.dart";

void main() {
  List<PokemonResumen> crearPokemonsDePrueba(int cantidad) {
    return List.generate(
      cantidad,
      (i) => PokemonResumen(
        id: i + 1,
        nombre: "pokemon_$i",
        urlImagen: "https://ejemplo.com/poke_$i.png",
        tipos: ["normal"],
        generacion: 1,
      ),
    );
  }

  List<int> buscarParDeIndices(PartidaMemorice partida, String nombrePokemon) {
    final indices = <int>[];
    for (int i = 0; i < partida.cartas.length; i++) {
      if (partida.cartas[i].pokemon.nombre == nombrePokemon) {
        indices.add(i);
      }
    }
    return indices;
  }

  group("Estructura del tablero, dificultades y flujo de tiempo", () {
    test("debe tener configurados los 4 niveles de dificultad requeridos", () {
      expect(DificultadMemorice.values.length, 4);
      expect(DificultadMemorice.facil.pares, 6);
      expect(DificultadMemorice.normal.pares, 8);
      expect(DificultadMemorice.dificil.pares, 10);
      expect(DificultadMemorice.extremo.pares, 12);
    });

    test("al iniciar partida genera los pares correspondientes boca arriba y en fase memorizando", () async {
      final cacheService = PokemonSessionCacheService(
        fetchPokemonList: () async => crearPokemonsDePrueba(15),
        preloadImage: (_) async {},
      );
      final partida = PartidaMemorice(
        cacheService: cacheService,
        random: Random(42),
      );

      await partida.iniciarPartida(DificultadMemorice.normal); // 8 pares = 16 cartas

      expect(partida.fase, FaseMemorice.memorizando);
      expect(partida.tableroBloqueado, isTrue);
      expect(partida.cartas.length, 16);
      expect(partida.cartas.every((c) => c.bocaArriba), isTrue);

      final conteoPorPokemon = <String, int>{};
      for (final carta in partida.cartas) {
        conteoPorPokemon[carta.pokemon.nombre] =
            (conteoPorPokemon[carta.pokemon.nombre] ?? 0) + 1;
      }
      expect(conteoPorPokemon.length, 8);
      expect(conteoPorPokemon.values.every((count) => count == 2), isTrue);

      partida.dispose();
    });

    test("transiciona automáticamente de memorización a juego activo volteando las cartas", () {
      fakeAsync((async) {
        final cacheService = PokemonSessionCacheService(
          fetchPokemonList: () async => crearPokemonsDePrueba(10),
          preloadImage: (_) async {},
        );
        final partida = PartidaMemorice(
          cacheService: cacheService,
          random: Random(1),
        );

        partida.iniciarPartida(DificultadMemorice.facil);
        async.flushMicrotasks();

        final segMem = DificultadMemorice.facil.segundosMemorizacion;
        async.elapse(Duration(seconds: segMem - 1));
        expect(partida.fase, FaseMemorice.memorizando);
        expect(partida.cartas.every((c) => c.bocaArriba), isTrue);

        async.elapse(const Duration(seconds: 1));
        expect(partida.fase, FaseMemorice.jugando);
        expect(partida.tableroBloqueado, isFalse);
        expect(partida.cartas.every((c) => !c.bocaArriba), isTrue);

        partida.dispose();
      });
    });

    test("cuando el temporizador llega a cero detiene el reloj, pasa a derrota y notifica resultado", () {
      fakeAsync((async) {
        DificultadMemorice? dificultadNotificada;
        bool? resultadoNotificado;
        int? mejorComboNotificado;

        final cacheService = PokemonSessionCacheService(
          fetchPokemonList: () async => crearPokemonsDePrueba(10),
          preloadImage: (_) async {},
        );
        final partida = PartidaMemorice(
          cacheService: cacheService,
          random: Random(1),
          onPartidaFinalizada: (dificultad, victoria, mejorCombo) {
            dificultadNotificada = dificultad;
            resultadoNotificado = victoria;
            mejorComboNotificado = mejorCombo;
          },
        );

        partida.iniciarPartida(DificultadMemorice.facil);
        async.flushMicrotasks();

        async.elapse(Duration(seconds: DificultadMemorice.facil.segundosMemorizacion));
        expect(partida.fase, FaseMemorice.jugando);

        int notificacionesTablero = 0;
        partida.addListener(() {
          notificacionesTablero++;
        });

        // El reloj avanza sin redibujar todo el tablero
        async.elapse(const Duration(seconds: 10));
        expect(
          partida.segundosRestantes.value,
          DificultadMemorice.facil.segundosJuego - 10,
        );
        expect(notificacionesTablero, 0);

        // Agotar tiempo restante
        final tiempoRestante = partida.segundosRestantes.value;
        async.elapse(Duration(seconds: tiempoRestante));

        expect(partida.segundosRestantes.value, 0);
        expect(partida.fase, FaseMemorice.derrota);
        expect(partida.tableroBloqueado, isTrue);
        expect(notificacionesTablero, 1);
        expect(dificultadNotificada, DificultadMemorice.facil);
        expect(resultadoNotificado, isFalse);
        expect(mejorComboNotificado, 0);

        partida.dispose();
      });
    });
  });

  group("Reglas de emparejamiento, bloqueo de toques y métricas", () {
    test("ignora toques sobre la misma carta o cartas ya emparejadas", () {
      fakeAsync((async) {
        final cacheService = PokemonSessionCacheService(
          fetchPokemonList: () async => crearPokemonsDePrueba(10),
          preloadImage: (_) async {},
        );
        final partida = PartidaMemorice(
          cacheService: cacheService,
          random: Random(1),
        );

        partida.iniciarPartida(DificultadMemorice.facil);
        async.flushMicrotasks();
        async.elapse(Duration(seconds: DificultadMemorice.facil.segundosMemorizacion));

        // Doble toque sobre la misma carta (índice 0)
        partida.seleccionarCarta(0);
        partida.seleccionarCarta(0);

        expect(partida.cartas.where((c) => c.bocaArriba).length, 1);
        expect(partida.errores, 0);

        // Emparejar carta 0 con su par
        final nombrePoke = partida.cartas[0].pokemon.nombre;
        final parIndices = buscarParDeIndices(partida, nombrePoke);
        final indicePareja = parIndices.firstWhere((i) => i != 0);

        partida.seleccionarCarta(indicePareja);
        expect(partida.cartas[0].emparejada, isTrue);
        expect(partida.cartas[indicePareja].emparejada, isTrue);
        expect(partida.comboActual, 1);

        // Intentar tocar una carta ya emparejada es ignorado
        partida.seleccionarCarta(0);
        expect(partida.cartas[0].bocaArriba, isTrue);
        expect(partida.errores, 0);

        partida.dispose();
      });
    });

    test("al seleccionar dos cartas distintas bloquea un tercer toque, cuenta el error y luego las oculta", () {
      fakeAsync((async) {
        final cacheService = PokemonSessionCacheService(
          fetchPokemonList: () async => crearPokemonsDePrueba(10),
          preloadImage: (_) async {},
        );
        final partida = PartidaMemorice(
          cacheService: cacheService,
          random: Random(1),
        );

        partida.iniciarPartida(DificultadMemorice.facil);
        async.flushMicrotasks();
        async.elapse(Duration(seconds: DificultadMemorice.facil.segundosMemorizacion));

        const int idx1 = 0;
        final int idx2 = partida.cartas.indexWhere(
          (c) => c.pokemon.nombre != partida.cartas[idx1].pokemon.nombre,
        );
        final int idx3 = [0, 1, 2, 3, 4].firstWhere((i) => i != idx1 && i != idx2);

        partida.seleccionarCarta(idx1);
        partida.seleccionarCarta(idx2);

        expect(partida.cartas[idx1].bocaArriba, isTrue);
        expect(partida.cartas[idx2].bocaArriba, isTrue);
        expect(partida.tableroBloqueado, isTrue);
        expect(partida.errores, 1);
        expect(partida.comboActual, 0);

        // Intento de voltear tercera carta durante el bloqueo por error
        partida.seleccionarCarta(idx3);
        expect(partida.cartas[idx3].bocaArriba, isFalse);

        // Al cumplirse el tiempo de muestra del error, se ocultan y se desbloquea
        async.elapse(PartidaMemorice.tiempoMuestraError);
        expect(partida.cartas[idx1].bocaArriba, isFalse);
        expect(partida.cartas[idx2].bocaArriba, isFalse);
        expect(partida.tableroBloqueado, isFalse);

        partida.dispose();
      });
    });

    test("calcula combos correctamente, detiene el reloj al emparejar todas y notifica victoria", () {
      fakeAsync((async) {
        DificultadMemorice? dificultadNotificada;
        bool? resultadoNotificado;
        int? mejorComboNotificado;

        final cacheService = PokemonSessionCacheService(
          fetchPokemonList: () async => crearPokemonsDePrueba(10),
          preloadImage: (_) async {},
        );
        final partida = PartidaMemorice(
          cacheService: cacheService,
          random: Random(1),
          onPartidaFinalizada: (dificultad, victoria, mejorCombo) {
            dificultadNotificada = dificultad;
            resultadoNotificado = victoria;
            mejorComboNotificado = mejorCombo;
          },
        );

        partida.iniciarPartida(DificultadMemorice.facil);
        async.flushMicrotasks();
        async.elapse(Duration(seconds: DificultadMemorice.facil.segundosMemorizacion));

        final nombresUnicos = partida.cartas.map((c) => c.pokemon.nombre).toSet().toList();

        // 1. Emparejar 2 pares seguidos (combo = 2, mejorCombo = 2)
        for (int p = 0; p < 2; p++) {
          final indices = buscarParDeIndices(partida, nombresUnicos[p]);
          partida.seleccionarCarta(indices[0]);
          partida.seleccionarCarta(indices[1]);
        }
        expect(partida.comboActual, 2);
        expect(partida.mejorCombo, 2);

        // 2. Cometer un error (combo baja a 0, mejorCombo se mantiene en 2)
        final par3 = buscarParDeIndices(partida, nombresUnicos[2]);
        final par4 = buscarParDeIndices(partida, nombresUnicos[3]);
        partida.seleccionarCarta(par3[0]);
        partida.seleccionarCarta(par4[0]);
        expect(partida.comboActual, 0);
        expect(partida.mejorCombo, 2);
        expect(partida.errores, 1);

        async.elapse(PartidaMemorice.tiempoMuestraError);

        // 3. Emparejar los 4 pares restantes (combo llega a 4, mejorCombo = 4)
        for (int p = 2; p < nombresUnicos.length; p++) {
          final indices = buscarParDeIndices(partida, nombresUnicos[p]);
          partida.seleccionarCarta(indices[0]);
          partida.seleccionarCarta(indices[1]);
        }

        expect(partida.fase, FaseMemorice.victoria);
        expect(partida.mejorCombo, 4);
        expect(dificultadNotificada, DificultadMemorice.facil);
        expect(resultadoNotificado, isTrue);
        expect(mejorComboNotificado, 4);

        final segundosAlGanar = partida.segundosRestantes.value;
        async.elapse(const Duration(seconds: 10));
        expect(partida.segundosRestantes.value, segundosAlGanar);

        partida.dispose();
      });
    });

    test("volverAlInicio limpia el tablero, detiene timers y regresa a fase inicial", () {
      fakeAsync((async) {
        final cacheService = PokemonSessionCacheService(
          fetchPokemonList: () async => crearPokemonsDePrueba(10),
          preloadImage: (_) async {},
        );
        final partida = PartidaMemorice(
          cacheService: cacheService,
          random: Random(1),
        );

        partida.iniciarPartida(DificultadMemorice.facil);
        async.flushMicrotasks();
        async.elapse(Duration(seconds: DificultadMemorice.facil.segundosMemorizacion));

        partida.volverAlInicio();

        expect(partida.fase, FaseMemorice.inicial);
        expect(partida.cartas, isEmpty);
        expect(partida.errores, 0);
        expect(partida.comboActual, 0);
        expect(partida.segundosRestantes.value, 0);

        partida.dispose();
      });
    });
  });
}