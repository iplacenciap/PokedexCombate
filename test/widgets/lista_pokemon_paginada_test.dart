import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:proyecto_pokedex/datos/pokemon_resumen.dart';
import 'package:proyecto_pokedex/widgets/lista_pokemon_paginada.dart';

void main() {
  // Datos de prueba (Mocks) compartidos para todos los tests
  final List<PokemonResumen> pokemonesPrueba = [
    PokemonResumen(id: 1, nombre: 'bulbasaur', urlImagen: 'url_falsa', tipos: ['planta', 'veneno'], generacion: 1),
    PokemonResumen(id: 2, nombre: 'ivysaur', urlImagen: 'url_falsa', tipos: ['planta'], generacion: 1),
  ];

  // Función de ayuda para montar el widget dentro de un MaterialApp (necesario en tests de Flutter)
  Widget crearWidgetDePrueba({
    void Function(PokemonResumen pokemon)? onPokemonTap,
    required int paginaActual,
    required int totalPaginas,
    VoidCallback? onAnterior,
    VoidCallback? onSiguiente,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: ListaPokemonPaginada(
          pokemones: pokemonesPrueba,
          paginaActual: paginaActual,
          totalPaginas: totalPaginas,
          onAnterior: onAnterior ?? () {},
          onSiguiente: onSiguiente ?? () {},
        ),
      ),
    );
  }

  testWidgets('Renderiza los Pokemon y el indicador de página correctamente', (WidgetTester tester) async {
    await tester.pumpWidget(crearWidgetDePrueba(paginaActual: 2, totalPaginas: 5));

    // Verificamos que los nombres aparezcan
    expect(find.text('bulbasaur'), findsOneWidget);
    expect(find.text('ivysaur'), findsOneWidget);
    
    // Verificamos el indicador
    expect(find.text('2/5'), findsOneWidget);
  });

  testWidgets('Deshabilita el botón "Anterior" si está en la página 1', (WidgetTester tester) async {
    await tester.pumpWidget(crearWidgetDePrueba(paginaActual: 1, totalPaginas: 3));

    // Encontramos el botón por su icono o texto
    final botonAnterior = tester.widget<OutlinedButton>(
      find.widgetWithText(OutlinedButton, 'Anterior')
    );

    // Si onPressed es null, Flutter desactiva el botón
    expect(botonAnterior.onPressed, isNull);
  });

  testWidgets('Deshabilita el botón "Siguiente" si está en la última página', (WidgetTester tester) async {
    await tester.pumpWidget(crearWidgetDePrueba(paginaActual: 3, totalPaginas: 3));

    final botonSiguiente = tester.widget<OutlinedButton>(
      find.widgetWithText(OutlinedButton, 'Siguiente')
    );

    expect(botonSiguiente.onPressed, isNull);
  });

  testWidgets('Ejecuta la función onSiguiente al presionar el botón habilitado', (WidgetTester tester) async {
    bool funcionEjecutada = false;

    await tester.pumpWidget(crearWidgetDePrueba(
      paginaActual: 1,
      totalPaginas: 5,
      onSiguiente: () {
        funcionEjecutada = true; // Si el botón funciona, esto cambiará a true
      },
    ));

    // Simulamos el toque del usuario en la pantalla
    await tester.tap(find.widgetWithText(OutlinedButton, 'Siguiente'));
    await tester.pump(); // Reconstruye el frame después del tap

    // Verificamos si se ejecutó.
    expect(funcionEjecutada, isTrue);
  });

  testWidgets('Ejecuta la función onAnterior al presionar el botón habilitado', (WidgetTester tester) async {
    bool funcionEjecutada = false;

    await tester.pumpWidget(crearWidgetDePrueba(
      paginaActual: 3,
      totalPaginas: 5,
      onAnterior: () {
        funcionEjecutada = true; // Si el botón funciona, esto cambiará a true
      },
    ));

    // Simulamos el toque del usuario en la pantalla
    await tester.tap(find.widgetWithText(OutlinedButton, 'Anterior'));
    await tester.pump(); // Reconstruye el frame después del tap

    // Verificamos si se ejecutó.
    expect(funcionEjecutada, isTrue);
  });
}
