import 'package:flutter/material.dart';
import 'package:proyecto_pokedex/colors/app_colors.dart';
import 'package:proyecto_pokedex/datos/pokemon.dart';
import 'package:proyecto_pokedex/logica/contador_coleccion.dart';
import 'package:proyecto_pokedex/widgets/elementos_pokedex.dart';

class PantallaDescripcionPokemon extends StatelessWidget {
  final Pokemon pokemon;

  const PantallaDescripcionPokemon({super.key, required this.pokemon});

  String _formatearGeneracion(String generacion) {
    final limpia = generacion.toLowerCase().replaceFirst('generation-', '').trim();
    const numeros = {
      'i': '1',
      'ii': '2',
      'iii': '3',
      'iv': '4',
      'v': '5',
      'vi': '6',
      'vii': '7',
      'viii': '8',
      'ix': '9',
    };
    return numeros[limpia] ?? limpia;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PokedexAppColors.marfil,
      appBar: AppBar(
        title: const Text('Ficha Pokémon'),
        titleTextStyle: const TextStyle(
          color: PokedexAppColors.tinta,
          fontSize: 20,
          fontWeight: FontWeight.w800,
        ),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        foregroundColor: PokedexAppColors.tinta,
        shape: const Border(bottom: BorderSide(color: PokedexAppColors.borde)),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: anchoContenidoPokedex),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 36),
              children: [
                _portada(),
                const SizedBox(height: 16),
                LayoutBuilder(
                  builder: (context, caja) {
                    final informacion = _informacion();
                    final estadisticas = _estadisticas();

                    if (caja.maxWidth >= 680) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 3, child: informacion),
                          const SizedBox(width: 16),
                          Expanded(flex: 2, child: estadisticas),
                        ],
                      );
                    }
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        informacion,
                        const SizedBox(height: 16),
                        estadisticas,
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _portada() {
    return PanelPokedex(
      color: fondoTipoPokemon(pokemon.tipos),
      child: LayoutBuilder(
        builder: (context, caja) {
          final amplia = caja.maxWidth >= 520;
          final datos = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              EtiquetaPokedex('#${pokemon.id.toString().padLeft(3, '0')}'),
              const SizedBox(height: 10),
              Text(
                nombreVisiblePokemon(pokemon.nombre.toUpperCase()),
                style: estiloTituloPokedex,
              ),
              if (pokemon.tipos.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final tipo in pokemon.tipos)
                      EtiquetaPokedex(nombresTipos[tipo.toLowerCase()] ?? tipo),
                  ],
                ),
              ],
            ],
          );

          final imagen = SizedBox(
            height: amplia ? 214 : 156,
            child: IlustracionPokemon(pokemon.urlImagen),
          );

          if (amplia) {
            return Row(
              children: [
                Expanded(child: datos),
                const SizedBox(width: 20),
                Expanded(child: imagen),
              ],
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [datos, const SizedBox(height: 16), imagen],
          );
        },
      ),
    );
  }

  Widget _informacion() {
    return PanelPokedex(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Información', style: estiloSubtituloPokedex),
          const SizedBox(height: 10),
          _fila('Altura', '${pokemon.altura / 10} m'),
          _fila('Peso', '${pokemon.peso / 10} kg'),
          _fila('Generación', _formatearGeneracion(pokemon.generacion)),
          const Divider(height: 26, color: PokedexAppColors.borde),
          const Text('Descripción', style: estiloSubtituloPokedex),
          const SizedBox(height: 8),
          Text(
            pokemon.descripcion.isEmpty
                ? 'Descripción no disponible.'
                : pokemon.descripcion,
            style: const TextStyle(color: PokedexAppColors.tenue, height: 1.45),
          ),
          const Divider(height: 26, color: PokedexAppColors.borde),
          const Text('Habilidades', style: estiloSubtituloPokedex),
          const SizedBox(height: 8),
          if (pokemon.habilidades.isEmpty)
            const Text('Habilidades no disponibles.')
          else
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final habilidad in pokemon.habilidades)
                  EtiquetaPokedex(habilidad.replaceAll('-', ' ')),
              ],
            ),
        ],
      ),
    );
  }

  Widget _estadisticas() {
    return PanelPokedex(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Estadísticas base', style: estiloSubtituloPokedex),
          const SizedBox(height: 8),
          if (pokemon.estadisticas.isEmpty)
            const Text('Estadísticas no disponibles.')
          else
            for (final estadistica in pokemon.estadisticas.entries)
              _fila(
                estadistica.key.replaceAll('-', ' ').toUpperCase(),
                '${estadistica.value}',
              ),
        ],
      ),
    );
  }

  Widget _fila(String titulo, String valor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              titulo,
              style: const TextStyle(color: PokedexAppColors.tenue),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              valor,
              textAlign: TextAlign.end,
              style: const TextStyle(
                color: PokedexAppColors.tinta,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}