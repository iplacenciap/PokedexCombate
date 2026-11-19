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

  Future<void> montar(
    WidgetTester tester, {
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
            obtenerPokemon: (id) async => crearPokemonCompleto(id),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  List<int> ordenEnPantalla(WidgetTester tester) {
    return tester
        .widgetList<TarjetaPokemonColeccion>(
          find.byType(TarjetaPokemonColeccion),
        )
        .map((tarjeta) => tarjeta.pokemon.id)
        .toList();
  }

  Future<void> desplegarFiltrosSiHaceFalta(WidgetTester tester, String clave) async {
    if (clave == 'boton_favoritos') return;
    if (find.byKey(ValueKey(clave)).evaluate().isNotEmpty) return;

    final abrir = find.byKey(const ValueKey('filtros_coleccion'));
    await tester.ensureVisible(abrir);
    await tester.tap(abrir);
    await tester.pumpAndSettle();
  }

  Future<void> elegir(WidgetTester tester, String clave, String texto) async {
    await desplegarFiltrosSiHaceFalta(tester, clave);
    await tester.tap(find.byKey(ValueKey(clave)));
    await tester.pumpAndSettle();
    await tester.tap(find.text(texto).last);
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

  group('PantallaColeccionables - orden', () {
    testWidgets('los obtenidos van primero, ordenados por número', (
      tester,
    ) async {
      await mockNetworkImagesFor(() async {
        await coleccion.agregarPokemon(155);
        await coleccion.agregarPokemon(4);
        await montar(tester);

        expect(ordenEnPantalla(tester), [4, 155, 1, 7, 152]);
        expect(find.text('NUEVO'), findsNothing);
      });
    });

    testWidgets('el orden se mantiene al aplicar filtros', (tester) async {
      await mockNetworkImagesFor(() async {
        await coleccion.agregarPokemon(155);
        await montar(tester);

        await elegir(tester, 'filtro_tipo', 'Fuego');
        await tocarEnLaBarra(tester, 'boton_agregar_filtros');

        expect(ordenEnPantalla(tester), [155, 4]);
      });
    });
  });

  group('PantallaColeccionables - pokemon nuevo', () {
    testWidgets('uno que llega con la pantalla abierta va primero con NUEVO', (
      tester,
    ) async {
      await mockNetworkImagesFor(() async {
        await coleccion.agregarPokemon(4);
        await montar(tester);

        await coleccion.agregarPokemon(155);
        await tester.pump();

        expect(ordenEnPantalla(tester), [155, 4, 1, 7, 152]);
        expect(find.text('NUEVO'), findsOneWidget);
        expect(
          find.descendant(
            of: find.byKey(const ValueKey('tarjeta_coleccion_155')),
            matching: find.text('NUEVO'),
          ),
          findsOneWidget,
        );
      });
    });

    testWidgets('con varios nuevos, el más reciente va primero', (
      tester,
    ) async {
      await mockNetworkImagesFor(() async {
        await montar(tester);

        await coleccion.agregarPokemon(4);
        await coleccion.agregarPokemon(155);
        await tester.pump();

        expect(ordenEnPantalla(tester), [155, 4, 1, 7, 152]);
        expect(find.text('NUEVO'), findsNWidgets(2));
      });
    });

    testWidgets('al abrir su descripción pierde la etiqueta y pasa a su lugar', (
      tester,
    ) async {
      await mockNetworkImagesFor(() async {
        await coleccion.agregarPokemon(4);
        await montar(tester);
        await coleccion.agregarPokemon(155);
        await tester.pump();

        await tester.tap(find.text('Cyndaquil'));
        await tester.pumpAndSettle();
        expect(find.byType(PantallaDescripcionPokemon), findsOneWidget);

        await tester.pageBack();
        await tester.pumpAndSettle();

        expect(find.text('NUEVO'), findsNothing);
        expect(ordenEnPantalla(tester), [4, 155, 1, 7, 152]);
      });
    });

    testWidgets('si falla el guardado, el pokemon deja de ser nuevo', (
      tester,
    ) async {
      await mockNetworkImagesFor(() async {
        final fallida = ColeccionServicio(
          persistirColeccion: () async => throw Exception('fallo al guardar'),
        );
        await montar(tester, servicio: fallida);

        await expectLater(
          fallida.agregarPokemon(4),
          throwsA(isA<Exception>()),
        );
        await tester.pump();

        expect(fallida.estaObtenido(4), false);
        expect(find.text('NUEVO'), findsNothing);
        expect(ordenEnPantalla(tester), [1, 4, 7, 152, 155]);
      });
    });
  });
}