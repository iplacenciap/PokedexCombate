import 'package:flutter_test/flutter_test.dart';
import 'package:proyecto_pokedex/datos/pokemon_resumen.dart';

void main(){
  test("Crear pokemon resumido correctamente", (){

  final PokemonResumen pokemonResumen = PokemonResumen(
    id: 6,
    nombre: "charizard", 
    urlImagen: "charizard.png",
    tipos: ['fuego', 'volar'],
    generacion: 1
  );

  expect(pokemonResumen.nombre, "charizard");
  expect(pokemonResumen.urlImagen, "charizard.png");
  expect(pokemonResumen.tipos, ['fuego', 'volar']);
  expect(pokemonResumen.generacion, 1);
  });
}