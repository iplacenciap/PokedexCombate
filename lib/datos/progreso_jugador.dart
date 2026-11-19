import 'package:proyecto_pokedex/datos/estadisticas_memorice.dart';
import 'package:proyecto_pokedex/datos/estadisticas_pokeguesser.dart';

class ProgresoJugador {
  final EstadisticasPokeGuesser pokeGuesser;
  final EstadisticasMemorice memorice;

  ProgresoJugador({
    EstadisticasPokeGuesser? pokeGuesser,
    EstadisticasMemorice? memorice,
  }) : pokeGuesser = pokeGuesser ?? EstadisticasPokeGuesser(),
       memorice = memorice ?? EstadisticasMemorice();

  Map<String, dynamic> toJson() {
    return {'pokeGuesser': pokeGuesser.toJson(), 'memorice': memorice.toJson()};
  }

  factory ProgresoJugador.fromJson(Map<String, dynamic> json) {
    return ProgresoJugador(
      pokeGuesser: EstadisticasPokeGuesser.fromJson(json['pokeGuesser'] ?? {}),
      memorice: EstadisticasMemorice.fromJson(json['memorice'] ?? {}),
    );
  }
}
