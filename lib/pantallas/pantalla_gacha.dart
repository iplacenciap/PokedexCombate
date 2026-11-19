import 'dart:math';

import 'package:flutter/material.dart';
import 'package:proyecto_pokedex/colors/app_colors.dart';
import 'package:proyecto_pokedex/datos/pokemon_resumen.dart';
import 'package:proyecto_pokedex/logica/sistema_gacha.dart';
import 'package:proyecto_pokedex/widgets/elementos_pokedex.dart';

class PantallaGacha extends StatefulWidget {
  final SistemaGacha sistema;

  const PantallaGacha({super.key, required this.sistema});

  @override
  State<PantallaGacha> createState() => _PantallaGachaState();
}

class _PantallaGachaState extends State<PantallaGacha>
    with SingleTickerProviderStateMixin {
  static const _inicio = 7;
  static const _avance = 26;

  final _azarVisual = Random();
  final _historial = <ResultadoTiradaGacha>[];

  late Future<List<PokemonResumen>> _catalogo;
  late final AnimationController _animacion;
  List<PokemonResumen> _cinta = const [];
  ResultadoTiradaGacha? _ultimoResultado;
  bool _procesando = false;

  @override
  void initState() {
    super.initState();
    _catalogo = widget.sistema.obtenerCatalogo();
    _animacion = AnimationController(vsync: this, duration: const Duration(milliseconds: 4100));
  }

  @override
  void didUpdateWidget(covariant PantallaGacha anterior) {
    super.didUpdateWidget(anterior);
    if (anterior.sistema != widget.sistema) {
      _catalogo = widget.sistema.obtenerCatalogo();
    }
  }

  @override
  void dispose() {
    _animacion.dispose();
    super.dispose();
  }

  Future<void> _tirar() async {
    if (_procesando) return;
    final sistema = widget.sistema;
    setState(() => _procesando = true);

    try {
      final catalogo = await _catalogo;
      if (!mounted) return;
      final resultado = await sistema.realizarTirada();
      if (!mounted) return;

      if (resultado == null) {
        _mensaje('No tienes suficientes Pokémonedas');
        return;
      }

      final alternativas = catalogo.where((p) => p.id != resultado.premio.id).toList()
        ..shuffle(_azarVisual);
      final cartas = alternativas.take(8).toList();
      if (cartas.isEmpty) cartas.add(resultado.premio);

      setState(() {
        _cinta = List.generate(
          2 * _inicio + _avance + 1,
          (i) => i == _inicio + _avance ? resultado.premio : cartas[i % cartas.length],
        );
      });

      await _animacion.forward(from: 0).orCancel;
      if (!mounted) return;
      setState(() {
        final anterior = _ultimoResultado;
        if (anterior != null) {
          _historial.insert(0, anterior);
          if (_historial.length > 5) _historial.removeLast();
        }
        _ultimoResultado = resultado;
      });
    } on TickerCanceled {
      return;
    } catch (_) {
      if (mounted) _mensaje('No se pudo completar la tirada');
    } finally {
      if (mounted) setState(() => _procesando = false);
    }
  }

  void _mensaje(String mensaje) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(mensaje)));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: PokedexAppColors.marfil,
    body: FutureBuilder<List<PokemonResumen>>(
      future: _catalogo,
      builder: (context, snapshot) {
        final catalogo = snapshot.data ?? const <PokemonResumen>[];
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(26, 23, 26, 36),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: anchoContenidoPokedex),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Gacha', style: estiloTituloPokedex),
                  const SizedBox(height: 22),
                  PanelPokedex(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _ruleta(catalogo),
                        const SizedBox(height: 16),
                        const Text('Tirada de colección', style: estiloSubtituloPokedex),
                        const SizedBox(height: 10),
                        FilledButton.icon(
                          key: const ValueKey('boton_tirar_gacha'),
                          onPressed: _procesando ? null : _tirar,
                          style: FilledButton.styleFrom(backgroundColor: const Color(0xFF1E654D)),
                          icon: const Icon(Icons.casino_outlined, size: 17),
                          label: Text(
                            _procesando
                                ? 'Girando…'
                                : 'Tirar · ${widget.sistema.getCostoTirada} Pokémonedas',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  LayoutBuilder(
                    builder: (context, caja) {
                      final resultado = _resultado();
                      final actividad = _actividad(snapshot);
                      return caja.maxWidth >= 700
                          ? Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(flex: 3, child: resultado),
                                const SizedBox(width: 16),
                                Expanded(flex: 2, child: actividad),
                              ],
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [resultado, const SizedBox(height: 16), actividad],
                            );
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    ),
  );

  Widget _ruleta(List<PokemonResumen> catalogo) {
    final muestra = catalogo.take(7).toList();
    final animada = _cinta.isNotEmpty;
    final pista = animada
        ? _cinta
        : muestra.isEmpty
        ? const <PokemonResumen>[]
        : List.generate(2 * _inicio + 1, (i) => muestra[i % muestra.length]);

    return ExcludeSemantics(
      child: Container(
        width: double.infinity,
        height: 188,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: PokedexAppColors.bosque,
          borderRadius: BorderRadius.circular(16),
        ),
        child: pista.isEmpty
            ? const Center(
                child: Icon(Icons.catching_pokemon, size: 56, color: PokedexAppColors.lima),
              )
            : LayoutBuilder(
                builder: (context, caja) {
                  final ancho = (caja.maxWidth * 0.34).clamp(76.0, 150.0).toDouble();
                  final paso = ancho + 10;
                  final centro = (caja.maxWidth - ancho) / 2;
                  final margen = (caja.maxWidth / (2 * paso)).ceil() + 1;

                  return AnimatedBuilder(
                    animation: _animacion,
                    builder: (context, _) {
                      final posicion = _inicio +
                          (animada ? _avance * Curves.easeOutCubic.transform(_animacion.value) : 0);
                      final entero = posicion.floor();
                      final desde = max(0, entero - margen);
                      final hasta = min(pista.length - 1, entero + margen);

                      return Stack(
                        children: [
                          for (var i = desde; i <= hasta; i++)
                            Positioned(
                              key: ValueKey(i),
                              left: centro + (i - posicion) * paso,
                              top: 24,
                              bottom: 18,
                              width: ancho,
                              child: _cartaRuleta(pista[i]),
                            ),
                          const Positioned.fill(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    PokedexAppColors.bosque,
                                    Color(0x0020392D),
                                    Color(0x0020392D),
                                    PokedexAppColors.bosque,
                                  ],
                                  stops: [0, 0.13, 0.87, 1],
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            left: centro,
                            top: 24,
                            bottom: 18,
                            width: ancho,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: PokedexAppColors.lima, width: 2),
                              ),
                            ),
                          ),
                          const Positioned(
                            top: 0,
                            left: 0,
                            right: 0,
                            child: Icon(Icons.arrow_drop_down, color: PokedexAppColors.lima, size: 32),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
      ),
    );
  }

  Widget _cartaRuleta(PokemonResumen pokemon) => Container(
    padding: const EdgeInsets.fromLTRB(6, 8, 6, 9),
    decoration: BoxDecoration(
      color: fondoTipoPokemon(pokemon.tipos),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      children: [
        Expanded(child: IlustracionPokemon(pokemon.urlImagen)),
        const SizedBox(height: 4),
        Text(
          nombreVisiblePokemon(pokemon.nombre),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: PokedexAppColors.tinta, fontSize: 12),
        ),
      ],
    ),
  );

  Widget _resultado() {
    final resultado = _ultimoResultado;
    return PanelPokedex(
      key: const ValueKey('resultado_gacha'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Última tirada', style: estiloSubtituloPokedex),
          const SizedBox(height: 10),
          Semantics(
            liveRegion: true,
            child: resultado == null
                ? const Text('Aquí aparecerá el Pokémon obtenido en tu primera tirada.')
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      PanelPokedex(
                        padding: const EdgeInsets.all(8),
                        color: fondoTipoPokemon(resultado.premio.tipos),
                        child: SizedBox(
                          height: 145,
                          child: IlustracionPokemon(resultado.premio.urlImagen),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(nombreVisiblePokemon(resultado.premio.nombre), style: estiloSubtituloPokedex),
                      Text(_detalle(resultado)),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _actividad(AsyncSnapshot<List<PokemonResumen>> snapshot) {
    final estado = snapshot.hasError
        ? 'No se pudo cargar el catálogo.'
        : snapshot.connectionState != ConnectionState.done
        ? 'Cargando catálogo…'
        : '${snapshot.data?.length ?? 0} Pokémon disponibles';

    return PanelPokedex(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Catálogo de premios', style: estiloSubtituloPokedex),
          const SizedBox(height: 6),
          Text(estado),
          const Divider(height: 26, color: PokedexAppColors.borde),
          const Text('Tiradas anteriores', style: estiloSubtituloPokedex),
          const SizedBox(height: 8),
          if (_historial.isEmpty) const Text('Todavía no tienes tiradas anteriores en esta sesión.'),
          for (final resultado in _historial)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: SizedBox(
                width: 40,
                height: 40,
                child: IlustracionPokemon(resultado.premio.urlImagen),
              ),
              title: Text(nombreVisiblePokemon(resultado.premio.nombre)),
              subtitle: Text(_detalle(resultado)),
            ),
        ],
      ),
    );
  }

  String _detalle(ResultadoTiradaGacha resultado) => resultado.repetido
      ? 'Pokémon repetido: recibiste ${resultado.compensacion} Pokémonedas'
      : 'Agregado a tu colección';
}