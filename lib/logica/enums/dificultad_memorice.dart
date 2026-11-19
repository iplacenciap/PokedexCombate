enum DificultadMemorice {
  facil(
    nombre: 'Fácil',
    pares: 6,
    segundosMemorizacion: 4,
    segundosJuego: 50,
    recompensa: 500,
  ),
  normal(
    nombre: 'Normal',
    pares: 8,
    segundosMemorizacion: 5,
    segundosJuego: 60,
    recompensa: 600,
  ),
  dificil(
    nombre: 'Difícil',
    pares: 10,
    segundosMemorizacion: 5,
    segundosJuego: 50,
    recompensa: 700,
  ),
  extremo(
    nombre: 'Extremo',
    pares: 12,
    segundosMemorizacion: 6,
    segundosJuego: 60,
    recompensa: 900,
  );

  final String nombre;
  final int pares;
  final int segundosMemorizacion;
  final int segundosJuego;
  final int recompensa;

  const DificultadMemorice({
    required this.nombre,
    required this.pares,
    required this.segundosMemorizacion,
    required this.segundosJuego,
    required this.recompensa
  });
}