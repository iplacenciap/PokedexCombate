import 'dart:math';

import 'combatiente.dart';
import 'dano_combate.dart';
import 'movimiento_ataque.dart';
import 'tipo_combate.dart';

enum BandoCombate { jugador, rival }

enum FaseCombate { elegirAcciones, sustituir, finalizado }

sealed class AccionCombate {
  const AccionCombate();
}

final class Atacar extends AccionCombate {
  const Atacar(this.indiceMovimiento);

  final int indiceMovimiento;
}

final class Forcejear extends AccionCombate {
  const Forcejear();
}

final class Cambiar extends AccionCombate {
  const Cambiar(this.indiceIntegrante);

  final int indiceIntegrante;
}

final class IntegranteEnCombate {
  const IntegranteEnCombate._(this.pokemon, this.ps, this.pp);

  factory IntegranteEnCombate._inicial(Combatiente pokemon) =>
      IntegranteEnCombate._(
        pokemon,
        pokemon.atributos.psMaximos,
        List.unmodifiable(
          pokemon.movimientos.map((movimiento) => movimiento.ppMaximos),
        ),
      );

  final Combatiente pokemon;
  final int ps;
  final List<int> pp;
  IntegranteEnCombate _con({int? ps, List<int>? pp}) =>
      IntegranteEnCombate._(pokemon, ps ?? this.ps, pp ?? this.pp);

  bool get debilitado => ps == 0;
  bool get requiereForcejeo => pp.every((restantes) => restantes == 0);
}

final class EquipoEnCombate {
  EquipoEnCombate._(
    Iterable<IntegranteEnCombate> integrantes,
    this.indiceActivo,
  ) : integrantes = List.unmodifiable(integrantes);

  factory EquipoEnCombate._inicial(EquipoCombate equipo) => EquipoEnCombate._(
    equipo.integrantes.map(IntegranteEnCombate._inicial),
    0,
  );

  final List<IntegranteEnCombate> integrantes;
  final int indiceActivo;

  IntegranteEnCombate get activo => integrantes[indiceActivo];
  bool get derrotado =>
      integrantes.every((integrante) => integrante.debilitado);

  Iterable<int> get reservasDisponibles sync* {
    for (var i = 0; i < integrantes.length; i++) {
      if (i != indiceActivo && !integrantes[i].debilitado) yield i;
    }
  }

  EquipoEnCombate _cambiar(int indice) =>
      EquipoEnCombate._(integrantes, indice);

  EquipoEnCombate _recibirDano(int dano) =>
      _actualizarActivo(activo._con(ps: max(0, activo.ps - dano)));

  EquipoEnCombate _gastarPP(int indice) {
    final restantes = List<int>.of(activo.pp);
    restantes[indice]--;
    return _actualizarActivo(activo._con(pp: List.unmodifiable(restantes)));
  }

  EquipoEnCombate _actualizarActivo(IntegranteEnCombate actualizado) {
    final copia = List<IntegranteEnCombate>.of(integrantes)
      ..[indiceActivo] = actualizado;
    return EquipoEnCombate._(copia, indiceActivo);
  }
}

final class EstadoCombate {
  const EstadoCombate._(this.jugador, this.rival, this.turnosResueltos);

  factory EstadoCombate.inicial({
    required EquipoCombate jugador,
    required EquipoCombate rival,
  }) => EstadoCombate._(
    EquipoEnCombate._inicial(jugador),
    EquipoEnCombate._inicial(rival),
    0,
  );

  final EquipoEnCombate jugador;
  final EquipoEnCombate rival;
  final int turnosResueltos;

  EquipoEnCombate equipo(BandoCombate bando) =>
      bando == BandoCombate.jugador ? jugador : rival;

  FaseCombate get fase {
    if (jugador.derrotado || rival.derrotado) return FaseCombate.finalizado;
    if (jugador.activo.debilitado || rival.activo.debilitado) {
      return FaseCombate.sustituir;
    }
    return FaseCombate.elegirAcciones;
  }

  BandoCombate? get ganador {
    if (jugador.derrotado == rival.derrotado) return null;
    return rival.derrotado ? BandoCombate.jugador : BandoCombate.rival;
  }

  EstadoCombate _conEquipo(BandoCombate bando, EquipoEnCombate equipo) =>
      bando == BandoCombate.jugador
      ? EstadoCombate._(equipo, rival, turnosResueltos)
      : EstadoCombate._(jugador, equipo, turnosResueltos);
}

sealed class EventoCombate {
  const EventoCombate();
}

final class PokemonCambiado extends EventoCombate {
  const PokemonCambiado(
    this.bando,
    this.ingresa, {
    required this.indiceIntegrante,
    required this.sustitucion,
  });

  final BandoCombate bando;
  final Combatiente ingresa;
  final int indiceIntegrante;
  final bool sustitucion;
}

