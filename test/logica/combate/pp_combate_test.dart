import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:proyecto_pokedex/logica/combate/combatiente.dart';
import 'package:proyecto_pokedex/logica/combate/motor_combate.dart';
import 'package:proyecto_pokedex/logica/combate/movimiento_ataque.dart';
import 'package:proyecto_pokedex/logica/combate/tipo_combate.dart';

MovimientoAtaque golpe(TipoCombate tipo, {int pp = 1, int? precision}) =>
    MovimientoAtaque(
      id: 1,
      nombre: 'Ataque',
      tipo: tipo,
      categoria: CategoriaAtaque.fisico,
      poder: 40,
      precision: precision,
      ppMaximos: pp,
    );

Combatiente pokemon(
  int id,
  TipoCombate tipo,
  MovimientoAtaque ataque, {
  int ps = 100,
}) => Combatiente(
  idPokemon: id,
  nombre: 'Pokémon $id',
  tipos: [tipo],
  atributos: AtributosCombate(
    psMaximos: ps,
    ataque: 40,
    defensa: 40,
    ataqueEspecial: 40,
    defensaEspecial: 40,
    velocidad: 100 - id,
  ),
  movimientos: [ataque],
);

EstadoCombate iniciar(List<Combatiente> jugador, List<Combatiente> rival) =>
    EstadoCombate.inicial(
      jugador: EquipoCombate(jugador),
      rival: EquipoCombate(rival),
    );

ResolucionCombate atacar(MotorCombate motor, EstadoCombate estado) => motor
    .resolverTurno(estado, jugador: const Atacar(0), rival: const Atacar(0));

class _AzarMaximo implements Random {
  @override
  bool nextBool() => true;

  @override
  double nextDouble() => 0.99;

  @override
  int nextInt(int max) => max - 1;
}

void main() {
  test('un fallo gasta PP y conserva la instantánea anterior', () {
    final motor = MotorCombate(azar: _AzarMaximo());
    final inicial = iniciar(
      [pokemon(1, TipoCombate.normal, golpe(TipoCombate.normal, precision: 1))],
      [pokemon(2, TipoCombate.fantasma, golpe(TipoCombate.fantasma))],
    );
    final jugado = atacar(motor, inicial);

    expect(jugado.eventos.whereType<AtaqueResuelto>().first.acerto, isFalse);
    expect(jugado.estado.jugador.activo.pp, [0]);
    expect(jugado.estado.rival.activo.pp, [0]);
    expect(jugado.estado.rival.activo.ps, 100);
    expect(inicial.jugador.activo.pp, [1]);
    expect(
      () => jugado.estado.jugador.activo.pp[0] = 1,
      throwsUnsupportedError,
    );
    expect(() => atacar(motor, jugado.estado), throwsArgumentError);
  });

  test('Forcejeo se habilita tras agotar PP, alcanza al fantasma y aplica retroceso', () {
    final motor = MotorCombate(azar: _AzarMaximo());
    final inicial = iniciar(
      [pokemon(1, TipoCombate.normal, golpe(TipoCombate.normal))],
      [pokemon(2, TipoCombate.fantasma, golpe(TipoCombate.fantasma, pp: 3))],
    );
    expect(
      () => motor.resolverTurno(
        inicial,
        jugador: const Forcejear(),
        rival: const Atacar(0),
      ),
      throwsArgumentError,
    );

    final agotado = atacar(motor, inicial).estado;
    expect(
      motor.accionesDisponibles(agotado, BandoCombate.jugador).single,
      isA<Forcejear>(),
    );

    final salida = motor.resolverTurno(
      agotado,
      jugador: const Forcejear(),
      rival: const Atacar(0),
    );
    final forcejeo = salida.eventos.whereType<AtaqueResuelto>().first;
    expect(forcejeo.movimiento.nombre, 'Forcejeo');
    expect(forcejeo.efectividad, 1);
    expect(forcejeo.dano, 14);
    expect(salida.eventos.whereType<DanoRetroceso>().single.dano, 25);
    expect(salida.estado.jugador.activo.ps, 75);
    expect(salida.estado.jugador.activo.pp, [0]);
    expect(salida.estado.rival.activo.ps, 86);
  });

  test(
    'el agotamiento se conserva al cambiar y el rival usa una acción válida',
    () {
      final motor = MotorCombate(azar: _AzarMaximo());
      final inicial = iniciar(
        [
          pokemon(1, TipoCombate.normal, golpe(TipoCombate.normal)),
          pokemon(2, TipoCombate.normal, golpe(TipoCombate.normal)),
        ],
        [pokemon(3, TipoCombate.fantasma, golpe(TipoCombate.fantasma))],
      );
      final agotado = atacar(motor, inicial).estado;
      expect(
        motor.accionesDisponibles(agotado, BandoCombate.rival).single,
        isA<Forcejear>(),
      );

      final cambio = motor.resolverTurno(
        agotado,
        jugador: const Cambiar(1),
        rival: const Forcejear(),
      );
      expect(cambio.estado.jugador.integrantes.first.pp, [0]);
      expect(cambio.estado.jugador.activo.pp, [1]);
      expect(
        cambio.eventos.whereType<AtaqueResuelto>().single.objetivo.idPokemon,
        2,
      );
    },
  );
  test('si el último Pokémon de ambos bandos cae por Forcejeo hay empate', () {
    final motor = MotorCombate(azar: _AzarMaximo());
    final inicial = iniciar(
      [pokemon(1, TipoCombate.normal, golpe(TipoCombate.normal), ps: 1)],
      [pokemon(2, TipoCombate.fantasma, golpe(TipoCombate.fantasma), ps: 5)],
    );
    final agotado = atacar(motor, inicial).estado;
    final desenlace = motor.resolverTurno(
      agotado,
      jugador: const Forcejear(),
      rival: const Forcejear(),
    );

    expect(desenlace.estado.fase, FaseCombate.finalizado);
    expect(desenlace.estado.ganador, isNull);
    expect(desenlace.eventos.whereType<AtaqueResuelto>(), hasLength(1));
    expect(desenlace.eventos.whereType<PokemonDebilitado>(), hasLength(2));
  });
}
