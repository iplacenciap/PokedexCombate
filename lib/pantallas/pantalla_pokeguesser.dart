import 'package:flutter/material.dart';
import 'package:proyecto_pokedex/colors/app_colors.dart';
import 'package:proyecto_pokedex/logica/sistema_recompensas.dart';
import 'package:proyecto_pokedex/widgets/elementos_pokedex.dart';

import '../api/buscar_pokemon_nombre.dart';
import '../api/buscar_todos_los_pokemon.dart';
import '../datos/pokemon.dart';
import '../datos/pokemon_resumen.dart';
import '../logica/generador_pistas_pokeguesser.dart';
import '../logica/gestor_progreso.dart';
import '../logica/partida_pokeguesser.dart';
import '../utilidades/analizador_busqueda.dart';
import 'pantalla_descripcion_pokemon.dart';

class PantallaPokeGuesser extends StatefulWidget {
  final Future<Pokemon> Function()? getPokemon;
  final Future<List<PokemonResumen>> Function()? getListaPokemon;
  final Future<Pokemon> Function(String nombre)? getPokemonPorNombre;
  final GestorProgreso? gestorProgreso;

  const PantallaPokeGuesser({
    super.key,
    this.getPokemon,
    this.getListaPokemon,
    this.getPokemonPorNombre,
    this.gestorProgreso,
  });

  @override
  State<PantallaPokeGuesser> createState() => _PantallaPokeGuesserState();
}

class _PantallaPokeGuesserState extends State<PantallaPokeGuesser> {
  int victorias = 0;
  int derrotas = 0;

  late final PartidaPokeGuesser _partida;
  late final Future<List<PokemonResumen>> Function() _obtenerLista;
  late final Future<Pokemon> Function(String nombre) _obtenerPokemonPorNombre;
  List<PokemonResumen> _todosLosPokemon = [];
  List<String> pistasTotales = [];

  bool enJuego = false;
  bool cargandoJuego = false;
  bool procesandoIntento = false;

  final GlobalKey _claveCampo = GlobalKey();
  final ScrollController _controladorPistas = ScrollController();

  @override
  void initState() {
    super.initState();
    _partida = PartidaPokeGuesser(getPokemon: widget.getPokemon);
    _obtenerLista = widget.getListaPokemon ?? () => buscarTodosLosPokemons(null);
    _obtenerPokemonPorNombre =
        widget.getPokemonPorNombre ?? (nombre) => buscarPokemonNombre(nombre);
  }

  @override
  void dispose() {
    _controladorPistas.dispose();
    super.dispose();
  }

  Future<void> _empezarJuego() async {
    if (cargandoJuego) return;
    setState(() => cargandoJuego = true);

    try {
      if (_todosLosPokemon.isEmpty) {
        _todosLosPokemon = await _obtenerLista();
      }
      if (_partida.pokemonAdivinar == null) {
        await _partida.iniciar();
      } else {
        await _partida.reiniciar();
      }
      if (!mounted) return;

      setState(() {
        pistasTotales = GeneradorPistasPokeguesser.generarPistas(
          _partida.pokemonAdivinar!,
        );
        enJuego = true;
      });
    } catch (_) {
      if (mounted) _mostrarErrorDeCarga();
    } finally {
      if (mounted) setState(() => cargandoJuego = false);
    }
  }

