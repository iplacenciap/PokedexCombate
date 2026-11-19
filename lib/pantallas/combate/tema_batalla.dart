import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:proyecto_pokedex/logica/combate/tipo_combate.dart';

class TemaBatalla {
  static const fondo = Color(0xFF111723);
  static const superficie = Color(0xFF222D40);
  static const hundido = Color(0xFF141D2C);
  static const sombra = Color(0xFF0B111C);
  static const metal = Color(0xFF607591);
  static const texto = Color(0xFFF2F5FC);
  static const suave = Color(0xFFC2CFE4);
  static const acento = Color(0xFF81E5E6);
  static const aliado = Color(0xFFFFCF82);
  static const alerta = Color(0xFFFF9698);

  static TextStyle letra(
    double tamano, {
    Color color = texto,
    bool fuerte = false,
    double? espaciado,
  }) => TextStyle(
    fontFamily: 'Pixelify Sans',
    fontSize: tamano,
    fontWeight: fuerte ? FontWeight.w700 : FontWeight.w400,
    color: color,
    height: 1.13,
    letterSpacing: espaciado,
  );

  static Color colorTipo(TipoCombate tipo) => switch (tipo) {
    TipoCombate.normal => const Color(0xFFC6C9D6),
    TipoCombate.fuego => const Color(0xFFFFA16D),
    TipoCombate.agua => const Color(0xFF84BBFF),
    TipoCombate.electrico => const Color(0xFFF8DC6F),
    TipoCombate.planta => const Color(0xFF9CD77D),
    TipoCombate.hielo => const Color(0xFF8CE1F0),
    TipoCombate.lucha => const Color(0xFFF79D9C),
    TipoCombate.veneno => const Color(0xFFDD9AFF),
    TipoCombate.tierra => const Color(0xFFE1BD89),
    TipoCombate.volador => const Color(0xFFB4BEFF),
    TipoCombate.psiquico => const Color(0xFFF79BC7),
    TipoCombate.bicho => const Color(0xFFD1DA7D),
    TipoCombate.roca => const Color(0xFFCFBF8F),
    TipoCombate.fantasma => const Color(0xFFC2A2F1),
    TipoCombate.dragon => const Color(0xFFB4A2FF),
    TipoCombate.siniestro => const Color(0xFFB7AAAF),
    TipoCombate.acero => const Color(0xFF9CC7DC),
    TipoCombate.hada => const Color(0xFFFFB9D8),
  };

  static ButtonStyle boton({
    Color acento = TemaBatalla.acento,
    Color fondo = hundido,
    bool seleccionado = false,
  }) => ButtonStyle(
    textStyle: WidgetStatePropertyAll(letra(15, fuerte: true)),
    alignment: Alignment.centerLeft,
    minimumSize: const WidgetStatePropertyAll(Size(0, 42)),
    padding: const WidgetStatePropertyAll(
      EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    ),
    shape: const WidgetStatePropertyAll(BiselBatalla()),
    side: WidgetStateProperty.resolveWith((estados) {
      final resaltado =
          seleccionado ||
          estados.contains(WidgetState.focused) ||
          estados.contains(WidgetState.hovered);
      final deshabilitado = estados.contains(WidgetState.disabled);
      return BorderSide(
        color: deshabilitado
            ? metal
            : resaltado
            ? Color.lerp(acento, texto, .35)!
            : acento,
        width: resaltado ? 3 : 2,
      );
    }),
    elevation: const WidgetStatePropertyAll(0),
    backgroundColor: WidgetStatePropertyAll(fondo),
    foregroundColor: WidgetStateProperty.resolveWith(
      (estados) => estados.contains(WidgetState.disabled) ? suave : texto,
    ),
    overlayColor: WidgetStatePropertyAll(texto.withValues(alpha: .08)),
  );
}

class BiselBatalla extends OutlinedBorder {
  const BiselBatalla({super.side, this.paso = 4});

  final double paso;

  @override
  BiselBatalla copyWith({BorderSide? side}) =>
      BiselBatalla(side: side ?? this.side, paso: paso);

  @override
  ShapeBorder scale(double t) =>
      BiselBatalla(side: side.scale(t), paso: paso * t);

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    final x = rect.left;
    final y = rect.top;
    final r = rect.right;
    final b = rect.bottom;
    final p = math.min(paso, rect.shortestSide / 4);
    return Path()
      ..moveTo(x + 2 * p, y)
      ..lineTo(r - 2 * p, y)
      ..lineTo(r - 2 * p, y + p)
      ..lineTo(r - p, y + p)
      ..lineTo(r - p, y + 2 * p)
      ..lineTo(r, y + 2 * p)
      ..lineTo(r, b - 2 * p)
      ..lineTo(r - p, b - 2 * p)
      ..lineTo(r - p, b)
      ..lineTo(x + 2 * p, b)
      ..lineTo(x + 2 * p, b - p)
      ..lineTo(x + p, b - p)
      ..lineTo(x + p, b - 2 * p)
      ..lineTo(x, b - 2 * p)
      ..lineTo(x, y + 2 * p)
      ..lineTo(x + p, y + 2 * p)
      ..lineTo(x + p, y + p)
      ..lineTo(x + 2 * p, y + p)
      ..close();
  }

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) =>
      getOuterPath(rect.deflate(side.width), textDirection: textDirection);

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    if (side.style == BorderStyle.none || side.width == 0 || rect.isEmpty) {
      return;
    }
    final trazo = rect.deflate(side.width / 2);
    if (trazo.isEmpty) return;
    canvas.drawPath(
      getOuterPath(trazo, textDirection: textDirection),
      side.toPaint(),
    );
  }

  @override
  bool operator ==(Object otro) =>
      otro is BiselBatalla && otro.side == side && otro.paso == paso;

  @override
  int get hashCode => Object.hash(side, paso);
}

class MarcoBatalla extends StatelessWidget {
  const MarcoBatalla({
    super.key,
    required this.child,
    this.fondo = TemaBatalla.superficie,
    this.borde = TemaBatalla.metal,
    this.padding = const EdgeInsets.all(12),
  });

  final Widget child;
  final Color fondo;
  final Color borde;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: ShapeDecoration(
      color: fondo,
      shape: BiselBatalla(side: BorderSide(color: borde, width: 2)),
      shadows: const [
        BoxShadow(color: TemaBatalla.sombra, offset: Offset(0, 4)),
      ],
    ),
    child: Padding(padding: padding, child: child),
  );
}

class EtiquetaPixel extends StatelessWidget {
  const EtiquetaPixel(this.texto, {super.key, required this.color});

  final String texto;
  final Color color;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: color,
      border: const Border(
        bottom: BorderSide(color: Color(0x560B111C), width: 2),
      ),
    ),
    child: Padding(
      padding: const EdgeInsets.fromLTRB(6, 2, 6, 2),
      child: Text(
        texto,
        style: TemaBatalla.letra(12, color: TemaBatalla.sombra, fuerte: true),
      ),
    ),
  );
}
