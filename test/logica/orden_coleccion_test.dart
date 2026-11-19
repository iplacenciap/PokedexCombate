import 'package:flutter_test/flutter_test.dart';
import 'package:proyecto_pokedex/datos/pokemon_resumen.dart';
import 'package:proyecto_pokedex/logica/orden_coleccion.dart';

void main() {
  PokemonResumen crear(int id) {
    return PokemonResumen(
      id: id,
      nombre: 'POKE_$id',
      urlImagen: '',
      tipos: ['normal'],
      generacion: 1,
    );
  }

  final pokemones = [for (final id in [1, 4, 7, 25, 150]) crear(id)];

  List<int> ids(List<PokemonResumen> lista) => lista.map((p) => p.id).toList();

  test('sin obtenidos deja todo ordenado por número', () {
    final resultado = ordenarColeccion(
      pokemones,
      estaObtenido: (id) => false,
    );

    expect(ids(resultado), [1, 4, 7, 25, 150]);
  });

  test('los obtenidos van primero y cada grupo va por número', () {
    final obtenidos = {25, 4};

    final resultado = ordenarColeccion(
      pokemones,
      estaObtenido: obtenidos.contains,
    );

    expect(ids(resultado), [4, 25, 1, 7, 150]);
  });

  test('los nuevos van antes que los obtenidos, el más reciente primero', () {
    final obtenidos = {4, 25, 150};

    final resultado = ordenarColeccion(
      pokemones,
      estaObtenido: obtenidos.contains,
      idsNuevos: [25, 150],
    );

    expect(ids(resultado), [150, 25, 4, 1, 7]);
  });

  test('un nuevo que ya no está obtenido se trata como oculto', () {
    final obtenidos = {4};

    final resultado = ordenarColeccion(
      pokemones,
      estaObtenido: obtenidos.contains,
      idsNuevos: [25],
    );

    expect(ids(resultado), [4, 1, 7, 25, 150]);
  });

  test('ordena aunque la lista original venga desordenada', () {
    final desordenados = [crear(25), crear(1), crear(150), crear(4)];
    final obtenidos = {25, 4};

    final resultado = ordenarColeccion(
      desordenados,
      estaObtenido: obtenidos.contains,
    );

    expect(ids(resultado), [4, 25, 1, 150]);
  });

  test('no modifica la lista original', () {
    final original = [crear(7), crear(1)];

    ordenarColeccion(original, estaObtenido: (id) => id == 7);

    expect(ids(original), [7, 1]);
  });
}