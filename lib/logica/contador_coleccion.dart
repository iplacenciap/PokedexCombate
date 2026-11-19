const Map<String, String> nombresTipos = {
  'normal': 'Normal',
  'fighting': 'Lucha',
  'flying': 'Volador',
  'poison': 'Veneno',
  'ground': 'Tierra',
  'rock': 'Roca',
  'bug': 'Bicho',
  'ghost': 'Fantasma',
  'steel': 'Acero',
  'fire': 'Fuego',
  'water': 'Agua',
  'grass': 'Planta',
  'electric': 'Eléctrico',
  'psychic': 'Psíquico',
  'ice': 'Hielo',
  'dragon': 'Dragón',
  'dark': 'Siniestro',
  'fairy': 'Hada',
};

String textoContador({
  required int obtenidos,
  required int total,
  int? generacion,
  String? tipo,
  bool soloFavoritos = false,
}) {
  final conteo = '$obtenidos/$total';
  final condiciones = <String>[];

  if (tipo != null) {
    condiciones.add('tipo ${(nombresTipos[tipo] ?? tipo).toLowerCase()}');
  }
  if (generacion != null) {
    condiciones.add('generación $generacion');
  }
  if (soloFavoritos) {
    condiciones.add('favoritos');
  }

  if (condiciones.isEmpty) {
    return conteo;
  }
  return '$conteo de ${condiciones.join(' y ')}';
}