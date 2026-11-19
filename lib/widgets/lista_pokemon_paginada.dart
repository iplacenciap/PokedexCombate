import 'package:flutter/material.dart';
import 'package:proyecto_pokedex/datos/pokemon_resumen.dart';
import 'package:proyecto_pokedex/widgets/elementos_pokedex.dart';

class ListaPokemonPaginada extends StatefulWidget {
  final List<PokemonResumen> pokemones;
  final int paginaActual;
  final int totalPaginas;
  final VoidCallback? onAnterior;
  final VoidCallback? onSiguiente;
  final Widget? encabezado;

  const ListaPokemonPaginada({
    super.key,
    required this.pokemones,
    required this.paginaActual,
    required this.totalPaginas,
    required this.onAnterior,
    required this.onSiguiente,
    this.encabezado,
  });

  @override
  State<ListaPokemonPaginada> createState() => _ListaPokemonPaginadaState();
}

class _ListaPokemonPaginadaState extends State<ListaPokemonPaginada> {
  final _scroll = ScrollController();

  @override
  void didUpdateWidget(covariant ListaPokemonPaginada anterior) {
    super.didUpdateWidget(anterior);
    if (anterior.paginaActual != widget.paginaActual && _scroll.hasClients) {
      _scroll.jumpTo(0);
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, caja) {
      final pokemon = widget.pokemones;
      final columnas = columnasPokedex(caja.maxWidth);
      final filas = (pokemon.length / columnas).ceil();

      return ListView.builder(
        controller: _scroll,
        itemCount: filas + 2,
        itemBuilder: (context, indice) {
          if (indice == 0) return widget.encabezado ?? const SizedBox.shrink();
          if (indice == filas + 1) return _pie();

          //ListView de pokemons.
          final inicio = (indice - 1) * columnas;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                for (var i = 0; i < columnas; i++) ...[
                  if (i > 0) const SizedBox(width: 12),
                  Expanded(
                    child: inicio + i < pokemon.length
                        ? SizedBox(
                            height: 202,
                            child: TarjetaVisualPokemon(
                              pokemon: pokemon[inicio + i],
                              onTap: () => abrirFichaDeCatalogo(context, pokemon[inicio + i]),
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                ],
              ],
            ),
          );
        },
      );
    },
  );

  Widget _pie() {
    if (widget.pokemones.isEmpty) {
      return const PanelPokedex(
        child: Text('No se han encontrado Pokémon con esas características'),
      );
    }

    //Controles de paginación.
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 16,
        children: [
          // Botón Anterior
          OutlinedButton.icon(
            //Si la pagina es 1, se deshabilita el botón.
            onPressed: widget.paginaActual > 1 ? widget.onAnterior : null,
            icon: const Icon(Icons.arrow_back),
            label: const Text('Anterior'),
          ),

          // Indicador de página actual
          Text('${widget.paginaActual}/${widget.totalPaginas}'),

          // Botón Siguiente
          OutlinedButton.icon(
            // Si es la última página, se deshabilita el botón.
            onPressed: widget.paginaActual < widget.totalPaginas ? widget.onSiguiente : null,
            icon: const Icon(Icons.arrow_forward),
            label: const Text('Siguiente'),
          ),
        ],
      ),
    );
  }
}