import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:proyecto_pokedex/api/buscar_pokemon_aleatorio.dart';

void main(){

  test('Genera una posicion aleatoria dentro de la cantidad de pokemon disponibles', (){

    final int cantidadPokemon = 100;

    for(int i = 0; i < 100; i++){
      final int indice = generarIndicePokemonAleatorio(cantidadPokemon);

      expect(indice, inInclusiveRange(0, cantidadPokemon - 1));
    }

  });

  test('Busca el pokemon correspondiente a la posicion seleccionada', () async{

    final cliente = MockClient((request) async{

      if(request.url.path == '/api/v2/pokemon-species' && request.url.queryParameters['offset'] == null){
        return http.Response(json.encode({
          'count': 3,
          'results': []
        }), 200);
      }

      if(request.url.path == '/api/v2/pokemon-species' && request.url.queryParameters['offset'] == '1'){
        return http.Response(json.encode({
          'results': [
            {
              'name': 'pikachu'
            }
          ]
        }), 200);
      }

      if(request.url.path == '/api/v2/pokemon/pikachu'){
        return http.Response(json.encode({
          'id': 25,
          'name': 'pikachu',
          'height': 4,
          'weight': 60,
          'types': [
            {
              'type': {'name': 'electric'}
            }
          ],
          'abilities': [
            {
              'ability': {'name': 'static'}
            }
          ],
          'stats': [
            {
              'base_stat': 35,
              'stat': {'name': 'hp'}
            }
          ],
          'sprites': {
            'other': {
              'official-artwork': {
                'front_default': 'imagen'
              }
            }
          },
          'species': {
            'url': 'https://pokeapi.co/api/v2/pokemon-species/25/'
          }
        }), 200);
      }

      if(request.url.path == '/api/v2/pokemon-species/25/'){
        return http.Response(json.encode({
          'generation': {
            'name': 'generation-i'
          },
          'flavor_text_entries': [
            {
              'flavor_text': 'Pokemon de prueba',
              'language': {
                'name': 'es'
              }
            }
          ]
        }), 200);
      }

      return http.Response('', 404);
    });

    final pokemon = await buscarPokemonAleatorio(
      cliente: cliente,
      indicePokemon: 1
    );

    expect(pokemon.id, 25);
    expect(pokemon.nombre, 'pikachu');

  });

}