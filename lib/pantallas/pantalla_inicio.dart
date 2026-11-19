import 'package:flutter/material.dart';
import 'package:proyecto_pokedex/api/buscar_todos_los_pokemon.dart';
import 'package:proyecto_pokedex/colors/app_colors.dart';
import 'package:proyecto_pokedex/datos/pokemon_resumen.dart';
import 'package:proyecto_pokedex/logica/contador_coleccion.dart';
import 'package:proyecto_pokedex/utilidades/analizador_busqueda.dart';
import 'package:proyecto_pokedex/utilidades/gestor_lista_paginada.dart';
import 'package:proyecto_pokedex/widgets/boton_pokemon_aleatorio.dart';
import 'package:proyecto_pokedex/widgets/elementos_pokedex.dart';

class PantallaInicio extends StatefulWidget {
  final List<PokemonResumen>? pokemonesIniciales;
  final Future<List<PokemonResumen>> Function()? cargarCatalogo;

  const PantallaInicio({super.key, this.pokemonesIniciales, this.cargarCatalogo});

  @override
  State<PantallaInicio> createState() => _PantallaInicioState();
}

class _PantallaInicioState extends State<PantallaInicio> {
  final _controlador = TextEditingController();
  final _tipos = <String>{};

  List<PokemonResumen> _catalogo = [];
  List<PokemonResumen> _resultados = [];
  int? _generacion;
  bool _cargando = true;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    final iniciales = widget.pokemonesIniciales;
    if (iniciales == null) {
      _cargar();
    } else {
      _catalogo = iniciales;
      _filtrar();
      _cargando = false;
    }
  }

  Future<void> _cargar() async {
    try {
      final cargar = widget.cargarCatalogo ?? () => buscarTodosLosPokemons(null);
      final catalogo = await cargar();
      if (!mounted) return;

      setState(() {
        _catalogo = catalogo;
        _filtrar();
        _cargando = false;
        _error = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _cargando = false;
        _error = true;
      });
    }
  }

  void _filtrar() {
    final consulta = _controlador.text.trim();
    final id = int.tryParse(
      consulta.startsWith('#') ? consulta.substring(1) : consulta,
    );

    _resultados = analizarYFiltrarBusqueda(
      allPokemon: id == null
          ? _catalogo
          : _catalogo.where((pokemon) => pokemon.id == id).toList(),
      filtroNombre: id == null ? consulta : null,
      filtrosTipo: _tipos.toList(),
      filtroGeneracion: _generacion,
    );
  }

  @override
  void dispose() {
    _controlador.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PokedexAppColors.marfil,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: anchoContenidoPokedex),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: _contenido(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _contenido() {
    if (_cargando) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error) {
      return Center(
        child: PanelPokedex(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('No se pudo cargar el catálogo.'),
              TextButton(
                onPressed: () {
                  setState(() => _cargando = true);
                  _cargar();
                },
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    return GestorListaPaginada(
      listaCompleta: _resultados,
      encabezado: _encabezado(),
    );
  }

  Widget _encabezado() {
    final destacado = _catalogo.where((pokemon) => pokemon.id == 149).firstOrNull;
    final tipos = nombresTipos.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 24),
        _portada(destacado),
        const SizedBox(height: 24),
        const Text(
          'Catálogo',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _controlador,
          onChanged: (_) => setState(_filtrar),
          decoration: InputDecoration(
            hintText: 'Busca por nombre o número',
            prefixIcon: const Icon(Icons.search),
            filled: true,
            fillColor: Colors.white,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: PokedexAppColors.borde),
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 10,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            PopupMenuButton<String>(
              tooltip: 'Filtrar por tipo',
              onSelected: (tipo) => setState(() {
                if (tipo.isEmpty) {
                  _tipos.clear();
                } else if (!_tipos.remove(tipo)) {
                  _tipos.add(tipo);
                }
                _filtrar();
              }),
              itemBuilder: (_) => [
                const PopupMenuItem(value: '', child: Text('Todos los tipos')),
                for (final tipo in tipos)
                  CheckedPopupMenuItem(
                    value: tipo.key,
                    checked: _tipos.contains(tipo.key),
                    child: Text(tipo.value),
                  ),
              ],
              child: _controlFiltro(
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _tipos.isEmpty
                            ? 'Todos los tipos'
                            : _tipos.length == 1
                            ? nombresTipos[_tipos.first] ?? _tipos.first
                            : '${_tipos.length} tipos',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                    const Icon(Icons.expand_more, size: 17),
                  ],
                ),
              ),
            ),
            _controlFiltro(
              DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  isExpanded: true,
                  value: _generacion,
                  hint: const Text(
                    'Todas las generaciones',
                    overflow: TextOverflow.ellipsis,
                  ),
                  style: const TextStyle(
                    color: PokedexAppColors.tinta,
                    fontSize: 13,
                  ),
                  icon: const Icon(Icons.expand_more, size: 17),
                  items: [
                    const DropdownMenuItem<int>(
                      child: Text('Todas las generaciones'),
                    ),
                    for (var i = 1; i <= 9; i++)
                      DropdownMenuItem(value: i, child: Text('Generación $i')),
                  ],
                  onChanged: (valor) => setState(() {
                    _generacion = valor;
                    _filtrar();
                  }),
                ),
              ),
            ),
            Text(
              '${_resultados.length} Pokémon',
              style: const TextStyle(fontSize: 13, color: PokedexAppColors.tenue),
            ),
            const BotonPokemonAleatorio(),
          ],
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _controlFiltro(Widget child) => Container(
    width: 192,
    height: 49,
    padding: const EdgeInsets.symmetric(horizontal: 11),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(9),
      border: Border.all(color: PokedexAppColors.borde),
    ),
    child: child,
  );

  Widget _portada(PokemonResumen? destacado) => LayoutBuilder(
    builder: (context, caja) {
      final amplia = caja.maxWidth >= 620;
      final lateral = amplia ? 34.0 : 18.0;
      final tamano = amplia ? 248.0 : (caja.maxWidth * 0.32).clamp(64.0, 118.0).toDouble();

      return Container(
        width: double.infinity,
        constraints: BoxConstraints(minHeight: amplia ? 268 : 204),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: const LinearGradient(
            colors: [Color(0xFF172E25), Color(0xFF3A5841)],
          ),
        ),
        child: Stack(
          children: [
            if (destacado != null)
              Positioned(
                right: amplia ? 38 : 4,
                bottom: amplia ? 0 : 12,
                width: tamano,
                height: tamano,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    for (final escala in [0.76, 0.90, 1.0])
                      Container(
                        width: tamano * escala,
                        height: tamano * escala,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: PokedexAppColors.lima.withAlpha(58),
                          ),
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: IlustracionPokemon(destacado.urlImagen),
                    ),
                  ],
                ),
              ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                lateral,
                lateral,
                destacado == null ? lateral : tamano + lateral,
                amplia ? 26 : 18,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (destacado != null) ...[
                    Text(
                      '${destacado.nombre.toUpperCase()}  /  #${destacado.id}',
                      style: const TextStyle(
                        color: PokedexAppColors.lima,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  Text(
                    'Explora la\nPokédex',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: amplia ? 57 : 35,
                      fontWeight: FontWeight.w800,
                      height: 1.1,
                      letterSpacing: -1.3,
                    ),
                  ),
                  if (destacado != null) ...[
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: PokedexAppColors.lima,
                        foregroundColor: PokedexAppColors.tinta,
                      ),
                      onPressed: () => abrirFichaDeCatalogo(context, destacado),
                      icon: const Icon(Icons.arrow_outward, size: 16),
                      label: const Text('Ver ficha'),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      );
    },
  );
}