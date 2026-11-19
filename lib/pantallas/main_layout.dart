import 'package:flutter/material.dart';
import 'package:proyecto_pokedex/api/buscar_todos_los_pokemon.dart';
import 'package:proyecto_pokedex/api/pokedex_session_cache_service.dart';
import 'package:proyecto_pokedex/colors/app_colors.dart';
import 'package:proyecto_pokedex/datos/almacenamiento_perfil.dart';
import 'package:proyecto_pokedex/datos/pokemon_resumen.dart';
import 'package:proyecto_pokedex/logica/coleccion_servicio.dart';
import 'package:proyecto_pokedex/logica/gestor_progreso.dart';
import 'package:proyecto_pokedex/logica/sistema_gacha.dart';
import 'package:proyecto_pokedex/pantallas/combate/pantalla_duelo_prueba.dart';
import 'package:proyecto_pokedex/pantallas/pantalla_coleccionables.dart';
import 'package:proyecto_pokedex/pantallas/pantalla_gacha.dart';
import 'package:proyecto_pokedex/pantallas/pantalla_inicio.dart';
import 'package:proyecto_pokedex/pantallas/pantalla_memorice.dart';
import 'package:proyecto_pokedex/pantallas/pantalla_perfil.dart';
import 'package:proyecto_pokedex/pantallas/pantalla_perfil_integrado.dart';
import 'package:proyecto_pokedex/pantallas/pantalla_pokeguesser.dart';
import 'package:proyecto_pokedex/widgets/elementos_pokedex.dart';
import 'package:proyecto_pokedex/widgets/top_nav_bar.dart';

class MainLayout extends StatefulWidget {
  final List<Widget>? vistasSecciones;
  final List<String>? nombresSecciones;

  const MainLayout({super.key, this.vistasSecciones, this.nombresSecciones});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  static const _nombresBase = ['Pokédex', 'Colección', 'Minijuegos', 'Gacha'];
  static const _nombreCombates = 'Combates';
  static const _nombres = [..._nombresBase, _nombreCombates];

  int _indiceActual = 0;
  int _revisionPerfil = 0;
  Future<List<Widget>>? _vistasPredeterminadas;
  GestorProgreso? _gestorProgreso;
  bool _abriendoPokemonFavorito = false;

  late final _cache = PokemonSessionCacheService(
    fetchPokemonList: () => buscarTodosLosPokemons(null),
    preloadImage: (url) async {
      if (mounted) await precacheImage(NetworkImage(url), context);
    },
  );

  @override
  void initState() {
    super.initState();
    if (widget.vistasSecciones == null) {
      _vistasPredeterminadas = _cargarVistas();
    }
  }

  Future<List<Widget>> _cargarVistas() async {
    final almacenamiento = AlmacenamientoPerfil();
    final perfil = await almacenamiento.cargarPerfil();
    final gestor = GestorProgreso(perfil: perfil, almacenamiento: almacenamiento);
    final coleccion = ColeccionServicio.instancia;

    _gestorProgreso = gestor;

    // Las tres vistas jugables y el perfil comparten la misma instancia
    // de PerfilJugador, administrada por GestorProgreso.
    return [
      PantallaInicio(cargarCatalogo: _cache.getPokemonList),
      PantallaColeccionables(cacheService: _cache, coleccion: coleccion),
      _Minijuegos(
        pokeGuesser: PantallaPokeGuesser(
          gestorProgreso: gestor,
          getListaPokemon: _cache.getPokemonList,
        ),
        memorice: PantallaMemorice(cacheService: _cache, gestorProgreso: gestor),
      ),
      PantallaGacha(
        sistema: SistemaGacha(
          cacheService: _cache,
          coleccionServicio: coleccion,
          gestor: gestor,
        ),
      ),
      const PantallaDueloPrueba(),
      PantallaPerfilIntegrado(
        gestorProgreso: gestor,
        coleccion: coleccion,
        cacheService: _cache,
        guardarPerfil: almacenamiento.guardarPerfil,
        onAbrirColeccion: () => _cambiarSeccion(1),
        onAbrirPokemon: _abrirPokemonDesdePerfil,
      ),
    ];
  }

  Future<void> _abrirPokemonDesdePerfil(PokemonResumen resumen) async {
    if (_abriendoPokemonFavorito) return;
    _abriendoPokemonFavorito = true;
    try {
      await abrirFichaDeCatalogo(context, resumen);
    } finally {
      _abriendoPokemonFavorito = false;
    }
  }

  void _cambiarSeccion(int nuevoIndice, {bool esPerfil = false}) {
    setState(() {
      _indiceActual = nuevoIndice;
      if (esPerfil && widget.vistasSecciones != null) _revisionPerfil++;
    });
  }

