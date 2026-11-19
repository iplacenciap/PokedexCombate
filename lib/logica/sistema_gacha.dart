import 'dart:math';

import 'package:proyecto_pokedex/api/pokedex_session_cache_service.dart';
import 'package:proyecto_pokedex/datos/pokemon_resumen.dart';
import 'package:proyecto_pokedex/logica/coleccion_servicio.dart';
import 'package:proyecto_pokedex/logica/gestor_progreso.dart';

class SistemaGacha {
  static const costoTirada = 400;

  final PokemonSessionCacheService _cacheService;
  final ColeccionServicio _coleccionServicio;
  final GestorProgreso _gestor;
  final Random _random;

  SistemaGacha({
    required PokemonSessionCacheService cacheService,
    required ColeccionServicio coleccionServicio,
    required GestorProgreso gestor,
    Random? random,
  }) : _cacheService = cacheService,
       _coleccionServicio = coleccionServicio,
       _gestor = gestor,
       _random = random ?? Random();

  int get getCostoTirada => costoTirada;

  Future<List<PokemonResumen>> obtenerCatalogo() => _cacheService.getPokemonList();

  Future<ResultadoTiradaGacha?> realizarTirada() async {
    final pokemons = await obtenerCatalogo();

    if (pokemons.isEmpty) {
      throw StateError('No hay Pokémon disponibles para el sorteo');
    }

    final cobrado = await _gestor.gastarPokemonedas(costoTirada);
    if (!cobrado) return null;

    final premio = pokemons[_random.nextInt(pokemons.length)];

    try {
      await _cacheService.preloadPokemonImages([premio]);
      final resultado = await _coleccionServicio.agregarPokemon(premio.id);

      if (resultado == ResultadoAgregar.repetido) {
        const int compensacion = costoTirada ~/ 2;
        await _gestor.reembolsarPokemonedas(compensacion);

        return ResultadoTiradaGacha(
          premio: premio,
          repetido: true,
          compensacion: compensacion,
        );
      }

      return ResultadoTiradaGacha(
        premio: premio,
        repetido: false,
        compensacion: 0,
      );
    } catch (error, stackTrace) {
      await _gestor.reembolsarPokemonedas(costoTirada);
      Error.throwWithStackTrace(error, stackTrace);
    }
  }
}

class ResultadoTiradaGacha {
  final PokemonResumen premio;
  final bool repetido;
  final int compensacion;

  const ResultadoTiradaGacha({
    required this.premio,
    required this.repetido,
    required this.compensacion,
  });
}