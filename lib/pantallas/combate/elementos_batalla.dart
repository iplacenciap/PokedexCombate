import 'package:flutter/material.dart';
import 'package:proyecto_pokedex/logica/combate/combatiente.dart';
import 'package:proyecto_pokedex/logica/combate/tipo_combate.dart';
import 'package:proyecto_pokedex/logica/contador_coleccion.dart';
import 'package:proyecto_pokedex/widgets/elementos_pokedex.dart';

import 'tema_batalla.dart';

class ArteCombatiente extends StatelessWidget {
  const ArteCombatiente(this.pokemon, {super.key});

  final Combatiente pokemon;

  @override
  Widget build(BuildContext context) => IlustracionPokemon(
    'https://raw.githubusercontent.com/PokeAPI/sprites/master/'
    'sprites/pokemon/other/official-artwork/${pokemon.idPokemon}.png',
  );
}

String nombreTipoCombate(TipoCombate tipo) =>
    nombresTipos[tipo.idApi] ?? tipo.idApi;

String nombreCombatiente(Combatiente pokemon) =>
    nombreVisiblePokemon(pokemon.nombre.toUpperCase());

class BarraPsCombate extends StatelessWidget {
  const BarraPsCombate({super.key, required this.ps, required this.maximo});

  final int ps;
  final int maximo;

  @override
  Widget build(BuildContext context) {
    final proporcion = ps / maximo;
    return Semantics(
      label: 'Puntos de salud',
      value: '$ps de $maximo',
      child: TweenAnimationBuilder<double>(
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : const Duration(milliseconds: 220),
        tween: Tween(end: proporcion),
        builder: (context, valor, _) => CustomPaint(
          painter: _MedidorPixel(valor),
          size: const Size(double.infinity, 12),
        ),
      ),
    );
  }
}

class _MedidorPixel extends CustomPainter {
  const _MedidorPixel(this.valor);

  final double valor;

  @override
  void paint(Canvas canvas, Size size) {
    final pintura = Paint()..isAntiAlias = false;
    final marco = Offset.zero & size;
    canvas.drawRect(marco, pintura..color = const Color(0xFFC1CEE1));
    final pista = marco.deflate(2);
    canvas.drawRect(pista, pintura..color = const Color(0xFF0B1320));
    final ancho = (pista.width * valor).roundToDouble();
    if (ancho <= 0) return;
    final color = switch (valor) {
      <= .25 => const Color(0xFFFF656D),
      <= .50 => const Color(0xFFFFC653),
      _ => const Color(0xFF78E46D),
    };
    final relleno = Rect.fromLTWH(pista.left, pista.top, ancho, pista.height);
    canvas.drawRect(relleno, pintura..color = color);
    canvas.drawRect(
      Rect.fromLTWH(relleno.left, relleno.top + 1, ancho, 2),
      pintura..color = Color.lerp(color, Colors.white, .52)!,
    );
    canvas.drawRect(
      Rect.fromLTWH(relleno.left, relleno.bottom - 2, ancho, 2),
      pintura..color = Color.lerp(color, TemaBatalla.sombra, .30)!,
    );
  }

  @override
  bool shouldRepaint(covariant _MedidorPixel anterior) =>
      anterior.valor != valor;
}

class RielSaludBatalla extends StatelessWidget {
  const RielSaludBatalla({
    super.key,
    required this.acento,
    required this.esJugador,
    required this.child,
  });

  final Color acento;
  final bool esJugador;
  final Widget child;

  @override
  Widget build(BuildContext context) => CustomPaint(
    painter: _RielSalud(acento, esJugador),
    child: Padding(
      padding: EdgeInsets.fromLTRB(
        esJugador ? 21 : 12,
        4,
        esJugador ? 12 : 21,
        4,
      ),
      child: child,
    ),
  );
}

class _RielSalud extends CustomPainter {
  const _RielSalud(this.acento, this.esJugador);

