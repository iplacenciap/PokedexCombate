import 'dart:convert';

import 'package:proyecto_pokedex/datos/perfil_jugador.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AlmacenamientoPerfil {
  static const String _clavePerfil = 'perfilJugador';

  Future<void> guardarPerfil(PerfilJugador perfil) async {
    final preferencias = await SharedPreferences.getInstance();

    final String perfilJson = jsonEncode(perfil.toJson());

    await preferencias.setString(_clavePerfil, perfilJson);
  }

  Future<PerfilJugador> cargarPerfil() async {
    final preferencias = await SharedPreferences.getInstance();

    final String? perfilJson = preferencias.getString(_clavePerfil);

    if (perfilJson == null) {
      return PerfilJugador();
    }

    final Map<String, dynamic> datos =
        jsonDecode(perfilJson) as Map<String, dynamic>;

    return PerfilJugador.fromJson(datos);
  }
}
