import 'package:proyecto_pokedex/api/buscar_pokemon_aleatorio.dart';
import 'package:proyecto_pokedex/datos/pokemon.dart';

enum EstadoPartida { noIniciada, activa, victoria, derrota }

class PartidaPokeGuesser {
  static const int intentosMaximos = 7;

  final Future<Pokemon> Function() _buscarPokemon;

  Pokemon? _pokemonAdivinar;
  int _intentosRestantes = 0;
  final List<Pokemon> _pokemonIntentados = [];
  EstadoPartida _estado = EstadoPartida.noIniciada;

  PartidaPokeGuesser({
    Future<Pokemon> Function()? getPokemon, // getPokemon es opcional y ? hace que acepte nulo, usado en tests para pasar pokemon personalizado
  }) : _buscarPokemon = getPokemon ?? buscarPokemonAleatorio;

  // getters para atributos privados
  Pokemon? get pokemonAdivinar => _pokemonAdivinar;
  int get intentosRestantes => _intentosRestantes;
  List<Pokemon> get pokemonIntentados => List.unmodifiable(_pokemonIntentados);
  EstadoPartida get estado => _estado;
  bool get estaActiva => _estado == EstadoPartida.activa;
  int get intentosIncorrectos => intentosMaximos - _intentosRestantes;

  Future<void> iniciar() async {
    _pokemonAdivinar = await _buscarPokemon();
    _prepararPartida();
  }

  Future<void> reiniciar() async {
    final Pokemon? pokemonAnterior = _pokemonAdivinar;

    Pokemon nuevoPokemon;

    // nos aseguramos de que cada pokemon seleccionado para adivinar sea distinto al que estaba previamente
    do {
      nuevoPokemon = await _buscarPokemon();
    } while (pokemonAnterior != null && nuevoPokemon.id == pokemonAnterior.id);

    _pokemonAdivinar = nuevoPokemon;
    _prepararPartida();
  }

  bool realizarIntento(Pokemon pokemon) {
    if (_estado != EstadoPartida.activa) {
      return false;
    }

    _pokemonIntentados.add(pokemon);

    if (pokemon.id == _pokemonAdivinar!.id) {
      _estado = EstadoPartida.victoria;
      return true;
    }

    _intentosRestantes--;

    if (_intentosRestantes <= 0) {
      _estado = EstadoPartida.derrota;
    }

    return false;
  }

  void _prepararPartida() {
    _intentosRestantes = intentosMaximos;
    _pokemonIntentados.clear();
    _estado = EstadoPartida.activa;
  }
}
