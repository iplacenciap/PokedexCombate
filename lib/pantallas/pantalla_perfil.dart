import 'package:flutter/material.dart';
import 'package:proyecto_pokedex/colors/app_colors.dart';
import 'package:proyecto_pokedex/datos/almacenamiento_perfil.dart';
import 'package:proyecto_pokedex/datos/perfil_jugador.dart';
import 'package:proyecto_pokedex/datos/pokemon_resumen.dart';
import 'package:proyecto_pokedex/logica/enums/dificultad_memorice.dart';
import 'package:proyecto_pokedex/widgets/elementos_pokedex.dart';

/// Presenta el perfil y muestra datos de economía y colección sin guardarlos.
/// PantallaPerfilIntegrado obtiene esos valores de sus servicios originales.
class PantallaPerfil extends StatefulWidget {
  final PerfilJugador perfil;
  final Future<void> Function(PerfilJugador)? guardarPerfil;

  // Datos de módulos externos. No se inventan saldos ni coleccionables.
  final int? saldoPokemonedas;
  final int? cantidadPokemonColeccionados;
  final int? totalPokemonDisponibles;
  final List<PokemonResumen> favoritos;
  final bool errorCargaFavoritos;
  final VoidCallback? onAbrirColeccion;
  final ValueChanged<PokemonResumen>? onAbrirPokemon;

  const PantallaPerfil({
    super.key,
    required this.perfil,
    this.guardarPerfil,
    this.saldoPokemonedas,
    this.cantidadPokemonColeccionados,
    this.totalPokemonDisponibles,
    this.favoritos = const [],
    this.errorCargaFavoritos = false,
    this.onAbrirColeccion,
    this.onAbrirPokemon,
  });

  @override
  State<PantallaPerfil> createState() => _PantallaPerfilState();
}

class _PantallaPerfilState extends State<PantallaPerfil> {
  bool _guardando = false;

