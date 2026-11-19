import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:proyecto_pokedex/colors/app_colors.dart';

import '../api/buscar_pokemon_aleatorio.dart';
import '../datos/pokemon.dart';
import '../pantallas/pantalla_descripcion_pokemon.dart';

class BotonPokemonAleatorio extends StatefulWidget {
  final http.Client? cliente;

  const BotonPokemonAleatorio({super.key, this.cliente});

  @override
  State<BotonPokemonAleatorio> createState() => _BotonPokemonAleatorioState();
}

class _BotonPokemonAleatorioState extends State<BotonPokemonAleatorio> {
  bool cargando = false;

  Future<void> buscar() async {
    if (cargando) return;
    setState(() => cargando = true);

    try {
      final Pokemon pokemon = await buscarPokemonAleatorio(cliente: widget.cliente);
      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PantallaDescripcionPokemon(pokemon: pokemon),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo obtener un Pokémon aleatorio')),
      );
    } finally {
      if (mounted) setState(() => cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ElevatedButton(
        onPressed: cargando ? null : buscar,
        style: ElevatedButton.styleFrom(
          backgroundColor: PokedexAppColors.lima,
          foregroundColor: PokedexAppColors.tinta,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          elevation: 0,
        ),
        child: Text(cargando ? 'Buscando...' : 'Pokémon aleatorio'),
      ),
    );
  }
}