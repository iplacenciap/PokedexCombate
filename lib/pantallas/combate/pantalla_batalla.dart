import 'package:flutter/material.dart';
import 'package:proyecto_pokedex/logica/combate/combatiente.dart';
import 'package:proyecto_pokedex/logica/combate/efectividad_tipos.dart';
import 'package:proyecto_pokedex/logica/combate/motor_combate.dart';
import 'package:proyecto_pokedex/logica/combate/movimiento_ataque.dart';

import 'campo_batalla.dart';
import 'controles_batalla.dart';
import 'elementos_batalla.dart';
import 'tema_batalla.dart';

typedef ElegirAccionRival = AccionCombate Function(
  EstadoCombate estado,
  List<AccionCombate> disponibles,
);

class PantallaBatalla extends StatefulWidget {
  const PantallaBatalla({
    super.key,
    required this.nombreDuelo,
    required this.nombreRival,
    required this.equipoRival,
    required this.equipo,
    this.elegirAccionRival,
  });

  final String nombreDuelo;
  final String nombreRival;
  final EquipoCombate equipoRival;
  final EquipoCombate equipo;
  final ElegirAccionRival? elegirAccionRival;

  @override
  State<PantallaBatalla> createState() => _PantallaBatallaState();
}

class _PantallaBatallaState extends State<PantallaBatalla>
    with SingleTickerProviderStateMixin {
  final _motor = MotorCombate();
  late var _estado = _inicial();
  List<EventoCombate> _eventos = [];
  late final _animacion = AnimationController(
    vsync: this,
    animationBehavior: AnimationBehavior.preserve,
    duration: const Duration(milliseconds: 430),
  );
  Map<BandoCombate, CombatienteEnEscena>? _visibles;
  final _bajasEnEscena = <BandoCombate, Set<int>>{};
  AtaqueResuelto? _ataqueEnEscena;
  String? _textoEnCurso;
  List<String>? _letrasEnCurso;
  bool _mostrarEquipo = false;
  int? _reservaSeleccionada;
  bool get _animando => _visibles != null;

  @override
  void dispose() {
    _animacion.dispose();
    super.dispose();
  }

  EstadoCombate _inicial() =>
      EstadoCombate.inicial(jugador: widget.equipo, rival: widget.equipoRival);

  Future<void> _aplicar(AccionCombate accion) async {
    if (_animando || _estado.fase != FaseCombate.elegirAcciones) return;
    final disponibles = _motor.accionesDisponibles(_estado, BandoCombate.rival);
    final resultado = _motor.resolverTurno(
      _estado,
      jugador: accion,
      rival:
          widget.elegirAccionRival?.call(_estado, disponibles) ??
          disponibles.first,
    );
    var estado = resultado.estado;
    final eventos = resultado.eventos.toList();
    if (estado.fase == FaseCombate.sustituir &&
        !estado.jugador.activo.debilitado) {
      final cambio = _motor.resolverSustituciones(
        estado,
        rival: estado.rival.reservasDisponibles.first,
      );
      estado = cambio.estado;
      eventos.addAll(cambio.eventos);
    }
    await _mostrarTurno(
      estado,
      eventos,
      reducirMovimiento: MediaQuery.disableAnimationsOf(context),
    );
  }

  Future<void> _mostrarTurno(
    EstadoCombate estado,
    List<EventoCombate> eventos, {
    required bool reducirMovimiento,
  }) async {
    setState(() {
      _visibles = {
        for (final bando in BandoCombate.values)
          bando: CombatienteEnEscena.deEquipo(_estado.equipo(bando)),
      };
      _eventos = [];
    });

    try {
      for (final evento in eventos) {
        if (evento is AtaqueResuelto) {
          await _escribirDialogo(
            '${nombreCombatiente(evento.atacante)} usó ${evento.movimiento.nombre}.',
            reducirMovimiento: reducirMovimiento,
          );
          if (!mounted) return;
          await _pausaDialogo(
            Duration(milliseconds: reducirMovimiento ? 540 : 250),
          );
          if (!mounted) return;
          if (!reducirMovimiento && evento.acerto && evento.efectividad > 0) {
            setState(() => _ataqueEnEscena = evento);
            await _animacion.forward(from: 0).orCancel;
            if (!mounted) return;
          }
        }

        setState(() {
          _ataqueEnEscena = null;
          _aplicarEventoVisual(evento);
          _eventos.add(evento);
        });
        await _escribirDialogo(
          _mensaje(evento),
          reducirMovimiento: reducirMovimiento,
        );
        if (!mounted) return;
        if (evento is! CombateFinalizado) {
          await _pausaDialogo(
            Duration(milliseconds: evento is AtaqueResuelto ? 850 : 420),
          );
          if (!mounted) return;
        }
      }
    } on TickerCanceled {
      return;
    }
    if (!mounted) return;
    setState(() {
      _estado = estado;
      _mostrarEquipo = false;
      _reservaSeleccionada = null;
      _visibles = null;
      _bajasEnEscena.clear();
      _ataqueEnEscena = null;
      _textoEnCurso = null;
      _eventos = eventos;
    });
  }

  Future<void> _escribirDialogo(
    String texto, {
    required bool reducirMovimiento,
  }) async {
    final letras = reducirMovimiento ? null : texto.characters.toList();
    setState(() {
      _textoEnCurso = texto;
      _letrasEnCurso = letras;
    });
    if (letras == null || letras.isEmpty) return;

    await _pausaDialogo(
      Duration(milliseconds: (letras.length * 16).clamp(80, 700)),
    );
    if (mounted) setState(() => _letrasEnCurso = null);
  }

  Future<void> _pausaDialogo(Duration duracion) {
    _animacion.value = 0;
    return _animacion.animateTo(1, duration: duracion).orCancel;
  }

  void _aplicarEventoVisual(EventoCombate evento) {
    final visibles = _visibles!;
    switch (evento) {
      case PokemonCambiado(:final bando, :final indiceIntegrante):
        visibles[bando] = CombatienteEnEscena.deEquipo(
          _estado.equipo(bando),
          indiceIntegrante,
        );
      case AtaqueResuelto(:final bandoObjetivo, :final psRestantes):
        visibles[bandoObjetivo] = visibles[bandoObjetivo]!.conPs(psRestantes);
      case DanoRetroceso(:final bando, :final psRestantes):
        visibles[bando] = visibles[bando]!.conPs(psRestantes);
      case PokemonDebilitado(:final bando):
        _bajasEnEscena
            .putIfAbsent(bando, () => {})
            .add(visibles[bando]!.indice);
      case CombateFinalizado():
        break;
    }
  }

  CombatienteEnEscena _visible(BandoCombate bando) =>
      _visibles?[bando] ?? CombatienteEnEscena.deEquipo(_estado.equipo(bando));

  List<bool> _equipoVisible(BandoCombate bando, CombatienteEnEscena activo) => [
    for (final (indice, integrante)
        in _estado.equipo(bando).integrantes.indexed)
      !integrante.debilitado &&
          !(_bajasEnEscena[bando]?.contains(indice) ?? false) &&
          (indice != activo.indice || activo.ps > 0),
  ];

  void _sustituir(int indice) {
    final cambio = _motor.resolverSustituciones(
      _estado,
      jugador: indice,
      rival: _estado.rival.activo.debilitado
          ? _estado.rival.reservasDisponibles.first
          : null,
    );
    setState(() {
      _estado = cambio.estado;
      _mostrarEquipo = false;
      _reservaSeleccionada = null;
      _eventos = [..._eventos, ...cambio.eventos];
    });
  }

  String _mensaje(EventoCombate evento) => switch (evento) {
    AtaqueResuelto(:final atacante, :final movimiento, acerto: false) =>
      '${nombreCombatiente(atacante)} usó ${movimiento.nombre} y falló.',
    AtaqueResuelto(:final atacante, :final movimiento, efectividad: 0) =>
      '${movimiento.nombre} de ${nombreCombatiente(atacante)} no tuvo efecto.',
    AtaqueResuelto(
      :final atacante,
      :final movimiento,
      :final dano,
      :final efectividad,
    ) =>
      '${nombreCombatiente(atacante)} usó ${movimiento.nombre} e infligió $dano PS.'
          '${efectividad > 1
              ? ' ¡Supereficaz!'
              : efectividad < 1
              ? ' Poco eficaz.'
              : ''}',
    PokemonDebilitado(:final pokemon) =>
      '${nombreCombatiente(pokemon)} se debilitó.',
    PokemonCambiado(:final ingresa, :final bando) =>
      bando == BandoCombate.jugador
          ? 'Enviaste a ${nombreCombatiente(ingresa)}.'
          : '${widget.nombreRival} envió a ${nombreCombatiente(ingresa)}.',
    DanoRetroceso(:final pokemon, :final dano) =>
      '${nombreCombatiente(pokemon)} perdió $dano PS por el retroceso.',
    CombateFinalizado(:final ganador) => switch (ganador) {
      BandoCombate.jugador => 'Ganaste el duelo.',
      BandoCombate.rival => '${widget.nombreRival} ganó el duelo.',
      null => 'El duelo terminó en empate.',
    },
  };

  EventoCombate? get _aviso {
    for (final evento in _eventos.reversed) {
      if (evento is CombateFinalizado ||
          evento is PokemonCambiado ||
          evento is PokemonDebilitado) {
        return evento;
      }
    }
    return _eventos.firstOrNull;
  }

  Widget _cuadroDialogo(EventoCombate? aviso, CombatienteEnEscena jugador) {
    final texto =
        _textoEnCurso ??
        (aviso == null
            ? '¿Qué hará ${nombreCombatiente(jugador.pokemon)}?'
            : _mensaje(aviso));
    return DecoratedBox(
      key: const ValueKey('dialogo_batalla'),
      decoration: const BoxDecoration(
        color: Color(0xFF172330),
        border: Border(top: BorderSide(color: TemaBatalla.acento, width: 2)),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 56),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 9),
          child: Semantics(liveRegion: true, child: _textoDialogo(texto)),
        ),
      ),
    );
  }

  Widget _textoDialogo(String texto) {
    final estilo = TemaBatalla.letra(19, fuerte: true);
    final letras = _letrasEnCurso;
    if (letras == null) return Text(texto, style: estilo);

    return AnimatedBuilder(
      animation: _animacion,
      builder: (context, child) {
        final visibles = (_animacion.value * letras.length).floor();
        return ExcludeSemantics(
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(text: letras.take(visibles).join()),
                TextSpan(
                  text: letras.skip(visibles).join(),
                  style: const TextStyle(color: Colors.transparent),
                ),
              ],
            ),
            style: estilo,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: TemaBatalla.fondo,
    appBar: AppBar(
      backgroundColor: TemaBatalla.hundido,
      foregroundColor: TemaBatalla.acento,
      surfaceTintColor: Colors.transparent,
      toolbarHeight: 48,
      title: Text('Combate', style: TemaBatalla.letra(20, fuerte: true)),
    ),
    body: SafeArea(
      child: LayoutBuilder(
        builder: (context, limites) {
          final compacto = limites.maxWidth < 580;
          final lateral = compacto ? 10.0 : 20.0;
          final aviso = _animando ? null : _aviso;
          final historial = _animando
              ? const <EventoCombate>[]
              : _eventos.where((evento) => evento != aviso);
          final jugador = _visible(BandoCombate.jugador);
          final rival = _visible(BandoCombate.rival);
          return Padding(
            padding: EdgeInsets.fromLTRB(lateral, 9, lateral, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Wrap(
                  spacing: 14,
                  runSpacing: 2,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  alignment: WrapAlignment.spaceBetween,
                  children: [
                    Text(
                      widget.nombreDuelo,
                      style: TemaBatalla.letra(
                        compacto ? 18 : 22,
                        fuerte: true,
                      ),
                    ),
                    Text(
                      'Contra ${widget.nombreRival} · '
                      'Turnos completados: ${_estado.turnosResueltos}',
                      style: TemaBatalla.letra(14, color: TemaBatalla.suave),
                    ),
                  ],
                ),
                const SizedBox(height: 9),
                Expanded(
                  child: MarcoBatalla(
                    fondo: TemaBatalla.metal,
                    padding: const EdgeInsets.all(3),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          key: const ValueKey('escenario_batalla'),
                          child: CampoBatalla(
                            jugador: jugador,
                            rival: rival,
                            equipoJugador: _equipoVisible(
                              BandoCombate.jugador,
                              jugador,
                            ),
                            equipoRival: _equipoVisible(
                              BandoCombate.rival,
                              rival,
                            ),
                            animacion: _animacion,
                            ataque: _ataqueEnEscena,
                          ),
                        ),
                        _cuadroDialogo(aviso, jugador),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: limites.maxHeight * .62,
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.bottomCenter,
                    child: SizedBox(
                      width: limites.maxWidth - lateral * 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _controles(),
                          if (historial.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            _registro(historial),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    ),
  );

  Widget _registro(Iterable<EventoCombate> historial) => MarcoBatalla(
    key: const ValueKey('registro_batalla'),
    fondo: TemaBatalla.hundido,
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
    child: Semantics(
      liveRegion: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final evento in historial)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Text(
                _mensaje(evento),
                style: TemaBatalla.letra(14, color: TemaBatalla.suave),
              ),
            ),
        ],
      ),
    ),
  );

  Widget _controles() {
    if (_estado.fase == FaseCombate.finalizado) {
      final titulo = switch (_estado.ganador) {
        BandoCombate.jugador => 'Victoria',
        BandoCombate.rival => 'Derrota',
        null => 'Empate',
      };
      return MarcoBatalla(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              titulo,
              style: TemaBatalla.letra(
                24,
                color: TemaBatalla.aliado,
                fuerte: true,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                FilledButton(
                  onPressed: () => setState(() {
                    _estado = _inicial();
                    _eventos = [];
                  }),
                  style: TemaBatalla.boton(acento: TemaBatalla.metal),
                  child: const Text('Volver a combatir'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(context, _estado),
                  style: TemaBatalla.boton(),
                  child: const Text('Continuar'),
                ),
              ],
            ),
          ],
        ),
      );
    }

    final sustitucion = _estado.fase == FaseCombate.sustituir;
    if (sustitucion || (_mostrarEquipo && !_animando)) {
      return _selectorEquipo(sustitucion);
    }

    final jugador = _estado.jugador;
    return MarcoBatalla(
      padding: const EdgeInsets.fromLTRB(12, 5, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            spacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 9),
                child: Text(
                  _animando ? 'Resolviendo turno…' : 'Elige tu movimiento',
                  style: TemaBatalla.letra(
                    20,
                    color: TemaBatalla.acento,
                    fuerte: true,
                  ),
                ),
              ),
              if (jugador.reservasDisponibles.isNotEmpty)
                TextButton.icon(
                  style: TemaBatalla.boton(acento: TemaBatalla.metal),
                  onPressed: _animando
                      ? null
                      : () => setState(() => _mostrarEquipo = true),
                  icon: const Icon(Icons.swap_horiz, size: 19),
                  label: const Text('Cambiar de Pokémon'),
                ),
              if (jugador.activo.requiereForcejeo)
                FilledButton(
                  onPressed: _animando
                      ? null
                      : () => _aplicar(const Forcejear()),
                  style: TemaBatalla.boton(acento: TemaBatalla.aliado),
                  child: const Text('Forcejeo'),
                ),
            ],
          ),
          const SizedBox(height: 7),
          FilaAccionesBatalla(
            key: ValueKey(jugador.indiceActivo),
            anchoMinimo: MediaQuery.sizeOf(context).width < 580 ? 92 : 150,
            tarjetas: [
              for (final (i, ataque)
                  in jugador.activo.pokemon.movimientos.indexed)
                _botonAtaque(i, ataque),
            ],
          ),
        ],
      ),
    );
  }

  void _volverAMovimientos() {
    setState(() {
      _mostrarEquipo = false;
      _reservaSeleccionada = null;
    });
  }

  Widget _selectorEquipo(bool obligatorio) {
    final equipo = _estado.jugador;
    final disponibles = {
      ...equipo.reservasDisponibles,
      if (!obligatorio) equipo.indiceActivo,
    };
    final indice = _reservaSeleccionada;
    final mantenerActivo = !obligatorio && indice == equipo.indiceActivo;
    return MarcoBatalla(
      padding: const EdgeInsets.fromLTRB(12, 7, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            spacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  obligatorio ? 'Elige un reemplazo' : 'Cambiar de Pokémon',
                  style: TemaBatalla.letra(
                    20,
                    color: obligatorio
                        ? TemaBatalla.aliado
                        : TemaBatalla.acento,
                    fuerte: true,
                  ),
                ),
              ),
              if (!obligatorio)
                TextButton(
                  style: TemaBatalla.boton(acento: TemaBatalla.metal),
                  onPressed: _volverAMovimientos,
                  child: const Text('Volver a movimientos'),
                ),
              FilledButton.icon(
                key: const ValueKey('enviar_reserva_batalla'),
                onPressed: indice == null || !disponibles.contains(indice)
                    ? null
                    : mantenerActivo
                    ? _volverAMovimientos
                    : () => obligatorio
                          ? _sustituir(indice)
                          : _aplicar(Cambiar(indice)),
                style: TemaBatalla.boton(acento: TemaBatalla.aliado),
                icon: const Icon(Icons.arrow_forward, size: 17),
                label: Text(
                  indice == null
                      ? 'Enviar al combate'
                      : '${mantenerActivo ? 'Mantener' : 'Enviar'} a '
                            '${nombreCombatiente(equipo.integrantes[indice].pokemon)}',
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          FilaAccionesBatalla(
            anchoMinimo: 145,
            tarjetas: [
              for (final (i, integrante) in equipo.integrantes.indexed)
                TarjetaReservaBatalla(
                  key: ValueKey('reserva_batalla_$i'),
                  integrante: integrante,
                  activo: i == equipo.indiceActivo,
                  seleccionado: i == indice,
                  onPressed: disponibles.contains(i)
                      ? () => setState(() => _reservaSeleccionada = i)
                      : null,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _botonAtaque(int i, MovimientoAtaque ataque) {
    final rival = _estado.rival.activo;
    final efectividad = efectividadTipo(ataque.tipo, rival.pokemon.tipos);
    final restantes = _estado.jugador.activo.pp[i];
    final impacto = switch (efectividad) {
      0 => 'Sin efecto',
      < 1 => 'Poco eficaz',
      > 1 => 'Supereficaz',
      _ => null,
    };
    return TarjetaMovimientoBatalla(
      claveBoton: ValueKey('movimiento_batalla_$i'),
      movimiento: ataque,
      pp: restantes,
      onPressed: _animando || restantes == 0 ? null : () => _aplicar(Atacar(i)),
      detalle: [
        ?impacto,
        if ((ataque.precision ?? 100) < 100)
          '${ataque.precision} % de precisión',
      ].join(' · '),
    );
  }
}
