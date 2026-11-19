import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:network_image_mock/network_image_mock.dart';
import 'package:proyecto_pokedex/api/pokedex_session_cache_service.dart';
import 'package:proyecto_pokedex/datos/pokemon.dart';
import 'package:proyecto_pokedex/datos/pokemon_resumen.dart';
import 'package:proyecto_pokedex/logica/coleccion_servicio.dart';
import 'package:proyecto_pokedex/pantallas/pantalla_coleccionables.dart';
import 'package:proyecto_pokedex/pantallas/pantalla_descripcion_pokemon.dart';
import 'package:proyecto_pokedex/widgets/tarjeta_pokemon_coleccion.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late ColeccionServicio coleccion;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    coleccion = ColeccionServicio();
  });

  List<PokemonResumen> crearPokemones(int cantidad) {
    return List.generate(
      cantidad,
      (i) => PokemonResumen(
        id: i + 1,
        nombre: 'POKE_${i + 1}',
        urlImagen: 'https://ejemplo.com/poke_${i + 1}.png',
        tipos: ['normal'],
        generacion: 1,
      ),
    );
  }

  Pokemon crearPokemonCompleto(int id) {
    return Pokemon(
      id: id,
      nombre: 'poke_$id',
      urlImagen: 'https://ejemplo.com/poke_$id.png',
      tipos: ['normal'],
      altura: 4,
      peso: 60,
      generacion: 'generation-i',
      descripcion: 'Descripción de prueba',
      habilidades: ['static'],
      estadisticas: {'hp': 35},
    );
  }

  PokemonSessionCacheService crearCache(
    Future<List<PokemonResumen>> Function() obtenerLista,
  ) {
    return PokemonSessionCacheService(
      fetchPokemonList: obtenerLista,
      preloadImage: (_) async {},
    );
  }

  Future<void> montarPantalla(
    WidgetTester tester,
    PokemonSessionCacheService cache, {
    Future<Pokemon> Function(int id)? obtenerPokemon,
  }) async {
    tester.view.physicalSize = const Size(1000, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PantallaColeccionables(
            cacheService: cache,
            coleccion: coleccion,
            obtenerPokemon: obtenerPokemon,
          ),
        ),
      ),
    );
  }

  group('PantallaColeccionables - carga', () {
    testWidgets('muestra un indicador mientras carga la lista', (tester) async {
      await mockNetworkImagesFor(() async {
        final completer = Completer<List<PokemonResumen>>();
        await montarPantalla(tester, crearCache(() => completer.future));

        expect(find.byType(CircularProgressIndicator), findsOneWidget);

        completer.complete(crearPokemones(3));
        await tester.pumpAndSettle();

        expect(find.byType(CircularProgressIndicator), findsNothing);
        expect(find.byType(TarjetaPokemonColeccion), findsNWidgets(3));
      });
    });

    testWidgets('muestra un mensaje si la carga falla', (tester) async {
      await mockNetworkImagesFor(() async {
        await montarPantalla(
          tester,
          crearCache(() async => throw Exception('sin conexión')),
        );
        await tester.pumpAndSettle();

        expect(find.text('No se pudo cargar la colección.'), findsOneWidget);
        expect(find.byType(CircularProgressIndicator), findsNothing);
      });
    });
  });

  group('PantallaColeccionables - álbum', () {
    testWidgets('muestra el título y una tarjeta por Pokémon', (
      tester,
    ) async {
      await mockNetworkImagesFor(() async {
        await montarPantalla(tester, crearCache(() async => crearPokemones(10)));
        await tester.pumpAndSettle();

        expect(find.text('Colección'), findsOneWidget);
        expect(find.byType(TarjetaPokemonColeccion), findsNWidgets(10));
      });
    });

    testWidgets('el álbum tiene 4 columnas en escritorio', (tester) async {
      await mockNetworkImagesFor(() async {
        await montarPantalla(tester, crearCache(() async => crearPokemones(10)));
        await tester.pumpAndSettle();

        final grilla = tester.widget<SliverGrid>(find.byType(SliverGrid));
        final delegado =
            grilla.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;

        expect(delegado.crossAxisCount, 4);
      });
    });

    testWidgets('carga perezosa: no construye todas las tarjetas', (
      tester,
    ) async {
      await mockNetworkImagesFor(() async {
        await montarPantalla(tester, crearCache(() async => crearPokemones(300)));
        await tester.pumpAndSettle();

        final construidas = find.byType(TarjetaPokemonColeccion).evaluate();
        expect(construidas, isNotEmpty);
        expect(construidas.length, lessThan(300));
      });
    });

    testWidgets('los obtenidos muestran nombre y los demás van en negro', (
      tester,
    ) async {
      await mockNetworkImagesFor(() async {
        await coleccion.agregarPokemon(2);
        await montarPantalla(tester, crearCache(() async => crearPokemones(5)));
        await tester.pumpAndSettle();

        expect(find.text('Poke_2'), findsOneWidget);
        expect(find.text('Poke_1'), findsNothing);
        expect(find.byType(ColorFiltered), findsNWidgets(4));
      });
    });

    testWidgets('se actualiza cuando entra un pokemon nuevo', (tester) async {
      await mockNetworkImagesFor(() async {
        await montarPantalla(tester, crearCache(() async => crearPokemones(5)));
        await tester.pumpAndSettle();
        expect(find.text('Poke_3'), findsNothing);

        await coleccion.agregarPokemon(3);
        await tester.pump();

        expect(find.text('Poke_3'), findsOneWidget);
        expect(find.byType(ColorFiltered), findsNWidgets(4));
      });
    });
  });

  group('PantallaColeccionables - descripción', () {
    testWidgets('tocar un obtenido abre su pantalla de descripción', (
      tester,
    ) async {
      await mockNetworkImagesFor(() async {
        await coleccion.agregarPokemon(2);
        final pedidos = <int>[];
        await montarPantalla(
          tester,
          crearCache(() async => crearPokemones(5)),
          obtenerPokemon: (id) async {
            pedidos.add(id);
            return crearPokemonCompleto(id);
          },
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Poke_2'));
        await tester.pumpAndSettle();

        expect(pedidos, [2]);
        expect(find.byType(PantallaDescripcionPokemon), findsOneWidget);
      });
    });

    testWidgets('tocar un oculto no pide datos ni abre nada', (tester) async {
      await mockNetworkImagesFor(() async {
        await coleccion.agregarPokemon(2);
        final pedidos = <int>[];
        await montarPantalla(
          tester,
          crearCache(() async => crearPokemones(5)),
          obtenerPokemon: (id) async {
            pedidos.add(id);
            return crearPokemonCompleto(id);
          },
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const ValueKey('tarjeta_coleccion_1')));
        await tester.pumpAndSettle();

        expect(pedidos, isEmpty);
        expect(find.byType(PantallaDescripcionPokemon), findsNothing);
      });
    });

    testWidgets('ignora toques repetidos mientras carga la descripción', (
      tester,
    ) async {
      await mockNetworkImagesFor(() async {
        await coleccion.agregarPokemon(2);
        final pedidos = <int>[];
        final completer = Completer<Pokemon>();
        await montarPantalla(
          tester,
          crearCache(() async => crearPokemones(5)),
          obtenerPokemon: (id) {
            pedidos.add(id);
            return completer.future;
          },
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Poke_2'));
        await tester.pump();
        await tester.tap(find.text('Poke_2'));
        await tester.pump();

        expect(pedidos, [2]);

        completer.complete(crearPokemonCompleto(2));
        await tester.pumpAndSettle();

        expect(find.byType(PantallaDescripcionPokemon), findsOneWidget);
      });
    });

    testWidgets('si falla la carga muestra un mensaje y no abre la pantalla', (
      tester,
    ) async {
      await mockNetworkImagesFor(() async {
        await coleccion.agregarPokemon(2);
        await montarPantalla(
          tester,
          crearCache(() async => crearPokemones(5)),
          obtenerPokemon: (id) async => throw Exception('sin conexión'),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Poke_2'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(
          find.text('No se pudo abrir la descripción del pokemon.'),
          findsOneWidget,
        );
        expect(find.byType(PantallaDescripcionPokemon), findsNothing);
      });
    });
  });
}