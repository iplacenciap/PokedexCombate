import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:proyecto_pokedex/datos/perfil_jugador.dart';
import 'package:proyecto_pokedex/datos/pokemon_resumen.dart';
import 'package:proyecto_pokedex/logica/enums/dificultad_memorice.dart';
import 'package:proyecto_pokedex/pantallas/main_layout.dart';
import 'package:proyecto_pokedex/pantallas/pantalla_perfil.dart';
import 'package:proyecto_pokedex/widgets/lista_pokemon_paginada.dart';
import 'package:proyecto_pokedex/widgets/top_nav_bar.dart';

void main() {
  group('MainLayout Widget Tests', () {
    // Vistas de prueba originales para cada sección.
    const testViews = [
      Center(child: Text('Vista 0: Página Principal')),
      Center(child: Text('Vista 1: Pokéguesser')),
    ];

    Future<void> pumpMainLayout(WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: MainLayout(
            vistasSecciones: testViews,
            nombresSecciones: ['Página Principal', 'Pokéguesser'],
          ),
        ),
      );
    }

    Future<void> seleccionarSeccion(
      WidgetTester tester,
      String nombreSeccion,
    ) async {
      final boton = find.text(nombreSeccion);
      await tester.ensureVisible(boton);
      await tester.pumpAndSettle();
      await tester.tap(boton);
      await tester.pumpAndSettle();
    }

    testWidgets('Renderiza TopNavBar e inicia en el índice 0', (tester) async {
      await pumpMainLayout(tester);
      final barra = find.byType(TopNavBar);
      expect(barra, findsOneWidget);
      expect(tester.widget<TopNavBar>(barra).indiceSeccionActual, 0);
    });

    testWidgets('Renderiza IndexedStack e inicia en el índice 0', (
      tester,
    ) async {
      await pumpMainLayout(tester);
      final stack = find.byType(IndexedStack);
      expect(stack, findsOneWidget);
      expect(tester.widget<IndexedStack>(stack).index, 0);
    });

    testWidgets('Muestra únicamente la vista 0 por defecto en pantalla', (
      tester,
    ) async {
      await pumpMainLayout(tester);
      expect(find.text('Vista 0: Página Principal'), findsOneWidget);
      expect(find.text('Vista 1: Pokéguesser'), findsNothing);
    });

    testWidgets('Verificar navegar a Pokéguesser (Índice 1)', (tester) async {
      await pumpMainLayout(tester);
      await seleccionarSeccion(tester, 'Pokéguesser');
      expect(find.text('Vista 1: Pokéguesser'), findsOneWidget);
      expect(find.text('Vista 0: Página Principal'), findsNothing);
    });

    testWidgets('Verificar navegar a Página Principal (Índice 0)', (
      tester,
    ) async {
      await pumpMainLayout(tester);
      await seleccionarSeccion(tester, 'Pokéguesser');
      await seleccionarSeccion(tester, 'Página Principal');
      expect(find.text('Vista 0: Página Principal'), findsOneWidget);
      expect(find.text('Vista 1: Pokéguesser'), findsNothing);
    });

    testWidgets(
      'TopNavBar permanece fija al hacer scroll y no hay doble AppBar',
      (tester) async {
        final pokemones = List.generate(
          15,
          (i) => PokemonResumen(
            id: i + 1,
            nombre: 'Poke $i',
            urlImagen: '',
            tipos: ['grass'],
            generacion: 1,
          ),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: MainLayout(
              vistasSecciones: [
                ListaPokemonPaginada(
                  pokemones: pokemones,
                  paginaActual: 1,
                  totalPaginas: 1,
                  onAnterior: () {},
                  onSiguiente: () {},
                ),
                const SizedBox(),
              ],
            ),
          ),
        );

        expect(find.byType(AppBar), findsOneWidget);
        await tester.drag(find.byType(ListView), const Offset(0, -300));
        await tester.pumpAndSettle();
        expect(tester.getTopLeft(find.byType(TopNavBar)), Offset.zero);
      },
    );

    // Únicamente la navegación que se incorpora en la Task #94.

    testWidgets('Memorice conserva su pestaña y perfil se abre por el icono', (
      tester,
    ) async {
      // Simulamos una ventana de escritorio con espacio suficiente
      // para las tres secciones y el botón de perfil.
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1;

      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final perfil = PerfilJugador(nombreUsuario: 'Misty');

      await tester.pumpWidget(
        MaterialApp(
          home: MainLayout(
            vistasSecciones: [
              const Center(child: Text('Inicio de prueba')),
              const Center(child: Text('PokéGuesser de prueba')),
              const Center(child: Text('Memorice de prueba')),
              const Center(child: Text('Gacha de prueba')),
              PantallaPerfil(perfil: perfil),
            ],
            nombresSecciones: const [
              'Página Principal',
              'Pokéguesser',
              'Memorice',
              'Gacha',
            ],
          ),
        ),
      );

      final stack = find.byType(IndexedStack);
      final botonPerfil = find.byKey(const ValueKey('boton_perfil'));

      expect(find.text('Memorice'), findsOneWidget);
      expect(botonPerfil, findsOneWidget);
      expect(tester.widget<IndexedStack>(stack).index, 0);

      // Buscamos específicamente el botón de navegación de Memorice.
      final botonMemorice = find.ancestor(
        of: find.descendant(
          of: find.byType(TopNavBar),
          matching: find.text('Memorice'),
        ),
        matching: find.byType(TextButton),
      );

      expect(botonMemorice, findsOneWidget);

      await tester.ensureVisible(botonMemorice);
      await tester.pumpAndSettle();
      await tester.tap(botonMemorice);
      await tester.pumpAndSettle();


      // Memorice está en el índice 2.
      expect(tester.widget<IndexedStack>(stack).index, 2);
      expect(find.text('Memorice de prueba'), findsOneWidget);
      
      final botonGacha = find.ancestor(
        of: find.descendant(
          of: find.byType(TopNavBar),
          matching: find.text('Gacha'),
        ),
        matching: find.byType(TextButton),
      );

      await tester.tap(botonGacha);
      await tester.pumpAndSettle();

      // Gacha está en el índice 3.
      expect(tester.widget<IndexedStack>(stack).index, 3);
      expect(find.text('Gacha'), findsOneWidget);

      // El icono derecho abre el perfil.
      await tester.tap(botonPerfil);
      await tester.pumpAndSettle();

      expect(tester.widget<IndexedStack>(stack).index, 4);
      expect(find.text('Misty'), findsOneWidget);

      // Podemos regresar a Inicio.
      await tester.tap(find.text('Página Principal'));
      await tester.pumpAndSettle();

      expect(tester.widget<IndexedStack>(stack).index, 0);
      expect(find.text('Inicio de prueba'), findsOneWidget);
    });

    testWidgets('Al volver al perfil se muestran estadísticas nuevas', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final perfil = PerfilJugador();
      await tester.pumpWidget(
        MaterialApp(
          home: MainLayout(
            vistasSecciones: [
              const Center(child: Text('Inicio de prueba')),
              const Center(child: Text('PokéGuesser de prueba')),
              const Center(child: Text('Memorice de prueba')),
              const Center(child: Text('Gacha')),
              PantallaPerfil(perfil: perfil),
            ],
            nombresSecciones: const [
              'Página Principal',
              'Pokéguesser',
              'Memorice',
              'Gacha',
            ],
          ),
        ),
      );

      final perfilBoton = find.byKey(const ValueKey('boton_perfil'));
      await tester.tap(perfilBoton);
      await tester.pump();

      // Simula que la Task #93 actualizó el PerfilJugador compartido.
      // Se pulsa exclusivamente la pestaña, no el título de la tarjeta.
      final ventanaMemorice = find.descendant(
        of: find.byType(TopNavBar),
        matching: find.text('Memorice'),
      );
      await tester.tap(ventanaMemorice);
      await tester.pump();
      perfil.progreso.memorice.registrarSesion(
        victoria: true,
        dificultad: DificultadMemorice.facil,
        mejorCombo: 5,
      );

      await tester.tap(perfilBoton);
      await tester.pump();

      // Comprueba la actualización en pantalla, no solo en el modelo.
      final facil = find.byKey(const ValueKey('perfil_memorice_facil'));
      expect(facil, findsOneWidget);
      expect(
        find.descendant(of: facil, matching: find.text('1')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: facil, matching: find.text('5')),
        findsOneWidget,
      );
    });
  });
}
