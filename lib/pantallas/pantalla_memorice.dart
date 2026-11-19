import 'package:flutter/material.dart';
import 'package:proyecto_pokedex/api/buscar_todos_los_pokemon.dart';
import 'package:proyecto_pokedex/api/pokedex_session_cache_service.dart';
import 'package:proyecto_pokedex/colors/app_colors.dart';
import 'package:proyecto_pokedex/logica/enums/estado_memorice.dart';
import 'package:proyecto_pokedex/logica/gestor_progreso.dart';
import 'package:proyecto_pokedex/logica/sistema_recompensas.dart';
import 'package:proyecto_pokedex/widgets/elementos_pokedex.dart';

import '../datos/pokemon_resumen.dart';
import '../logica/enums/dificultad_memorice.dart';
import '../logica/partida_memorice.dart';

class PantallaMemorice extends StatefulWidget {
  /// Permite inyectar una partida controlada en los Widget Tests (sin internet)
  final PartidaMemorice? partidaInyectada;

  /// Permite usar un caché de sesión compartido si no se inyecta la partida directamente
  final PokemonSessionCacheService? cacheService;

  /// Gestor de progreso del jugador para guardar victorias y derrotas en el perfil
  final GestorProgreso? gestorProgreso;

  /// Callback opcional adicional al terminar una partida
  final FinPartidaCallback? onPartidaFinalizada;

  /// Constructor opcional de imagen para facilitar pruebas de interfaz sin red
  final Widget Function(PokemonResumen pokemon)? imageBuilder;

  const PantallaMemorice({
    super.key,
    this.partidaInyectada,
    this.cacheService,
    this.gestorProgreso,
    this.onPartidaFinalizada,
    this.imageBuilder,
  });

  @override
  State<PantallaMemorice> createState() => _PantallaMemoriceState();
}

class _PantallaMemoriceState extends State<PantallaMemorice> {
  late final PartidaMemorice _partida;
  late final bool _esPartidaPropia;

  DificultadMemorice _dificultadSeleccionada = DificultadMemorice.facil;
  FaseMemorice _ultimaFaseConocida = FaseMemorice.inicial;
  bool _cargandoPartida = false;
  bool _dialogoAbierto = false;
  int _recompensa = 0;

  @override
  void initState() {
    super.initState();
    final partidaInyectada = widget.partidaInyectada;
    _esPartidaPropia = partidaInyectada == null;

    if (partidaInyectada != null) {
      _partida = partidaInyectada;
    } else {
      final cache = widget.cacheService ??
          PokemonSessionCacheService(
            fetchPokemonList: () => buscarTodosLosPokemons(null),
            preloadImage: (url) async {
              if (!mounted) return;
              await precacheImage(NetworkImage(url), context);
            },
          );

      _partida = PartidaMemorice(
        cacheService: cache,
        onPartidaFinalizada: (dificultad, victoria, mejorCombo) {
          _recompensa = SistemaRecompensas.recompensaMemorice(
            victoria: victoria,
            intentosIncorrectos: _partida.errores,
            dificultad: dificultad,
          );
          widget.gestorProgreso?.registrarSesionMemorice(
            victoria: victoria,
            recompensa: _recompensa,
            dificultad: dificultad,
            mejorCombo: mejorCombo,
          );
          widget.onPartidaFinalizada?.call(dificultad, victoria, mejorCombo);
        },
      );
    }

    _ultimaFaseConocida = _partida.fase;
    _partida.addListener(_onCambioEstadoPartida);
  }

