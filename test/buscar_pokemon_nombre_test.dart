import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:proyecto_pokedex/api/buscar_pokemon_nombre.dart';

void main(){

  test('buscar Pokemon correctamente', () async{

    final MockClient clienteFalso = MockClient((request) async{

      if(request.url.path.contains('pokemon-species')){
        return http.Response(
          jsonEncode({
            'generation': {'name': 'generation-i'},
            'flavor_text_entries': [
              {
                'flavor_text': 'Pokémon eléctrico',
                'language': {'name': 'es'}
              }
            ]
          }), 200);
      }

      return http.Response(
        jsonEncode({
          'id': 25,
          'name': 'pikachu',
          'height': 4,
          'weight': 60,
          'types': [
            {'type': {'name': 'electric'}}
          ],
          'abilities': [
            {'ability': {'name': 'static'}}
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
                'front_default': 'pikachu.png'
              }
            }  
          },
          'species': {
            'url': 'https://pokeapi.co/api/v2/pokemon-species/25/',
          }
        }), 200);
    });

    final pokemon = await buscarPokemonNombre('pikachu', cliente: clienteFalso);

    expect(pokemon.id, 25);
    expect(pokemon.nombre, 'pikachu');
    expect(pokemon.tipos, ['electric']);
    expect(pokemon.generacion, 'generation-i');
    
  });


  test('normalizar nombre antes de buscar', () async{

    final MockClient clienteFalso = MockClient((request) async{

      if(request.url.path.contains('pokemon-species')){
        expect(request.url.path, '/api/v2/pokemon-species/25/');

        return http.Response(
          jsonEncode({
            'generation': {'name': 'generation-i'},
            'flavor_text_entries': []
          }), 200);
      }

      expect(request.url.path, '/api/v2/pokemon/pikachu');

      return http.Response(
        jsonEncode({
          'id': 25,
          'name': 'pikachu',
          'height': 4,
          'weight': 60,
          'types': [],
          'abilities': [],
          'stats': [],
          'sprites': {
            'other': {
              'official-artwork': {
                'front_default': 'pikachu.png'
              }
            }
          },
          'species': {
            'url': 'https://pokeapi.co/api/v2/pokemon-species/25/',
          }
        }), 200);
    });

    await buscarPokemonNombre('  PIKACHU  ',cliente: clienteFalso);});


  test('Pokemon inexistente lanza una excepcion', () async{

    final MockClient clienteFalso = MockClient((request) async{
      return http.Response('Not Found', 404);
    });

    expect(() => buscarPokemonNombre('pokemoninexistente', cliente: clienteFalso), throwsException);
    
    });


  test('error al buscar especie lanza una excepcion', () async{

    final MockClient clienteFalso = MockClient((request) async{

      if(request.url.path.contains('pokemon-species')){
        return http.Response('Not Found', 404);
      }

      return http.Response(
        jsonEncode({
          'id': 25,
          'name': 'pikachu',
          'height': 4,
          'weight': 60,
          'types': [],
          'abilities': [],
          'stats': [],
          'sprites': {
            'other': {
              'official-artwork': {
                'front_default': 'pikachu.png'
              }
            }
          },
          'species': {
            'url': 'https://pokeapi.co/api/v2/pokemon-species/25/',
          }
        }), 200);
    });

    expect(() => buscarPokemonNombre('pikachu',cliente: clienteFalso), throwsException);
  });

}