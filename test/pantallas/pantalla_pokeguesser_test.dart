import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:proyecto_pokedex/datos/almacenamiento_perfil.dart';
import 'package:proyecto_pokedex/datos/perfil_jugador.dart';
import 'package:proyecto_pokedex/datos/pokemon.dart';
import 'package:proyecto_pokedex/logica/gestor_progreso.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:proyecto_pokedex/datos/pokemon_resumen.dart';
import 'package:proyecto_pokedex/pantallas/pantalla_pokeguesser.dart';
import 'package:proyecto_pokedex/utilidades/analizador_busqueda.dart';

final List<int> _pngTransparente = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==',
);

class _HttpOverridesFalsos extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) => _ClienteFalso();
}

class _ClienteFalso extends Fake implements HttpClient {
  @override
  bool autoUncompress = true;

  @override
  Future<HttpClientRequest> getUrl(Uri url) async => _SolicitudFalsa();
}

class _SolicitudFalsa extends Fake implements HttpClientRequest {
  @override
  final HttpHeaders headers = _CabecerasFalsas();

  @override
  Future<HttpClientResponse> close() async => _RespuestaFalsa();
}

class _CabecerasFalsas extends Fake implements HttpHeaders {
  @override
  void add(String name, Object value, {bool preserveHeaderCase = false}) {}
}

class _RespuestaFalsa extends Fake implements HttpClientResponse {
  @override
  int get statusCode => 200;

  @override
  int get contentLength => _pngTransparente.length;

  @override
  HttpClientResponseCompressionState get compressionState =>
      HttpClientResponseCompressionState.notCompressed;

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return Stream<List<int>>.value(_pngTransparente).listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }
}

Pokemon _pokemon(
  int id,
  String nombre, {
  List<String> tipos = const ['normal'],
}) {
  return Pokemon(
    id: id,
    nombre: nombre,
    urlImagen: 'https://example.com/$id.png',
    tipos: tipos,
    altura: 4,
    peso: 60,
    generacion: 'generation-i',
    descripcion: '',
    habilidades: ['static'],
    estadisticas: {'hp': 35, 'speed': 90},
  );
}

PokemonResumen _aResumen(Pokemon p) {
  return PokemonResumen(
    id: p.id,
    nombre: p.nombre.toUpperCase(),
    urlImagen: p.urlImagen,
    tipos: p.tipos,
    generacion: 1,
  );
}

final Pokemon _objetivo = _pokemon(25, 'pikachu', tipos: ['electric']);

final List<String> _nombresIncorrectos = [
  'bulbasaur',
  'charmander',
  'squirtle',
  'pidgey',
  'rattata',
  'sandshrew',
  'eevee',
];

final Map<String, Pokemon> _pokemonPorNombre = {
  for (int i = 0; i < _nombresIncorrectos.length; i++)
    _nombresIncorrectos[i]: _pokemon(i + 1, _nombresIncorrectos[i]),
  'pikachu': _objetivo,
};

final List<PokemonResumen> _listaDePrueba = _pokemonPorNombre.values
    .map(_aResumen)
    .toList();

const String _pista1 = 'El tipo principal de este Pokémon es eléctrico';
const String _pista2 =
    'Este Pokémon tiene un peso de 6.0 kg y una altura de 0.4 m';

class _AlmacenamientoPerfilConError extends AlmacenamientoPerfil {
  @override
  Future<void> guardarPerfil(PerfilJugador perfil) async {
    throw Exception('Error de almacenamiento simulado');
  }
}

Future<void> _montarPantalla(
  WidgetTester tester, {
  GestorProgreso? gestorProgreso,
}) async {
  tester.view.physicalSize = const Size(1400, 900);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    MaterialApp(
      home: PantallaPokeGuesser(
        getPokemon: () async => _objetivo,
        getListaPokemon: () async => _listaDePrueba,
        getPokemonPorNombre: (nombre) async =>
            _pokemonPorNombre[nombre.toLowerCase()]!,
        gestorProgreso: gestorProgreso,
      ),
    ),
  );
  await tester.pump();
}

