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
    bool esNuevo = false,
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
                esNuevo: esNuevo,
                onTap: onTap,
              ),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('un obtenido nuevo muestra la etiqueta NUEVO', (tester) async {
    await mockNetworkImagesFor(() async {
      await montarTarjeta(tester, obtenido: true, esNuevo: true);

      expect(find.text('NUEVO'), findsOneWidget);
    });
  });

  testWidgets('un obtenido que no es nuevo no muestra la etiqueta', (
    tester,
  ) async {
    await mockNetworkImagesFor(() async {
      await montarTarjeta(tester, obtenido: true);

      expect(find.text('NUEVO'), findsNothing);
    });
  });

  testWidgets('un no obtenido nunca muestra la etiqueta', (tester) async {
    await mockNetworkImagesFor(() async {
      await montarTarjeta(tester, obtenido: false, esNuevo: true);

      expect(find.text('NUEVO'), findsNothing);
    });
  });

  testWidgets('tocar la etiqueta cuenta como tocar la tarjeta', (tester) async {
    await mockNetworkImagesFor(() async {
      int toques = 0;
      await montarTarjeta(
        tester,
        obtenido: true,
        esNuevo: true,
        onTap: () => toques++,
      );

      await tester.tap(find.text('NUEVO'), warnIfMissed: false);

      expect(toques, 1);
    });
  });
}