  Future<void> _editarNombre() async {
    if (_guardando) return;

    final perfil = widget.perfil;
    var borrador = perfil.nombreUsuario;
    final nombre = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        void guardar(String texto) {
          final limpio = texto.trim();
          if (limpio.isNotEmpty) Navigator.of(dialogContext).pop(limpio);
        }

        return AlertDialog(
          title: const Text('Editar nombre'),
          content: TextFormField(
            key: const ValueKey('campo_nombre_perfil'),
            initialValue: borrador,
            autofocus: true,
            maxLength: 20,
            textInputAction: TextInputAction.done,
            onChanged: (texto) => borrador = texto,
            onFieldSubmitted: guardar,
            decoration: const InputDecoration(labelText: 'Nombre de usuario'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => guardar(borrador),
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );

    if (!mounted || nombre == null || nombre == perfil.nombreUsuario) return;

    final anterior = perfil.nombreUsuario;
    final guardar = widget.guardarPerfil ?? AlmacenamientoPerfil().guardarPerfil;
    setState(() {
      _guardando = true;
      perfil.cambiarNombre(nombre);
    });

    try {
      await guardar(perfil);
    } catch (_) {
      if (perfil.nombreUsuario == nombre) perfil.cambiarNombre(anterior);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo guardar el perfil.')),
        );
      }
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: PokedexAppColors.marfil,
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: anchoContenidoPokedex),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(26, 23, 26, 40),
            children: [
              const Text('Perfil', style: estiloTituloPokedex),
              const SizedBox(height: 22),
              _cabecera(),
              const SizedBox(height: 26),
              const Text('Progreso general', style: estiloSubtituloPokedex),
              const SizedBox(height: 12),
              _progresoGeneral(),
              const SizedBox(height: 26),
              const Text('Favoritos', style: estiloSubtituloPokedex),
              const SizedBox(height: 12),
              _favoritos(),
              const SizedBox(height: 26),
              const Text('Estadísticas', style: estiloSubtituloPokedex),
              const SizedBox(height: 12),
              _estadisticas(),
            ],
          ),
        ),
      ),
    ),
  );

  Widget _cabecera() => PanelPokedex(
    child: Column(
      children: [
        const CircleAvatar(
          radius: 36,
          backgroundColor: PokedexAppColors.lima,
          child: Icon(Icons.person_outline, color: PokedexAppColors.tinta, size: 36),
        ),
        const SizedBox(height: 8),
        TextButton.icon(
          key: const ValueKey('editar_nombre_perfil'),
          onPressed: _guardando ? null : _editarNombre,
          iconAlignment: IconAlignment.end,
          icon: const Icon(Icons.edit_outlined, size: 15),
          style: TextButton.styleFrom(
            foregroundColor: PokedexAppColors.tinta,
            minimumSize: const Size(0, 30),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            padding: const EdgeInsets.symmetric(horizontal: 8),
          ),
          label: Text(
            widget.perfil.nombreUsuario,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
          ),
        ),

        // Por este sprint solo existe el título inicial.
        // Los títulos desbloqueables mediante logros quedaron
        // para el próximo sprint.
        const Text(
          'Entrenador Pokémon',
          key: ValueKey('titulo_perfil'),
          style: TextStyle(color: PokedexAppColors.tenue, fontSize: 14),
        ),
        if (_guardando) ...[
          const SizedBox(height: 8),
          const SizedBox(
            height: 16,
            width: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ],
      ],
    ),
  );

  Widget _progresoGeneral() {
    final cantidad = widget.cantidadPokemonColeccionados;
    final total = widget.totalPokemonDisponibles;
    final valor = cantidad == null ? '—' : total == null ? '$cantidad' : '$cantidad / $total';

    final saldo = _indicador(
      clave: 'perfil_monedas',
      icono: Icons.toll,
      nombre: 'Pokémonedas',
      valor: widget.saldoPokemonedas?.toString() ?? '—',
    );
    final coleccion = _indicador(
      clave: 'perfil_coleccion',
      icono: Icons.catching_pokemon,
      nombre: 'Pokémon coleccionados',
      valor: valor,
      onTap: widget.onAbrirColeccion,
    );

    return LayoutBuilder(
      builder: (context, caja) => caja.maxWidth < 420
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [saldo, const SizedBox(height: 12), coleccion],
            )
          : Row(
              children: [
                Expanded(child: saldo),
                const SizedBox(width: 12),
                Expanded(child: coleccion),
              ],
            ),
    );
  }

  Widget _indicador({
    required String clave,
    required IconData icono,
    required String nombre,
    required String valor,
    VoidCallback? onTap,
  }) => Material(
    key: ValueKey(clave),
    color: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
      side: const BorderSide(color: PokedexAppColors.borde),
    ),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 22),
        child: Column(
          children: [
            Icon(icono, color: PokedexAppColors.bosque, size: 26),
            const SizedBox(height: 8),
            Text(
              valor,
              style: const TextStyle(
                color: PokedexAppColors.tinta,
                fontSize: 32,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              nombre,
              textAlign: TextAlign.center,
              style: const TextStyle(color: PokedexAppColors.tenue, fontSize: 14),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _favoritos() {
    // Si falla la carga del catálogo, no debemos interpretar
    // que el jugador no tiene favoritos.
    if (widget.errorCargaFavoritos) {
      return const PanelPokedex(
        key: ValueKey('perfil_favoritos_error'),
        child: Text(
          'No se pudo cargar el catálogo Pokémon. '
          'Los favoritos no están disponibles en este momento.',
        ),
      );
    }
    if (widget.favoritos.isEmpty) {
      return const PanelPokedex(
        key: ValueKey('perfil_favoritos_vacio'),
        child: Text('Aún no hay Pokémon favoritos para mostrar'),
      );
    }

    return SizedBox(
      height: 145,
      child: ListView.separated(
        primary: false,
        padding: EdgeInsets.zero,
        scrollDirection: Axis.horizontal,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemCount: widget.favoritos.length,
        itemBuilder: (context, indice) {
          final pokemon = widget.favoritos[indice];
          final abrir = widget.onAbrirPokemon;
          return SizedBox(
            width: 126,
            child: Material(
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: PokedexAppColors.borde),
              ),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: abrir == null ? null : () => abrir(pokemon),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: ColoredBox(
                        color: fondoTipoPokemon(pokemon.tipos),
                        child: Padding(
                          padding: const EdgeInsets.all(9),
                          child: IlustracionPokemon(pokemon.urlImagen),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.favorite, color: Color(0xFFAD364D), size: 13),
                          const SizedBox(width: 5),
                          Flexible(
                            child: Text(
                              nombreVisiblePokemon(pokemon.nombre),
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// Task #94: muestra siempre las cuatro dificultades y los resultados
  /// existentes en el mismo PerfilJugador utilizado por GestorProgreso.
  /// No calcula ni guarda estadísticas nuevas.
  Widget _estadisticas() {
    final progreso = widget.perfil.progreso;
    final adivinanzas = progreso.pokeGuesser;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PanelPokedex(
          key: const ValueKey('perfil_pokeguesser'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('PokéGuesser', style: estiloSubtituloPokedex),
              const Divider(height: 22),
              _fila('Partidas jugadas', adivinanzas.partidasJugadas),
              _fila('Victorias', adivinanzas.victorias),
              _fila('Derrotas', adivinanzas.derrotas),
            ],
          ),
        ),
        const SizedBox(height: 14),
        PanelPokedex(
          key: const ValueKey('perfil_memorice'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Row(
                children: [
                  Icon(Icons.psychology_alt, color: PokedexAppColors.bosque),
                  SizedBox(width: 8),
                  Text('Memorice', style: estiloSubtituloPokedex),
                ],
              ),
              for (final dificultad in DificultadMemorice.values) ...[
                const Divider(height: 24),
                _dificultad(dificultad),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _dificultad(DificultadMemorice dificultad) {
    final estadisticas = widget.perfil.progreso.memorice.obtenerPorDificultad(dificultad);
    return Column(
      key: ValueKey('perfil_memorice_${dificultad.name}'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Dificultad ${dificultad.nombre}',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 5),
        _fila('Victorias', estadisticas.victorias),
        _fila('Derrotas', estadisticas.derrotas),
        _fila('Mejor combo', estadisticas.mejorCombo),
      ],
    );
  }

  Widget _fila(String texto, int numero) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      children: [
        Expanded(child: Text(texto, style: const TextStyle(color: PokedexAppColors.tenue))),
        const SizedBox(width: 12),
        Text('$numero', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
      ],
    ),
  );
}