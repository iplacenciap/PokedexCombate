import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:proyecto_pokedex/datos/almacenamiento_perfil.dart';
import 'package:proyecto_pokedex/datos/estadisticas_memorice.dart';
import 'package:proyecto_pokedex/datos/estadisticas_pokeguesser.dart';
import 'package:proyecto_pokedex/datos/perfil_jugador.dart';
import 'package:proyecto_pokedex/datos/pokemon_resumen.dart';
import 'package:proyecto_pokedex/datos/progreso_jugador.dart';
import 'package:proyecto_pokedex/logica/enums/dificultad_memorice.dart';
import 'package:proyecto_pokedex/pantallas/pantalla_perfil.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Future<void> montarPerfil(
    WidgetTester tester,
    PerfilJugador perfil, {
    int? monedas,
    int? coleccionados,
    int? totalDisponibles,
    List<PokemonResumen> favoritos = const [],
    ValueChanged<PokemonResumen>? onAbrirPokemon,
  }) async {
    tester.view.physicalSize = const Size(1400, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: PantallaPerfil(
          perfil: perfil,
          guardarPerfil: AlmacenamientoPerfil().guardarPerfil,
          saldoPokemonedas: monedas,
          cantidadPokemonColeccionados: coleccionados,
          totalPokemonDisponibles: totalDisponibles,
          favoritos: favoritos,
          onAbrirPokemon: onAbrirPokemon,
        ),
      ),
    );
  }

  group('PantallaPerfil - Task #94', () {
    testWidgets('muestra nombre, título inicial y avatar', (tester) async {
      await montarPerfil(tester, PerfilJugador(nombreUsuario: 'Misty'));
      expect(find.text('Misty'), findsOneWidget);
      expect(find.text('Entrenador Pokémon'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('editar_nombre_perfil')),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('titulo_perfil')), findsOneWidget);
      expect(find.byType(CircleAvatar), findsOneWidget);
      expect(find.textContaining('Logros'), findsNothing);
    });

    testWidgets('progreso general no inventa monedas ni colección', (
      tester,
    ) async {
      await montarPerfil(tester, PerfilJugador());
      expect(find.text('Progreso general'), findsOneWidget);
      expect(find.text('Pokémonedas'), findsOneWidget);
      expect(find.text('Pokémon coleccionados'), findsOneWidget);
      expect(find.text('—'), findsNWidgets(2));
      expect(find.text('Favoritos'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('perfil_favoritos_vacio')),
        findsOneWidget,
      );
    });

    testWidgets('muestra valores externos solo cuando se proporcionan', (
      tester,
    ) async {
      await montarPerfil(
        tester,
        PerfilJugador(),
        monedas: 35,
        coleccionados: 2,
        totalDisponibles: 10,
      );
      expect(find.text('35'), findsOneWidget);
      expect(find.text('2 / 10'), findsOneWidget);
    });

    testWidgets('muestra las estadísticas existentes de PokéGuesser', (
      tester,
    ) async {
      final perfil = PerfilJugador(
        progreso: ProgresoJugador(
          pokeGuesser: EstadisticasPokeGuesser(
            partidasJugadas: 5,
            victorias: 3,
            derrotas: 2,
          ),
        ),
      );
      await montarPerfil(tester, perfil);

      final tarjeta = find.byKey(const ValueKey('perfil_pokeguesser'));
      expect(tarjeta, findsOneWidget);
      for (final valor in ['5', '3', '2']) {
        expect(
          find.descendant(of: tarjeta, matching: find.text(valor)),
          findsOneWidget,
        );
      }
    });

    testWidgets('permite editar el nombre y guardar la modificación', (
      tester,
    ) async {
      final perfil = PerfilJugador();
      await montarPerfil(tester, perfil);

      await tester.tap(find.byKey(const ValueKey('editar_nombre_perfil')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('campo_nombre_perfil')),
        'Red',
      );
      await tester.tap(find.text('Guardar'));
      await tester.pumpAndSettle();

      expect(perfil.nombreUsuario, 'Red');
      expect(find.text('Red'), findsOneWidget);
      expect(
        (await AlmacenamientoPerfil().cargarPerfil()).nombreUsuario,
        'Red',
      );
    });

    testWidgets('no ofrece títulos desbloqueables ni logros', (tester) async {
      await montarPerfil(tester, PerfilJugador());
      expect(find.text('Entrenador Pokémon'), findsOneWidget);
      expect(find.text('Coleccionista'), findsNothing);
      expect(find.textContaining('Logros'), findsNothing);
      expect(find.byType(DropdownButton<String>), findsNothing);
    });

    testWidgets('muestra todos los favoritos y permite abrirlos', (
      tester,
    ) async {
      final favoritos = List.generate(
        7,
        (indice) => PokemonResumen(
          id: indice + 1,
          nombre: 'Favorito $indice',
          urlImagen: '',
          tipos: const ['normal'],
          generacion: 1,
        ),
      );
      PokemonResumen? seleccionado;
      await montarPerfil(
        tester,
        PerfilJugador(),
        favoritos: favoritos,
        onAbrirPokemon: (pokemon) => seleccionado = pokemon,
      );
      expect(find.text('Favorito 0'), findsOneWidget);
      expect(find.text('Favorito 5'), findsOneWidget);
      expect(find.text('Favorito 6'), findsOneWidget);
      await tester.tap(find.text('Favorito 0'));
      expect(seleccionado?.nombre, 'Favorito 0');
    });

    testWidgets('Memorice muestra las cuatro dificultades sin selector', (
      tester,
    ) async {
      final perfilOriginal = PerfilJugador(
        progreso: ProgresoJugador(
          memorice: EstadisticasMemorice(
            sesionesJugadas: 80,
            victorias: 40,
            derrotas: 40,
            porDificultad: {
              DificultadMemorice.facil: EstadisticasDificultadMemorice(
                victorias: 1,
                derrotas: 2,
                mejorCombo: 3,
              ),
              DificultadMemorice.normal: EstadisticasDificultadMemorice(
                victorias: 4,
                derrotas: 5,
                mejorCombo: 6,
              ),
              DificultadMemorice.dificil: EstadisticasDificultadMemorice(
                victorias: 7,
                derrotas: 8,
                mejorCombo: 9,
              ),
              DificultadMemorice.extremo: EstadisticasDificultadMemorice(
                victorias: 10,
                derrotas: 11,
                mejorCombo: 12,
              ),
            },
          ),
        ),
      );

      final almacenamiento = AlmacenamientoPerfil();
      await almacenamiento.guardarPerfil(perfilOriginal);
      final perfilGuardado = await almacenamiento.cargarPerfil();
      await montarPerfil(tester, perfilGuardado);

      final tarjeta = find.byKey(const ValueKey('perfil_memorice'));
      expect(tarjeta, findsOneWidget);
      expect(
        find.descendant(
          of: tarjeta,
          matching: find.byIcon(Icons.psychology_alt),
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('perfil_memorice_dificultad')),
        findsNothing,
      );

      final grupos = <DificultadMemorice, List<int>>{
        DificultadMemorice.facil: [1, 2, 3],
        DificultadMemorice.normal: [4, 5, 6],
        DificultadMemorice.dificil: [7, 8, 9],
        DificultadMemorice.extremo: [10, 11, 12],
      };

      for (final entrada in grupos.entries) {
        final grupo = find.byKey(
          ValueKey('perfil_memorice_${entrada.key.name}'),
        );
        expect(grupo, findsOneWidget);
        expect(
          find.descendant(
            of: grupo,
            matching: find.text('Dificultad ${entrada.key.nombre}'),
          ),
          findsOneWidget,
        );
        for (final titulo in ['Victorias', 'Derrotas', 'Mejor combo']) {
          expect(
            find.descendant(of: grupo, matching: find.text(titulo)),
            findsOneWidget,
          );
        }
        for (final valor in entrada.value) {
          expect(
            find.descendant(of: grupo, matching: find.text('$valor')),
            findsOneWidget,
          );
        }
      }
    });
  });
}
