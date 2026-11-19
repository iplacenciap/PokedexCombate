import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum ResultadoAgregar { nuevo, repetido }

class ColeccionServicio extends ChangeNotifier {
  static final ColeccionServicio instancia = ColeccionServicio();

  static const String _claveIds = 'coleccion_ids';
  static const String _claveFavoritos = 'coleccion_favoritos';

  final Set<int> _idsObtenidos = {};
  final Set<int> _idsFavoritos = {};
  final Future<void> Function()? _persistirColeccion;
  final Future<void> Function()? _persistirFavoritos;

  ColeccionServicio({
    Future<void> Function()? persistirColeccion,
    Future<void> Function()? persistirFavoritos,
  }) : _persistirColeccion = persistirColeccion,
       _persistirFavoritos = persistirFavoritos;

  Future<void> cargar() async {
    final preferencias = await SharedPreferences.getInstance();
    final guardados = preferencias.getStringList(_claveIds) ?? [];
    final favoritosGuardados =
        preferencias.getStringList(_claveFavoritos) ?? [];

    _idsObtenidos.clear();
    for (final texto in guardados) {
      final id = int.tryParse(texto);
      if (id != null) {
        _idsObtenidos.add(id);
      }
    }

    _idsFavoritos.clear();
    for (final texto in favoritosGuardados) {
      final id = int.tryParse(texto);
      if (id != null && _idsObtenidos.contains(id)) {
        _idsFavoritos.add(id);
      }
    }
    notifyListeners();
  }

  Future<ResultadoAgregar> agregarPokemon(int id) async {
    if (!_idsObtenidos.add(id)) {
      return ResultadoAgregar.repetido;
    }
    notifyListeners();

    try{
      await (_persistirColeccion ?? _guardar)();

    }catch(_){
      _idsObtenidos.remove(id);
      notifyListeners();
      rethrow;
    }
    return ResultadoAgregar.nuevo;
  }

  bool estaObtenido(int id) => _idsObtenidos.contains(id);

  Set<int> get idsObtenidos => Set.unmodifiable(_idsObtenidos);

  int get cantidadObtenidos => _idsObtenidos.length;

  Future<void> alternarFavorito(int id) async {
    if (!_idsObtenidos.contains(id)) {
      return;
    }

    final eraFavorito = _idsFavoritos.contains(id);
    if (eraFavorito) {
      _idsFavoritos.remove(id);
    } else {
      _idsFavoritos.add(id);
    }
    notifyListeners();

    try {
      await (_persistirFavoritos ?? _guardarFavoritos)();
    } catch (_) {
      if (eraFavorito) {
        _idsFavoritos.add(id);
      } else {
        _idsFavoritos.remove(id);
      }
      notifyListeners();
      rethrow;
    }
  }

  bool esFavorito(int id) => _idsFavoritos.contains(id);

  Set<int> get idsFavoritos => Set.unmodifiable(_idsFavoritos);

  int get cantidadFavoritos => _idsFavoritos.length;

  Future<void> _guardarFavoritos() async {
    final preferencias = await SharedPreferences.getInstance();
    await preferencias.setStringList(
      _claveFavoritos,
      _idsFavoritos.map((id) => id.toString()).toList(),
    );
  }

  Future<void> _guardar() async {
    final preferencias = await SharedPreferences.getInstance();
    await preferencias.setStringList(
      _claveIds,
      _idsObtenidos.map((id) => id.toString()).toList(),
    );
  }
}