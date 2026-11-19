import "package:flutter_test/flutter_test.dart";
import "package:proyecto_pokedex/datos/pokemon_resumen.dart";
import "package:proyecto_pokedex/api/pokedex_session_cache_service.dart";

void main() {
  group("PokemonSessionCacheService - Caché de listado", () {
    test("Debe consultar a la API solo la primera vez y luego retornar desde memoria", () async {
      int apiCallCount = 0;

      final fakePokemons = [
        PokemonResumen(
          id: 1,
          nombre: "bulbasaur",
          urlImagen: "https://ejemplo.com/bulbasaur.png",
          tipos: ["planta"],
          generacion: 1,
        ),
        PokemonResumen(
          id: 4,
          nombre: "charmander",
          urlImagen: "https://ejemplo.com/charmander.png",
          tipos: ["fuego"],
          generacion: 1,
        ),
      ];

      final cacheService = PokemonSessionCacheService(
        fetchPokemonList: () async {
          apiCallCount++;
          return fakePokemons;
        },
        preloadImage: (_) async {},
      );

      final primeraLectura = await cacheService.getPokemonList();
      final segundaLectura = await cacheService.getPokemonList();

      expect(apiCallCount, 1);
      expect(primeraLectura, fakePokemons);
      expect(segundaLectura, fakePokemons);
    });
  });
  group('PokemonSessionCacheService - Precarga de imágenes', () {
    test('Debe precargar solo las imágenes de los Pokémon seleccionados y no repetir las ya descargadas', () async {
      final List<String> urlsPrecargadas = [];

      final bulbasaur = PokemonResumen(
        id: 1,
        nombre: 'bulbasaur',
        urlImagen: 'https://ejemplo.com/bulbasaur.png',
        tipos: ['planta'],
        generacion: 1,
      );
      final charmander = PokemonResumen(
        id: 4,
        nombre: 'charmander',
        urlImagen: 'https://ejemplo.com/charmander.png',
        tipos: ['fuego'],
        generacion: 1,
      );
      final pikachu = PokemonResumen(
        id: 25,
        nombre: 'pikachu',
        urlImagen: 'https://ejemplo.com/pikachu.png',
        tipos: ['electrico'],
        generacion: 1,
      );

      final cacheService = PokemonSessionCacheService(
        fetchPokemonList: () async => [bulbasaur, charmander, pikachu],
        preloadImage: (url) async {
          urlsPrecargadas.add(url);
        },
      );

      await cacheService.preloadPokemonImages([bulbasaur, charmander]);
      await cacheService.preloadPokemonImages([charmander, pikachu]);

      expect(urlsPrecargadas.length, 3);
      expect(urlsPrecargadas, [
        'https://ejemplo.com/bulbasaur.png',
        'https://ejemplo.com/charmander.png',
        'https://ejemplo.com/pikachu.png',
      ]);
    });
  });

  test('No debe ejecutar cargas al instanciarse y debe ignorar duplicados en una misma lista o URLs vacías', () async {
      int apiCallCount = 0;
      final List<String> urlsPrecargadas = [];

      final pikachu = PokemonResumen(
        id: 25,
        nombre: 'pikachu',
        urlImagen: 'https://ejemplo.com/pikachu.png',
        tipos: ['electrico'],
        generacion: 1,
      );
      final pokemonSinImagen = PokemonResumen(
        id: 999,
        nombre: 'missingno',
        urlImagen: '', // URL vacía
        tipos: ['normal'],
        generacion: 1,
      );

      final cacheService = PokemonSessionCacheService(
        fetchPokemonList: () async {
          apiCallCount++;
          return [pikachu];
        },
        preloadImage: (url) async {
          urlsPrecargadas.add(url);
        },
      );

      expect(apiCallCount, 0);
      expect(urlsPrecargadas, isEmpty);

      await cacheService.preloadPokemonImages([pikachu, pikachu, pokemonSinImagen]);

      expect(urlsPrecargadas.length, 1);
      expect(urlsPrecargadas, ['https://ejemplo.com/pikachu.png']);
    });
}