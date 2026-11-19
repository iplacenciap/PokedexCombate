import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:proyecto_pokedex/datos/perfil_jugador.dart";
import "package:proyecto_pokedex/logica/gestor_progreso.dart";
import "package:proyecto_pokedex/widgets/top_nav_bar.dart";
import "package:shared_preferences/shared_preferences.dart";

void main() {
  group('TopNavBar Widget Tests', () {
    //Lista de secciones para testear.
    const List<String> testNombresSecciones = [
      'Página Principal',
      'Pokéguesser',
      'Placeholder 1',
      'Placeholder 2',
    ];
    testWidgets('Muestra los 4 textos requeridos', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: TopNavBar(
              indiceSeccionActual: 0,
              onTapSeccion: (_) {},
              nombresSecciones: testNombresSecciones,
              gestorProgreso: null,
            ),
          ),
        ),
      );

      expect(find.text('Página Principal'), findsOneWidget);
      expect(find.text('Pokéguesser'), findsOneWidget);
      expect(find.text('Placeholder 1'), findsOneWidget);
      expect(find.text('Placeholder 2'), findsOneWidget);
    });

    testWidgets('Dispara onTapSeccion solo en secciones no activas', (
      WidgetTester tester,
    ) async {
      int capturedIndex = -1; // Valor inicial por defecto

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: TopNavBar(
              indiceSeccionActual:
                  0, // Página Principal está activa por defecto
              onTapSeccion: (index) {
                capturedIndex = index;
              },
              nombresSecciones: testNombresSecciones,
              gestorProgreso: null,
            ),
          ),
        ),
      );

      //Click en Página Principal (índice 0, ya está activo)
      await tester.tap(find.text('Página Principal'));
      await tester.pumpAndSettle(); // Espera a que termine cualquier animación
      // Como onPressed es null, el capturedIndex debe seguir siendo -1
      expect(capturedIndex, -1);

      //Click en Pokéguesser (índice 1)
      await tester.ensureVisible(
        find.text('Pokéguesser'),
      ); // Hace scroll si es necesario
      await tester.pumpAndSettle();
      await tester.tap(find.text('Pokéguesser'));
      await tester.pumpAndSettle();
      expect(capturedIndex, 1);

      // Resetear la variable auxiliar
      capturedIndex = -1;

      //Click en Placeholder 1 (índice 2)
      await tester.ensureVisible(find.text('Placeholder 1'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Placeholder 1'));
      await tester.pumpAndSettle();
      expect(capturedIndex, 2);

      capturedIndex = -1;

      //Click en Placeholder 2 (índice 3)
      await tester.ensureVisible(find.text('Placeholder 2'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Placeholder 2'));
      await tester.pumpAndSettle();
      expect(capturedIndex, 3);
    });

    testWidgets("Muestra el saldo actualizado", (tester) async {
      SharedPreferences.setMockInitialValues({});
      final perfil = PerfilJugador();
      final gestor = GestorProgreso(perfil: perfil);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: TopNavBar(
              indiceSeccionActual:
                  0, // Página Principal está activa por defecto
              onTapSeccion: (_) {},
              nombresSecciones: testNombresSecciones,
              gestorProgreso: gestor,
            ),
          ),
        ),
      );

      expect(find.text('0'), findsOneWidget);

      await gestor.registrarResultadoPokeGuesser(
        victoria: true,
        recompensa: 500,
      );
      await tester.pump();

      expect(find.text('500'), findsOneWidget);
    });
  });
}
