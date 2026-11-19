import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:proyecto_pokedex/colors/app_colors.dart';
import 'package:proyecto_pokedex/pantallas/pantalla_inicio.dart';

void main() {
  group('Pantalla Inicio - Test Visual', () {
    Future<void> cargarPantalla(WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: PantallaInicio(pokemonesIniciales: [])),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('Debería mostrar el título de la aplicación', (
      WidgetTester tester,
    ) async {
      await cargarPantalla(tester);
      expect(find.text('Explora la\nPokédex'), findsOneWidget);
    });

    testWidgets('Debería mostrar el texto de ayuda del buscador', (
      WidgetTester tester,
    ) async {
      await cargarPantalla(tester);
      expect(find.text('Busca por nombre o número'), findsOneWidget);
    });

    testWidgets('Debería mostrar una barra de búsqueda', (
      WidgetTester tester,
    ) async {
      await cargarPantalla(tester);
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('Debería mostrar un icono de búsqueda en el campo', (
      WidgetTester tester,
    ) async {
      await cargarPantalla(tester);
      expect(
        find.descendant(
          of: find.byType(TextField),
          matching: find.byIcon(Icons.search),
        ),
        findsOneWidget,
      );
    });

    testWidgets('Debería usar el nuevo color de fondo', (
      WidgetTester tester,
    ) async {
      await cargarPantalla(tester);
      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, PokedexAppColors.marfil);
    });
  });
}
