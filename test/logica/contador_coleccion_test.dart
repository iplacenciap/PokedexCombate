import 'package:flutter_test/flutter_test.dart';
import 'package:proyecto_pokedex/logica/contador_coleccion.dart';

void main() {
  group('textoContador', () {
    test('sin filtros muestra obtenidos/total', () {
      expect(textoContador(obtenidos: 8, total: 1025), '8/1025');
    });

    test('con tipo agrega el nombre del tipo en español', () {
      expect(
        textoContador(obtenidos: 3, total: 18, tipo: 'fire'),
        '3/18 de tipo fuego',
      );
    });

    test('con generación agrega la generación', () {
      expect(
        textoContador(obtenidos: 5, total: 100, generacion: 2),
        '5/100 de generación 2',
      );
    });

    test('con tipo y generación junta ambas condiciones', () {
      expect(
        textoContador(obtenidos: 1, total: 12, tipo: 'electric', generacion: 1),
        '1/12 de tipo eléctrico y generación 1',
      );
    });

    test('con favoritos lo indica en el texto', () {
      expect(
        textoContador(obtenidos: 3, total: 3, soloFavoritos: true),
        '3/3 de favoritos',
      );
    });

    test('con favoritos y filtros junta las condiciones', () {
      expect(
        textoContador(
          obtenidos: 1,
          total: 1,
          tipo: 'fire',
          soloFavoritos: true,
        ),
        '1/1 de tipo fuego y favoritos',
      );
    });
  });

  test('nombresTipos tiene los 18 tipos', () {
    expect(nombresTipos.length, 18);
    expect(nombresTipos['fire'], 'Fuego');
  });
}