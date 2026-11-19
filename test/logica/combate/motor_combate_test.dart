import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:proyecto_pokedex/logica/combate/combatiente.dart';
import 'package:proyecto_pokedex/logica/combate/motor_combate.dart';
import 'package:proyecto_pokedex/logica/combate/movimiento_ataque.dart';
import 'package:proyecto_pokedex/logica/combate/tipo_combate.dart';

MovimientoAtaque golpe({
  int poder = 40,
  int prioridad = 0,
  int? precision,
  CategoriaAtaque categoria = CategoriaAtaque.fisico,
}) => MovimientoAtaque(
  id: 1,
  nombre: 'Placaje',
  tipo: TipoCombate.normal,
  categoria: categoria,
  poder: poder,
  prioridad: prioridad,
  precision: precision,
);

Combatiente pokemon(
  int id, {
  int ps = 100,
  int velocidad = 50,
  MovimientoAtaque? movimiento,
  TipoCombate tipo = TipoCombate.normal,
}) => Combatiente(
  idPokemon: id,
  nombre: 'Pokémon $id',
  tipos: [tipo],
  atributos: AtributosCombate(
    psMaximos: ps,
    ataque: 40,
    defensa: 40,
    ataqueEspecial: 80,
    defensaEspecial: 20,
    velocidad: velocidad,
  ),
  movimientos: [movimiento ?? golpe()],
);

EstadoCombate batalla(List<Combatiente> jugador, List<Combatiente> rival) =>
    EstadoCombate.inicial(
      jugador: EquipoCombate(jugador),
      rival: EquipoCombate(rival),
    );

ResolucionCombate atacarAmbos(MotorCombate motor, EstadoCombate estado) => motor
    .resolverTurno(estado, jugador: const Atacar(0), rival: const Atacar(0));

class _AzarFijo implements Random {
  _AzarFijo({this.entero = 0, this.empate = true});

  final int entero;
  final bool empate;
  int llamadas = 0;

  @override
  bool nextBool() {
    llamadas++;
    return empate;
  }

  @override
  double nextDouble() {
    llamadas++;
    return 0.5;
  }

  @override
  int nextInt(int max) {
    llamadas++;
    return max == 16 ? 15 : entero;
  }
}

