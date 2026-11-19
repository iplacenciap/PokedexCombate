import 'package:flutter/material.dart';
import 'package:proyecto_pokedex/colors/app_colors.dart';
import 'package:proyecto_pokedex/logica/gestor_progreso.dart';

class TopNavBar extends StatelessWidget implements PreferredSizeWidget {
  final int indiceSeccionActual;
  final ValueChanged<int> onTapSeccion;
  final List<String> nombresSecciones;
  final VoidCallback? onTapPerfil;
  final bool perfilSeleccionado;
  final GestorProgreso? gestorProgreso;
  final bool compacto;

  const TopNavBar({
    super.key,
    required this.indiceSeccionActual,
    required this.onTapSeccion,
    required this.nombresSecciones,
    this.onTapPerfil,
    this.perfilSeleccionado = false,
    this.gestorProgreso,
    this.compacto = false,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  Widget _destino({
    required String texto,
    required VoidCallback? accion,
    required bool seleccionado,
    required IconData icono,
    required bool conIcono,
    Key? clave,
  }) {
    return Semantics(
      selected: seleccionado,
      child: TextButton(
        key: clave,
        onPressed: accion,
        style: TextButton.styleFrom(
          foregroundColor: PokedexAppColors.tenue,
          disabledForegroundColor: PokedexAppColors.tinta,
          backgroundColor: seleccionado ? PokedexAppColors.lima : Colors.transparent,
          disabledBackgroundColor: seleccionado ? PokedexAppColors.lima : Colors.transparent,
          padding: EdgeInsets.symmetric(horizontal: conIcono ? 3 : 12, vertical: 7),
          minimumSize: const Size(0, 34),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        child: conIcono
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icono, size: 19),
                  const SizedBox(height: 3),
                  Text(texto, style: const TextStyle(fontSize: 10)),
                ],
              )
            : Text(texto),
      ),
    );
  }

  List<Widget> _destinos({required bool conIconos}) {
    const iconos = [
      Icons.catching_pokemon,
      Icons.collections_bookmark_outlined,
      Icons.sports_esports_outlined,
      Icons.auto_awesome,
      Icons.sports_martial_arts_outlined,
    ];

    return [
      for (var i = 0; i < nombresSecciones.length; i++)
        _destino(
          texto: nombresSecciones[i],
          accion: i == indiceSeccionActual ? null : () => onTapSeccion(i),
          seleccionado: i == indiceSeccionActual,
          icono: i < iconos.length ? iconos[i] : Icons.apps,
          conIcono: conIconos,
        ),
      if (onTapPerfil != null)
        _destino(
          clave: const ValueKey('boton_perfil'),
          texto: 'Perfil',
          accion: onTapPerfil,
          seleccionado: perfilSeleccionado,
          icono: Icons.person_outline,
          conIcono: conIconos,
        ),
    ];
  }

  Widget barraInferior() => Material(
    color: Colors.white,
    child: SafeArea(
      top: false,
      minimum: const EdgeInsets.all(6),
      child: Row(
        children: [
          for (final destino in _destinos(conIconos: true))
            Expanded(child: destino),
        ],
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final gestor = gestorProgreso;
    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      foregroundColor: PokedexAppColors.tinta,
      shape: const Border(bottom: BorderSide(color: PokedexAppColors.borde)),
      titleSpacing: compacto ? 16 : 27,
      title: Row(
        children: [
          const CircleAvatar(
            radius: 18,
            backgroundColor: PokedexAppColors.bosque,
            child: Icon(Icons.catching_pokemon, color: PokedexAppColors.lima, size: 21),
          ),
          const SizedBox(width: 8),
          const Text('Pokédex', style: TextStyle(fontWeight: FontWeight.w800)),
          if (compacto)
            const Spacer()
          else
            // Navegación de la aplicación.
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(children: _destinos(conIconos: false)),
                ),
              ),
            ),

          // Economía de Benjamín.
          // Se actualiza cuando GestorProgreso notifica cambios.
          if (gestor != null)
            ListenableBuilder(
              listenable: gestor,
              builder: (context, _) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  color: PokedexAppColors.marfil,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.toll, size: 17, color: Color(0xFF746324)),
                    const SizedBox(width: 5),
                    Text(
                      '${gestor.perfil.saldoMonedas}',
                      key: const ValueKey('saldo_monedas'),
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}