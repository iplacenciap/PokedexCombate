import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:proyecto_pokedex/logica/combate/combatiente.dart';
import 'package:proyecto_pokedex/logica/combate/motor_combate.dart';
import 'package:proyecto_pokedex/logica/combate/movimiento_ataque.dart';
import 'package:proyecto_pokedex/logica/combate/tipo_combate.dart';

import 'elementos_batalla.dart';
import 'escenario_batalla.dart';
import 'pradera_duelos.dart';
import 'sprite_batalla.dart';
import 'tema_batalla.dart';

final class CombatienteEnEscena {
  const CombatienteEnEscena._(this.pokemon, this.indice, this.ps);

  factory CombatienteEnEscena.deEquipo(EquipoEnCombate equipo, [int? indice]) {
    final posicion = indice ?? equipo.indiceActivo;
    final integrante = equipo.integrantes[posicion];
    return CombatienteEnEscena._(integrante.pokemon, posicion, integrante.ps);
  }

  final Combatiente pokemon;
  final int indice;
  final int ps;

  CombatienteEnEscena conPs(int ps) =>
      CombatienteEnEscena._(pokemon, indice, ps);
}

class CampoBatalla extends StatelessWidget {
  const CampoBatalla({
    super.key,
    required this.jugador,
    required this.rival,
    required this.equipoJugador,
    required this.equipoRival,
    required this.animacion,
    this.ataque,
  });

  final CombatienteEnEscena jugador;
  final CombatienteEnEscena rival;
  final List<bool> equipoJugador;
  final List<bool> equipoRival;
  final Animation<double> animacion;
  final AtaqueResuelto? ataque;

  @override
  Widget build(BuildContext context) {
    final ataqueActual = ataque;
    return LayoutBuilder(
      builder: (context, limites) {
        final size = limites.biggest;
        final posiciones = PosicionesCancha(size);
        final margen = posiciones.compacto ? 12.0 : 26.0;
        final anchoPs = posiciones.compacto
            ? math.min(
                size.width - margen * 2,
                math.max(160.0, size.width * .48),
              )
            : math.min(size.width * .32, 325.0);
        final escena = Stack(
          fit: StackFit.expand,
          children: [
            _CombatienteVisible(
              activo: rival,
              bando: BandoCombate.rival,
              posiciones: posiciones,
              animacion: animacion,
              ataque: ataqueActual,
            ),
            _CombatienteVisible(
              activo: jugador,
              bando: BandoCombate.jugador,
              posiciones: posiciones,
              animacion: animacion,
              ataque: ataqueActual,
            ),
            if (ataqueActual != null &&
                ataqueActual.movimiento.categoria != CategoriaAtaque.fisico)
              IgnorePointer(
                child: ExcludeSemantics(
                  child: _Proyectil(
                    ataque: ataqueActual,
                    animacion: animacion,
                    posiciones: posiciones,
                  ),
                ),
              ),
            Positioned(
              left: margen,
              top: margen,
              width: anchoPs,
              child: _HudCombatiente(
                activo: rival,
                esJugador: false,
                equipo: equipoRival,
              ),
            ),
            Positioned(
              right: margen,
              bottom: margen,
              width: anchoPs,
              child: _HudCombatiente(
                activo: jugador,
                esJugador: true,
                equipo: equipoJugador,
              ),
            ),
          ],
        );
        return PraderaDuelos(child: escena);
      },
    );
  }
}

class _HudCombatiente extends StatelessWidget {
  const _HudCombatiente({
    required this.activo,
    required this.esJugador,
    required this.equipo,
  });

  final CombatienteEnEscena activo;
  final bool esJugador;
  final List<bool> equipo;

