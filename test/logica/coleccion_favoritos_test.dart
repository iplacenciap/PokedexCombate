import 'package:flutter_test/flutter_test.dart';
import 'package:proyecto_pokedex/logica/coleccion_servicio.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ColeccionServicio coleccion;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    coleccion = ColeccionServicio();
  });

  test('empieza sin favoritos', () {
    expect(coleccion.cantidadFavoritos, 0);
    expect(coleccion.idsFavoritos, isEmpty);
    expect(coleccion.esFavorito(25), false);
  });

  test('un pokemon obtenido se marca como favorito', () async {
    await coleccion.agregarPokemon(25);

    await coleccion.alternarFavorito(25);

    expect(coleccion.esFavorito(25), true);
    expect(coleccion.cantidadFavoritos, 1);
    expect(coleccion.idsFavoritos, {25});
  });

  test('al alternar otra vez se quita de favoritos', () async {
    await coleccion.agregarPokemon(25);

    await coleccion.alternarFavorito(25);
    await coleccion.alternarFavorito(25);

    expect(coleccion.esFavorito(25), false);
    expect(coleccion.cantidadFavoritos, 0);
  });

  test('un pokemon no obtenido no puede ser favorito', () async {
    await coleccion.alternarFavorito(25);

    expect(coleccion.esFavorito(25), false);
    expect(coleccion.cantidadFavoritos, 0);
  });

  test('notifica al cambiar un favorito, pero no si no se pudo marcar', () async {
    await coleccion.agregarPokemon(25);
    var llamadas = 0;
    coleccion.addListener(() => llamadas++);

    await coleccion.alternarFavorito(25);
    await coleccion.alternarFavorito(99);

    expect(llamadas, 1);
  });

  test('guarda en las preferencias con la llave coleccion_favoritos', () async {
    await coleccion.agregarPokemon(25);
    await coleccion.agregarPokemon(4);

    await coleccion.alternarFavorito(25);

    final preferencias = await SharedPreferences.getInstance();
    expect(preferencias.getStringList('coleccion_favoritos'), ['25']);
  });

  test('al quitar el último favorito se guarda la lista vacía', () async {
    await coleccion.agregarPokemon(25);
    await coleccion.alternarFavorito(25);

    await coleccion.alternarFavorito(25);

    final preferencias = await SharedPreferences.getInstance();
    expect(preferencias.getStringList('coleccion_favoritos'), isEmpty);
  });

  test('los favoritos se mantienen al crear un servicio nuevo', () async {
    await coleccion.agregarPokemon(25);
    await coleccion.agregarPokemon(4);
    await coleccion.alternarFavorito(4);

    final otraSesion = ColeccionServicio();
    await otraSesion.cargar();

    expect(otraSesion.idsObtenidos, {25, 4});
    expect(otraSesion.idsFavoritos, {4});
  });

  test('al cargar ignora favoritos inválidos o que no están obtenidos', () async {
    SharedPreferences.setMockInitialValues({
      'coleccion_ids': ['4'],
      'coleccion_favoritos': ['4', '9', 'abc'],
    });

    await coleccion.cargar();

    expect(coleccion.idsFavoritos, {4});
  });

  test('si falla el guardado al marcar, el favorito se revierte', () async {
    final fallida = ColeccionServicio(
      persistirFavoritos: () async => throw Exception('fallo al guardar'),
    );
    await fallida.agregarPokemon(25);
    var llamadas = 0;
    fallida.addListener(() => llamadas++);

    await expectLater(
      fallida.alternarFavorito(25),
      throwsA(isA<Exception>()),
    );

    expect(fallida.esFavorito(25), false);
    expect(fallida.cantidadFavoritos, 0);
    expect(llamadas, 2);
  });

  test('si falla el guardado al quitar, el favorito se vuelve a marcar', () async {
    var fallar = false;
    final servicio = ColeccionServicio(
      persistirFavoritos: () async {
        if (fallar) {
          throw Exception('fallo al guardar');
        }
      },
    );
    await servicio.agregarPokemon(25);
    await servicio.alternarFavorito(25);
    fallar = true;

    await expectLater(
      servicio.alternarFavorito(25),
      throwsA(isA<Exception>()),
    );

    expect(servicio.esFavorito(25), true);
    expect(servicio.idsFavoritos, {25});
  });

  test('idsFavoritos no se puede modificar desde afuera', () async {
    await coleccion.agregarPokemon(25);
    await coleccion.alternarFavorito(25);

    expect(() => coleccion.idsFavoritos.add(2), throwsUnsupportedError);
  });
}