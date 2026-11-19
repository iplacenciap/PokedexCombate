import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:network_image_mock/network_image_mock.dart';
import 'package:proyecto_pokedex/colors/app_colors.dart';
import 'package:proyecto_pokedex/datos/pokemon_resumen.dart';
import 'package:proyecto_pokedex/widgets/tarjeta_pokemon_coleccion.dart';

void main() {
  final pikachu = PokemonResumen(
    id: 25,
    nombre: 'PIKACHU',
    urlImagen: 'https://ejemplo.com/pikachu.png',
    tipos: ['electric'],
    generacion: 1,
  );

  Future<void> montarTarjeta(
    WidgetTester tester, {
    required bool obtenido,
    VoidCallback? onTap,
  }) {
    return tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 150,
              height: 190,
              child: TarjetaPokemonColeccion(
                pokemon: pikachu,
                obtenido: obtenido,
                onTap: onTap,
              ),
            ),
          ),
        ),
      ),
    );
  }

  group('TarjetaPokemonColeccion - obtenido', () {
    testWidgets('muestra la imagen normal y el nombre', (tester) async {
      await mockNetworkImagesFor(() async {
        await montarTarjeta(tester, obtenido: true);
        expect(find.text('Pikachu'), findsOneWidget);
        expect(find.byType(Image), findsOneWidget);
        expect(find.byType(ColorFiltered), findsNothing);
      });
    });

    testWidgets('tiene el marco que lo destaca', (tester) async {
      await mockNetworkImagesFor(() async {
        await montarTarjeta(tester, obtenido: true);
        final material = tester.widget<Material>(
          find.ancestor(
            of: find.text('Pikachu'),
            matching: find.byWidgetPredicate(
              (widget) =>
                  widget is Material && widget.shape is RoundedRectangleBorder,
            ),
          ),
        );
        final forma = material.shape as RoundedRectangleBorder;
        expect(forma.side.color, PokedexAppColors.borde);
      });
    });

    testWidgets('al tocarlo ejecuta onTap', (tester) async {
      await mockNetworkImagesFor(() async {
        int toques = 0;
        await montarTarjeta(tester, obtenido: true, onTap: () => toques++);
        await tester.tap(find.text('Pikachu'));
        expect(toques, 1);
      });
    });
  });

  group('TarjetaPokemonColeccion - no obtenido', () {
    testWidgets('muestra la silueta y oculta el nombre', (tester) async {
      await mockNetworkImagesFor(() async {
        await montarTarjeta(tester, obtenido: false);
        expect(find.byType(ColorFiltered), findsOneWidget);
        expect(find.byType(Image), findsOneWidget);
        expect(find.text('Por descubrir'), findsOneWidget);
        expect(find.text('Pikachu'), findsNothing);
      });
    });

    testWidgets('no tiene marco interactivo', (tester) async {
      await mockNetworkImagesFor(() async {
        await montarTarjeta(tester, obtenido: false);
        expect(
          find.descendant(
            of: find.byType(TarjetaPokemonColeccion),
            matching: find.byType(Material),
          ),
          findsNothing,
        );
      });
    });

    testWidgets('al tocarlo no ocurre nada', (tester) async {
      await mockNetworkImagesFor(() async {
        int toques = 0;
        await montarTarjeta(tester, obtenido: false, onTap: () => toques++);
        await tester.tap(find.byType(TarjetaPokemonColeccion));
        expect(toques, 0);
        expect(find.byType(InkWell), findsNothing);
      });
    });
  });
}
