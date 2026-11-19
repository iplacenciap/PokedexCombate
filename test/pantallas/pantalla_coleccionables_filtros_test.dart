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

  List<PokemonResumen> crearMuchos(int cantidad) {
    return List.generate(
      cantidad,
      (i) => crear(i + 1, 'POKE_${i + 1}', ['normal'], 1),
    );
  }

  Future<void> montar(
    WidgetTester tester,
    List<PokemonResumen> lista,
  ) async {
    tester.view.physicalSize = const Size(1000, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final cache = PokemonSessionCacheService(
      fetchPokemonList: () async => lista,
      preloadImage: (_) async {},
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PantallaColeccionables(
            cacheService: cache,
            coleccion: coleccion,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
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

  Future<void> tocarBotonDeFiltros(WidgetTester tester, String clave) async {
    await desplegarFiltrosSiHaceFalta(tester, clave);
    final boton = find.byKey(ValueKey(clave));
    await tester.ensureVisible(boton);
    await tester.pumpAndSettle();
    await tester.tap(boton);
    await tester.pumpAndSettle();
  }

  Future<void> aplicar(WidgetTester tester) {
    return tocarBotonDeFiltros(tester, 'boton_agregar_filtros');
  }

  group('PantallaColeccionables - contador', () {
    testWidgets('muestra obtenidos/total y se actualiza', (tester) async {
      await mockNetworkImagesFor(() async {
        await coleccion.agregarPokemon(4);
        await montar(tester, crearLista());

        expect(find.byKey(const ValueKey('contador_coleccion')), findsOneWidget);
        expect(find.text('1 de 5 obtenidos'), findsOneWidget);

        await coleccion.agregarPokemon(155);
        await tester.pump();

        expect(find.text('2 de 5 obtenidos'), findsOneWidget);
      });
    });
  });

  group('PantallaColeccionables - flecha para volver arriba', () {
    testWidgets('no aparece al inicio', (tester) async {
      await mockNetworkImagesFor(() async {
        await montar(tester, crearMuchos(300));

        expect(find.byKey(const ValueKey('boton_volver_arriba')), findsNothing);
      });
    });

    testWidgets('aparece al bajar y al tocarla vuelve al inicio', (
      tester,
    ) async {
      await mockNetworkImagesFor(() async {
        await montar(tester, crearMuchos(300));
        final flecha = find.byKey(const ValueKey('boton_volver_arriba'));

        await tester.drag(find.byType(CustomScrollView), const Offset(0, -1500));
        await tester.pumpAndSettle();
        expect(flecha, findsOneWidget);

        await tester.tap(flecha);
        await tester.pumpAndSettle();

        final controlador = tester
            .widget<CustomScrollView>(find.byType(CustomScrollView))
            .controller!;
        expect(controlador.offset, 0);
        expect(flecha, findsNothing);
      });
    });
  });

  group('PantallaColeccionables - filtros', () {
    testWidgets('la barra de filtros es un SliverAppBar floating', (
      tester,
    ) async {
      await mockNetworkImagesFor(() async {
        await montar(tester, crearLista());

        final barra = tester.widget<SliverAppBar>(find.byType(SliverAppBar));
        expect(barra.floating, isTrue);
      });
    });

    testWidgets('se esconden al bajar y reaparecen al subir', (tester) async {
      await mockNetworkImagesFor(() async {
        await montar(tester, crearMuchos(300));
        final filtro = find.byKey(const ValueKey('filtros_coleccion'));
        expect(filtro, findsOneWidget);

        await tester.drag(find.byType(CustomScrollView), const Offset(0, -3000));
        await tester.pumpAndSettle();
        expect(filtro, findsNothing);

        final gesto = await tester.startGesture(
          tester.getCenter(find.byType(CustomScrollView)),
        );
        await gesto.moveBy(const Offset(0, 100));
        await tester.pump();
        await gesto.moveBy(const Offset(0, 100));
        await tester.pump();

        expect(filtro, findsOneWidget);

        await gesto.up();
        await tester.pumpAndSettle();
      });
    });

    testWidgets('elegir un filtro no cambia nada hasta presionar agregar', (
      tester,
    ) async {
      await mockNetworkImagesFor(() async {
        await coleccion.agregarPokemon(4);
        await montar(tester, crearLista());

        await elegir(tester, 'filtro_tipo', 'Fuego');

        expect(find.byType(TarjetaPokemonColeccion), findsNWidgets(5));
        expect(find.text('1 de 5 obtenidos'), findsOneWidget);
      });
    });

    testWidgets('filtra por tipo y el contador refleja el conteo filtrado', (
      tester,
    ) async {
      await mockNetworkImagesFor(() async {
        await coleccion.agregarPokemon(4);
        await montar(tester, crearLista());

        await elegir(tester, 'filtro_tipo', 'Fuego');
        await aplicar(tester);

        expect(find.byType(TarjetaPokemonColeccion), findsNWidgets(2));
        expect(find.text('1/2 de tipo fuego'), findsOneWidget);
      });
    });

    testWidgets('filtra por generación', (tester) async {
      await mockNetworkImagesFor(() async {
        await coleccion.agregarPokemon(155);
        await montar(tester, crearLista());

        await elegir(tester, 'filtro_generacion', 'Generación 2');
        await aplicar(tester);

        expect(find.byType(TarjetaPokemonColeccion), findsNWidgets(2));
        expect(find.text('1/2 de generación 2'), findsOneWidget);
      });
    });

    testWidgets('combina generación y tipo', (tester) async {
      await mockNetworkImagesFor(() async {
        await coleccion.agregarPokemon(4);
        await montar(tester, crearLista());

        await elegir(tester, 'filtro_generacion', 'Generación 1');
        await elegir(tester, 'filtro_tipo', 'Fuego');
        await aplicar(tester);

        expect(find.byType(TarjetaPokemonColeccion), findsNWidgets(1));
        expect(find.text('1/1 de tipo fuego y generación 1'), findsOneWidget);
      });
    });

    testWidgets('muestra un mensaje si ningún pokemon cumple los filtros', (
      tester,
    ) async {
      await mockNetworkImagesFor(() async {
        await montar(tester, crearLista());

        await elegir(tester, 'filtro_generacion', 'Generación 2');
        await elegir(tester, 'filtro_tipo', 'Agua');
        await aplicar(tester);

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
        await montar(tester, crearLista());

        await elegir(tester, 'filtro_tipo', 'Fuego');
        await aplicar(tester);
        expect(find.byType(TarjetaPokemonColeccion), findsNWidgets(2));

        await tocarBotonDeFiltros(tester, 'boton_restablecer_filtros');

        expect(find.byType(TarjetaPokemonColeccion), findsNWidgets(5));
        expect(find.text('1 de 5 obtenidos'), findsOneWidget);
      });
    });
  });
}