final class AtaqueResuelto extends EventoCombate {
  const AtaqueResuelto({
    required this.bando,
    required this.bandoObjetivo,
    required this.atacante,
    required this.objetivo,
    required this.movimiento,
    required this.acerto,
    required this.dano,
    required this.efectividad,
    required this.psRestantes,
  });

  final BandoCombate bando;
  final BandoCombate bandoObjetivo;
  final Combatiente atacante;
  final Combatiente objetivo;
  final MovimientoAtaque movimiento;
  final bool acerto;
  final int dano;
  final double efectividad;
  final int psRestantes;
}

final class PokemonDebilitado extends EventoCombate {
  const PokemonDebilitado(this.bando, this.pokemon);

  final BandoCombate bando;
  final Combatiente pokemon;
}

final class DanoRetroceso extends EventoCombate {
  const DanoRetroceso(this.bando, this.pokemon, this.dano, this.psRestantes);

  final BandoCombate bando;
  final Combatiente pokemon;
  final int dano;
  final int psRestantes;
}

final class CombateFinalizado extends EventoCombate {
  const CombateFinalizado(this.ganador);

  final BandoCombate? ganador;
}

final class ResolucionCombate {
  ResolucionCombate._(this.estado, Iterable<EventoCombate> eventos)
    : eventos = List.unmodifiable(eventos);

  final EstadoCombate estado;
  final List<EventoCombate> eventos;
}

class MotorCombate {
  MotorCombate({Random? azar}) : _azar = azar ?? Random();

  final Random _azar;
  static final _forcejeo = MovimientoAtaque(
    id: 165,
    nombre: 'Forcejeo',
    tipo: TipoCombate.normal,
    categoria: CategoriaAtaque.fisico,
    poder: 50,
    ppMaximos: 1,
  );

  List<AccionCombate> accionesDisponibles(
    EstadoCombate estado,
    BandoCombate bando,
  ) {
    if (estado.fase != FaseCombate.elegirAcciones) return const [];
    final equipo = estado.equipo(bando);
    return [
      if (equipo.activo.requiereForcejeo)
        const Forcejear()
      else
        for (final (i, restantes) in equipo.activo.pp.indexed)
          if (restantes > 0) Atacar(i),
      for (final i in equipo.reservasDisponibles) Cambiar(i),
    ];
  }

  ResolucionCombate resolverTurno(
    EstadoCombate estado, {
    required AccionCombate jugador,
    required AccionCombate rival,
  }) {
    if (estado.fase != FaseCombate.elegirAcciones) {
      throw StateError('El combate no admite un turno de acciones');
    }
    _validarAccion(estado.jugador, jugador);
    _validarAccion(estado.rival, rival);

    final acciones = {BandoCombate.jugador: jugador, BandoCombate.rival: rival};
    final primero = _primerBando(estado, jugador, rival);
    final eventos = <EventoCombate>[];
    var siguiente = estado;
    for (final bando in [primero, _opuesto(primero)]) {
      final equipo = siguiente.equipo(bando);
      if (equipo.activo.debilitado ||
          siguiente.equipo(_opuesto(bando)).activo.debilitado) {
        continue;
      }
      switch (acciones[bando]!) {
        case Cambiar(:final indiceIntegrante):
          final actualizado = equipo._cambiar(indiceIntegrante);
          siguiente = siguiente._conEquipo(bando, actualizado);
          eventos.add(
            PokemonCambiado(
              bando,
              actualizado.activo.pokemon,
              indiceIntegrante: actualizado.indiceActivo,
              sustitucion: false,
            ),
          );
        case Atacar(:final indiceMovimiento):
          siguiente = _atacar(siguiente, bando, indiceMovimiento, eventos);
        case Forcejear():
          siguiente = _atacar(siguiente, bando, null, eventos);
      }
    }

    siguiente = EstadoCombate._(
      siguiente.jugador,
      siguiente.rival,
      estado.turnosResueltos + 1,
    );
    if (siguiente.fase == FaseCombate.finalizado) {
      eventos.add(CombateFinalizado(siguiente.ganador));
    }
    return ResolucionCombate._(siguiente, eventos);
  }

  ResolucionCombate resolverSustituciones(
    EstadoCombate estado, {
    int? jugador,
    int? rival,
  }) {
    if (estado.fase != FaseCombate.sustituir) {
      throw StateError('El combate no requiere sustituciones');
    }

    final indices = {BandoCombate.jugador: jugador, BandoCombate.rival: rival};
    var siguiente = estado;
    final eventos = <EventoCombate>[];
    for (final entrada in indices.entries) {
      final equipo = estado.equipo(entrada.key);
      final indice = entrada.value;
      if (!equipo.activo.debilitado && indice == null) continue;
      if (!equipo.activo.debilitado ||
          indice == null ||
          !equipo.reservasDisponibles.contains(indice)) {
        throw ArgumentError.value(
          indice,
          entrada.key.name,
          'Sustitución inválida',
        );
      }
      final actualizado = equipo._cambiar(indice);
      siguiente = siguiente._conEquipo(entrada.key, actualizado);
      eventos.add(
        PokemonCambiado(
          entrada.key,
          actualizado.activo.pokemon,
          indiceIntegrante: actualizado.indiceActivo,
          sustitucion: true,
        ),
      );
    }
    return ResolucionCombate._(siguiente, eventos);
  }

