import 'package:flutter/foundation.dart';
import 'package:proyecto_pokedex/datos/almacenamiento_perfil.dart';
import 'package:proyecto_pokedex/datos/perfil_jugador.dart';
import 'package:proyecto_pokedex/logica/enums/dificultad_memorice.dart';

class GestorProgreso extends ChangeNotifier {
  final PerfilJugador perfil;
  final AlmacenamientoPerfil almacenamiento;

  GestorProgreso({required this.perfil, AlmacenamientoPerfil? almacenamiento})
    : almacenamiento = almacenamiento ?? AlmacenamientoPerfil();

  // Registra el resultado de PokéGuesser y su recompensa.
  Future<void> registrarResultadoPokeGuesser({
    required bool victoria,
    required int recompensa,
  }) async {
    if (victoria) {
      perfil.progreso.pokeGuesser.registrarVictoria();
    } else {
      perfil.progreso.pokeGuesser.registrarDerrota();
    }

    perfil.sumarSaldoMonedas(recompensa);

    await almacenamiento.guardarPerfil(perfil);
    notifyListeners();
  }

  // Compatibilidad con el sistema anterior de PokéGuesser.
  Future<void> registrarVictoriaPokeGuesser() {
    return registrarResultadoPokeGuesser(victoria: true, recompensa: 0);
  }

  Future<void> registrarDerrotaPokeGuesser() {
    return registrarResultadoPokeGuesser(victoria: false, recompensa: 0);
  }

  // Registra los resultados de Memorice según dificultad.
  Future<void> registrarSesionMemorice({
    required bool victoria,
    int recompensa = 0,
    DificultadMemorice? dificultad,
    int mejorCombo = 0,
  }) async {
    perfil.progreso.memorice.registrarSesion(
      victoria: victoria,
      dificultad: dificultad,
      mejorCombo: mejorCombo,
    );

    perfil.sumarSaldoMonedas(recompensa);
    await almacenamiento.guardarPerfil(perfil);
    notifyListeners();
  }

  Future<bool> gastarPokemonedas(int costo) async {
    final saldoAnterior = perfil.saldoMonedas;
    if (!perfil.restarSaldoMonedas(costo)) return false;

    try {
      await almacenamiento.guardarPerfil(perfil);
    } catch (_) {
      perfil.saldoMonedas = saldoAnterior;
      rethrow;
    }

    notifyListeners();
    return true;
  }

  Future<void> reembolsarPokemonedas(int cantidad) async{
    if(cantidad <= 0){
      throw ArgumentError.value(cantidad, "cantidad");
    }

    final saldoAnterior = perfil.saldoMonedas;
    perfil.sumarSaldoMonedas(cantidad);

    try{
      await almacenamiento.guardarPerfil(perfil);
    } catch (_){
      perfil.saldoMonedas = saldoAnterior;
      rethrow;
    }

    notifyListeners();
  }
}
