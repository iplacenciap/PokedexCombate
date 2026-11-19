import 'combatiente.dart';
import 'movimiento_ataque.dart';
import 'tipo_combate.dart';

final equipoJugadorPrueba = EquipoCombate([
  _pokemon(4, 'Charmander', [TipoCombate.fuego], (39, 52, 43, 60, 50, 65), [
    _pirotecnia,
    _aranazo,
    _ascuas,
  ]),
  _pokemon(7, 'Squirtle', [TipoCombate.agua], (44, 48, 65, 50, 64, 43), [
    _pistolaAgua,
    _placaje,
  ]),
]);

final equipoRivalPrueba = EquipoCombate([
  _pokemon(
    16,
    'Pidgey',
    [TipoCombate.normal, TipoCombate.volador],
    (40, 45, 40, 35, 35, 56),
    [_tornado, _ataqueRapido],
  ),
  _pokemon(
    74,
    'Geodude',
    [TipoCombate.roca, TipoCombate.tierra],
    (40, 80, 100, 30, 30, 20),
    [_lanzarrocas, _placaje],
  ),
]);

Combatiente _pokemon(
  int id,
  String nombre,
  List<TipoCombate> tipos,
  (int, int, int, int, int, int) base,
  List<MovimientoAtaque> movimientos,
) {
  final (ps, ataque, defensa, atEsp, defEsp, velocidad) = base;
  return Combatiente(
    idPokemon: id,
    nombre: nombre,
    tipos: tipos,
    atributos: AtributosCombate.desdeBase({
      'hp': ps,
      'attack': ataque,
      'defense': defensa,
      'special-attack': atEsp,
      'special-defense': defEsp,
      'speed': velocidad,
    }),
    movimientos: movimientos,
  );
}

MovimientoAtaque _movimiento(
  int id,
  String nombre,
  TipoCombate tipo,
  int poder, {
  required int pp,
  bool especial = false,
  int? precision = 100,
  int prioridad = 0,
}) => MovimientoAtaque(
  id: id,
  nombre: nombre,
  tipo: tipo,
  categoria: especial ? CategoriaAtaque.especial : CategoriaAtaque.fisico,
  poder: poder,
  precision: precision,
  prioridad: prioridad,
  ppMaximos: pp,
);

final _pirotecnia = _movimiento(
  481,
  'Pirotecnia',
  TipoCombate.fuego,
  70,
  pp: 15,
  especial: true,
);
final _aranazo = _movimiento(10, 'Arañazo', TipoCombate.normal, 40, pp: 35);
final _ascuas = _movimiento(
  52,
  'Ascuas',
  TipoCombate.fuego,
  40,
  pp: 25,
  especial: true,
);
final _pistolaAgua = _movimiento(
  55,
  'Pistola Agua',
  TipoCombate.agua,
  40,
  pp: 25,
  especial: true,
);
final _placaje = _movimiento(33, 'Placaje', TipoCombate.normal, 40, pp: 35);
final _tornado = _movimiento(
  16,
  'Tornado',
  TipoCombate.volador,
  40,
  pp: 35,
  especial: true,
);
final _ataqueRapido = _movimiento(
  98,
  'Ataque Rápido',
  TipoCombate.normal,
  40,
  pp: 30,
  prioridad: 1,
);
final _lanzarrocas = _movimiento(
  88,
  'Lanzarrocas',
  TipoCombate.roca,
  50,
  pp: 15,
  precision: 90,
);
