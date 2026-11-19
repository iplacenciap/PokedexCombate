import 'dart:math' as math;
import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/material.dart';
import 'package:proyecto_pokedex/logica/combate/motor_combate.dart';
import 'package:proyecto_pokedex/logica/combate/movimiento_ataque.dart';

import 'elementos_batalla.dart';
import 'sprite_batalla.dart';
import 'tema_batalla.dart';

class FilaAccionesBatalla extends StatelessWidget {
  const FilaAccionesBatalla({
    super.key,
    required this.tarjetas,
    required this.anchoMinimo,
  });

  final List<Widget> tarjetas;
  final double anchoMinimo;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, limites) {
      const separacion = 10.0;
      final cantidad = tarjetas.length;
      final ancho = math.max(
        anchoMinimo * MediaQuery.textScalerOf(context).scale(1).clamp(1, 1.4),
        (limites.maxWidth - separacion * (cantidad - 1)) / cantidad,
      );
      final comportamiento = ScrollConfiguration.of(context);
      return ScrollConfiguration(
        behavior: comportamiento.copyWith(
          dragDevices: {...comportamiento.dragDevices, PointerDeviceKind.mouse},
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final (i, tarjeta) in tarjetas.indexed) ...[
                  if (i > 0) const SizedBox(width: separacion),
                  SizedBox(width: ancho, child: tarjeta),
                ],
              ],
            ),
          ),
        ),
      );
    },
  );
}

class TarjetaMovimientoBatalla extends StatelessWidget {
  const TarjetaMovimientoBatalla({
    super.key,
    required this.claveBoton,
    required this.movimiento,
    required this.pp,
    required this.detalle,
    required this.onPressed,
  });

  final Key claveBoton;
  final MovimientoAtaque movimiento;
  final int pp;
  final String detalle;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final color = TemaBatalla.colorTipo(movimiento.tipo);
    return FilledButton(
      key: claveBoton,
      onPressed: onPressed,
      style: TemaBatalla.boton(acento: color, fondo: TemaBatalla.hundido)
          .copyWith(
            alignment: Alignment.topLeft,
            padding: const WidgetStatePropertyAll(
              EdgeInsets.fromLTRB(12, 10, 12, 10),
            ),
          ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(movimiento.nombre, style: TemaBatalla.letra(20, fuerte: true)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            alignment: WrapAlignment.spaceBetween,
            children: [
              EtiquetaPixel(
                nombreTipoCombate(movimiento.tipo).toUpperCase(),
                color: color,
              ),
              Text(
                '$pp / ${movimiento.ppMaximos} PP',
                style: TemaBatalla.letra(
                  16,
                  color: pp == 0 ? TemaBatalla.alerta : TemaBatalla.texto,
                  espaciado: .3,
                ),
              ),
            ],
          ),
          if (detalle.isNotEmpty) ...[
            const SizedBox(height: 5),
            Text(
              detalle,
              style: TemaBatalla.letra(13, color: TemaBatalla.suave),
            ),
          ],
        ],
      ),
    );
  }
}

class TarjetaReservaBatalla extends StatelessWidget {
  const TarjetaReservaBatalla({
    super.key,
    required this.integrante,
    required this.activo,
    required this.seleccionado,
    required this.onPressed,
  });

  final IntegranteEnCombate integrante;
  final bool activo;
  final bool seleccionado;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final pokemon = integrante.pokemon;
    final ps = integrante.ps;
    final maximo = pokemon.atributos.psMaximos;
    final debilitado = integrante.debilitado;
    final color = debilitado ? TemaBatalla.alerta : TemaBatalla.acento;
    final fondo = Color.lerp(
      TemaBatalla.hundido,
      color,
      seleccionado ? .25 : .07,
    )!;
    return Semantics(
      selected: seleccionado,
      child: OutlinedButton(
        onPressed: onPressed,
        style: TemaBatalla.boton(
          acento: color,
          fondo: fondo,
          seleccionado: seleccionado,
        ).copyWith(alignment: Alignment.topLeft),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                SizedBox(
                  width: 36,
                  height: 35,
                  child: Opacity(
                    opacity: debilitado ? .45 : 1,
                    child: SpriteBatalla(pokemon, deEspaldas: false),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    nombreCombatiente(pokemon),
                    style: TemaBatalla.letra(16, fuerte: true),
                  ),
                ),
                if (seleccionado)
                  const Icon(Icons.check, color: TemaBatalla.acento, size: 17),
              ],
            ),
            const SizedBox(height: 7),
            BarraPsCombate(ps: ps, maximo: maximo),
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              runSpacing: 3,
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  '$ps / $maximo PS',
                  style: TemaBatalla.letra(16, espaciado: .3),
                ),
                if (debilitado)
                  Text('Debilitado', style: TemaBatalla.letra(13, color: color))
                else if (activo)
                  Text(
                    'En combate',
                    style: TemaBatalla.letra(13, color: TemaBatalla.suave),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
