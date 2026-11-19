import 'package:flutter/material.dart';
import '../datos/pokemon_resumen.dart';
import '../widgets/lista_pokemon_paginada.dart'; // Tu widget actual

class GestorListaPaginada extends StatefulWidget {
  final List<PokemonResumen> listaCompleta;
  final Widget? encabezado;

  const GestorListaPaginada({
    super.key,
    required this.listaCompleta,
    this.encabezado,
  });

  @override
  State<GestorListaPaginada> createState() => _GestorListaPaginadaState();
}

class _GestorListaPaginadaState extends State<GestorListaPaginada> {
  final int elementosPorPagina = 15;
  int _paginaActual = 1;

  @override
  void didUpdateWidget(covariant GestorListaPaginada oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.listaCompleta, widget.listaCompleta)) {
      _paginaActual = 1;
    }
  }

  @override
  Widget build(BuildContext context) {
    //Calcular el total de páginas.
    final totalPaginas = (widget.listaCompleta.length / elementosPorPagina).ceil();

    //Calcular los índices para cortar la lista por páginas.
    final indiceInicio = (_paginaActual - 1) * elementosPorPagina;
    var indiceFin = indiceInicio + elementosPorPagina;

    //Evitar desbordamientos si última página tiene menos elementos que cantidad definida.
    if (indiceFin > widget.listaCompleta.length) {
      indiceFin = widget.listaCompleta.length;
    }

    //Obtener solo los Pokémon de esta página
    final pokemonesPagina = widget.listaCompleta.sublist(indiceInicio, indiceFin);

    //Retornar tu widget listo.
    return ListaPokemonPaginada(
      encabezado: widget.encabezado,
      pokemones: pokemonesPagina,
      paginaActual: _paginaActual,
      totalPaginas: totalPaginas,
      onAnterior: () => setState(() => _paginaActual--),
      onSiguiente: () => setState(() => _paginaActual++),
    );
  }
}