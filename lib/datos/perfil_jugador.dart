import 'package:proyecto_pokedex/datos/progreso_jugador.dart';

class PerfilJugador {
  String nombreUsuario;
  String tituloSeleccionado;
  final ProgresoJugador progreso;
  int saldoMonedas;

  PerfilJugador({
    this.nombreUsuario = 'Entrenador',
    this.tituloSeleccionado = 'Entrenador Pokémon',
    ProgresoJugador? progreso,
    int saldoMonedas = 0,
  }) : saldoMonedas = saldoMonedas >= 0 ? saldoMonedas : 0,
       progreso = progreso ?? ProgresoJugador();

  bool cambiarNombre(String nuevoNombre) {
    final nombreLimpio = nuevoNombre.trim();

    if (nombreLimpio.isEmpty) {
      return false;
    }

    nombreUsuario = nombreLimpio;
    return true;
  }

  void cambiarTitulo(String nuevoTitulo) {
    tituloSeleccionado = nuevoTitulo;
  }

  Map<String, dynamic> toJson() {
    return {
      'nombreUsuario': nombreUsuario,
      'tituloSeleccionado': tituloSeleccionado,
      'progreso': progreso.toJson(),
      'saldoMonedas': saldoMonedas,
    };
  }

  void sumarSaldoMonedas(int cantidad){
    if(cantidad > 0){
      saldoMonedas += cantidad;
    }
  }

  bool restarSaldoMonedas(int cantidad){
    if(cantidad > 0 && saldoMonedas >= cantidad){
      saldoMonedas -= cantidad;
      return true;
    }
    return false;
  }

  factory PerfilJugador.fromJson(Map<String, dynamic> json) {
    final saldo = json['saldoMonedas'];

    return PerfilJugador(
      nombreUsuario: json['nombreUsuario'] ?? 'Entrenador',
      tituloSeleccionado: json['tituloSeleccionado'] ?? 'Entrenador Pokémon',
      progreso: ProgresoJugador.fromJson(json['progreso'] ?? {}),
      saldoMonedas: saldo is int && saldo >= 0 ? saldo : 0,
    );
  }
}
