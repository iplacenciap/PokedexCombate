import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'escenario_batalla.dart';

class PraderaDuelos extends StatelessWidget {
  const PraderaDuelos({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => ClipRect(
    child: Stack(
      fit: StackFit.passthrough,
      children: [
        const Positioned.fill(
          child: RepaintBoundary(
            child: CustomPaint(painter: _ClaroBosque(), isComplex: true),
          ),
        ),
        child,
      ],
    ),
  );
}

class _ClaroBosque extends CustomPainter {
  const _ClaroBosque();

  static const _horizonte = .33;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    _cesped(canvas, size);
    _bosque(canvas, size);
    final posiciones = PosicionesCancha(size);
    _ring(canvas, posiciones.plataforma(jugador: false));
    _ring(canvas, posiciones.plataforma(jugador: true));
  }

  void _bosque(Canvas canvas, Size size) {
    Offset punto(double x, double y) => Offset(x * size.width, y * size.height);
    final cielo =
        Offset.zero & Size(size.width, size.height * (_horizonte + .015));
    final pintura = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF2F5D70), Color(0xFF8FAF9C)],
      ).createShader(cielo);
    canvas.drawRect(cielo, pintura);
    pintura.shader = null;
    canvas.drawPath(
      Path()..addPolygon([
        punto(0, .10),
        punto(.15, .075),
        punto(.28, .13),
        punto(.39, .18),
        punto(.52, .15),
        punto(.70, .098),
        punto(.80, .075),
        punto(1, .13),
        punto(1, .345),
        punto(0, .345),
      ], true),
      pintura..color = const Color(0xFF648E7F),
    );

    final azar = math.Random(13);
    for (var i = 0; i <= 15; i++) {
      final x = i * .069 - .04 + azar.nextDouble() * .022;
      final y = .329 + azar.nextDouble() * .027;
      final altura = .145 + azar.nextDouble() * .09;
      _arbol(
        canvas,
        pintura,
        punto(x, y),
        Size(
          size.width * (.079 + azar.nextDouble() * .041),
          size.height * altura,
        ),
        const Color(0xFF3D645C),
        Color.lerp(
          const Color(0xFF497566),
          const Color(0xFF64897B),
          azar.nextDouble(),
        )!,
        reflejado: i.isOdd,
      );
    }
    for (final (x, y, alto, ancho) in [
      (.012, .375, .31, .146),
      (.117, .354, .26, .139),
      (.215, .338, .21, .118),
      (.720, .340, .216, .127),
      (.839, .350, .27, .156),
      (.981, .372, .32, .177),
    ]) {
      _arbol(
        canvas,
        pintura,
        punto(x, y),
        Size(size.width * ancho, size.height * alto),
        const Color(0xFF274D43),
        const Color(0xFF45745A),
        reflejado: x > .5,
      );
    }
  }

  void _arbol(
    Canvas canvas,
    Paint pintura,
    Offset base,
    Size tamano,
    Color sombra,
    Color copa, {
    required bool reflejado,
  }) {
    final ancho = reflejado ? -tamano.width : tamano.width;
    Offset punto(double x, double y) =>
        base + Offset(x * ancho, y * tamano.height);
    canvas.drawPath(
      Path()..addPolygon([
        punto(-.16, 0),
        punto(-.063, -.12),
        punto(-.080, -.47),
        punto(.09, -.47),
        punto(.065, -.09),
        punto(.15, 0),
      ], true),
      pintura..color = Color.lerp(sombra, const Color(0xFF9B814F), .30)!,
    );
    const contorno = [
      (-.19, -.97),
      (.12, -.98),
      (.12, -.90),
      (.32, -.90),
      (.32, -.81),
      (.44, -.81),
      (.44, -.69),
      (.50, -.69),
      (.50, -.53),
      (.38, -.53),
      (.38, -.40),
      (.12, -.38),
      (.08, -.32),
      (-.29, -.37),
      (-.29, -.44),
      (-.46, -.44),
      (-.46, -.56),
      (-.50, -.58),
      (-.48, -.73),
      (-.35, -.73),
      (-.35, -.86),
      (-.19, -.86),
    ];
    canvas.drawPath(
      Path()..addPolygon([for (final (x, y) in contorno) punto(x, y)], true),
      pintura..color = sombra,
    );
    canvas.drawPath(
      Path()..addPolygon([
        for (final (x, y) in contorno) punto(x * .77 - .055, y * .70 - .315),
      ], true),
      pintura..color = copa,
    );
  }

  void _cesped(Canvas canvas, Size size) {
    final suelo = Rect.fromLTRB(
      0,
      size.height * _horizonte,
      size.width,
      size.height,
    );
    final pintura = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF527B62), Color(0xFF6D925E), Color(0xFF416B56)],
        stops: [0, .36, 1],
      ).createShader(suelo);
    canvas.drawRect(suelo, pintura);
    pintura.shader = null;

    canvas.save();
    canvas.clipRect(suelo);
    for (final (x, y, ancho, alto, color) in [
      (.47, .54, .92, .54, const Color(0x589DB574)),
      (.23, .80, .63, .50, const Color(0x3BCAB679)),
      (.90, .68, .65, .55, const Color(0x48213E44)),
      (.02, .48, .48, .40, const Color(0x57253543)),
    ]) {
      canvas.save();
      canvas.translate(size.width * x, size.height * y);
      canvas.scale(size.width * ancho / 2, size.height * alto / 2);
      final luz = RadialGradient(colors: [color, color.withValues(alpha: 0)]);
      pintura.shader = luz.createShader(
        Rect.fromCircle(center: Offset.zero, radius: 1),
      );
      canvas.drawCircle(Offset.zero, 1, pintura);
      canvas.restore();
    }
    pintura.shader = null;

    _texturaCesped(canvas, suelo, pintura);
    canvas.restore();
  }

  void _texturaCesped(Canvas canvas, Rect suelo, Paint pintura) {
    final azar = math.Random(27);
    const claros = [
      (.14, .19, .25, .10, Color(0x4A3A6953)),
      (.35, .26, .24, .10, Color(0x3893AA64)),
      (.63, .21, .29, .10, Color(0x4C345846)),
      (.48, .41, .30, .135, Color(0x48A4B76F)),
      (.72, .47, .27, .13, Color(0x4F355943)),
      (.36, .61, .27, .16, Color(0x4D3A6849)),
      (.53, .75, .33, .18, Color(0x5595AE6B)),
      (.85, .78, .24, .16, Color(0x49304F47)),
      (.64, .93, .29, .15, Color(0x4A36624F)),
    ];
    for (final (x, avance, ancho, alto, color) in claros) {
      final centro = Offset(suelo.width * x, suelo.top + suelo.height * avance);
      final contorno = [
        for (var i = 0; i < 22; i++)
          _bordeDeMancha(
            centro,
            Size(suelo.width * ancho, suelo.height * alto),
            i * 2 * math.pi / 22,
            .78 + azar.nextDouble() * .22,
          ),
      ];
      canvas.drawPath(
        Path()..addPolygon(contorno, true),
        pintura..color = color,
      );
    }

    final columnas = (suelo.width / 30).clamp(12, 40).round();
    for (var fila = 0; fila < 7; fila++) {
      for (var columna = 0; columna < columnas; columna++) {
        final x = (columna + azar.nextDouble()) / columnas;
        final avance = (fila + azar.nextDouble()) / 7;
        _mata(canvas, pintura, suelo, azar, x, avance, .75);
      }
    }

    for (final (x, avance) in [
      (.18, .21),
      (.31, .25),
      (.48, .32),
      (.65, .26),
      (.85, .34),
      (.39, .43),
      (.54, .51),
      (.69, .54),
      (.93, .58),
      (.32, .68),
      (.45, .81),
      (.60, .68),
      (.77, .86),
      (.57, .94),
    ]) {
      for (var i = 0; i < 13; i++) {
        _mata(
          canvas,
          pintura,
          suelo,
          azar,
          x + (azar.nextDouble() - .5) * .13,
          avance + (azar.nextDouble() - .5) * .14,
          1.15,
        );
      }
    }
  }

  Offset _bordeDeMancha(
    Offset centro,
    Size extension,
    double angulo,
    double radio,
  ) =>
      centro +
      Offset(
        math.cos(angulo) * extension.width * radio / 2,
        math.sin(angulo) * extension.height * radio / 2,
      );

  void _mata(
    Canvas canvas,
    Paint pintura,
    Rect suelo,
    math.Random azar,
    double x,
    double avance,
    double escala,
  ) {
    final base = Offset(suelo.width * x, suelo.top + suelo.height * avance);
    final alto =
        suelo.height *
        (.008 + avance * .033) *
        escala *
        (.55 + azar.nextDouble() * .65);
    final ancho = alto * (1 + azar.nextDouble() * .55);
    final inclinacion = azar.nextDouble() - .5;
    Offset punto(double x, double y) =>
        base + Offset((x + inclinacion * y) * ancho, y * alto);
    const tonos = [
      Color(0x65446E49),
      Color(0x7756774B),
      Color(0x52799B5D),
      Color(0x58A7BF7B),
      Color(0x70558053),
    ];
    canvas.drawPath(
      Path()..addPolygon([
        punto(-.42, 0),
        punto(-.92, -.69),
        punto(-.30, -.37),
        punto(-.15, -1),
        punto(.09, -.41),
        punto(.60, -.91),
        punto(.39, -.26),
        punto(.95, -.52),
        punto(.47, 0),
      ], true),
      pintura..color = tonos[azar.nextInt(tonos.length)],
    );
  }

  void _ring(Canvas canvas, Rect superficie) {
    final pintura = Paint();
    final grosor = superficie.height * .10;
    canvas.drawOval(
      superficie.shift(Offset(0, grosor)),
      pintura..color = const Color(0x8C294D39),
    );
    canvas.drawOval(superficie, pintura..color = const Color(0xFF345D42));

    final interior = Rect.fromCenter(
      center: superficie.center,
      width: superficie.width * .89,
      height: superficie.height * .76,
    );
    canvas.drawOval(
      interior,
      pintura
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF65874D), Color(0xFF8FA763), Color(0xFF668A58)],
          stops: [0, .50, 1],
        ).createShader(interior),
    );
    pintura.shader = null;
    for (var i = 0; i < 34; i++) {
      final angulo = i * 2 * math.pi / 34;
      final x =
          superficie.center.dx + math.cos(angulo) * superficie.width * .473;
      final y =
          superficie.center.dy + math.sin(angulo) * superficie.height * .438;
      final alto = grosor * (.67 + (i % 3) * .22);
      canvas.drawPath(
        Path()..addPolygon([
          Offset(x - alto * .87, y - alto * .64),
          Offset(x - alto * .29, y - alto * .28),
          Offset(x + alto * .04, y - alto),
          Offset(x + alto * .30, y - alto * .28),
          Offset(x + alto * .81, y - alto * .55),
          Offset(x + alto * .38, y),
          Offset(x - alto * .37, y),
        ], true),
        pintura
          ..color = i.isEven
              ? const Color(0xFF345D42)
              : const Color(0xFF476E46),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ClaroBosque anterior) => false;
}