  final Color acento;
  final bool esJugador;

  @override
  void paint(Canvas canvas, Size size) {
    final ancho = size.width;
    final alto = size.height;
    if (ancho < 30 || alto < 10) return;
    final forma = Path()
      ..addPolygon([
        const Offset(18, 0),
        Offset(ancho - 4, 0),
        Offset(ancho, 4),
        Offset(ancho, alto),
        Offset(8, alto),
        Offset(0, alto - 5),
      ], true);
    final pintura = Paint()..isAntiAlias = false;
    canvas.save();
    if (!esJugador) {
      canvas.translate(ancho, 0);
      canvas.scale(-1, 1);
    }
    canvas.drawPath(
      forma.shift(const Offset(0, 3)),
      pintura..color = TemaBatalla.sombra,
    );
    canvas.drawPath(forma, pintura..color = const Color(0xFF273747));
    canvas.drawLine(
      const Offset(18, 1),
      Offset(ancho - 5, 1),
      pintura
        ..color = const Color(0xFF9CAEBB)
        ..strokeWidth = 2,
    );
    canvas.drawLine(
      Offset(8, alto - 1),
      const Offset(18, 2),
      pintura
        ..color = acento
        ..strokeWidth = 2,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _RielSalud anterior) =>
      anterior.acento != acento || anterior.esJugador != esJugador;
}

class IndicadorEquipoBatalla extends StatelessWidget {
  const IndicadorEquipoBatalla({
    super.key,
    required this.disponibles,
    required this.nombre,
  });

  static const casillasBase = 6;

  final List<bool> disponibles;
  final String nombre;

  @override
  Widget build(BuildContext context) {
    final cantidad = disponibles.length;
    final vivos = disponibles.where((disponible) => disponible).length;
    final casillas = cantidad < casillasBase ? casillasBase : cantidad;
    return Semantics(
      label:
          '$nombre. Disponibles: $vivos. Debilitados: ${cantidad - vivos}. Huecos: ${casillas - cantidad}.',
      child: Wrap(
        spacing: 3,
        runSpacing: 3,
        children: [
          for (var i = 0; i < casillas; i++)
            CustomPaint(
              painter: _BolaEquipo(i < cantidad ? disponibles[i] : null),
              size: const Size.square(13),
            ),
        ],
      ),
    );
  }
}

class _BolaEquipo extends CustomPainter {
  const _BolaEquipo(this.disponible);

  final bool? disponible;

  @override
  void paint(Canvas canvas, Size size) {
    const pixeles = [
      '...ooo...',
      '..orhro..',
      '.orrrrro.',
      'orrrrrrro',
      'oooodoooo',
      'obbbdbbbo',
      '.obbbbbo.',
      '..obbbo..',
      '...ooo...',
    ];
    final (color, base, linea, centro) = switch (disponible) {
      true => (
        const Color(0xFFF47166),
        const Color(0xFFF1E8D6),
        const Color(0xFF242C36),
        Colors.white,
      ),
      false => (
        const Color(0xFF87929B),
        const Color(0xFFA9B0B7),
        const Color(0xFF303943),
        const Color(0xFFC5CED5),
      ),
      null => (
        const Color(0xFF141B25),
        const Color(0xFF26313C),
        const Color(0xFF10151D),
        const Color(0xFF647180),
      ),
    };
    final escala = size.width / 9;
    final pintura = Paint()..isAntiAlias = false;
    for (final (y, fila) in pixeles.indexed) {
      for (var x = 0; x < fila.length; x++) {
        final tono = switch (fila[x]) {
          'r' => color,
          'b' => base,
          'o' => linea,
          'd' => centro,
          'h' => Color.lerp(color, base, .53),
          _ => null,
        };
        if (tono != null) {
          canvas.drawRect(
            Rect.fromLTWH(x * escala, y * escala, escala, escala),
            pintura..color = tono,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _BolaEquipo anterior) =>
      anterior.disponible != disponible;
}
