import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:network_image_mock/network_image_mock.dart';
import 'package:proyecto_pokedex/api/pokedex_session_cache_service.dart';
import 'package:proyecto_pokedex/datos/pokemon_resumen.dart';
import 'package:proyecto_pokedex/logica/coleccion_servicio.dart';
import 'package:proyecto_pokedex/pantallas/pantalla_coleccionables.dart';
import 'package:proyecto_pokedex/widgets/tarjeta_pokemon_coleccion.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late ColeccionServicio coleccion;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    coleccion = ColeccionServicio();
  });

  PokemonResumen crear(int id, String nombre, List<String> tipos, int gen) {
    return PokemonResumen(
      id: id,
      nombre: nombre,
      urlImagen: 'https://ejemplo.com/$id.png',
      tipos: tipos,
      generacion: gen,
    );
  }

  List<PokemonResumen> crearLista() {
    return [
      crear(1, 'BULBASAUR', ['grass', 'poison'], 1),
      crear(4, 'CHARMANDER', ['fire'], 1),
      crear(7, 'SQUIRTLE', ['water'], 1),
      crear(152, 'CHIKORITA', ['grass'], 2),
      crear(155, 'CYNDAQUIL', ['fire'], 2),
    ];
  }

  const mensajeSinFavoritos =
      'Aún no tienes favoritos. Marca la estrella de un pokemon obtenido '
      'para agregarlo.';

  Future<void> montar(
    WidgetTester tester,
    List<int> abiertos, {
    ColeccionServicio? servicio,
  }) async {
    tester.view.physicalSize = const Size(1000, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final cache = PokemonSessionCacheService(
      fetchPokemonList: () async => crearLista(),
      preloadImage: (_) async {},
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PantallaColeccionables(
            cacheService: cache,
            coleccion: servicio ?? coleccion,
            obtenerPokemon: (id) async {
              abiertos.add(id);
              throw Exception('no se usa en estas pruebas');
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> desplegarFiltrosSiHaceFalta(
    WidgetTester tester,
    String clave,
  ) async {
    if (clave == 'boton_favoritos') return;
    if (find.byKey(ValueKey(clave)).evaluate().isNotEmpty) return;

    final abrir = find.byKey(const ValueKey('filtros_coleccion'));
    await tester.ensureVisible(abrir);
    await tester.tap(abrir);
    await tester.pumpAndSettle();
  }

  Future<void> tocarEnLaBarra(WidgetTester tester, String clave) async {
    await desplegarFiltrosSiHaceFalta(tester, clave);
    final boton = find.byKey(ValueKey(clave));
    await tester.ensureVisible(boton);
    await tester.pumpAndSettle();
    await tester.tap(boton);
    await tester.pumpAndSettle();
  }

  Future<void> elegir(WidgetTester tester, String clave, String texto) async {
    await desplegarFiltrosSiHaceFalta(tester, clave);
    await tester.tap(find.byKey(ValueKey(clave)));
    await tester.pumpAndSettle();
    await tester.tap(find.text(texto).last);
    await tester.pumpAndSettle();
  }

  Finder iconoDe(String clave, IconData icono) {
    return find.descendant(
      of: find.byKey(ValueKey(clave)),
      matching: find.byIcon(icono),
    );
  }

  group('PantallaColeccionables - estrellas', () {
    testWidgets('solo los obtenidos tienen estrella', (tester) async {
      await mockNetworkImagesFor(() async {
        await coleccion.agregarPokemon(4);
        await montar(tester, []);

        expect(find.byKey(const ValueKey('estrella_4')), findsOneWidget);
        expect(find.byKey(const ValueKey('estrella_1')), findsNothing);
      });
    });

    testWidgets('tocar la estrella marca y quita el favorito', (tester) async {
      await mockNetworkImagesFor(() async {
        final abiertos = <int>[];
        await coleccion.agregarPokemon(4);
        await montar(tester, abiertos);

        await tester.tap(find.byKey(const ValueKey('estrella_4')));
        await tester.pump();

        expect(coleccion.esFavorito(4), true);
        expect(iconoDe('estrella_4', Icons.star), findsOneWidget);

        await tester.tap(find.byKey(const ValueKey('estrella_4')));
        await tester.pump();

        expect(coleccion.esFavorito(4), false);
        expect(iconoDe('estrella_4', Icons.star_border), findsOneWidget);
        expect(abiertos, isEmpty);
      });
    });
  });

  testWidgets('si falla el guardado avisa y la estrella no queda marcada', (
    tester,
  ) async {
    await mockNetworkImagesFor(() async {
      final fallida = ColeccionServicio(
        persistirFavoritos: () async => throw Exception('fallo al guardar'),
      );
      await fallida.agregarPokemon(4);
      await montar(tester, [], servicio: fallida);

      await tester.tap(find.byKey(const ValueKey('estrella_4')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(fallida.esFavorito(4), false);
      expect(iconoDe('estrella_4', Icons.star_border), findsOneWidget);
      expect(find.text('No se pudo guardar el favorito.'), findsOneWidget);
    });
  });

  group('PantallaColeccionables - botón de favoritos', () {
    testWidgets('muestra solo los favoritos y el contador refleja ese conteo', (
      tester,
    ) async {
      await mockNetworkImagesFor(() async {
        await coleccion.agregarPokemon(4);
        await coleccion.agregarPokemon(155);
        await coleccion.agregarPokemon(7);
        await coleccion.alternarFavorito(4);
        await coleccion.alternarFavorito(155);
        await montar(tester, []);
        expect(find.byType(TarjetaPokemonColeccion), findsNWidgets(5));

        await tocarEnLaBarra(tester, 'boton_favoritos');

        expect(find.byType(TarjetaPokemonColeccion), findsNWidgets(2));
        expect(find.text('2/2 de favoritos'), findsOneWidget);
      });
    });

    testWidgets('volver a tocar el botón muestra todo otra vez', (
      tester,
    ) async {
      await mockNetworkImagesFor(() async {
        await coleccion.agregarPokemon(4);
        await coleccion.alternarFavorito(4);
        await montar(tester, []);

        await tocarEnLaBarra(tester, 'boton_favoritos');
        expect(find.byType(TarjetaPokemonColeccion), findsNWidgets(1));

        await tocarEnLaBarra(tester, 'boton_favoritos');
        expect(find.byType(TarjetaPokemonColeccion), findsNWidgets(5));
        expect(find.text('1 de 5 obtenidos'), findsOneWidget);
      });
    });

    testWidgets('si no hay favoritos muestra un mensaje', (tester) async {
      await mockNetworkImagesFor(() async {
        await coleccion.agregarPokemon(4);
        await montar(tester, []);

        await tocarEnLaBarra(tester, 'boton_favoritos');

        expect(find.text(mensajeSinFavoritos), findsOneWidget);
        expect(find.byType(TarjetaPokemonColeccion), findsNothing);
      });
    });

    testWidgets('quitar un favorito en esa vista lo saca del álbum', (
      tester,
    ) async {
      await mockNetworkImagesFor(() async {
        await coleccion.agregarPokemon(4);
        await coleccion.alternarFavorito(4);
        await montar(tester, []);
        await tocarEnLaBarra(tester, 'boton_favoritos');
        expect(find.byType(TarjetaPokemonColeccion), findsNWidgets(1));

        await tester.tap(find.byKey(const ValueKey('estrella_4')));
        await tester.pumpAndSettle();

        expect(find.byType(TarjetaPokemonColeccion), findsNothing);
        expect(find.text(mensajeSinFavoritos), findsOneWidget);
      });
    });

    testWidgets('se combina con los filtros de generación y tipo', (
      tester,
    ) async {
      await mockNetworkImagesFor(() async {
        await coleccion.agregarPokemon(4);
        await coleccion.agregarPokemon(155);
        await coleccion.alternarFavorito(4);
        await coleccion.alternarFavorito(155);
        await montar(tester, []);

        await elegir(tester, 'filtro_generacion', 'Generación 1');
        await tocarEnLaBarra(tester, 'boton_agregar_filtros');
        await tocarEnLaBarra(tester, 'boton_favoritos');

        expect(find.byType(TarjetaPokemonColeccion), findsNWidgets(1));
        expect(find.text('1/1 de generación 1 y favoritos'), findsOneWidget);
      });
    });

    testWidgets('restablecer también sale de la vista de favoritos', (
      tester,
    ) async {
      await mockNetworkImagesFor(() async {
        await coleccion.agregarPokemon(4);
        await coleccion.alternarFavorito(4);
        await montar(tester, []);
        await tocarEnLaBarra(tester, 'boton_favoritos');
        expect(find.byType(TarjetaPokemonColeccion), findsNWidgets(1));

        await tocarEnLaBarra(tester, 'boton_restablecer_filtros');

        expect(find.byType(TarjetaPokemonColeccion), findsNWidgets(5));
        expect(find.text('1 de 5 obtenidos'), findsOneWidget);
      });
    });
  });
}
