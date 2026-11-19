import 'package:flutter/material.dart';
import 'package:proyecto_pokedex/logica/combate/equipos_duelo_prueba.dart';
import 'package:proyecto_pokedex/logica/combate/motor_combate.dart';
import 'package:proyecto_pokedex/widgets/elementos_pokedex.dart';

import 'pantalla_batalla.dart';

class PantallaDueloPrueba extends StatelessWidget {
  const PantallaDueloPrueba({super.key});

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.all(24),
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Combates', style: estiloTituloPokedex),
            const SizedBox(height: 16),
            PanelPokedex(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Duelo de prueba',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Juega con Charmander y Squirtle contra Pidgey y Geodude.',
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () => Navigator.of(context).push<EstadoCombate>(
                      MaterialPageRoute<EstadoCombate>(
                        builder: (_) => PantallaBatalla(
                          nombreDuelo: 'Duelo de prueba',
                          nombreRival: 'Rival de práctica',
                          equipo: equipoJugadorPrueba,
                          equipoRival: equipoRivalPrueba,
                        ),
                      ),
                    ),
                    icon: const Icon(Icons.sports_martial_arts_outlined),
                    label: const Text('Iniciar duelo de prueba'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