  Widget _construirLayout(List<Widget> vistas, List<String> nombres) {
    final indice = _indiceActual < vistas.length ? _indiceActual : 0;
    final indicePerfil = nombres.length;
    final hayPerfil = vistas.length > indicePerfil &&
        (vistas[indicePerfil] is PantallaPerfil ||
         vistas[indicePerfil] is PantallaPerfilIntegrado);
    final compacto = widget.vistasSecciones == null && MediaQuery.sizeOf(context).width < 820;
    final secciones = List<Widget>.of(vistas);

    if (hayPerfil && widget.vistasSecciones != null) {
      secciones[indicePerfil] = KeyedSubtree(
        key: ValueKey('revision_perfil_$_revisionPerfil'),
        child: vistas[indicePerfil],
      );
    }

    final barra = TopNavBar(
      indiceSeccionActual: indice,
      onTapSeccion: _cambiarSeccion,
      nombresSecciones: nombres,
      onTapPerfil: hayPerfil
          ? () => _cambiarSeccion(indicePerfil, esPerfil: true)
          : null,
      perfilSeleccionado: hayPerfil && indice == indicePerfil,
      gestorProgreso: _gestorProgreso,
      compacto: compacto,
    );

    return Scaffold(
      backgroundColor: PokedexAppColors.marfil,
      appBar: barra,
      body: IndexedStack(index: indice, children: secciones),
      bottomNavigationBar: compacto ? barra.barraInferior() : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final inyectadas = widget.vistasSecciones;
    if (inyectadas != null) {
      return _construirLayout(
        inyectadas,
        widget.nombresSecciones ?? _nombresBase.take(inyectadas.length).toList(),
      );
    }

    return FutureBuilder<List<Widget>>(
      future: _vistasPredeterminadas,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('No se pudo cargar el perfil del jugador.'),
                  ElevatedButton(
                    onPressed: () => setState(() => _vistasPredeterminadas = _cargarVistas()),
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            ),
          );
        }

        final nombres = switch (widget.nombresSecciones) {
          final personalizados? when personalizados.length == _nombresBase.length =>
            [...personalizados, _nombreCombates],
          final personalizados? when personalizados.length == _nombres.length =>
            personalizados,
          _ => _nombres,
        };
        return _construirLayout(snapshot.data!, nombres);
      },
    );
  }
}

class _Minijuegos extends StatefulWidget {
  final Widget pokeGuesser;
  final Widget memorice;

  const _Minijuegos({required this.pokeGuesser, required this.memorice});

  @override
  State<_Minijuegos> createState() => _MinijuegosState();
}

class _MinijuegosState extends State<_Minijuegos> {
  int _vista = 0;
  final _juegosAbiertos = <int>{};

  void _abrir(int indice) => setState(() {
    _juegosAbiertos.add(indice);
    _vista = indice;
  });

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      if (_vista != 0)
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () => setState(() => _vista = 0),
            icon: const Icon(Icons.arrow_back),
            label: const Text('Volver a minijuegos'),
          ),
        ),
      Expanded(
        child: IndexedStack(
          index: _vista,
          children: [
            _portada(),
            if (_juegosAbiertos.contains(1)) widget.pokeGuesser else const SizedBox.shrink(),
            if (_juegosAbiertos.contains(2)) widget.memorice else const SizedBox.shrink(),
          ],
        ),
      ),
    ],
  );

  Widget _portada() => SingleChildScrollView(
    padding: const EdgeInsets.fromLTRB(26, 23, 26, 30),
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: anchoContenidoPokedex),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Minijuegos', style: estiloTituloPokedex),
            const SizedBox(height: 20),
            LayoutBuilder(
              builder: (context, caja) {
                final ancho = caja.maxWidth >= 620 ? (caja.maxWidth - 14) / 2 : caja.maxWidth;
                return Wrap(
                  spacing: 14,
                  runSpacing: 14,
                  children: [
                    _tarjeta(
                      ancho: ancho,
                      titulo: 'PokéGuesser',
                      descripcion: 'Adivina el Pokémon a partir de las pistas.',
                      etiquetas: const ['Pistas', '7 intentos'],
                      vista: const PanelPokedex(
                        color: Color(0xFFEEE6F4),
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          width: double.infinity,
                          height: 126,
                          child: IlustracionPokemon(
                            'https://raw.githubusercontent.com/PokeAPI/sprites/master/'
                            'sprites/pokemon/other/official-artwork/94.png',
                            silueta: true,
                          ),
                        ),
                      ),
                      onTap: () => _abrir(1),
                    ),
                    _tarjeta(
                      ancho: ancho,
                      titulo: 'Memorice',
                      descripcion: 'Encuentra parejas de Pokémon.',
                      etiquetas: const ['4 dificultades', 'Combos'],
                      vista: _cartasMemorice(),
                      onTap: () => _abrir(2),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    ),
  );

  Widget _tarjeta({
    required double ancho,
    required String titulo,
    required String descripcion,
    required List<String> etiquetas,
    required Widget vista,
    required VoidCallback onTap,
  }) => SizedBox(
    width: ancho,
    child: Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: PokedexAppColors.borde),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(titulo, style: estiloSubtituloPokedex.copyWith(fontSize: 25)),
              const SizedBox(height: 10),
              vista,
              const SizedBox(height: 13),
              Wrap(spacing: 6, children: [
                for (final etiqueta in etiquetas) EtiquetaPokedex(etiqueta),
              ]),
              const SizedBox(height: 8),
              Text(descripcion, style: const TextStyle(color: PokedexAppColors.tenue)),
            ],
          ),
        ),
      ),
    ),
  );

  Widget _cartasMemorice() => PanelPokedex(
    color: PokedexAppColors.marfil,
    padding: const EdgeInsets.all(12),
    child: SizedBox(
      height: 126,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < 3; i++) ...[
            if (i > 0) const SizedBox(width: 6),
            Expanded(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: i == 1 ? PokedexAppColors.lima : PokedexAppColors.bosque,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: i == 1
                    ? const Padding(
                        padding: EdgeInsets.all(6),
                        child: IlustracionPokemon(
                          'https://raw.githubusercontent.com/PokeAPI/sprites/master/'
                          'sprites/pokemon/other/official-artwork/197.png',
                        ),
                      )
                    : const Center(
                        child: Icon(Icons.catching_pokemon, color: PokedexAppColors.lima),
                      ),
              ),
            ),
          ],
        ],
      ),
    ),
  );
}
