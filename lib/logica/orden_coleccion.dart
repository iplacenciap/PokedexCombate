import 'package:proyecto_pokedex/datos/pokemon_resumen.dart';

List<PokemonResumen> ordenarColeccion(
  List<PokemonResumen> pokemones, {
  required bool Function(int id) estaObtenido,
  List<int> idsNuevos = const [],
}) {
  final nuevos = <PokemonResumen>[];
  final obtenidos = <PokemonResumen>[];
  final ocultos = <PokemonResumen>[];

  for (final pokemon in pokemones) {
    if (!estaObtenido(pokemon.id)) {
      ocultos.add(pokemon);
    } else if (idsNuevos.contains(pokemon.id)) {
      nuevos.add(pokemon);
    } else {
      obtenidos.add(pokemon);
    }
  }

  nuevos.sort(
    (a, b) => idsNuevos.indexOf(b.id).compareTo(idsNuevos.indexOf(a.id)),
  );
  obtenidos.sort((a, b) => a.id.compareTo(b.id));
  ocultos.sort((a, b) => a.id.compareTo(b.id));

  return [...nuevos, ...obtenidos, ...ocultos];
}