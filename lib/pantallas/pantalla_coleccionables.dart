import 'package:flutter/material.dart';
import 'package:proyecto_pokedex/api/buscar_pokemon_nombre.dart';
import 'package:proyecto_pokedex/api/pokedex_session_cache_service.dart';
import 'package:proyecto_pokedex/colors/app_colors.dart';
import 'package:proyecto_pokedex/datos/pokemon.dart';
import 'package:proyecto_pokedex/datos/pokemon_resumen.dart';
import 'package:proyecto_pokedex/logica/coleccion_servicio.dart';
import 'package:proyecto_pokedex/logica/contador_coleccion.dart';
import 'package:proyecto_pokedex/logica/orden_coleccion.dart';
import 'package:proyecto_pokedex/pantallas/pantalla_descripcion_pokemon.dart';
import 'package:proyecto_pokedex/utilidades/analizador_busqueda.dart';
import 'package:proyecto_pokedex/widgets/elementos_pokedex.dart';
import 'package:proyecto_pokedex/widgets/tarjeta_pokemon_coleccion.dart';

class PantallaColeccionables extends StatefulWidget {
  final PokemonSessionCacheService cacheService;
  final ColeccionServicio coleccion;
  final Future<Pokemon> Function(int id) obtenerPokemon;

  PantallaColeccionables({
    super.key,
    required this.cacheService,
    ColeccionServicio? coleccion,
    Future<Pokemon> Function(int id)? obtenerPokemon,
  }) : coleccion = coleccion ?? ColeccionServicio.instancia,
       obtenerPokemon = obtenerPokemon ?? _buscarPorId;

  static Future<Pokemon> _buscarPorId(int id) => buscarPokemonNombre('$id');

  @override
  State<PantallaColeccionables> createState() => _PantallaColeccionablesState();
}

class _PantallaColeccionablesState extends State<PantallaColeccionables> {
  final _controlador = ScrollController();
  final _idsNuevos = <int>[];

  late final Future<List<PokemonResumen>> _catalogo;
  late Set<int> _idsConocidos;

  bool _abriendoDescripcion = false;
  bool _mostrarFlecha = false;
  bool _soloFavoritos = false;
  bool _mostrarFiltros = false;

  int? _generacionElegida;
  String? _tipoElegido;
  int? _generacionAplicada;
  String? _tipoAplicado;

  @override
  void initState() {
    super.initState();
    _catalogo = widget.cacheService.getPokemonList();
    _idsConocidos = Set.of(widget.coleccion.idsObtenidos);
    widget.coleccion.addListener(_detectarNuevos);
    _controlador.addListener(_actualizarFlecha);
  }

  @override
  void dispose() {
    widget.coleccion.removeListener(_detectarNuevos);
    _controlador.dispose();
    super.dispose();
  }

  void _detectarNuevos() {
    final actuales = widget.coleccion.idsObtenidos;
    _idsNuevos.addAll(actuales.difference(_idsConocidos));
    _idsNuevos.removeWhere((id) => !actuales.contains(id));
    _idsConocidos = Set.of(actuales);
  }

  void _actualizarFlecha() {
    final mostrar = _controlador.hasClients && _controlador.offset > 400;
    if (mostrar != _mostrarFlecha) setState(() => _mostrarFlecha = mostrar);
  }

  void _irAlInicio() {
    if (_controlador.hasClients) _controlador.jumpTo(0);
  }

  void _aplicarFiltros() {
    setState(() {
      _generacionAplicada = _generacionElegida;
      _tipoAplicado = _tipoElegido;
      _mostrarFiltros = false;
    });
    _irAlInicio();
  }

  void _restablecerFiltros() {
    setState(() {
      _generacionElegida = null;
      _tipoElegido = null;
      _generacionAplicada = null;
      _tipoAplicado = null;
      _soloFavoritos = false;
      _mostrarFiltros = false;
    });
    _irAlInicio();
  }