  EstadoCombate _atacar(
    EstadoCombate estado,
    BandoCombate bando,
    int? indiceMovimiento,
    List<EventoCombate> eventos,
  ) {
    final activo = estado.equipo(bando).activo;
    final atacante = activo.pokemon;
    final bandoObjetivo = _opuesto(bando);
    final objetivo = estado.equipo(bandoObjetivo);
    final esForcejeo = indiceMovimiento == null;
    final movimiento = esForcejeo
        ? _forcejeo
        : atacante.movimientos[indiceMovimiento];
    final conConsumo = esForcejeo
        ? estado
        : estado._conEquipo(
            bando,
            estado.equipo(bando)._gastarPP(indiceMovimiento),
          );
    final precision = movimiento.precision;
    final acerto =
        precision == null || precision == 100 || _azar.nextInt(100) < precision;
    final impacto = acerto
        ? calcularDano(
            atacante,
            objetivo.activo.pokemon,
            movimiento,
            variacion: 85 + _azar.nextInt(16),
            ignoraTipos: esForcejeo,
          )
        : (puntos: 0, efectividad: 1.0);
    final dano = min(objetivo.activo.ps, impacto.puntos);
    eventos.add(
      AtaqueResuelto(
        bando: bando,
        bandoObjetivo: bandoObjetivo,
        atacante: atacante,
        objetivo: objetivo.activo.pokemon,
        movimiento: movimiento,
        acerto: acerto,
        dano: dano,
        efectividad: impacto.efectividad,
        psRestantes: objetivo.activo.ps - dano,
      ),
    );
    if (dano == 0) return conConsumo;

    final actualizado = objetivo._recibirDano(dano);
    if (actualizado.activo.debilitado) {
      eventos.add(PokemonDebilitado(bandoObjetivo, actualizado.activo.pokemon));
    }
    final conGolpe = conConsumo._conEquipo(bandoObjetivo, actualizado);
    if (!esForcejeo) return conGolpe;

    final retroceso = min(activo.ps, max(1, atacante.atributos.psMaximos ~/ 4));
    final equipoTrasRetroceso = conGolpe.equipo(bando)._recibirDano(retroceso);
    eventos.add(
      DanoRetroceso(bando, atacante, retroceso, equipoTrasRetroceso.activo.ps),
    );
    if (equipoTrasRetroceso.activo.debilitado) {
      eventos.add(PokemonDebilitado(bando, atacante));
    }
    return conGolpe._conEquipo(bando, equipoTrasRetroceso);
  }

  void _validarAccion(EquipoEnCombate equipo, AccionCombate accion) {
    final valido = switch (accion) {
      Atacar(:final indiceMovimiento) =>
        indiceMovimiento >= 0 &&
            indiceMovimiento < equipo.activo.pp.length &&
            equipo.activo.pp[indiceMovimiento] > 0,
      Forcejear() => equipo.activo.requiereForcejeo,
      Cambiar(:final indiceIntegrante) => equipo.reservasDisponibles.contains(
        indiceIntegrante,
      ),
    };
    if (!valido) {
      throw ArgumentError.value(accion, 'accion', 'Acción no disponible');
    }
  }

  BandoCombate _primerBando(
    EstadoCombate estado,
    AccionCombate jugador,
    AccionCombate rival,
  ) {
    if ((jugador is Cambiar) != (rival is Cambiar)) {
      return jugador is Cambiar ? BandoCombate.jugador : BandoCombate.rival;
    }

    int prioridad(AccionCombate accion, EquipoEnCombate equipo) =>
        accion is Atacar
        ? equipo.activo.pokemon.movimientos[accion.indiceMovimiento].prioridad
        : 0;

    var orden = prioridad(
      jugador,
      estado.jugador,
    ).compareTo(prioridad(rival, estado.rival));
    if (orden == 0) {
      orden = estado.jugador.activo.pokemon.atributos.velocidad.compareTo(
        estado.rival.activo.pokemon.atributos.velocidad,
      );
    }
    if (orden == 0) {
      return _azar.nextBool() ? BandoCombate.jugador : BandoCombate.rival;
    }
    return orden > 0 ? BandoCombate.jugador : BandoCombate.rival;
  }

  BandoCombate _opuesto(BandoCombate bando) =>
      bando == BandoCombate.jugador ? BandoCombate.rival : BandoCombate.jugador;
}
