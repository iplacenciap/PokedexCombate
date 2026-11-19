import 'tipo_combate.dart';

enum CategoriaAtaque { fisico, especial }

class MovimientoAtaque {
  MovimientoAtaque({
    required this.id,
    required this.nombre,
    required this.tipo,
    required this.categoria,
    required this.poder,
    this.precision,
    this.prioridad = 0,
    this.ppMaximos = 20,
  }) {
    if (id <= 0) throw ArgumentError.value(id, 'id', 'Debe ser positivo');
    if (ppMaximos <= 0) {
      throw ArgumentError.value(ppMaximos, 'ppMaximos', 'Debe ser positivo');
    }
    if (nombre.trim().isEmpty) throw ArgumentError.value(nombre, 'nombre');
    if (poder <= 0) {
      throw ArgumentError.value(poder, 'poder', 'Debe ser positivo');
    }
    final porcentaje = precision;
    if (porcentaje != null && (porcentaje < 1 || porcentaje > 100)) {
      throw RangeError.range(porcentaje, 1, 100, 'precision');
    }
  }

  final int id;
  final String nombre;
  final TipoCombate tipo;
  final CategoriaAtaque categoria;
  final int poder;
  final int? precision;
  final int prioridad;
  final int ppMaximos;
}
