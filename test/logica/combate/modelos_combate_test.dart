import 'package:flutter_test/flutter_test.dart';
import 'package:proyecto_pokedex/datos/pokemon.dart';
import 'package:proyecto_pokedex/logica/combate/combatiente.dart';
import 'package:proyecto_pokedex/logica/combate/movimiento_ataque.dart';
import 'package:proyecto_pokedex/logica/combate/tipo_combate.dart';

MovimientoAtaque ataque({int id = 1, int poder = 40, int? precision}) =>
    MovimientoAtaque(
      id: id,
      nombre: 'Placaje',
      tipo: TipoCombate.normal,
      categoria: CategoriaAtaque.fisico,
      poder: poder,
      precision: precision,
    );

final base = <String, int>{
  'hp': 34,
  'attack': 45,
  'defense': 50,
  'special-attack': 65,
  'special-defense': 80,
  'speed': 110,
};

Pokemon pokemon({int id = 1, Map<String, int>? estadisticas}) => Pokemon(
  id: id,
  nombre: 'Bulbasaur',
  urlImagen: '',
  tipos: ['grass', 'poison'],
  altura: 7,
  peso: 69,
  descripcion: '',
  habilidades: [],
  estadisticas: estadisticas ?? base,
  generacion: 'generation-i',
);

void main() {
  test('adapta tipos y los seis atributos de la ficha Pokémon', () {
    final combatiente = Combatiente.desdePokemon(
      pokemon(),
      movimientos: [ataque()],
    );

    expect(combatiente.idPokemon, 1);
    expect(combatiente.tipos, [TipoCombate.planta, TipoCombate.veneno]);
    final a = combatiente.atributos;
    expect(
      [
        a.psMaximos,
        a.ataque,
        a.defensa,
        a.ataqueEspecial,
        a.defensaEspecial,
        a.velocidad,
      ],
      [104, 75, 80, 95, 110, 140],
    );
  });

  test('rechaza atributos ausentes, no positivos y tipos desconocidos', () {
    expect(
      () => AtributosCombate.desdeBase({...base}..remove('defense')),
      throwsArgumentError,
    );
    expect(
      () => AtributosCombate.desdeBase({...base, 'speed': 0}),
      throwsArgumentError,
    );
    expect(() => TipoCombate.desdeApi('desconocido'), throwsArgumentError);
  });

  test('rechaza poder inválido y porcentajes fuera de rango', () {
    expect(() => ataque(poder: 0), throwsArgumentError);
    expect(() => ataque(precision: 0), throwsRangeError);
    expect(() => ataque(precision: 101), throwsRangeError);
    expect(ataque(precision: 1).precision, 1);
    expect(ataque(precision: 100).precision, 100);
    expect(ataque().precision, isNull);
  });

  test('acepta hasta cuatro movimientos distintos', () {
    Combatiente crear(List<MovimientoAtaque> movimientos) =>
        Combatiente.desdePokemon(pokemon(), movimientos: movimientos);

    expect(
      crear(List.generate(4, (i) => ataque(id: i + 1))).movimientos,
      hasLength(4),
    );
    expect(() => crear([]), throwsArgumentError);
    expect(() => crear([ataque(), ataque()]), throwsArgumentError);
    expect(
      () => crear(List.generate(5, (i) => ataque(id: i + 1))),
      throwsArgumentError,
    );
  });

  test('acepta equipos de un integrante y mantiene copias inmutables', () {
    final tipos = <TipoCombate>[TipoCombate.planta];
    final kit = [ataque()];
    final combatiente = Combatiente(
      idPokemon: 1,
      nombre: 'Bulbasaur',
      tipos: tipos,
      atributos: AtributosCombate.desdeBase(base),
      movimientos: kit,
    );
    final entradas = [combatiente];
    final equipo = EquipoCombate(entradas);

    tipos.clear();
    kit.clear();
    entradas.clear();
    expect(combatiente.tipos, [TipoCombate.planta]);
    expect(combatiente.movimientos, hasLength(1));
    expect(equipo.integrantes, [combatiente]);
    expect(() => equipo.integrantes.clear(), throwsUnsupportedError);
    expect(() => EquipoCombate([]), throwsArgumentError);
  });

  test('admite equipos de tamaños distintos y conserva el orden', () {
    final integrantes = List.generate(
      7,
      (indice) => Combatiente.desdePokemon(
        pokemon(id: indice + 1),
        movimientos: [ataque()],
      ),
    );
    final equipoCorto = EquipoCombate(integrantes.take(2));
    final equipoLargo = EquipoCombate(integrantes);

    expect(equipoCorto.integrantes.map((pokemon) => pokemon.idPokemon), [1, 2]);
    expect(equipoLargo.integrantes, orderedEquals(integrantes));
  });

  test('rechaza tipos repetidos o más de dos tipos', () {
    Combatiente crear(List<TipoCombate> tipos) => Combatiente(
      idPokemon: 1,
      nombre: 'Bulbasaur',
      tipos: tipos,
      atributos: AtributosCombate.desdeBase(base),
      movimientos: [ataque()],
    );

    expect(() => crear([]), throwsArgumentError);
    expect(
      () => crear([TipoCombate.planta, TipoCombate.planta]),
      throwsArgumentError,
    );
    expect(
      () => crear([TipoCombate.planta, TipoCombate.veneno, TipoCombate.bicho]),
      throwsArgumentError,
    );
  });
}
