import 'package:flutter/material.dart';
import 'package:proyecto_pokedex/colors/app_colors.dart';
import 'package:proyecto_pokedex/datos/pokemon_resumen.dart';
import 'package:proyecto_pokedex/widgets/elementos_pokedex.dart';

class TarjetaPokemonColeccion extends StatelessWidget {
  final PokemonResumen pokemon;
  final bool obtenido;
  final bool esFavorito;
  final bool esNuevo;
  final VoidCallback? onTap;
  final VoidCallback? onFavorito;

  const TarjetaPokemonColeccion({
    super.key,
    required this.pokemon,
    required this.obtenido,
    this.esFavorito = false,
    this.esNuevo = false,
    this.onTap,
    this.onFavorito,
  });

  @override
  Widget build(BuildContext context) => TarjetaVisualPokemon(
    pokemon: pokemon,
    oculto: !obtenido,
    onTap: obtenido ? onTap : null,
    adornos: [
      if (obtenido && esNuevo)
        const Positioned(
          right: 8,
          bottom: 8,
          child: IgnorePointer(child: EtiquetaPokedex('NUEVO')),
        ),
      if (obtenido)
        Positioned(
          top: 2,
          right: 2,
          child: IconButton(
            key: ValueKey('estrella_${pokemon.id}'),
            tooltip: esFavorito ? 'Quitar favorito' : 'Marcar favorito',
            onPressed: onFavorito,
            icon: Icon(
              esFavorito ? Icons.star : Icons.star_border,
              size: 20,
              color: PokedexAppColors.tinta,
            ),
          ),
        ),
    ],
  );
}