  void _onCambioEstadoPartida() {
    if (!mounted) return;

    final faseActual = _partida.fase;
    final transicionAFin =
        (faseActual == FaseMemorice.victoria || faseActual == FaseMemorice.derrota) &&
        _ultimaFaseConocida != faseActual;

    _ultimaFaseConocida = faseActual;
    setState(() {});

    if (transicionAFin && !_dialogoAbierto) {
      _dialogoAbierto = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _mostrarDialogoFinPartida(esVictoria: faseActual == FaseMemorice.victoria);
        }
      });
    }
  }

  Future<void> _comenzarPartida(DificultadMemorice dificultad) async {
    if (_cargandoPartida) return;
    setState(() => _cargandoPartida = true);

    try {
      await _partida.iniciarPartida(dificultad);
    } finally {
      if (mounted) setState(() => _cargandoPartida = false);
    }
  }

  Future<void> _mostrarDialogoFinPartida({required bool esVictoria}) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        key: const ValueKey('memorice_dialogo_fin'),
        backgroundColor: Colors.white,
        scrollable: true,
        title: Text(esVictoria ? '¡Victoria!' : '¡Derrota!'),
        content: SizedBox(
          width: 360,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                esVictoria
                    ? '¡Lograste encontrar todos los pares a tiempo!'
                    : 'Se agotó el tiempo antes de completar el tablero.',
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerLeft,
                child: Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 4,
                  children: [
                    const Icon(Icons.toll, color: PokedexAppColors.bosque),
                    Text(esVictoria ? '¡Has ganado ' : 'Recompensa por la partida '),
                    Text('$_recompensa', style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text(esVictoria ? 'Pokémonedas!' : 'Pokémonedas'),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              PanelPokedex(
                color: PokedexAppColors.marfil,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Dificultad: ${_partida.dificultad.nombre}'),
                    Text('Errores cometidos: ${_partida.errores}'),
                    Text('Mejor combo: ${_partida.mejorCombo}'),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          OutlinedButton.icon(
            key: const ValueKey('btn_fin_inicio'),
            onPressed: () {
              Navigator.of(dialogContext).pop();
              _dialogoAbierto = false;
              _partida.volverAlInicio();
            },
            icon: const Icon(Icons.home_outlined),
            label: const Text('Inicio'),
          ),
          FilledButton.icon(
            key: const ValueKey('btn_fin_reintentar'),
            style: FilledButton.styleFrom(
              backgroundColor: PokedexAppColors.lima,
              foregroundColor: PokedexAppColors.tinta,
            ),
            onPressed: () {
              final dificultadActual = _partida.dificultad;
              Navigator.of(dialogContext).pop();
              _dialogoAbierto = false;
              _comenzarPartida(dificultadActual);
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
          ),
        ],
      ),
    );
    _dialogoAbierto = false;
  }

  @override
  void dispose() {
    _partida.removeListener(_onCambioEstadoPartida);
    if (_esPartidaPropia) _partida.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_cargandoPartida) {
      return const ColoredBox(
        color: PokedexAppColors.marfil,
        child: Center(child: CircularProgressIndicator(color: PokedexAppColors.bosque)),
      );
    }

    if (_partida.fase == FaseMemorice.inicial) {
      return _construirVistaSeleccionDificultad();
    }

    return Column(
      children: [
        _construirBarraSuperiorHUD(),
        Expanded(child: _construirTableroCartas()),
      ],
    );
  }

  /// Vista inicial amplia: Selector de las 4 dificultades y botón "Comenzar"
  Widget _construirVistaSeleccionDificultad() => ColoredBox(
    color: PokedexAppColors.marfil,
    child: Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: PanelPokedex(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Memorice Pokémon',
                  style: TextStyle(
                    color: PokedexAppColors.tinta,
                    fontSize: 34,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Encuentra parejas de Pokémon.',
                  style: TextStyle(color: PokedexAppColors.tenue),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  height: 124,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (var i = 0; i < 3; i++) ...[
                        if (i > 0) const SizedBox(width: 8),
                        Expanded(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: i == 1 ? PokedexAppColors.lima : PokedexAppColors.bosque,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: i == 1
                                ? const Padding(
                                    padding: EdgeInsets.all(10),
                                    child: IlustracionPokemon(
                                      'https://raw.githubusercontent.com/PokeAPI/'
                                      'sprites/master/sprites/pokemon/other/'
                                      'official-artwork/197.png',
                                    ),
                                  )
                                : const Center(
                                    child: Icon(
                                      Icons.catching_pokemon,
                                      color: PokedexAppColors.lima,
                                      size: 36,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Dificultad', style: TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final dificultad in DificultadMemorice.values)
                      ChoiceChip(
                        key: ValueKey('chip_dificultad_${dificultad.name}'),
                        label: Text('${dificultad.nombre} (${dificultad.pares} pares)'),
                        selected: _dificultadSeleccionada == dificultad,
                        selectedColor: PokedexAppColors.lima,
                        backgroundColor: Colors.white,
                        side: const BorderSide(color: PokedexAppColors.borde),
                        onSelected: (_) => setState(() => _dificultadSeleccionada = dificultad),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  key: const ValueKey('btn_comenzar_memorice'),
                  style: FilledButton.styleFrom(
                    backgroundColor: PokedexAppColors.lima,
                    foregroundColor: PokedexAppColors.tinta,
                  ),
                  onPressed: () => _comenzarPartida(_dificultadSeleccionada),
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: const Text('Comenzar'),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );

  /// Barra superior (HUD) con tiempo restante, errores y combo actual
  Widget _construirBarraSuperiorHUD() {
    const estilo = TextStyle(
      color: PokedexAppColors.tinta,
      fontSize: 16,
      fontWeight: FontWeight.w600,
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: PokedexAppColors.borde)),
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceAround,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 16,
        runSpacing: 6,
        children: [
          if (_partida.fase == FaseMemorice.memorizando)
            const Row(
              key: ValueKey('hud_estado_memorizando'),
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.visibility, color: PokedexAppColors.bosque),
                SizedBox(width: 8),
                Text('¡Memoriza!', style: estilo),
              ],
            )
          else
            ValueListenableBuilder<int>(
              valueListenable: _partida.segundosRestantes,
              builder: (context, segundos, _) => Row(
                key: const ValueKey('hud_tiempo_restante'),
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.timer_outlined, color: PokedexAppColors.bosque),
                  const SizedBox(width: 8),
                  Text('Tiempo: ${segundos}s', style: estilo),
                ],
              ),
            ),
          Text(
            'Errores: ${_partida.errores}',
            key: const ValueKey('hud_errores'),
            style: estilo,
          ),
          Text(
            'Combo: x${_partida.comboActual}',
            key: const ValueKey('hud_combo'),
            style: estilo,
          ),
          TextButton.icon(
            key: const ValueKey('btn_salir_partida'),
            onPressed: _partida.volverAlInicio,
            icon: const Icon(Icons.exit_to_app_rounded, size: 20),
            label: const Text('Salir', style: estilo),
          ),
        ],
      ),
    );
  }

  /// Tablero auto-ajustable a pantalla completa (sin scroll)
  Widget _construirTableroCartas() {
    final cartas = _partida.cartas;
    if (cartas.isEmpty) return const SizedBox.shrink();

    // Distribución óptima de columnas según el total de cartas (12, 16, 20 o 24)
    final int columnas = switch (cartas.length) {
      <= 12 => 4, // 4x3 (Fácil)
      <= 16 => 4, // 4x4 (Normal)
      <= 20 => 5, // 5x4 (Difícil)
      _ => 6, // 6x4 (Extremo)
    };
    final filas = (cartas.length / columnas).ceil();

    return Container(
      key: const ValueKey('grilla_cartas_memorice'),
      color: PokedexAppColors.marfil,
      padding: const EdgeInsets.all(12),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Column(
            children: List.generate(filas, (fila) {
              return Expanded(
                child: Row(
                  children: List.generate(columnas, (columna) {
                    final indice = fila * columnas + columna;
                    if (indice >= cartas.length) {
                      return const Expanded(child: SizedBox.shrink());
                    }
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: _construirTarjetaIndividual(cartas[indice], indice),
                      ),
                    );
                  }),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  Widget _construirTarjetaIndividual(CartaMemorice carta, int index) {
    final mostrarFrente = carta.bocaArriba || carta.emparejada;
    final imagen = widget.imageBuilder;

    return GestureDetector(
      key: ValueKey('carta_memorice_$index'),
      behavior: HitTestBehavior.opaque,
      onTap: () => _partida.seleccionarCarta(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: mostrarFrente
              ? (carta.emparejada ? PokedexAppColors.lima : Colors.white)
              : PokedexAppColors.bosque,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: carta.emparejada
                ? Colors.green.shade600
                : (mostrarFrente ? PokedexAppColors.borde : PokedexAppColors.bosque),
            width: carta.emparejada ? 3 : 1,
          ),
        ),
        child: mostrarFrente
            ? Column(
                key: ValueKey('carta_frente_$index'),
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(6),
                      child: imagen == null
                          ? IlustracionPokemon(carta.pokemon.urlImagen)
                          : Center(child: imagen(carta.pokemon)),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(4, 0, 4, 4),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        carta.pokemon.nombre,
                        maxLines: 1,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              )
            : const Center(
                key: ValueKey('carta_reverso'),
                child: Padding(
                  padding: EdgeInsets.all(6),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Icon(Icons.catching_pokemon, color: PokedexAppColors.lima, size: 40),
                  ),
                ),
              ),
      ),
    );
  }
}