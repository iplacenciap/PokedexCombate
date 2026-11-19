import 'package:flutter_test/flutter_test.dart';
import 'package:proyecto_pokedex/datos/pokemon.dart';
import 'package:proyecto_pokedex/logica/partida_pokeguesser.dart';

Pokemon crearPokemonPrueba({int id = 25, String nombre = 'pikachu'}) {
  return Pokemon(
    id: id,
    nombre: nombre,
    urlImagen: '',
    tipos: [],
    altura: 0,
    peso: 0,
    descripcion: '',
    habilidades: [],
    estadisticas: {},
    generacion: '',
  );
}

void main() {
  test('La partida comienza con un estado inicial correcto', () {
    final PartidaPokeGuesser partida = PartidaPokeGuesser();

    expect(partida.pokemonAdivinar, isNull);
    expect(partida.intentosRestantes, 0);
    expect(partida.pokemonIntentados, isEmpty);
    expect(partida.estaActiva, false);
    expect(partida.estado, EstadoPartida.noIniciada);
  });

  test('No se registran intentos si la partida no esta activa', () {
    final PartidaPokeGuesser partida = PartidaPokeGuesser();
    final Pokemon pokemon = crearPokemonPrueba();

    final bool resultado = partida.realizarIntento(pokemon);

    expect(resultado, false);
    expect(partida.pokemonIntentados, isEmpty);
    expect(partida.intentosRestantes, 0);
    expect(partida.estado, EstadoPartida.noIniciada);
  });

  test('Reiniciar restablece el estado y cambia el Pokemon objetivo', () async {
    final Pokemon primerPokemon = crearPokemonPrueba(id: 25, nombre: 'pikachu');

    final Pokemon segundoPokemon = crearPokemonPrueba(
      id: 1,
      nombre: 'bulbasaur',
    );

    final List<Pokemon> pokemones = [primerPokemon, segundoPokemon];

    int indice = 0;

    final PartidaPokeGuesser partida = PartidaPokeGuesser(
      getPokemon: () async {
        final Pokemon pokemon = pokemones[indice];
        indice++;
        return pokemon;
      },
    );

    await partida.iniciar();

    final Pokemon intentoIncorrecto = crearPokemonPrueba(
      id: -1,
      nombre: 'incorrecto',
    );

    partida.realizarIntento(intentoIncorrecto);

    expect(partida.intentosRestantes, 6);
    expect(partida.pokemonIntentados.length, 1);

    await partida.reiniciar();

    expect(partida.pokemonAdivinar!.id, segundoPokemon.id);
    expect(partida.intentosRestantes, PartidaPokeGuesser.intentosMaximos);
    expect(partida.pokemonIntentados, isEmpty);
    expect(partida.estado, EstadoPartida.activa);
  });

  test(
    'Un intento incorrecto se registra y reduce los intentos restantes',
    () async {
      final Pokemon objetivo = crearPokemonPrueba();
      final Pokemon pokemonIncorrecto = crearPokemonPrueba(
        id: -1,
        nombre: 'incorrecto',
      );

      final PartidaPokeGuesser partida = PartidaPokeGuesser(
        getPokemon: () async => objetivo,
      );

      await partida.iniciar();

      final bool resultado = partida.realizarIntento(pokemonIncorrecto);

      expect(resultado, false);
      expect(partida.intentosRestantes, 6);
      expect(partida.pokemonIntentados.length, 1);
      expect(partida.pokemonIntentados.first.id, pokemonIncorrecto.id);
      expect(partida.estado, EstadoPartida.activa);
    },
  );

  test(
    'Adivinar el Pokemon objetivo finaliza la partida con victoria',
    () async {
      final Pokemon objetivo = crearPokemonPrueba();

      final PartidaPokeGuesser partida = PartidaPokeGuesser(
        getPokemon: () async => objetivo,
      );

      await partida.iniciar();

      final bool resultado = partida.realizarIntento(objetivo);

      expect(resultado, true);
      expect(partida.estado, EstadoPartida.victoria);
      expect(partida.estaActiva, false);
      expect(partida.intentosRestantes, PartidaPokeGuesser.intentosMaximos);
      expect(partida.pokemonIntentados.length, 1);
    },
  );

  test('Agotar todos los intentos finaliza la partida con derrota', () async {
    final Pokemon objetivo = crearPokemonPrueba();

    final Pokemon pokemonIncorrecto = crearPokemonPrueba(
      id: -1,
      nombre: 'incorrecto',
    );

    final PartidaPokeGuesser partida = PartidaPokeGuesser(
      getPokemon: () async => objetivo,
    );

    await partida.iniciar();

    for (int i = 0; i < PartidaPokeGuesser.intentosMaximos; i++) {
      partida.realizarIntento(pokemonIncorrecto);
    }

    expect(partida.intentosRestantes, 0);
    expect(partida.estado, EstadoPartida.derrota);
    expect(partida.estaActiva, false);
    expect(
      partida.pokemonIntentados.length,
      PartidaPokeGuesser.intentosMaximos,
    );

    final bool resultadoExtra = partida.realizarIntento(pokemonIncorrecto);

    expect(resultadoExtra, false);
    expect(partida.intentosRestantes, 0);
    expect(
      partida.pokemonIntentados.length,
      PartidaPokeGuesser.intentosMaximos,
    );
  });
}
