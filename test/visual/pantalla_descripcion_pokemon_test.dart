import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:network_image_mock/network_image_mock.dart';
import 'package:proyecto_pokedex/colors/app_colors.dart';
import 'package:proyecto_pokedex/datos/pokemon.dart';
import 'package:proyecto_pokedex/pantallas/pantalla_descripcion_pokemon.dart';
import 'package:proyecto_pokedex/widgets/elementos_pokedex.dart';

void main() {
  group('Pantalla Descripción Pokémon - Test Visual', () {
    final pokemonPrueba = Pokemon(
      id: 25,
      nombre: 'pikachu',
      urlImagen: 'https://ejemplo.com/pikachu.png',
      tipos: ['electric'],
      altura: 4,
      peso: 60,
      descripcion: 'Descripción de prueba.',
      habilidades: ['static'],
      estadisticas: {'hp': 50, 'attack': 100},
      generacion: 'generation-i',
    );

    Future<void> cargarPantalla(WidgetTester tester) async {
      await mockNetworkImagesFor(() async {
        await tester.pumpWidget(
          MaterialApp(home: PantallaDescripcionPokemon(pokemon: pokemonPrueba)),
        );
        await tester.pumpAndSettle();
      });
    }

    testWidgets('muestra el nombre y número en la ficha', (tester) async {
      await cargarPantalla(tester);

      expect(find.byType(AppBar), findsOneWidget);
      expect(find.text('Ficha Pokémon'), findsOneWidget);
      expect(find.text('Pikachu'), findsOneWidget);
      expect(find.text('#025'), findsOneWidget);
    });

    testWidgets('usa el fondo marfil del catálogo', (tester) async {
      await cargarPantalla(tester);

      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, PokedexAppColors.marfil);
    });

    testWidgets('muestra la ilustración en un panel del color del tipo', (tester) async {
      await cargarPantalla(tester);

      final portada = find.ancestor(
        of: find.byType(IlustracionPokemon),
        matching: find.byType(PanelPokedex),
      );
      expect(portada, findsOneWidget);
      expect(tester.widget<PanelPokedex>(portada).color, fondoTipoPokemon(['electric']));
    });

    testWidgets('muestra el tipo traducido, altura y peso', (tester) async {
      await cargarPantalla(tester);

      expect(find.text('Eléctrico'), findsOneWidget);
      expect(find.text('0.4 m'), findsOneWidget);
      expect(find.text('6.0 kg'), findsOneWidget);
    });

    testWidgets('muestra la generación formateada', (tester) async {
      await cargarPantalla(tester);

      expect(find.text('Generación'), findsOneWidget);
      expect(find.text('1'), findsOneWidget);
    });

    testWidgets('muestra descripción y habilidades', (tester) async {
      await cargarPantalla(tester);
      await tester.ensureVisible(find.text('Habilidades'));
      await tester.pumpAndSettle();

      expect(find.text('Descripción'), findsOneWidget);
      expect(find.text('Descripción de prueba.'), findsOneWidget);
      expect(find.text('Habilidades'), findsOneWidget);
      expect(find.text('static'), findsOneWidget);
    });

    testWidgets('muestra las estadísticas base', (tester) async {
      await cargarPantalla(tester);
      await tester.ensureVisible(find.text('Estadísticas base'));
      await tester.pumpAndSettle();

      expect(find.text('HP'), findsOneWidget);
      expect(find.text('50'), findsOneWidget);
      expect(find.text('ATTACK'), findsOneWidget);
      expect(find.text('100'), findsOneWidget);
    });
  });
}