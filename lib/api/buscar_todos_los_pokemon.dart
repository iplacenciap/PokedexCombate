import 'package:http/http.dart' as http;
import 'dart:convert';
import '../datos/pokemon_resumen.dart';

Future<List<PokemonResumen>> buscarTodosLosPokemons(http.Client? client,) async{
  final http.Client clienteHttp = client ?? http.Client();

  try{
    final Map<int,PokemonResumen> mapPokemon = {};
  
    final peticiones = List.generate(18, (i) {
      final tipo = i+1;
      return clienteHttp.get(Uri.parse('https://pokeapi.co/api/v2/type/$tipo'));
    });

    final respuestas = await Future.wait(peticiones);

    for (var respuesta in respuestas){
      if(respuesta.statusCode == 200){
        final data = json.decode(respuesta.body);
        final String tipoNombre = data['name'];
        final List pokemonDelTipo = data['pokemon'];

        for(var objeto in pokemonDelTipo){
          final String url = objeto['pokemon']['url'];
          final partes = url.split('/');
          final int id = int.parse(partes[partes.length-2]);

          if(id > 1025) continue;

          final String nombre = objeto['pokemon']['name'].toString().toUpperCase();
          final String urlImagen = "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/$id.png";

          if(!mapPokemon.containsKey(id)){
            mapPokemon[id] = PokemonResumen(
              id: id,
              nombre: nombre, 
              urlImagen: urlImagen, 
              tipos: [tipoNombre], 
              generacion: obtenerGeneracion(id));
          }
          else{
            mapPokemon[id]!.tipos.add(tipoNombre);
          }
        } 
      }
      if (respuesta.statusCode != 200){
        throw Exception("Error al consultar a la PokeAPI: ${respuesta.statusCode}");
      }
    }

    final List<int> idsOrdenadas = mapPokemon.keys.toList()..sort();

    final List<PokemonResumen> resultadosPokemon = idsOrdenadas.map(
      (id) => mapPokemon[id]!).toList();
    
    return resultadosPokemon;

  }catch (e){
    throw Exception("Error al consultar a la PokeAPI: $e");
  }
}

int obtenerGeneracion(int id){
  if(id <= 151) {return 1;}
  else if(id <= 251) {return 2;}
  else if(id <= 386) {return 3;}
  else if(id <= 493) {return 4;}
  else if(id <= 649) {return 5;}
  else if(id <= 721) {return 6;}
  else if(id <= 809) {return 7;}
  else if(id <= 905) {return 8;}
  else {return 9;}
}
