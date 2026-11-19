import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:proyecto_pokedex/widgets/boton_pokemon_aleatorio.dart';

void main(){

  testWidgets('Muestra el boton de pokemon aleatorio', (WidgetTester tester) async{

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: BotonPokemonAleatorio()
        )
      )
    );

    expect(find.text('Pokémon aleatorio'), findsOneWidget);
  });
}