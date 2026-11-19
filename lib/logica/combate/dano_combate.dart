import 'dart:math';

import 'combatiente.dart';
import 'efectividad_tipos.dart';
import 'movimiento_ataque.dart';

({int puntos, double efectividad}) calcularDano(
  Combatiente atacante,
  Combatiente objetivo,
  MovimientoAtaque movimiento, {
  int variacion = 100,
  bool ignoraTipos = false,
}) {
  final efectividad = ignoraTipos
      ? 1.0
      : efectividadTipo(movimiento.tipo, objetivo.tipos);
  if (efectividad == 0) return (puntos: 0, efectividad: 0);

  final fisico = movimiento.categoria == CategoriaAtaque.fisico;
  final ofensiva = fisico
      ? atacante.atributos.ataque
      : atacante.atributos.ataqueEspecial;
  final defensa = fisico
      ? objetivo.atributos.defensa
      : objetivo.atributos.defensaEspecial;
  final base = (movimiento.poder * ofensiva) ~/ (4 * defensa) + 2;
  final afinidad = !ignoraTipos && atacante.tipos.contains(movimiento.tipo)
      ? 1.5
      : 1.0;
  final puntos = (base * afinidad * efectividad * variacion / 100).floor();
  return (puntos: max(1, puntos), efectividad: efectividad);
}
