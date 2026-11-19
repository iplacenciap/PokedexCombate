import 'package:flutter/material.dart';
import 'package:proyecto_pokedex/api/buscar_pokemon_nombre.dart';
import 'package:proyecto_pokedex/colors/app_colors.dart';
import 'package:proyecto_pokedex/datos/pokemon_resumen.dart';
import 'package:proyecto_pokedex/logica/contador_coleccion.dart';
import 'package:proyecto_pokedex/pantallas/pantalla_descripcion_pokemon.dart';

const anchoContenidoPokedex = 1164.0;

const estiloTituloPokedex = TextStyle(
  color: PokedexAppColors.tinta,
  fontSize: 38,
  fontWeight: FontWeight.w800,
  letterSpacing: -1.3,
  height: 1.13,
);

const estiloSubtituloPokedex = TextStyle(
  color: PokedexAppColors.tinta,
  fontSize: 22,
  fontWeight: FontWeight.w800,
);

class PanelPokedex extends StatelessWidget {
  final Widget child;
  final Color color;
  final EdgeInsetsGeometry padding;

  const PanelPokedex({
    super.key,
    required this.child,
    this.color = Colors.white,
    this.padding = const EdgeInsets.all(20),
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: padding,
    decoration: BoxDecoration(
      color: color,
      border: Border.all(color: PokedexAppColors.borde),
      borderRadius: BorderRadius.circular(20),
    ),
    child: child,
  );
}

class IlustracionPokemon extends StatelessWidget {
  final String url;
  final bool silueta;

  const IlustracionPokemon(this.url, {super.key, this.silueta = false});

  @override
  Widget build(BuildContext context) {
    const respaldo = Center(
      child: Icon(Icons.catching_pokemon, size: 42, color: PokedexAppColors.tenue),
    );
    final imagen = url.isEmpty
        ? respaldo
        : Image.network(
            url,
            fit: BoxFit.contain,
            excludeFromSemantics: true,
            errorBuilder: (_, _, _) => respaldo,
          );

    return silueta
        ? ColorFiltered(
            colorFilter: const ColorFilter.mode(PokedexAppColors.tinta, BlendMode.srcIn),
            child: imagen,
          )
        : imagen;
  }
}

class EtiquetaPokedex extends StatelessWidget {
  final String texto;

  const EtiquetaPokedex(this.texto, {super.key});

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: PokedexAppColors.marfil,
      borderRadius: BorderRadius.circular(7),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      child: Text(
        texto,
        style: const TextStyle(
          color: PokedexAppColors.tenue,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          height: 1.1,
        ),
      ),
    ),
  );
}

String nombreVisiblePokemon(String nombre) {
  final texto = nombre.replaceAll('-', ' ').trim();
  if (texto.isEmpty || texto != texto.toUpperCase()) return texto;
  return texto[0] + texto.substring(1).toLowerCase();
}

Color fondoTipoPokemon(List<String> tipos) {
  final tipo = tipos.isEmpty
      ? null
      : tipos[tipos.length > 1 ? 1 : 0].toLowerCase();

  return switch (tipo) {
    'grass' || 'bug' => const Color(0xFFE3EEDB),
    'fire' || 'fighting' => const Color(0xFFF6E7DA),
    'water' || 'ice' || 'flying' => const Color(0xFFE1EDF2),
    'electric' => const Color(0xFFF7EFCE),
    'dragon' || 'ground' || 'rock' => const Color(0xFFF3EBD6),
    'poison' || 'ghost' || 'psychic' || 'fairy' =>
      const Color(0xFFEEE6F4),
    'dark' => const Color(0xFFEBEBE1),
    'steel' => const Color(0xFFE1EBF0),
    _ => PokedexAppColors.marfil,
  };
}

int columnasPokedex(double ancho) => switch (ancho) {
  >= 920 => 4,
  >= 620 => 3,
  >= 265 => 2,
  _ => 1,
};

class TarjetaVisualPokemon extends StatelessWidget {
  final PokemonResumen pokemon;
  final bool oculto;
  final VoidCallback? onTap;
  final List<Widget> adornos;

  const TarjetaVisualPokemon({
    super.key,
    required this.pokemon,
    this.oculto = false,
    this.onTap,
    this.adornos = const [],
  });

  @override
  Widget build(BuildContext context) {
    final forma = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(17),
      side: const BorderSide(color: PokedexAppColors.borde),
    );

    final contenido = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: ColoredBox(
            color: oculto ? const Color(0xFFD8E0D6) : fondoTipoPokemon(pokemon.tipos),
            child: Stack(
              children: [
                Positioned.fill(
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: IlustracionPokemon(pokemon.urlImagen, silueta: oculto),
                  ),
                ),
                Positioned(
                  top: 8,
                  left: 8,
                  child: EtiquetaPokedex('#${pokemon.id.toString().padLeft(3, '0')}'),
                ),
                ...adornos,
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 9),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                oculto ? 'Por descubrir' : nombreVisiblePokemon(pokemon.nombre),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: PokedexAppColors.tinta,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (!oculto && pokemon.tipos.isNotEmpty) ...[
                const SizedBox(height: 5),
                Wrap(
                  spacing: 4,
                  runSpacing: 3,
                  children: [
                    for (final tipo in pokemon.tipos)
                      EtiquetaPokedex(nombresTipos[tipo.toLowerCase()] ?? tipo),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );

    if (oculto) {
      return DecoratedBox(
        decoration: ShapeDecoration(color: Colors.white, shape: forma),
        child: ClipRRect(borderRadius: BorderRadius.circular(17), child: contenido),
      );
    }

    return Material(
      color: Colors.white,
      shape: forma,
      clipBehavior: Clip.antiAlias,
      child: InkWell(onTap: onTap, child: contenido),
    );
  }
}

Future<void> abrirFichaDeCatalogo(
  BuildContext context,
  PokemonResumen resumen,
) async {
  try {
    final pokemon = await buscarPokemonNombre('${resumen.id}');
    if (!context.mounted) return;

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PantallaDescripcionPokemon(pokemon: pokemon),
      ),
    );
  } catch (_) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('No se pudo abrir la ficha del Pokémon.')),
    );
  }
}