Future<void> _pasarFrames(WidgetTester tester) async {
  for (int i = 0; i < 3; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> _comenzarPartida(
  WidgetTester tester, {
  GestorProgreso? gestorProgreso,
}) async {
  await _montarPantalla(tester, gestorProgreso: gestorProgreso);
  await tester.tap(find.text('Comenzar'));
  await _pasarFrames(tester);
}

Future<void> _intentar(WidgetTester tester, String nombre) async {
  await tester.enterText(find.byType(TextField), nombre);
  await tester.pump();
  await tester.pump();
  await tester.tap(find.widgetWithText(InkWell, nombre.toUpperCase()));
  await _pasarFrames(tester);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = _HttpOverridesFalsos();

  group('PantallaPokeGuesser - estado inicial', () {
    testWidgets('muestra el título y el botón Comenzar', (tester) async {
      await _montarPantalla(tester);

      expect(find.textContaining('adivinarlo?'), findsOneWidget);
      expect(find.text('Comenzar'), findsOneWidget);
    });

    testWidgets('el marcador empieza en 0 victorias y 0 derrotas', (
      tester,
    ) async {
      await _montarPantalla(tester);

      expect(find.text('Victorias: 0'), findsOneWidget);
      expect(find.text('Derrotas: 0'), findsOneWidget);
    });

    testWidgets('no hay campo de búsqueda antes de comenzar', (tester) async {
      await _montarPantalla(tester);

      expect(find.byType(TextField), findsNothing);
    });
  });

  group('PantallaPokeGuesser - partida', () {
    testWidgets('al comenzar se ve la primera pista y el campo de búsqueda', (
      tester,
    ) async {
      await _comenzarPartida(tester);

      expect(find.text(_pista1), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('al escribir se muestran sugerencias de la lista', (
      tester,
    ) async {
      await _comenzarPartida(tester);

      await tester.enterText(find.byType(TextField), 'bulba');
      await tester.pump();
      await tester.pump();

      expect(find.widgetWithText(InkWell, 'BULBASAUR'), findsOneWidget);
      expect(find.widgetWithText(InkWell, 'CHARMANDER'), findsNothing);
    });

    testWidgets(
      'un Pokémon ya intentado no vuelve a aparecer en las sugerencias',
      (tester) async {
        await _comenzarPartida(tester);

        await _intentar(tester, 'bulbasaur');

        await tester.enterText(find.byType(TextField), 'bulba');
        await tester.pump();
        await tester.pump();

        expect(find.byType(InkWell), findsNothing);
      },
    );

    testWidgets('un texto sin coincidencias no cuenta como intento', (
      tester,
    ) async {
      await _comenzarPartida(tester);

      await tester.enterText(find.byType(TextField), 'asdjhfhjdfuhdsfhia');
      await tester.pump();
      await tester.pump();
      expect(find.byType(InkWell), findsNothing);

      await tester.testTextInput.receiveAction(TextInputAction.done);
      await _pasarFrames(tester);

      expect(find.text(_pista1), findsOneWidget);
      expect(find.textContaining('peso de'), findsNothing);
    });

    testWidgets(
      'un intento incorrecto revela la siguiente pista y agrega el sprite al panel',
      (tester) async {
        await _comenzarPartida(tester);

        await _intentar(tester, 'bulbasaur');

        expect(find.text(_pista2), findsOneWidget);
        expect(find.text('• $_pista1'), findsOneWidget);
        expect(find.byType(Image), findsOneWidget);
      },
    );

    testWidgets('en el último intento disponible se muestra la silueta', (
      tester,
    ) async {
      await _comenzarPartida(tester);
      expect(find.byType(ColorFiltered), findsNothing);

      for (final nombre in _nombresIncorrectos.take(6)) {
        await _intentar(tester, nombre);
      }

      expect(find.byType(ColorFiltered), findsOneWidget);
    });

    testWidgets('adivinar el Pokémon muestra la victoria y suma al marcador', (
      tester,
    ) async {
      await _comenzarPartida(tester);

      await _intentar(tester, 'pikachu');

      expect(find.text('¡Victoria!'), findsOneWidget);
      expect(find.text('Experto'), findsOneWidget);

      await tester.tap(find.text('Experto'));
      await _pasarFrames(tester);

      expect(find.text('Victorias: 1'), findsOneWidget);
      expect(find.text('Derrotas: 0'), findsOneWidget);
    });

    testWidgets(
      'gastar todos los intentos muestra la derrota y suma al marcador',
      (tester) async {
        await _comenzarPartida(tester);

        for (final nombre in _nombresIncorrectos) {
          await _intentar(tester, nombre);
        }

        expect(find.text('Derrota'), findsOneWidget);
        expect(find.text('Reintentar'), findsOneWidget);

        await tester.tap(find.text('Reintentar'));
        await _pasarFrames(tester);

        expect(find.text('Derrotas: 1'), findsOneWidget);
        expect(find.text('Victorias: 0'), findsOneWidget);
      },
    );
  });

  group('PantallaPokeGuesser - progreso persistente', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets('una victoria se registra y se guarda una sola vez', (
      tester,
    ) async {
      final perfil = PerfilJugador();
      final gestor = GestorProgreso(perfil: perfil);
      await _comenzarPartida(tester, gestorProgreso: gestor);

      await _intentar(tester, 'pikachu');
      expect(find.text('¡Victoria!'), findsOneWidget);
      expect(perfil.progreso.pokeGuesser.partidasJugadas, 1);
      expect(perfil.progreso.pokeGuesser.victorias, 1);
      expect(perfil.progreso.pokeGuesser.derrotas, 0);

      // Más fotogramas o cerrar el modal no deben contar otra partida.
      await _pasarFrames(tester);
      await tester.tap(find.text('Experto'));
      await _pasarFrames(tester);
      expect(perfil.progreso.pokeGuesser.partidasJugadas, 1);

      final recuperado = await AlmacenamientoPerfil().cargarPerfil();
      expect(recuperado.progreso.pokeGuesser.partidasJugadas, 1);
      expect(recuperado.progreso.pokeGuesser.victorias, 1);
      expect(recuperado.progreso.pokeGuesser.derrotas, 0);
    });

    testWidgets('una derrota se registra y se guarda', (tester) async {
      final perfil = PerfilJugador();
      final gestor = GestorProgreso(perfil: perfil);
      await _comenzarPartida(tester, gestorProgreso: gestor);

      for (final nombre in _nombresIncorrectos) {
        await _intentar(tester, nombre);
      }

      expect(find.text('Derrota'), findsOneWidget);
      expect(perfil.progreso.pokeGuesser.partidasJugadas, 1);
      expect(perfil.progreso.pokeGuesser.victorias, 0);
      expect(perfil.progreso.pokeGuesser.derrotas, 1);

      final recuperado = await AlmacenamientoPerfil().cargarPerfil();
      expect(recuperado.progreso.pokeGuesser.partidasJugadas, 1);
      expect(recuperado.progreso.pokeGuesser.victorias, 0);
      expect(recuperado.progreso.pokeGuesser.derrotas, 1);
    });

    testWidgets('continúa las estadísticas previamente guardadas', (
      tester,
    ) async {
      final almacenamiento = AlmacenamientoPerfil();
      final anterior = PerfilJugador();
      anterior.progreso.pokeGuesser.registrarVictoria();
      await almacenamiento.guardarPerfil(anterior);

      final recuperado = await almacenamiento.cargarPerfil();
      final gestor = GestorProgreso(
        perfil: recuperado,
        almacenamiento: almacenamiento,
      );
      await _comenzarPartida(tester, gestorProgreso: gestor);
      await _intentar(tester, 'pikachu');

      final finalGuardado = await almacenamiento.cargarPerfil();
      expect(finalGuardado.progreso.pokeGuesser.partidasJugadas, 2);
      expect(finalGuardado.progreso.pokeGuesser.victorias, 2);
    });

    testWidgets('informa si no se pudo guardar sin ocultar la victoria', (
      tester,
    ) async {
      final perfil = PerfilJugador();
      final gestor = GestorProgreso(
        perfil: perfil,
        almacenamiento: _AlmacenamientoPerfilConError(),
      );
      await _comenzarPartida(tester, gestorProgreso: gestor);
      await _intentar(tester, 'pikachu');

      expect(find.text('¡Victoria!'), findsOneWidget);
      expect(
        find.text('La partida terminó, pero no se pudo guardar el progreso.'),
        findsOneWidget,
      );
      // La actualización ocurrió en memoria, pero el disco no fue actualizado.
      expect(perfil.progreso.pokeGuesser.partidasJugadas, 1);
      expect(perfil.progreso.pokeGuesser.victorias, 1);
      final recuperado = await AlmacenamientoPerfil().cargarPerfil();
      expect(recuperado.progreso.pokeGuesser.partidasJugadas, 0);
    });
  });

  group('analizarYFiltrarBusqueda - sugerencias del intento', () {
    test('texto sin sentido no devuelve coincidencias', () {
      final resultado = analizarYFiltrarBusqueda(
        allPokemon: _listaDePrueba,
        filtroNombre: 'asdjhfhjdfuhdsfhia',
      );

      expect(resultado, isEmpty);
    });

    test('un texto parcial devuelve los Pokémon que coinciden', () {
      final resultado = analizarYFiltrarBusqueda(
        allPokemon: _listaDePrueba,
        filtroNombre: 'chu',
      );

      expect(resultado.map((p) => p.nombre), ['PIKACHU']);
    });

    test('ignora mayúsculas y espacios alrededor', () {
      final resultado = analizarYFiltrarBusqueda(
        allPokemon: _listaDePrueba,
        filtroNombre: '  PIKA ',
      );

      expect(resultado.map((p) => p.nombre), ['PIKACHU']);
    });
  });
}
