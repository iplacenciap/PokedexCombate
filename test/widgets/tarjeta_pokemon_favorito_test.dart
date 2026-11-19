import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:network_image_mock/network_image_mock.dart';
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
    bool esFavorito = false,
    VoidCallback? onTap,
    VoidCallback? onFavorito,
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
                esFavorito: esFavorito,
                onTap: onTap,
                onFavorito: onFavorito,
              ),
            ),
          ),
        ),
      ),
    );
  }

  final estrella = find.byKey(const ValueKey('estrella_25'));

  testWidgets('un obtenido tiene una estrella vacía si no es favorito', (
    tester,
  ) async {
    await mockNetworkImagesFor(() async {
      await montarTarjeta(tester, obtenido: true);

      expect(estrella, findsOneWidget);
      expect(find.byIcon(Icons.star_border), findsOneWidget);
      expect(find.byIcon(Icons.star), findsNothing);
    });
  });

  testWidgets('un obtenido favorito tiene la estrella rellena', (tester) async {
    await mockNetworkImagesFor(() async {
      await montarTarjeta(tester, obtenido: true, esFavorito: true);

      expect(find.byIcon(Icons.star), findsOneWidget);
      expect(find.byIcon(Icons.star_border), findsNothing);
    });
  });

  testWidgets('tocar la estrella llama onFavorito y no onTap', (tester) async {
    await mockNetworkImagesFor(() async {
      int favoritos = 0;
      int toques = 0;
      await montarTarjeta(
        tester,
        obtenido: true,
        onTap: () => toques++,
        onFavorito: () => favoritos++,
      );

      await tester.tap(estrella);

      expect(favoritos, 1);
      expect(toques, 0);
    });
  });

  testWidgets('un no obtenido no tiene estrella', (tester) async {
    await mockNetworkImagesFor(() async {
      await montarTarjeta(tester, obtenido: false, onFavorito: () {});

      expect(estrella, findsNothing);
      expect(find.byIcon(Icons.star_border), findsNothing);
      expect(find.byIcon(Icons.star), findsNothing);
    });
  });
}