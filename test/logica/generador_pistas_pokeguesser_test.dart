import 'package:flutter_test/flutter_test.dart';
import 'package:proyecto_pokedex/datos/pokemon.dart';
import 'package:proyecto_pokedex/logica/generador_pistas_pokeguesser.dart';

void main() {
  test('Genera las pistas a partir de los datos del Pokémon', () {
    final Pokemon pokemon = Pokemon(
      id: 25,
      nombre: 'charizard',
      urlImagen: 'charizard.png',
      tipos: ['fire', 'flying'],
      altura: 4,
      peso: 60,
      descripcion: 'Charizard es de tipo fuego y volador. Es conocido por su gran poder y su habilidad para lanzar llamas.',
      habilidades: ['habilidad1', 'habilidad2'],
      estadisticas: {
        'hp': 35,
        'speed': 90,
      },
      generacion: 'generation-ii',
    );

    expect(
      GeneradorPistasPokeguesser.generarPistas(pokemon),
      [
        'El tipo principal de este Pokémon es fuego',
        'Este Pokémon tiene un peso de 6.0 kg y una altura de 0.4 m',
        'Posee la habilidad habilidad1',
        'Pertenece a la generación 2',
        'La estadística más alta de este Pokémon es velocidad: 90',
        'Posee el tipo secundario volador',
      ],
    );
  });

  test('Maneja datos faltantes al generar pistas', () {
    final Pokemon pokemon = Pokemon(
      id: 1,
      nombre: 'bulbasaur',
      urlImagen: 'bulbasaur.png',
      tipos: [],
      altura: 7,
      peso: 69,
      descripcion: '',
      habilidades: [],
      estadisticas: {},
      generacion: 'generation-x',
    );

    expect(
      GeneradorPistasPokeguesser.generarPistas(pokemon),
      [
        'El tipo principal de este Pokémon es desconocido',
        'Este Pokémon tiene un peso de 6.9 kg y una altura de 0.7 m',
        'Posee la habilidad desconocida',
        'Pertenece a la generación x',
        'No hay estadísticas disponibles para este Pokémon',
        'No posee un tipo secundario',
      ],
    );
  });
}