  void _mostrarErrorDeCarga() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Error al cargar el Pokémon.')),
    );
  }

  void _reiniciarJuego() {
    setState(() => enJuego = false);
  }

  Future<bool> _guardarProgresoResultado({
    required bool victoria,
    required int recompensa,
  }) async {
    final gestor = widget.gestorProgreso;
    if (gestor == null) return true;

    try {
      await gestor.registrarResultadoPokeGuesser(
        victoria: victoria,
        recompensa: recompensa,
      );
      return true;
    } catch (e) {
      debugPrint('Error al guardar el progreso de PokéGuesser: $e');
      return false;
    }
  }

  Future<void> _realizarIntento(PokemonResumen seleccion) async {
    if (procesandoIntento || !_partida.estaActiva) return;
    setState(() => procesandoIntento = true);

    try {
      final objetivo = _partida.pokemonAdivinar!;
      final esCorrecto = seleccion.nombre.toLowerCase() == objetivo.nombre.toLowerCase();
      final intento = esCorrecto
          ? objetivo
          : await _obtenerPokemonPorNombre(seleccion.nombre);

      if (!mounted) return;
      _partida.realizarIntento(intento);
    } catch (_) {
      if (mounted) {
        setState(() => procesandoIntento = false);
        _mostrarErrorDeCarga();
      }
      return;
    }

    final victoria = _partida.estado == EstadoPartida.victoria;
    if (victoria || _partida.estado == EstadoPartida.derrota) {
      if (victoria) {
        victorias++;
      } else {
        derrotas++;
      }

      final recompensa = SistemaRecompensas.recompensaPokeguesser(
        victoria: victoria,
        intentosIncorrectos: _partida.intentosIncorrectos,
      );
      final guardado = await _guardarProgresoResultado(
        victoria: victoria,
        recompensa: recompensa,
      );
      if (!mounted) return;

      _mostrarModalResultado(
        victoria: victoria,
        recompensa: recompensa,
        errorGuardado: !guardado,
      );
    }

    if (mounted) setState(() => procesandoIntento = false);
  }

  void _mostrarModalResultado({
    required bool victoria,
    required int recompensa,
    required bool errorGuardado,
  }) {
    final pokemon = _partida.pokemonAdivinar;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        scrollable: true,
        title: Text(victoria ? '¡Victoria!' : 'Derrota'),
        content: SizedBox(
          width: 360,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (pokemon != null) ...[
                SizedBox(height: 140, child: IlustracionPokemon(pokemon.urlImagen)),
                const SizedBox(height: 8),
                Text(
                  pokemon.nombre.toUpperCase(),
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ],
              const SizedBox(height: 12),
              Text(
                victoria
                    ? '¡Has ganado $recompensa Pokémonedas!'
                    : 'Buen intento · $recompensa Pokémonedas',
                textAlign: TextAlign.center,
              ),
              if (errorGuardado) ...[
                const SizedBox(height: 10),
                const Text(
                  'La partida terminó, pero no se pudo guardar el progreso.',
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
        actions: [
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: PokedexAppColors.lima,
              foregroundColor: PokedexAppColors.tinta,
            ),
            onPressed: () {
              Navigator.of(dialogContext).pop();
              _reiniciarJuego();
            },
            child: Text(victoria ? 'Experto' : 'Reintentar'),
          ),
        ],
      ),
    );
  }

  Iterable<PokemonResumen> _buscarCoincidencias(TextEditingValue valor) {
    if (valor.text.trim().isEmpty) return const Iterable<PokemonResumen>.empty();

    final yaIntentados = _partida.pokemonIntentados
        .map((pokemon) => pokemon.nombre.toLowerCase())
        .toSet();
    return analizarYFiltrarBusqueda(
      allPokemon: _todosLosPokemon,
      filtroNombre: valor.text,
    ).where((pokemon) => !yaIntentados.contains(pokemon.nombre.toLowerCase())).take(8);
  }

  double _altoMaximoSugerencias() {
    final caja = _claveCampo.currentContext?.findRenderObject() as RenderBox?;
    if (caja == null || !caja.hasSize) return 320;

    final bordeInferior = caja.localToGlobal(Offset(0, caja.size.height)).dy;
    final disponible = MediaQuery.sizeOf(context).height - bordeInferior - 16;
    return disponible.clamp(120.0, 320.0).toDouble();
  }

  Widget _construirMarcador() {
    final progreso = widget.gestorProgreso?.perfil.progreso.pokeGuesser;
    return PanelPokedex(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Marcador', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
          const SizedBox(height: 12),
          Text('Victorias: ${progreso?.victorias ?? victorias}'),
          const Divider(color: PokedexAppColors.borde, height: 18),
          Text('Derrotas: ${progreso?.derrotas ?? derrotas}'),
        ],
      ),
    );
  }

  Widget _construirHistorial() {
    final intentos = _partida.pokemonIntentados;

    return PanelPokedex(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Pokémon intentados',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
          ),
          const SizedBox(height: 8),
          if (intentos.isEmpty)
            const Text(
              'Todavía no hay intentos.',
              style: TextStyle(color: PokedexAppColors.tenue),
            ),
          for (final intento in intentos)
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => PantallaDescripcionPokemon(pokemon: intento),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Row(
                  children: [
                    SizedBox(
                      width: 44,
                      height: 44,
                      child: IlustracionPokemon(intento.urlImagen),
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: Text(intento.nombre)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _construirPortada() => PanelPokedex(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          '¿Podrás adivinarlo?',
          style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        const Text(
          'Identifica al Pokémon a partir de sus pistas.',
          style: TextStyle(color: PokedexAppColors.tenue),
        ),
        const SizedBox(height: 14),
        const PanelPokedex(
          color: Color(0xFFEEE6F4),
          child: SizedBox(
            height: 136,
            child: IlustracionPokemon(
              'https://raw.githubusercontent.com/PokeAPI/sprites/master/'
              'sprites/pokemon/other/official-artwork/94.png',
              silueta: true,
            ),
          ),
        ),
        const SizedBox(height: 14),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: PokedexAppColors.lima,
            foregroundColor: PokedexAppColors.tinta,
          ),
          onPressed: cargandoJuego ? null : _empezarJuego,
          child: Text(cargandoJuego ? 'Cargando...' : 'Comenzar'),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final contenido = enJuego ? _construirZonaJuego() : _construirPortada();
    final resumen = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _construirMarcador(),
        const SizedBox(height: 12),
        _construirHistorial(),
      ],
    );

    return Scaffold(
      backgroundColor: PokedexAppColors.marfil,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, caja) => SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1060),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'PokéGuesser',
                      style: TextStyle(
                        color: PokedexAppColors.tinta,
                        fontSize: 34,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 14),
                    if (caja.maxWidth >= 760)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: contenido),
                          const SizedBox(width: 14),
                          SizedBox(width: 250, child: resumen),
                        ],
                      )
                    else ...[
                      contenido,
                      const SizedBox(height: 14),
                      resumen,
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _construirZonaJuego() {
    final objetivo = _partida.pokemonAdivinar;
    if (objetivo == null) return const Center(child: CircularProgressIndicator());

    final intentosFallidos = PartidaPokeGuesser.intentosMaximos - _partida.intentosRestantes;
    final mostrarSilueta = intentosFallidos >= 6;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PanelPokedex(
          child: Column(
            children: [
              Text(
                'Intentos restantes: ${_partida.intentosRestantes}',
                style: const TextStyle(color: PokedexAppColors.tenue),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 158,
                child: mostrarSilueta
                    ? IlustracionPokemon(objetivo.urlImagen, silueta: true)
                    : Center(
                        child: Text(
                          pistasTotales[intentosFallidos],
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: PokedexAppColors.tinta,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
              ),
            ],
          ),
        ),
        if (intentosFallidos > 0) ...[
          const SizedBox(height: 10),
          PanelPokedex(
            padding: const EdgeInsets.all(10),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 96),
              child: Scrollbar(
                controller: _controladorPistas,
                thumbVisibility: true,
                child: ListView(
                  controller: _controladorPistas,
                  shrinkWrap: true,
                  children: [
                    for (final pista in pistasTotales.take(intentosFallidos.clamp(0, 6).toInt()))
                      Padding(
                        padding: const EdgeInsets.only(bottom: 5),
                        child: Text('• $pista'),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
        const SizedBox(height: 12),
        if (procesandoIntento)
          const Center(child: CircularProgressIndicator(color: PokedexAppColors.bosque))
        else
          _campoIntento(),
      ],
    );
  }

  Widget _campoIntento() {
    return LayoutBuilder(
      builder: (context, caja) => SizedBox(
        key: _claveCampo,
        child: Autocomplete<PokemonResumen>(
          displayStringForOption: (pokemon) => pokemon.nombre,
          optionsBuilder: _buscarCoincidencias,
          onSelected: _realizarIntento,
          fieldViewBuilder: (context, controlador, foco, enviar) => TextField(
            controller: controlador,
            focusNode: foco,
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'Adivina el Pokémon...',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onSubmitted: (_) => enviar(),
          ),
          optionsViewBuilder: (context, seleccionar, opciones) => Align(
            alignment: Alignment.topLeft,
            child: Material(
              color: Colors.white,
              elevation: 4,
              borderRadius: BorderRadius.circular(12),
              clipBehavior: Clip.antiAlias,
              child: SizedBox(
                width: caja.maxWidth,
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: _altoMaximoSugerencias()),
                  child: ListView.builder(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    itemCount: opciones.length,
                    itemBuilder: (context, index) {
                      final opcion = opciones.elementAt(index);
                      final resaltada = AutocompleteHighlightedOption.of(context) == index;

                      return InkWell(
                        onTap: () => seleccionar(opcion),
                        child: Container(
                          color: resaltada ? PokedexAppColors.lima : null,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 40,
                                height: 40,
                                child: IlustracionPokemon(opcion.urlImagen),
                              ),
                              const SizedBox(width: 12),
                              Expanded(child: Text(opcion.nombre)),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}