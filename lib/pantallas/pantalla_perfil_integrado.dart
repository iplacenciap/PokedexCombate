import 'package:flutter/material.dart';
import 'package:proyecto_pokedex/api/pokedex_session_cache_service.dart';
import 'package:proyecto_pokedex/datos/perfil_jugador.dart';
import 'package:proyecto_pokedex/datos/pokemon_resumen.dart';
import 'package:proyecto_pokedex/logica/coleccion_servicio.dart';
import 'package:proyecto_pokedex/logica/gestor_progreso.dart';
import 'package:proyecto_pokedex/pantallas/pantalla_perfil.dart';

/// Adapta los datos existentes de economía y colección a la pantalla de perfil.
/// No posee ni guarda una segunda copia de monedas, colección o favoritos.
class PantallaPerfilIntegrado extends StatefulWidget {
  final GestorProgreso gestorProgreso;
  final ColeccionServicio coleccion;
  final PokemonSessionCacheService cacheService;
  final Future<void> Function(PerfilJugador) guardarPerfil;
  final VoidCallback onAbrirColeccion;
  final ValueChanged<PokemonResumen> onAbrirPokemon;

  const PantallaPerfilIntegrado({
    super.key,
    required this.gestorProgreso,
    required this.coleccion,
    required this.cacheService,
    required this.guardarPerfil,
    required this.onAbrirColeccion,
    required this.onAbrirPokemon,
  });

  @override
  State<PantallaPerfilIntegrado> createState() =>
      _PantallaPerfilIntegradoState();
}

class _PantallaPerfilIntegradoState extends State<PantallaPerfilIntegrado> {
  late Future<List<PokemonResumen>> _futuroCatalogo;
  late Listenable _fuentesCambios;

  @override
  void initState() {
    super.initState();

    _futuroCatalogo = widget.cacheService.getPokemonList();

    _fuentesCambios = Listenable.merge([
      widget.gestorProgreso,
      widget.coleccion,
    ]);
  }

  @override
  void didUpdateWidget(covariant PantallaPerfilIntegrado anterior) {
    super.didUpdateWidget(anterior);

    if (anterior.cacheService != widget.cacheService) {
      _futuroCatalogo = widget.cacheService.getPokemonList();
    }

    if (anterior.gestorProgreso != widget.gestorProgreso ||
        anterior.coleccion != widget.coleccion) {
      _fuentesCambios = Listenable.merge([
        widget.gestorProgreso,
        widget.coleccion,
      ]);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _fuentesCambios,
      builder: (context, _) {
        return FutureBuilder<List<PokemonResumen>>(
          future: _futuroCatalogo,
          builder: (context, snapshot) {
            final catalogo = snapshot.data ?? const <PokemonResumen>[];

            final favoritos = catalogo
                .where((pokemon) => widget.coleccion.esFavorito(pokemon.id))
                .toList();

            return PantallaPerfil(
              perfil: widget.gestorProgreso.perfil,
              guardarPerfil: widget.guardarPerfil,
              saldoPokemonedas: widget.gestorProgreso.perfil.saldoMonedas,
              cantidadPokemonColeccionados: widget.coleccion.cantidadObtenidos,
              totalPokemonDisponibles: snapshot.hasData
                  ? catalogo.length
                  : null,
              favoritos: favoritos,

              // Si falló el catálogo, no confundirlo con
              // que el jugador no tenga favoritos.
              errorCargaFavoritos: snapshot.hasError,

              onAbrirColeccion: widget.onAbrirColeccion,
              onAbrirPokemon: widget.onAbrirPokemon,
            );
          },
        );
      },
    );
  }
}
