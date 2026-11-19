import 'package:proyecto_pokedex/datos/pokemon.dart';

class GeneradorPistasPokeguesser {
  static List<String> generarPistas(Pokemon pokemonOculto){
    final List<String> pistas = [];

    final String tipoPrincipal = pokemonOculto.tipos.isNotEmpty ? _formatearTipo(pokemonOculto.tipos.first) : "desconocido";
    final String habilidad = pokemonOculto.habilidades.isNotEmpty ? pokemonOculto.habilidades.first : "desconocida";
    final Map<String, int> estadisticas = pokemonOculto.estadisticas;
    final String generacion = _formatearGeneracion(pokemonOculto.generacion);


    pistas.add("El tipo principal de este Pokémon es $tipoPrincipal");
    pistas.add("Este Pokémon tiene un peso de ${pokemonOculto.peso/10} kg y una altura de ${pokemonOculto.altura/10} m");
    pistas.add("Posee la habilidad $habilidad");
    pistas.add("Pertenece a la generación $generacion");

    if(estadisticas.isEmpty){
      pistas.add("No hay estadísticas disponibles para este Pokémon");
    } else {
      final MapEntry<String, int> mejorEstadistica = estadisticas.entries.reduce((a, b) => a.value > b.value ? a : b);
      pistas.add("La estadística más alta de este Pokémon es ${_formatearEstadistica(mejorEstadistica.key)}: ${mejorEstadistica.value}");
    }
   
    pistas.add(pokemonOculto.tipos.length > 1 ? "Posee el tipo secundario ${_formatearTipo(pokemonOculto.tipos.last)}"
     : "No posee un tipo secundario");
    
    return pistas;
  }
  
  static String _formatearGeneracion(String generacion){
    const Map<String, String> numerosRomanos = {
      "i": "1",
      "ii": "2",
      "iii": "3",
      "iv": "4",
      "v": "5",
      "vi": "6",
      "vii": "7",
      "viii": "8",
      "ix": "9"
    };

    final String codigo = generacion.split("-").last.toLowerCase();
    return numerosRomanos[codigo] ?? codigo;
  }

  static String _formatearEstadistica(String estadistica){
    const Map<String, String> nombresEstadisticas = {
      "hp": "PS",
      "attack": "ataque",
      "defense": "defensa",
      "special-attack": "ataque especial",
      "special-defense": "defensa especial",
      "speed": "velocidad"
    };
    return nombresEstadisticas[estadistica] ?? estadistica;
  }

  static String _formatearTipo(String tipo){
    const Map<String, String> tiposEspanol = {
    'fire': 'fuego', 'water': 'agua', 'grass': 'planta', 'bug': 'bicho', 
    'normal': 'normal', 'flying': 'volador', 'poison': 'veneno', 
    'electric': 'eléctrico', 'ground': 'tierra', 'fairy': 'hada', 
    'fighting': 'lucha', 'psychic': 'psíquico', 'rock': 'roca', 
    'ghost': 'fantasma', 'ice': 'hielo', 'dragon': 'dragón', 
    'dark': 'siniestro', 'steel': 'acero'
    };
    return tiposEspanol[tipo] ?? tipo;
  }
}
