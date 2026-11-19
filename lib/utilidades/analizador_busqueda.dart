import '../datos/pokemon_resumen.dart'; 

List<PokemonResumen> analizarYFiltrarBusqueda({
  required List<PokemonResumen> allPokemon,
  String? filtroNombre,
  List<String>? filtrosTipo, 
  int? filtroGeneracion,     
}) {
  
  if ((filtroNombre == null || filtroNombre.trim().isEmpty) && 
      (filtrosTipo == null || filtrosTipo.isEmpty) && 
      filtroGeneracion == null) {
    return List.from(allPokemon);
  }

  return allPokemon.where((pokemon) {
    
    bool coincideNombre = true;
    if (filtroNombre != null && filtroNombre.trim().isNotEmpty) {
      coincideNombre = pokemon.nombre.toLowerCase().replaceAll("-", " ").contains(
        filtroNombre.trim().toLowerCase().replaceAll("-", " "));
    }

    bool coincideTipo = true;
    if (filtrosTipo != null && filtrosTipo.isNotEmpty) {
      coincideTipo = pokemon.tipos.any((tipoPokemon) => 
          filtrosTipo.any((filtro) => filtro.toLowerCase() == tipoPokemon.toLowerCase()));
    }

    bool coincideGeneracion = true;
    if (filtroGeneracion != null) {
      coincideGeneracion = pokemon.generacion == filtroGeneracion;
    }

    return coincideNombre && coincideTipo && coincideGeneracion;
    
  }).toList();
}