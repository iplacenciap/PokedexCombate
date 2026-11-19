import "../datos/pokemon_resumen.dart";

typedef PokemonListFetcher = Future<List<PokemonResumen>> Function();
typedef ImagePreloader = Future<void> Function(String urlImagen);

class PokemonSessionCacheService {
  List<PokemonResumen>? _cachedPokemonResumenList;
  final Set<String> _precachedImageUrls = {};
  final PokemonListFetcher _fetchPokemonList;
  final ImagePreloader _preloadImage;
  Future<List<PokemonResumen>>? _fetchingFuture;

  PokemonSessionCacheService({
    required PokemonListFetcher fetchPokemonList,
    required ImagePreloader preloadImage,
  })  : _fetchPokemonList = fetchPokemonList,
        _preloadImage = preloadImage;

  Future<List<PokemonResumen>> getPokemonList() {
    if (_cachedPokemonResumenList != null) {
      return Future.value(_cachedPokemonResumenList!);
    }
    // Si ya hay una petición en curso, retorna la misma
    _fetchingFuture ??= _fetchPokemonList().then((list) {
      _cachedPokemonResumenList = List.unmodifiable(list);
      return _cachedPokemonResumenList!;
    });
    return _fetchingFuture!;
  }

  Future<void> preloadPokemonImages(List<PokemonResumen> pokemons) async {
    final List<Future<void>> descargasPendientes = [];
    for (final pokemon in pokemons) {
      final url = pokemon.urlImagen;
      if (url.isNotEmpty && _precachedImageUrls.add(url)) {
        descargasPendientes.add(_preloadImage(url));
      }
    }
    await Future.wait(descargasPendientes);
  }
}