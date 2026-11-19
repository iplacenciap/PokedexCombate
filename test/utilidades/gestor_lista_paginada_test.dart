import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:proyecto_pokedex/datos/pokemon_resumen.dart';
import 'package:proyecto_pokedex/utilidades/gestor_lista_paginada.dart';
import 'package:proyecto_pokedex/widgets/lista_pokemon_paginada.dart';

void main() {
  // Función auxiliar para generar datos de prueba.
  List<PokemonResumen> generarMockPokemones(int cantidad) {
    return List.generate(
      cantidad,
      (index) => PokemonResumen(id: index + 1, nombre: 'Pokemon ${index + 1}', urlImagen: '', tipos: ['Normal'], generacion: 1),
    );
  }

  // Función auxiliar para construir el widget en cada test.
  Future<void> montarGestor(WidgetTester tester, List<PokemonResumen> lista) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: GestorListaPaginada(
          listaCompleta: lista,
        ),
      ),
    ));
  }

  group('GestorListaPaginada - Cálculos de Paginación', () {
    testWidgets('Calcula correctamente el total de páginas cuando hay residuo', (WidgetTester tester) async {
      // 20 elementos / 15 = 1.33 -> Deberían ser 2 páginas
      final lista = generarMockPokemones(20);
      await montarGestor(tester, lista);

      var listaWidget = tester.widget<ListaPokemonPaginada>(find.byType(ListaPokemonPaginada));
      expect(listaWidget.totalPaginas, 2);
    });

    testWidgets('Calcula correctamente el total de páginas cuando no hay residuo', (WidgetTester tester) async {
      // 30 elementos / 15 = 2.0 -> Deberían ser exactamente 2 páginas (sin página extra vacía)
      final lista = generarMockPokemones(30);
      await montarGestor(tester, lista);

      var listaWidget = tester.widget<ListaPokemonPaginada>(find.byType(ListaPokemonPaginada));
      expect(listaWidget.totalPaginas, 2);
    });

    testWidgets('Maneja correctamente listas menores al límite de 15 elementos', (WidgetTester tester) async {
      final lista = generarMockPokemones(8);
      await montarGestor(tester, lista);

      var listaWidget = tester.widget<ListaPokemonPaginada>(find.byType(ListaPokemonPaginada));
      expect(listaWidget.totalPaginas, 1);
      expect(listaWidget.pokemones.length, 8);
    });
  });

  group('GestorListaPaginada - Estados y Sublistas', () {
    testWidgets('Se construye correctamente el primer bloque de 15 elementos en la página 1', (WidgetTester tester) async {
      final lista = generarMockPokemones(20);
      await montarGestor(tester, lista);

      var listaWidget = tester.widget<ListaPokemonPaginada>(find.byType(ListaPokemonPaginada));
      expect(listaWidget.paginaActual, 1);
      expect(listaWidget.pokemones.length, 15);
      expect(listaWidget.pokemones.first.nombre, 'Pokemon 1');
      expect(listaWidget.pokemones.last.nombre, 'Pokemon 15');
    });

    testWidgets('Se construye correctamente el residuo al avanzar a la última página', (WidgetTester tester) async {
      final lista = generarMockPokemones(20);
      await montarGestor(tester, lista);

      // Simular tap en el botón Siguiente
      final siguiente = find.widgetWithText(OutlinedButton, 'Siguiente').hitTestable();
      await tester.scrollUntilVisible(siguiente, 180);
      await tester.pumpAndSettle();
      await tester.tap(siguiente);
      await tester.pumpAndSettle();

      // Recapturar el widget tras la reconstrucción
      var listaWidget = tester.widget<ListaPokemonPaginada>(find.byType(ListaPokemonPaginada));
      
      expect(listaWidget.paginaActual, 2);
      expect(listaWidget.pokemones.length, 5); // Solo deben quedar los 5 restantes
      expect(listaWidget.pokemones.first.nombre, 'Pokemon 16');
      expect(listaWidget.pokemones.last.nombre, 'Pokemon 20');
    });
    
    testWidgets('Retrocede correctamente y restaura la lista anterior', (WidgetTester tester) async {
      final lista = generarMockPokemones(20);
      await montarGestor(tester, lista);

      // Avanzamos a la página 2
      final siguiente = find.widgetWithText(OutlinedButton, 'Siguiente').hitTestable();
      await tester.scrollUntilVisible(siguiente, 180);
      await tester.pumpAndSettle();
      await tester.tap(siguiente);
      await tester.pumpAndSettle();
      expect(tester.widget<ListaPokemonPaginada>(find.byType(ListaPokemonPaginada)).paginaActual, 2);
      
      // Retrocedemos a la página 1
      final anterior = find.widgetWithText(OutlinedButton, 'Anterior').hitTestable();
      await tester.scrollUntilVisible(anterior, 180);
      await tester.pumpAndSettle();
      await tester.tap(anterior);
      await tester.pumpAndSettle();

      var listaWidget = tester.widget<ListaPokemonPaginada>(find.byType(ListaPokemonPaginada));
      
      expect(listaWidget.paginaActual, 1);
      expect(listaWidget.pokemones.length, 15);
      expect(listaWidget.pokemones.first.nombre, 'Pokemon 1');
    });

    testWidgets('Reinicia la página al actualizar la lista por resultados más cortos', (WidgetTester tester) async {
      final lista = generarMockPokemones(20);
      await montarGestor(tester, lista);

      final siguiente = find.widgetWithText(OutlinedButton, 'Siguiente').hitTestable();
      await tester.scrollUntilVisible(siguiente, 180);
      await tester.pumpAndSettle();
      await tester.tap(siguiente);
      await tester.pumpAndSettle();
      expect(tester.widget<ListaPokemonPaginada>(find.byType(ListaPokemonPaginada)).paginaActual, 2);

      final nuevaLista = generarMockPokemones(8);
      await montarGestor(tester, nuevaLista);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);

      final listaWidget = tester.widget<ListaPokemonPaginada>(find.byType(ListaPokemonPaginada));
      expect(listaWidget.paginaActual, 1);
      expect(listaWidget.totalPaginas, 1);
      expect(listaWidget.pokemones.length, 8);
      expect(listaWidget.pokemones.first.nombre, 'Pokemon 1');
      expect(listaWidget.pokemones.last.nombre, 'Pokemon 8');
    });
  });
}
