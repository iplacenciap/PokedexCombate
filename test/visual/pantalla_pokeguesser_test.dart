import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:network_image_mock/network_image_mock.dart';
import 'package:proyecto_pokedex/pantallas/pantalla_pokeguesser.dart';

void main() {
  testWidgets(
    'La pantalla PokéGuesser carga la interfaz y marcadores en cero',
    (WidgetTester tester) async {
      await mockNetworkImagesFor(() async {
        await tester.pumpWidget(const MaterialApp(home: PantallaPokeGuesser()));

        await tester.pump();

        expect(find.text('¿Podrás adivinarlo?'), findsOneWidget);
        expect(find.text('Comenzar'), findsOneWidget);
        expect(find.text('Pokémon intentados'), findsOneWidget);

        expect(find.text('Victorias: 0'), findsOneWidget);
        expect(find.text('Derrotas: 0'), findsOneWidget);
      });
    },
  );
}
