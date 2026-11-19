import 'package:http/http.dart' as http;
import 'dart:convert';
import '../datos/pokemon.dart';

Future<Pokemon> buscarPokemonNombre(
  String nombre, {
  http.Client? cliente,
}) async {
  final String nombreBuscado = nombre.trim().toLowerCase();
  final http.Client clienteHttp = cliente ?? http.Client();

  // datos correspondientes a pokemon en la API
  final url = Uri.parse(
    'https://pokeapi.co/api/v2/pokemon/$nombreBuscado',
  );
  final respuestaPokemon = await clienteHttp.get(url);

  if (respuestaPokemon.statusCode != 200) {
    throw Exception('No se pudo encontrar el Pokémon $nombre');
  }

  final Map<String, dynamic> datos = json.decode(respuestaPokemon.body);

  final int id = datos['id'];
  final String nombrePokemon = datos['name'];
  final int altura = datos['height'];
  final int peso = datos['weight'];

  final List<String> tipos = [];
  for (var tipo in datos['types']) {
    tipos.add(tipo['type']['name']);
  }

  const ordenTipos = [
    'normal',
    'fighting',
    'flying',
    'poison',
    'ground',
    'rock',
    'bug',
    'ghost',
    'steel',
    'fire',
    'water',
    'grass',
    'electric',
    'psychic',
    'ice',
    'dragon',
    'dark',
    'fairy',
  ];

  tipos.sort((a, b) {
    final posicionA = ordenTipos.indexOf(a);
    final posicionB = ordenTipos.indexOf(b);
    final ordenA = posicionA < 0 ? ordenTipos.length : posicionA;
    final ordenB = posicionB < 0 ? ordenTipos.length : posicionB;
    final comparacion = ordenA.compareTo(ordenB);

    return comparacion != 0 ? comparacion : a.compareTo(b);
  });

  final List<String> habilidades = [];
  for (var habilidad in datos['abilities']) {
    habilidades.add(habilidad['ability']['name']);
  }

  final Map<String, int> estadisticas = {};
  for (var estadistica in datos['stats']) {
    String nombreEstadistica = estadistica['stat']['name'];
    int valor = estadistica['base_stat'];

    estadisticas[nombreEstadistica] = valor;
  }

  final String urlImagen =
      datos['sprites']['other']['official-artwork']['front_default'];

  // datos correspondientes a pokemon-species en la API, aca se encuentran la generacion y la mini descripcion de la Pokedex
  final urlEspecie = Uri.parse(datos['species']['url'] as String);
  final respuestaEspecie = await clienteHttp.get(urlEspecie);

  if (respuestaEspecie.statusCode != 200) {
    throw Exception(
      'No se pudo encontrar la especie del Pokémon $nombre',
    );
  }

  final Map<String, dynamic> datosEspecie = json.decode(
    respuestaEspecie.body,
  );

  final String generacion = datosEspecie['generation']['name'];

  String descripcionPokedex = '';
  for (var descripcion in datosEspecie['flavor_text_entries']) {
    if (descripcion['language']['name'] == 'es') {
      descripcionPokedex = descripcion['flavor_text']
          .replaceAll('\n', ' ')
          .replaceAll('\f', ' ');
      break;
    }
  }

  return Pokemon(
    id: id,
    nombre: nombrePokemon,
    urlImagen: urlImagen,
    tipos: tipos,
    altura: altura,
    peso: peso,
    descripcion: descripcionPokedex,
    habilidades: habilidades,
    estadisticas: estadisticas,
    generacion: generacion,
  );
}