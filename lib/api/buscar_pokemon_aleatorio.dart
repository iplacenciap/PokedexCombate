import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math';
import '../datos/pokemon.dart';
import 'buscar_pokemon_nombre.dart';

int generarIndicePokemonAleatorio(int cantidadPokemon){

  return Random().nextInt(cantidadPokemon);

}

Future<Pokemon> buscarPokemonAleatorio({http.Client? cliente, int? indicePokemon}) async{

  final http.Client clienteHttp = cliente ?? http.Client();

  // se obtiene la cantidad total de especies disponibles en la API
  final urlCantidad = Uri.parse('https://pokeapi.co/api/v2/pokemon-species?limit=1');
  final respuestaCantidad = await clienteHttp.get(urlCantidad);

  if(respuestaCantidad.statusCode != 200){
    throw Exception('No se pudo obtener la cantidad de Pokémon');
  }

  final Map<String, dynamic> datosCantidad = json.decode(respuestaCantidad.body);

  final int cantidadPokemon = datosCantidad['count'];
  final int indice = indicePokemon ?? generarIndicePokemonAleatorio(cantidadPokemon);

  // se obtiene el nombre de la especie seleccionada aleatoriamente
  final urlPokemon = Uri.parse('https://pokeapi.co/api/v2/pokemon-species?limit=1&offset=$indice');
  final respuestaPokemon = await clienteHttp.get(urlPokemon);

  if(respuestaPokemon.statusCode != 200){
    throw Exception('No se pudo obtener un Pokémon aleatorio');
  }

  final Map<String, dynamic> datosPokemon = json.decode(respuestaPokemon.body);

  final String nombrePokemon = datosPokemon['results'][0]['name'];

  return buscarPokemonNombre(nombrePokemon, cliente: clienteHttp);

}