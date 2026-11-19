import 'dart:ui';

class PosicionesCancha {
  const PosicionesCancha(this.size);

  final Size size;

  bool get compacto => size.width < 580;

  Rect plataforma({required bool jugador}) => Rect.fromCenter(
    center: Offset(
      size.width * (jugador ? .218 : .804),
      size.height * (jugador ? .835 : (compacto ? .51 : .485)),
    ),
    width:
        size.width *
        (jugador ? (compacto ? .41 : .39) : (compacto ? .34 : .30)),
    height: size.height * (jugador ? .235 : .14),
  );
}
