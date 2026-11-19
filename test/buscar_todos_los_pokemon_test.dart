import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:http/http.dart' as http;
import 'package:proyecto_pokedex/api/buscar_todos_los_pokemon.dart';
import 'package:proyecto_pokedex/datos/pokemon_resumen.dart';

void main() {
  late List<PokemonResumen> resultados;

  setUpAll(() async {
    final MockClient clienteFalso = MockClient((request) async {
      final idTipo = int.parse(request.url.pathSegments.last);

      final datos = switch (idTipo) {
        4 => {
          "name": "poison",
          "pokemon": [
            {"pokemon": {"name": "bulbasaur", "url": "https://pokeapi.co/api/v2/pokemon/1/"}},
            {"pokemon": {"name": "pecharunt", "url": "https://pokeapi.co/api/v2/pokemon/1025/"}}
          ]
        },
        8 => {
          "name": "ghost",
          "pokemon": [
            {"pokemon": {"name": "pecharunt", "url": "https://pokeapi.co/api/v2/pokemon/1025/"}}
          ]
        },
        12 => {
          "name": "grass",
          "pokemon": [
            {"pokemon": {"name": "bulbasaur", "url": "https://pokeapi.co/api/v2/pokemon/1/"}},
            {"pokemon": {"name": "ivysaur", "url": "https://pokeapi.co/api/v2/pokemon/2/"}}
          ]
        },
        _ => {
          "name": "tipo_$idTipo",
          "pokemon": []
        }
      };         
      return http.Response(jsonEncode(datos), 200);
    }); 

    addTearDown(clienteFalso.close);

    resultados = await buscarTodosLosPokemons(clienteFalso);
  });

  test("Devuelve 3 pokemons", () async{

    expect(resultados.length, 3);
  });

  test("El primer pokemon es Bulbasaur", () async{
    final bulbaaur = resultados.first;

    expect(bulbaaur.nombre, "BULBASAUR");
    expect(bulbaaur.tipos, containsAll(['grass', 'poison']));
    expect(bulbaaur.generacion, 1);
  });

  test("El ultimo pokemon es Pecharunt", () async{
    final pecharunt = resultados.last;

    expect(pecharunt.nombre, "PECHARUNT");
    expect(pecharunt.tipos, containsAll(['poison', 'ghost']));
    expect(pecharunt.generacion, 9);
  });

  test("No hay pokemons duplicados y estan ordenados por id", () async{

    expect(resultados.where((pokemon) => pokemon.nombre == "BULBASAUR").length, 1);
    expect(resultados.where((pokemon) => pokemon.nombre == "IVYSAUR").length, 1);
    expect(resultados.where((pokemon) => pokemon.nombre == "PECHARUNT").length, 1);

    expect(resultados.map((pokemon) => pokemon.nombre).toList(), ["BULBASAUR", "IVYSAUR", "PECHARUNT"]);
  });

  test("Falla si la PokeAPI devuelve un error HTTP", () async{
    final MockClient clienteFalso = MockClient((request) async {
      return http.Response("", 500);
    });

    addTearDown(clienteFalso.close);

    expect(() async => await buscarTodosLosPokemons(clienteFalso), throwsException);
  });
}