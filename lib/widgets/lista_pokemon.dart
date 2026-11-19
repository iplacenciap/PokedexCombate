import 'package:flutter/material.dart';
import 'package:proyecto_pokedex/datos/pokemon_resumen.dart';

class ListaPokemon extends StatelessWidget{
  final List<PokemonResumen> resultados;

  final Future<void> Function(PokemonResumen pokemon) onPokemonTap;

  const ListaPokemon({
    super.key,
    required this.resultados,
    required this.onPokemonTap,
  });

  @override
  Widget build(BuildContext context){
    return Expanded(
      child: ListView.builder(
        itemCount: resultados.length,
        itemBuilder: (context, index) {
          final pokemon = resultados[index];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Card(
              child: ListTile(
                title: Text(pokemon.nombre.toUpperCase()),
                leading: Image.network(
                  pokemon.urlImagen,
                  width: 50,
                  errorBuilder: (context, error, stackTrace) => const Icon(Icons.catching_pokemon),
                ),
                onTap: () => onPokemonTap(pokemon),
              ),
            ),
          ); 
        },
      ),
    );
  } 
}