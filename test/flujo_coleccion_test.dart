import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:network_image_mock/network_image_mock.dart';
import 'package:proyecto_pokedex/api/pokedex_session_cache_service.dart';
import 'package:proyecto_pokedex/datos/pokemon_resumen.dart';
import 'package:proyecto_pokedex/logica/coleccion_servicio.dart';
import 'package:proyecto_pokedex/pantallas/pantalla_coleccionables.dart';
import 'package:proyecto_pokedex/pantallas/pantalla_descripcion_pokemon.dart';
import 'package:proyecto_pokedex/widgets/tarjeta_pokemon_coleccion.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Pruebas del flujo completo de la colección
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

  Future<void> montar(
    WidgetTester tester,
    ColeccionServicio servicio, {
    List<int>? pedidos,
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
            coleccion: servicio,
            obtenerPokemon: (id) async {
              pedidos?.add(id);
              throw Exception('la descripción no se usa en este flujo');
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<ColeccionServicio> cerrarYAbrir(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    final nuevo = ColeccionServicio();
    await nuevo.cargar();
    await montar(tester, nuevo);
    return nuevo;
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

  Finder iconoDe(String clave, IconData icono) {
    return find.descendant(
      of: find.byKey(ValueKey(clave)),
      matching: find.byIcon(icono),
    );
  }

  group('Flujo de la colección - obtenidos y no obtenidos', () {
    testWidgets('un pokemon agregado aparece a la vista y el contador se actualiza', (
      tester,
    ) async {
      await mockNetworkImagesFor(() async {
        await montar(tester, coleccion);
        expect(find.text('0 de 5 obtenidos'), findsOneWidget);
        expect(find.byType(ColorFiltered), findsNWidgets(5));

        final resultado = await coleccion.agregarPokemon(4);
        await tester.pump();

        expect(resultado, ResultadoAgregar.nuevo);
        expect(find.text('Charmander'), findsOneWidget);
        expect(find.byType(ColorFiltered), findsNWidgets(4));
        expect(find.text('1 de 5 obtenidos'), findsOneWidget);
      });
    });

    testWidgets('un pokemon repetido no se duplica y se informa como repetido', (
      tester,
    ) async {
      await mockNetworkImagesFor(() async {
        await coleccion.agregarPokemon(4);
        await montar(tester, coleccion);

        final resultado = await coleccion.agregarPokemon(4);
        await tester.pump();

        expect(resultado, ResultadoAgregar.repetido);
        expect(coleccion.cantidadObtenidos, 1);
        expect(find.text('Charmander'), findsOneWidget);
        expect(find.text('1 de 5 obtenidos'), findsOneWidget);
        expect(find.text('NUEVO'), findsNothing);

        final preferencias = await SharedPreferences.getInstance();
        expect(preferencias.getStringList('coleccion_ids'), ['4']);
      });
    });

    testWidgets('un pokemon que entrega el gacha se ve a la vista y se guarda solo', (
      tester,
    ) async {
      await mockNetworkImagesFor(() async {
        await montar(tester, coleccion);

        await coleccion.agregarPokemon(7);
        await tester.pump();

        expect(find.text('Squirtle'), findsOneWidget);
        expect(find.text('NUEVO'), findsOneWidget);

        final preferencias = await SharedPreferences.getInstance();
        expect(preferencias.getStringList('coleccion_ids'), ['7']);
      });
    });

    testWidgets('un no obtenido se ve en negro y al tocarlo no ocurre nada', (
      tester,
    ) async {
      await mockNetworkImagesFor(() async {
        final pedidos = <int>[];
        await coleccion.agregarPokemon(4);
        await montar(tester, coleccion, pedidos: pedidos);

        final tarjeta = find.byKey(const ValueKey('tarjeta_coleccion_1'));
        expect(
          find.descendant(of: tarjeta, matching: find.byType(ColorFiltered)),
          findsOneWidget,
        );
        expect(find.text('Bulbasaur'), findsNothing);

        await tester.tap(tarjeta);
        await tester.pumpAndSettle();

        expect(pedidos, isEmpty);
        expect(find.byType(PantallaDescripcionPokemon), findsNothing);
      });
    });
  });

  group('Flujo de la colección - guardado', () {
    testWidgets('al cerrar y abrir la aplicación la colección se mantiene igual', (
      tester,
    ) async {
      await mockNetworkImagesFor(() async {
        await montar(tester, coleccion);
        await coleccion.agregarPokemon(4);
        await coleccion.agregarPokemon(155);
        await tester.pump();

        final reabierto = await cerrarYAbrir(tester);

        expect(reabierto.idsObtenidos, {4, 155});
        expect(find.text('Charmander'), findsOneWidget);
        expect(find.text('Cyndaquil'), findsOneWidget);
        expect(find.text('Squirtle'), findsNothing);
        expect(find.text('2 de 5 obtenidos'), findsOneWidget);
        expect(find.text('NUEVO'), findsNothing);
      });
    });
  });

  group('Flujo de la colección - filtros', () {
    testWidgets('al aplicar filtros el álbum y el contador reflejan solo los que cumplen', (
      tester,
    ) async {
      await mockNetworkImagesFor(() async {
        await coleccion.agregarPokemon(4);
        await montar(tester, coleccion);

        await elegir(tester, 'filtro_tipo', 'Fuego');
        await tocarEnLaBarra(tester, 'boton_agregar_filtros');

        expect(find.byType(TarjetaPokemonColeccion), findsNWidgets(2));
        expect(find.text('1/2 de tipo fuego'), findsOneWidget);
      });
    });

    testWidgets('si ningún pokemon cumple los filtros se informa al jugador', (
      tester,
    ) async {
      await mockNetworkImagesFor(() async {
        await montar(tester, coleccion);

        await elegir(tester, 'filtro_generacion', 'Generación 2');
        await elegir(tester, 'filtro_tipo', 'Agua');
        await tocarEnLaBarra(tester, 'boton_agregar_filtros');

        expect(find.byType(TarjetaPokemonColeccion), findsNothing);
        expect(
          find.text('No hay pokemons que cumplan los filtros.'),
          findsOneWidget,
        );
        expect(find.text('0/0 de tipo agua y generación 2'), findsOneWidget);
      });
    });

    testWidgets('restablecer vuelve a mostrar la colección completa', (
      tester,
    ) async {
      await mockNetworkImagesFor(() async {
        await coleccion.agregarPokemon(4);
        await montar(tester, coleccion);
        await elegir(tester, 'filtro_tipo', 'Fuego');
        await tocarEnLaBarra(tester, 'boton_agregar_filtros');
        expect(find.byType(TarjetaPokemonColeccion), findsNWidgets(2));

        await tocarEnLaBarra(tester, 'boton_restablecer_filtros');

        expect(find.byType(TarjetaPokemonColeccion), findsNWidgets(5));
        expect(find.text('1 de 5 obtenidos'), findsOneWidget);
      });
    });
  });

  group('Flujo de la colección - favoritos', () {
    testWidgets('marcar un favorito y ver solo los favoritos, y se mantienen al cerrar y abrir', (
      tester,
    ) async {
      await mockNetworkImagesFor(() async {
        await coleccion.agregarPokemon(4);
        await coleccion.agregarPokemon(155);
        await montar(tester, coleccion);

        await tester.tap(find.byKey(const ValueKey('estrella_4')));
        await tester.pump();
        expect(iconoDe('estrella_4', Icons.star), findsOneWidget);

        await tocarEnLaBarra(tester, 'boton_favoritos');
        expect(find.byType(TarjetaPokemonColeccion), findsNWidgets(1));
        expect(find.text('1/1 de favoritos'), findsOneWidget);

        await cerrarYAbrir(tester);

        expect(iconoDe('estrella_4', Icons.star), findsOneWidget);
        expect(iconoDe('estrella_155', Icons.star_border), findsOneWidget);

        await tocarEnLaBarra(tester, 'boton_favoritos');
        expect(find.byType(TarjetaPokemonColeccion), findsNWidgets(1));
        expect(find.text('Charmander'), findsOneWidget);
        expect(find.text('1/1 de favoritos'), findsOneWidget);
      });
    });

    testWidgets('sin favoritos el botón muestra un mensaje', (tester) async {
      await mockNetworkImagesFor(() async {
        await coleccion.agregarPokemon(4);
        await montar(tester, coleccion);

        await tocarEnLaBarra(tester, 'boton_favoritos');

        expect(
          find.text(
            'Aún no tienes favoritos. Marca la estrella de un pokemon '
            'obtenido para agregarlo.',
          ),
          findsOneWidget,
        );
      });
    });
  });
}