  @override
  Widget build(BuildContext context) {
    final maximo = activo.pokemon.atributos.psMaximos;
    final acento = esJugador ? TemaBatalla.aliado : TemaBatalla.acento;
    const sombras = [
      Shadow(color: TemaBatalla.sombra, offset: Offset(1, 2), blurRadius: 2),
      Shadow(color: TemaBatalla.sombra, blurRadius: 5),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            nombreCombatiente(activo.pokemon),
            textAlign: esJugador ? TextAlign.right : TextAlign.left,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TemaBatalla.letra(
              MediaQuery.sizeOf(context).width < 580 ? 18 : 23,
              fuerte: true,
            ).copyWith(shadows: sombras),
          ),
        ),
        const SizedBox(height: 3),
        RielSaludBatalla(
          acento: acento,
          esJugador: esJugador,
          child: Row(
            children: [
              Text(
                'PS',
                style: TemaBatalla.letra(14, color: acento, fuerte: true),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: BarraPsCombate(
                  key: ValueKey(activo.indice),
                  ps: activo.ps,
                  maximo: maximo,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Wrap(
            spacing: 7,
            runSpacing: 4,
            alignment: esJugador ? WrapAlignment.end : WrapAlignment.start,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              IndicadorEquipoBatalla(
                disponibles: equipo,
                nombre: esJugador ? 'Tu equipo' : 'Equipo rival',
              ),
              if (activo.ps == 0)
                EtiquetaPixel('Debilitado', color: TemaBatalla.alerta),
              Text(
                '${activo.ps} / $maximo PS',
                style: TemaBatalla.letra(
                  15,
                  espaciado: .3,
                ).copyWith(shadows: sombras),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CombatienteVisible extends StatelessWidget {
  const _CombatienteVisible({
    required this.activo,
    required this.bando,
    required this.posiciones,
    required this.animacion,
    required this.ataque,
  });

  final CombatienteEnEscena activo;
  final BandoCombate bando;
  final PosicionesCancha posiciones;
  final Animation<double> animacion;
  final AtaqueResuelto? ataque;

  bool get esJugador => bando == BandoCombate.jugador;

  @override
  Widget build(BuildContext context) {
    final ring = posiciones.plataforma(jugador: esJugador);
    final altura = posiciones.size.height;
    final ancho = posiciones.compacto
        ? ring.width * (esJugador ? .94 : 1.08)
        : ring.width * .66;
    final alto = altura * (esJugador ? .50 : .40);
    final duracion = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 180);
    return Positioned(
      left: ring.center.dx - ancho / 2,
      top: ring.center.dy - alto,
      width: ancho,
      height: alto,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          if (activo.ps > 0)
            Positioned(
              bottom: -ring.height * .12,
              left: ancho * .22,
              right: ancho * .22,
              height: ring.height * .25,
              child: CustomPaint(
                painter: const _SombraCombatiente(Color(0xA0414C42)),
              ),
            ),
          Positioned.fill(child: _sprite(duracion)),
        ],
      ),
    );
  }

  Widget _sprite(Duration duracion) {
    final sprite = AnimatedSwitcher(
      duration: duracion,
      child: activo.ps == 0
          ? SizedBox.expand(key: ValueKey('debilitado_${activo.indice}'))
          : SpriteBatalla(
              activo.pokemon,
              key: ValueKey(activo.indice),
              deEspaldas: esJugador,
            ),
    );
    final ataqueActual = ataque;

    return AnimatedBuilder(
      animation: animacion,
      child: sprite,
      builder: (context, child) {
        final t = animacion.value;
        final direccion = esJugador ? 1.0 : -1.0;
        final atacando = ataqueActual?.bando == bando;
        final fisico =
            ataqueActual?.movimiento.categoria == CategoriaAtaque.fisico;
        final impulso = math.sin(math.pi * t);
        final impacto = ((t - .52) / .48).clamp(0.0, 1.0);
        final golpeVisible =
            !atacando && (ataqueActual?.dano ?? 0) > 0 && impacto > 0;
        final sacudida = golpeVisible
            ? 7 * math.sin(3 * math.pi * impacto) * (1 - impacto)
            : 0.0;

        return Stack(
          alignment: Alignment.center,
          fit: StackFit.expand,
          clipBehavior: Clip.none,
          children: [
            Transform.translate(
              offset: atacando && fisico
                  ? Offset(27 * direccion * impulso, -5 * impulso)
                  : Offset(-direccion * sacudida, 0),
              child: child,
            ),
            if (ataqueActual != null && golpeVisible)
              Positioned(
                top: 5 - 16 * impacto,
                child: ExcludeSemantics(
                  child: Opacity(
                    opacity: 1 - impacto,
                    child: MarcoBatalla(
                      borde: TemaBatalla.colorTipo(
                        ataqueActual.movimiento.tipo,
                      ),
                      fondo: TemaBatalla.hundido,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 4,
                      ),
                      child: Text(
                        '−${ataqueActual.dano} PS',
                        style: TemaBatalla.letra(17, fuerte: true),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _SombraCombatiente extends CustomPainter {
  const _SombraCombatiente(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final gradiente = RadialGradient(
      colors: [color, color.withValues(alpha: 0)],
      stops: const [.16, 1],
    );
    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);
    canvas.scale(size.width / 2, size.height / 2);
    canvas.drawCircle(
      Offset.zero,
      1,
      Paint()
        ..shader = gradiente.createShader(
          Rect.fromCircle(center: Offset.zero, radius: 1),
        ),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _SombraCombatiente anterior) =>
      anterior.color != color;
}

class _Proyectil extends StatelessWidget {
  const _Proyectil({
    required this.ataque,
    required this.animacion,
    required this.posiciones,
  });

  final AtaqueResuelto ataque;
  final Animation<double> animacion;
  final PosicionesCancha posiciones;

  @override
  Widget build(BuildContext context) {
    final tipo = ataque.movimiento.tipo;
    final color = TemaBatalla.colorTipo(tipo);
    final ilustracion = MarcoBatalla(
      borde: color,
      fondo: TemaBatalla.hundido,
      padding: const EdgeInsets.all(6),
      child: Icon(
        switch (tipo) {
          TipoCombate.fuego => Icons.local_fire_department_outlined,
          TipoCombate.agua => Icons.water_drop_outlined,
          TipoCombate.electrico => Icons.bolt,
          TipoCombate.planta => Icons.eco_outlined,
          _ => Icons.auto_awesome,
        },
        color: color,
        size: 20,
      ),
    );
    final desdeJugador = ataque.bando == BandoCombate.jugador;
    Offset punto(bool jugador) => posiciones
        .plataforma(jugador: jugador)
        .center
        .translate(0, -posiciones.size.height * (jugador ? .22 : .18));
    final izquierda = punto(true);
    final derecha = punto(false);
    final desde = desdeJugador ? izquierda : derecha;
    final hasta = ataque.bando == ataque.bandoObjetivo
        ? desde
        : (desdeJugador ? derecha : izquierda);

    return AnimatedBuilder(
      key: ValueKey('proyectil_${tipo.idApi}'),
      animation: animacion,
      child: ilustracion,
      builder: (context, child) {
        final progreso = animacion.value;
        if (progreso >= .66) return const SizedBox.shrink();
        final trayecto = Curves.easeIn.transform(
          (progreso / .66).clamp(0.0, 1.0),
        );
        final coordenadas = Offset.lerp(desde, hasta, trayecto)!;
        final arco = math.sin(math.pi * trayecto);
        return Stack(
          children: [
            Positioned(
              left: coordenadas.dx - 18,
              top: coordenadas.dy - 18 - posiciones.size.height * .11 * arco,
              child: Opacity(
                opacity: (arco * 1.65).clamp(0.0, 1.0),
                child: child,
              ),
            ),
          ],
        );
      },
    );
  }
}
