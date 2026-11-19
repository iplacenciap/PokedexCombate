import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:proyecto_pokedex/api/pokedex_session_cache_service.dart';
import 'package:proyecto_pokedex/datos/perfil_jugador.dart';
import 'package:proyecto_pokedex/datos/pokemon_resumen.dart';
import 'package:proyecto_pokedex/logica/coleccion_servicio.dart';
import 'package:proyecto_pokedex/logica/gestor_progreso.dart';
import 'package:proyecto_pokedex/pantallas/pantalla_perfil_integrado.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  final catalogo = [
    PokemonResumen(
      id: 25,
      nombre: 'Pikachu',
      urlImagen: '',
      tipos: ['electric'],
      generacion: 1,
    ),
    PokemonResumen(
      id: 4,
      nombre: 'Charmander',
      urlImagen: '',
      tipos: ['fire'],
      generacion: 1,
    ),
    PokemonResumen(
      id: 1,
      nombre: 'Bulbasaur',
      urlImagen: '',
      tipos: ['grass'],
      generacion: 1,
    ),
  ];

  Future<void> montar(
    WidgetTester tester, {
    required GestorProgreso gestor,
    required ColeccionServicio coleccion,
    required VoidCallback abrirColeccion,
    required ValueChanged<PokemonResumen> abrirPokemon,
    Future<List<PokemonResumen>> Function()? obtenerCatalogo,
  }) async {
    tester.view.physicalSize = const Size(1400, 2400);
    tester.view.devicePixelRatio = 1;

    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final cache = PokemonSessionCacheService(
      fetchPokemonList: obtenerCatalogo ?? () async => catalogo,
      preloadImage: (_) async {},
    );

    await tester.pumpWidget(
      MaterialApp(
        home: PantallaPerfilIntegrado(
          gestorProgreso: gestor,
          coleccion: coleccion,
          cacheService: cache,
          guardarPerfil: gestor.almacenamiento.guardarPerfil,
          onAbrirColeccion: abrirColeccion,
          onAbrirPokemon: abrirPokemon,
        ),
      ),
    );

    await tester.pumpAndSettle();
  }

  testWidgets('muestra el saldo, colección y favoritos reales', (tester) async {
    final perfil = PerfilJugador(saldoMonedas: 850);
    final gestor = GestorProgreso(perfil: perfil);
    final coleccion = ColeccionServicio();

    await coleccion.agregarPokemon(25);
    await coleccion.alternarFavorito(25);

    await montar(
      tester,
      gestor: gestor,
      coleccion: coleccion,
      abrirColeccion: () {},
      abrirPokemon: (_) {},
    );

    expect(find.text('850'), findsOneWidget);
    expect(find.text('1 / 3'), findsOneWidget);
    expect(find.text('Pikachu'), findsOneWidget);
    expect(find.text('Charmander'), findsNothing);
  });

  testWidgets('se actualiza al gastar monedas y modificar la colección', (
    tester,
  ) async {
    final gestor = GestorProgreso(perfil: PerfilJugador(saldoMonedas: 850));
    final coleccion = ColeccionServicio();

    await montar(
      tester,
      gestor: gestor,
      coleccion: coleccion,
      abrirColeccion: () {},
      abrirPokemon: (_) {},
    );

    await gestor.gastarPokemonedas(400);
    await coleccion.agregarPokemon(4);
    await coleccion.alternarFavorito(4);
    await tester.pumpAndSettle();

    expect(find.text('450'), findsOneWidget);
    expect(find.text('1 / 3'), findsOneWidget);
    expect(find.text('Charmander'), findsOneWidget);

    await coleccion.alternarFavorito(4);
    await tester.pumpAndSettle();

    expect(find.text('Charmander'), findsNothing);

    expect(
      find.byKey(const ValueKey('perfil_favoritos_vacio')),
      findsOneWidget,
    );
  });

  testWidgets('permite abrir Coleccionables y la descripción del favorito', (
    tester,
  ) async {
    final gestor = GestorProgreso(perfil: PerfilJugador());
    final coleccion = ColeccionServicio();

    await coleccion.agregarPokemon(25);
    await coleccion.alternarFavorito(25);

    var vecesColeccion = 0;
    PokemonResumen? elegido;

    await montar(
      tester,
      gestor: gestor,
      coleccion: coleccion,
      abrirColeccion: () => vecesColeccion++,
      abrirPokemon: (pokemon) => elegido = pokemon,
    );

    await tester.tap(find.byKey(const ValueKey('perfil_coleccion')));

    expect(vecesColeccion, 1);

    await tester.tap(find.text('Pikachu'));

    expect(elegido?.id, 25);
  });

  // Verifica la corrección solicitada en la review de la PR #141.
  testWidgets('si falla el catálogo muestra error y conserva los demás datos', (
    tester,
  ) async {
    final gestor = GestorProgreso(perfil: PerfilJugador(saldoMonedas: 850));

    final coleccion = ColeccionServicio();

    // El Pokémon sí está obtenido y marcado como favorito.
    await coleccion.agregarPokemon(25);
    await coleccion.alternarFavorito(25);

    // Simulamos un fallo al descargar el catálogo.
    await montar(
      tester,
      gestor: gestor,
      coleccion: coleccion,
      abrirColeccion: () {},
      abrirPokemon: (_) {},
      obtenerCatalogo: () async {
        throw Exception('Error de conexión simulado');
      },
    );

    // Debe aparecer el mensaje de error.
    expect(
      find.byKey(const ValueKey('perfil_favoritos_error')),
      findsOneWidget,
    );

    // No debe mostrarse el mensaje de favoritos vacíos.
    expect(find.byKey(const ValueKey('perfil_favoritos_vacio')), findsNothing);

    // Las Pokémonedas siguen disponibles.
    expect(find.text('850'), findsOneWidget);

    // La cantidad de obtenidos sigue disponible,
    // aunque no pueda determinarse el total del catálogo.
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('perfil_coleccion')),
        matching: find.text('1'),
      ),
      findsOneWidget,
    );
  });
}
