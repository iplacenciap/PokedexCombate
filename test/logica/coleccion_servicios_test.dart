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

  test('empieza vacía si no hay datos guardados', () async {
    await coleccion.cargar();

    expect(coleccion.cantidadObtenidos, 0);
    expect(coleccion.estaObtenido(25), false);
  });

  test('un pokemon nuevo se registra e informa nuevo', () async {
    final resultado = await coleccion.agregarPokemon(25);

    expect(resultado, ResultadoAgregar.nuevo);
    expect(coleccion.estaObtenido(25), true);
    expect(coleccion.cantidadObtenidos, 1);
  });

  test('un repetido no se duplica e informa repetido', () async {
    await coleccion.agregarPokemon(25);
    final resultado = await coleccion.agregarPokemon(25);

    expect(resultado, ResultadoAgregar.repetido);
    expect(coleccion.cantidadObtenidos, 1);
  });

  test('notifica solo cuando entra un pokemon nuevo', () async {
    var llamadas = 0;
    coleccion.addListener(() => llamadas++);

    await coleccion.agregarPokemon(1);
    await coleccion.agregarPokemon(1);

    expect(llamadas, 1);
  });

  test('guarda en las preferencias con la llave coleccion_ids', () async {
    await coleccion.agregarPokemon(4);
    await coleccion.agregarPokemon(7);

    final preferencias = await SharedPreferences.getInstance();
    expect(preferencias.getStringList('coleccion_ids'), ['4', '7']);
  });

  test('la colección se mantiene al crear un servicio nuevo', () async {
    await coleccion.agregarPokemon(4);
    await coleccion.agregarPokemon(7);

    final otraSesion = ColeccionServicio();
    await otraSesion.cargar();

    expect(otraSesion.idsObtenidos, {4, 7});
  });

  test('ignora valores guardados que no son números', () async {
    SharedPreferences.setMockInitialValues({
      'coleccion_ids': ['25', 'abc', '7'],
    });

    await coleccion.cargar();

    expect(coleccion.idsObtenidos, {25, 7});
  });

  test('idsObtenidos no se puede modificar desde afuera', () async {
    await coleccion.agregarPokemon(1);

    expect(() => coleccion.idsObtenidos.add(2), throwsUnsupportedError);
  });
}