  Future<void> _alternarFavorito(int id) async {
    try {
      await widget.coleccion.alternarFavorito(id);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo guardar el favorito.')),
      );
    }
  }

  Future<void> _abrirDescripcion(PokemonResumen resumen) async {
    if (_abriendoDescripcion) return;
    _abriendoDescripcion = true;
    try {
      final pokemon = await widget.obtenerPokemon(resumen.id);
      if (!mounted) return;
      setState(() => _idsNuevos.remove(resumen.id));
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => PantallaDescripcionPokemon(pokemon: pokemon)),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo abrir la descripción del pokemon.')),
      );
    } finally {
      _abriendoDescripcion = false;
    }
  }

  Widget _filtros() {
    final tipos = nombresTipos.entries.toList()..sort((a, b) => a.value.compareTo(b.value));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            const Text('Generación'),
            const SizedBox(width: 8),
            DropdownButton<int?>(
              key: const ValueKey('filtro_generacion'),
              value: _generacionElegida,
              items: [
                const DropdownMenuItem<int?>(child: Text('Todos')),
                for (var i = 1; i <= 9; i++)
                  DropdownMenuItem<int?>(value: i, child: Text('Generación $i')),
              ],
              onChanged: (valor) => setState(() => _generacionElegida = valor),
            ),
            const SizedBox(width: 16),
            const Text('Tipo'),
            const SizedBox(width: 8),
            DropdownButton<String?>(
              key: const ValueKey('filtro_tipo'),
              value: _tipoElegido,
              items: [
                const DropdownMenuItem<String?>(child: Text('Todos')),
                for (final tipo in tipos)
                  DropdownMenuItem<String?>(value: tipo.key, child: Text(tipo.value)),
              ],
              onChanged: (valor) => setState(() => _tipoElegido = valor),
            ),
            const SizedBox(width: 12),
            FilledButton(
              key: const ValueKey('boton_agregar_filtros'),
              onPressed: _aplicarFiltros,
              child: const Text('Aplicar filtros'),
            ),
            TextButton(
              key: const ValueKey('boton_restablecer_filtros'),
              onPressed: _restablecerFiltros,
              child: const Text('Restablecer'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: PokedexAppColors.marfil,
    child: FutureBuilder<List<PokemonResumen>>(
      future: _catalogo,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return const Center(child: Text('No se pudo cargar la colección.'));
        }
        return _album(snapshot.data!);
      },
    ),
  );

  Widget _album(List<PokemonResumen> pokemon) => ListenableBuilder(
    listenable: widget.coleccion,
    builder: (context, _) {
      final filtrados = analizarYFiltrarBusqueda(
        allPokemon: pokemon,
        filtrosTipo: _tipoAplicado == null ? null : [_tipoAplicado!],
        filtroGeneracion: _generacionAplicada,
      );
      final visibles = ordenarColeccion(
        _soloFavoritos
            ? filtrados.where((p) => widget.coleccion.esFavorito(p.id)).toList()
            : filtrados,
        estaObtenido: widget.coleccion.estaObtenido,
        idsNuevos: _idsNuevos,
      );
      final obtenidos = visibles.where((p) => widget.coleccion.estaObtenido(p.id)).length;
      final hayFiltros = _generacionAplicada != null || _tipoAplicado != null || _soloFavoritos;
      final conteo = hayFiltros
          ? textoContador(
              obtenidos: obtenidos,
              total: visibles.length,
              generacion: _generacionAplicada,
              tipo: _tipoAplicado,
              soloFavoritos: _soloFavoritos,
            )
          : '$obtenidos de ${visibles.length} obtenidos';
      final vacio = _soloFavoritos && widget.coleccion.cantidadFavoritos == 0
          ? 'Aún no tienes favoritos. Marca la estrella de un pokemon obtenido para agregarlo.'
          : 'No hay pokemons que cumplan los filtros.';

      return Stack(
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: anchoContenidoPokedex),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 26),
                child: LayoutBuilder(
                  builder: (context, caja) => CustomScrollView(
                    controller: _controlador,
                    slivers: [
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Colección', style: estiloTituloPokedex),
                              const SizedBox(height: 18),
                              Text(
                                conteo,
                                key: const ValueKey('contador_coleccion'),
                                style: const TextStyle(fontSize: 16, color: PokedexAppColors.tenue),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SliverAppBar(
                        floating: true,
                        primary: false,
                        automaticallyImplyLeading: false,
                        backgroundColor: PokedexAppColors.marfil,
                        surfaceTintColor: Colors.transparent,
                        toolbarHeight: 46,
                        titleSpacing: 0,
                        title: Row(
                          children: [
                            FilterChip(
                              key: const ValueKey('boton_favoritos'),
                              label: const Text('Solo favoritos'),
                              selected: _soloFavoritos,
                              selectedColor: PokedexAppColors.lima,
                              backgroundColor: Colors.white,
                              side: const BorderSide(color: PokedexAppColors.borde),
                              onSelected: (valor) {
                                setState(() => _soloFavoritos = valor);
                                _irAlInicio();
                              },
                            ),
                            const SizedBox(width: 7),
                            IconButton(
                              key: const ValueKey('filtros_coleccion'),
                              tooltip: 'Filtros de colección',
                              onPressed: () => setState(() => _mostrarFiltros = !_mostrarFiltros),
                              icon: const Icon(Icons.tune),
                            ),
                          ],
                        ),
                        bottom: _mostrarFiltros
                            ? PreferredSize(
                                preferredSize: const Size.fromHeight(48),
                                child: _filtros(),
                              )
                            : null,
                      ),
                      if (visibles.isEmpty)
                        SliverFillRemaining(
                          hasScrollBody: false,
                          child: Center(child: Text(vacio, textAlign: TextAlign.center)),
                        )
                      else
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(0, 9, 0, 36),
                          sliver: SliverGrid.builder(
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: columnasPokedex(caja.maxWidth),
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              mainAxisExtent: 202,
                            ),
                            itemCount: visibles.length,
                            itemBuilder: (context, i) {
                              final p = visibles[i];
                              return TarjetaPokemonColeccion(
                                key: ValueKey('tarjeta_coleccion_${p.id}'),
                                pokemon: p,
                                obtenido: widget.coleccion.estaObtenido(p.id),
                                esFavorito: widget.coleccion.esFavorito(p.id),
                                esNuevo: _idsNuevos.contains(p.id),
                                onTap: () => _abrirDescripcion(p),
                                onFavorito: () => _alternarFavorito(p.id),
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (_mostrarFlecha)
            Positioned(
              right: 16,
              bottom: 16,
              child: FloatingActionButton.small(
                key: const ValueKey('boton_volver_arriba'),
                heroTag: null,
                tooltip: 'Volver arriba',
                backgroundColor: PokedexAppColors.lima,
                foregroundColor: PokedexAppColors.tinta,
                onPressed: () => _controlador.animateTo(
                  0,
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeOut,
                ),
                child: const Icon(Icons.arrow_upward),
              ),
            ),
        ],
      );
    },
  );
}