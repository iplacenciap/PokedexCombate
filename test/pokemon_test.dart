import 'package:flutter_test/flutter_test.dart';

import 'package:proyecto_pokedex/datos/pokemon.dart';

void main(){

  test('crear Pokemon con sus datos correctamente', (){

    final Pokemon pokemon = Pokemon(
      id: 25,
      nombre: 'pikachu',
      urlImagen: 'pikachu.png',
      tipos: ['electric'],
      altura: 4,
      peso: 60,
      descripcion: 'Pokémon eléctrico',
      habilidades: ['static'],
      estadisticas: {
        'hp': 35,
        'attack': 55
      },
      generacion: 'generation-i'
    );

    expect(pokemon.id, 25);
    expect(pokemon.nombre, 'pikachu');
    expect(pokemon.urlImagen, 'pikachu.png');
    expect(pokemon.tipos, ['electric']);
    expect(pokemon.altura, 4);
    expect(pokemon.peso, 60);
    expect(pokemon.descripcion, 'Pokémon eléctrico');
    expect(pokemon.habilidades, ['static']);
    expect(pokemon.estadisticas, {
      'hp': 35,
      'attack': 55
    });
    expect(pokemon.generacion, 'generation-i');
  });

}