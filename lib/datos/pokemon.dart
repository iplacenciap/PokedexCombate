
class Pokemon {
  final int id;
  final String nombre;
  final String urlImagen;
  final List<String> tipos;
  final int altura;
  final int peso;
  final String descripcion;
  final List<String> habilidades;
  final Map<String, int> estadisticas;
  final String generacion;

  Pokemon({
    required this.id,
    required this.nombre,
    required this.urlImagen,
    required this.tipos,
    required this.altura,
    required this.peso,
    required this.descripcion,
    required this.habilidades,
    required this.estadisticas,
    required this.generacion,
  });

}