void main() {
  test('inicializa PS y conserva intacta la instantánea anterior', () {
    final motor = MotorCombate(azar: _AzarFijo());
    final inicial = batalla([pokemon(1)], [pokemon(2)]);

    final turno = atacarAmbos(motor, inicial);

    expect(inicial.turnosResueltos, 0);
    expect(inicial.jugador.activo.ps, 100);
    expect(inicial.rival.activo.ps, 100);
    expect(turno.estado.turnosResueltos, 1);
    expect(turno.estado.jugador.activo.ps, 82);
    expect(turno.estado.rival.activo.ps, 82);
    expect(turno.estado.ganador, isNull);
    expect(() => inicial.jugador.integrantes.clear(), throwsUnsupportedError);
    expect(() => turno.eventos.clear(), throwsUnsupportedError);
  });

  test(
    'prioridad supera velocidad y cancela el ataque al debilitar al rival',
    () {
      final motor = MotorCombate();
      final inicial = batalla(
        [
          pokemon(
            1,
            velocidad: 10,
            movimiento: golpe(poder: 400, prioridad: 1),
          ),
        ],
        [pokemon(2, ps: 8, velocidad: 90)],
      );

      final turno = atacarAmbos(motor, inicial);

      expect(turno.eventos.map((evento) => evento.runtimeType), [
        AtaqueResuelto,
        PokemonDebilitado,
        CombateFinalizado,
      ]);
      expect(turno.eventos.whereType<AtaqueResuelto>().single.dano, 8);
      expect(turno.estado.jugador.activo.ps, 100);
      expect(turno.estado.rival.activo.ps, 0);
      expect(turno.estado.ganador, BandoCombate.jugador);
      expect(turno.estado.fase, FaseCombate.finalizado);
      expect(() => atacarAmbos(motor, turno.estado), throwsStateError);
    },
  );

  test('usa velocidad y admite resultado de derrota del jugador', () {
    final inicial = batalla([pokemon(1, ps: 10)], [pokemon(2, velocidad: 51)]);
    final turno = atacarAmbos(MotorCombate(), inicial);

    expect(
      turno.eventos.whereType<AtaqueResuelto>().single.bando,
      BandoCombate.rival,
    );
    expect(turno.estado.ganador, BandoCombate.rival);
  });

  test('desempata con la fuente de azar inyectada', () {
    final inicial = batalla([pokemon(1)], [pokemon(2)]);
    final azar = _AzarFijo(empate: false);
    final turno = atacarAmbos(MotorCombate(azar: azar), inicial);

    expect(
      turno.eventos.whereType<AtaqueResuelto>().first.bando,
      BandoCombate.rival,
    );
    expect(azar.llamadas, 3);
  });

  test(
    'un cambio voluntario se aplica antes del ataque y cambia su objetivo',
    () {
      final motor = MotorCombate(azar: _AzarFijo());
      final inicial = batalla(
        [pokemon(1), pokemon(3)],
        [pokemon(2, movimiento: golpe(prioridad: 5))],
      );

      final turno = motor.resolverTurno(
        inicial,
        jugador: const Cambiar(1),
        rival: const Atacar(0),
      );

      final cambio = turno.eventos.first as PokemonCambiado;
      expect(cambio.sustitucion, isFalse);
      expect(
        turno.eventos.whereType<AtaqueResuelto>().single.objetivo.idPokemon,
        3,
      );
      expect(
        turno.estado.jugador.integrantes.map((integrante) => integrante.ps),
        [100, 82],
      );
    },
  );

  test(
    'un debilitamiento con reserva exige sustituir sin gastar otro turno',
    () {
      final motor = MotorCombate();
      final inicial = batalla(
        [pokemon(1, ps: 1), pokemon(3)],
        [pokemon(2, velocidad: 60)],
      );
      final pendiente = atacarAmbos(motor, inicial).estado;

      expect(pendiente.fase, FaseCombate.sustituir);
      expect(pendiente.ganador, isNull);
      expect(pendiente.jugador.reservasDisponibles, [1]);
      expect(motor.accionesDisponibles(pendiente, BandoCombate.rival), isEmpty);
      expect(() => atacarAmbos(motor, pendiente), throwsStateError);
      expect(
        () => motor.resolverSustituciones(pendiente, jugador: 0),
        throwsArgumentError,
      );
      expect(
        () => motor.resolverSustituciones(pendiente, jugador: 1, rival: 0),
        throwsArgumentError,
      );

      final reanudado = motor.resolverSustituciones(pendiente, jugador: 1);
      expect(reanudado.estado.fase, FaseCombate.elegirAcciones);
      expect(reanudado.estado.jugador.activo.pokemon.idPokemon, 3);
      expect(reanudado.estado.turnosResueltos, 1);
      expect((reanudado.eventos.single as PokemonCambiado).sustitucion, isTrue);
      expect(
        motor
            .accionesDisponibles(reanudado.estado, BandoCombate.jugador)
            .whereType<Cambiar>(),
        isEmpty,
      );
    },
  );

  test(
    'respeta precisión y usa estadísticas especiales para un ataque especial',
    () {
      final motor = MotorCombate(azar: _AzarFijo(entero: 79));
      final inicial = batalla(
        [pokemon(1, velocidad: 60, movimiento: golpe(precision: 79))],
        [pokemon(2, movimiento: golpe(categoria: CategoriaAtaque.especial))],
      );

      final turno = atacarAmbos(motor, inicial);
      final ataques = turno.eventos.whereType<AtaqueResuelto>().toList();

      expect(ataques.first.acerto, isFalse);
      expect(ataques.first.dano, 0);
      expect(ataques.last.acerto, isTrue);
      expect(ataques.last.dano, 63);
      expect(turno.estado.rival.activo.ps, 100);
      expect(turno.estado.jugador.activo.ps, 37);
    },
  );

  test(
    'un golpe inmune emite el evento sin cambiar PS ni impedir la respuesta',
    () {
      final motor = MotorCombate(azar: _AzarFijo());
      final inicial = batalla(
        [pokemon(1, velocidad: 65)],
        [pokemon(2, tipo: TipoCombate.fantasma)],
      );
      final turno = atacarAmbos(motor, inicial);
      final ataques = turno.eventos.whereType<AtaqueResuelto>().toList();

      expect(ataques.length, 2);
      expect(ataques.first.acerto, isTrue);
      expect(ataques.first.efectividad, 0);
      expect(ataques.first.dano, 0);
      expect(ataques.first.psRestantes, 100);
      expect(turno.estado.rival.activo.ps, 100);
    },
  );

  test(
    'rechaza acciones de ambos bandos antes de resolver o consumir azar',
    () {
      final azar = _AzarFijo();
      final motor = MotorCombate(azar: azar);
      final inicial = batalla([pokemon(1)], [pokemon(2)]);

      expect(
        () => motor.resolverTurno(
          inicial,
          jugador: const Atacar(0),
          rival: const Cambiar(0),
        ),
        throwsArgumentError,
      );
      expect(
        () => motor.resolverTurno(
          inicial,
          jugador: const Atacar(-1),
          rival: const Atacar(0),
        ),
        throwsArgumentError,
      );
      expect(azar.llamadas, 0);
      expect(inicial.jugador.activo.ps, 100);
      expect(inicial.rival.activo.ps, 100);
      expect(
        motor.accionesDisponibles(inicial, BandoCombate.jugador).single,
        isA<Atacar>(),
      );
    },
  );
}
