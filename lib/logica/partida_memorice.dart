import "dart:async";
import "dart:math";
import "package:flutter/foundation.dart";
import "package:proyecto_pokedex/api/pokedex_session_cache_service.dart";
import "package:proyecto_pokedex/logica/enums/estado_memorice.dart";
import "../datos/pokemon_resumen.dart";
import "enums/dificultad_memorice.dart";

typedef FinPartidaCallback = void Function(
  DificultadMemorice dificultad,
  bool victoria,
  int mejorCombo,
);

class CartaMemorice {
  final int id;
  final PokemonResumen pokemon;
  bool _bocaArriba;
  bool _emparejada;

  CartaMemorice({
    required this.id,
    required this.pokemon,
    bool bocaArriba = true,
    bool emparejada = false,
  })  : _bocaArriba = bocaArriba,
        _emparejada = emparejada;

  // Getters públicos de solo lectura para evitar mutaciones accidentales desde la UI
  bool get bocaArriba => _bocaArriba;
  bool get emparejada => _emparejada;
}

class PartidaMemorice extends ChangeNotifier {
  // Tiempo que permanecen visibles dos cartas distintas antes de volver a ocultarse
  static const Duration tiempoMuestraError = Duration(milliseconds: 800);

  final PokemonSessionCacheService _cacheService;
  final Random _random;
  final FinPartidaCallback? _onPartidaFinalizada;

  DificultadMemorice _dificultad = DificultadMemorice.facil;
  FaseMemorice _fase = FaseMemorice.inicial;
  List<CartaMemorice> _cartas = [];

  CartaMemorice? _primeraCartaSeleccionada;
  bool _esperandoOcultarPar = false;

  int _errores = 0;
  int _comboActual = 0;
  int _mejorCombo = 0;

  // Control de concurrencia y ciclo de vida para operaciones asíncronas
  int _idOperacionActual = 0;
  bool _disposed = false;

  Timer? _timerMemorizacion;
  Timer? _timerJuego;
  Timer? _timerOcultarPar;

  // Notificador independiente para actualizar el reloj sin redibujar todo el tablero
  final ValueNotifier<int> segundosRestantes = ValueNotifier<int>(0);

  PartidaMemorice({
    required PokemonSessionCacheService cacheService,
    Random? random,
    FinPartidaCallback? onPartidaFinalizada,
  })  : _cacheService = cacheService,
        _random = random ?? Random(),
        _onPartidaFinalizada = onPartidaFinalizada;

  // Getters públicos de estado y métricas
  DificultadMemorice get dificultad => _dificultad;
  FaseMemorice get fase => _fase;
  List<CartaMemorice> get cartas => List.unmodifiable(_cartas);
  int get errores => _errores;
  int get comboActual => _comboActual;
  int get mejorCombo => _mejorCombo;

  // El tablero está bloqueado si no estamos en fase jugando o si se muestra un error temporal
  bool get tableroBloqueado =>
      _fase != FaseMemorice.jugando || _esperandoOcultarPar;

  // Inicia una nueva partida en la dificultad indicada
  Future<void> iniciarPartida(DificultadMemorice dificultadElegida) async {
    _cancelarTimers();
    final int idOperacion = ++_idOperacionActual;

    _dificultad = dificultadElegida;
    _primeraCartaSeleccionada = null;
    _esperandoOcultarPar = false;
    _errores = 0;
    _comboActual = 0;
    _mejorCombo = 0;

    // Obtener listado desde el servicio de caché
    final todosLosPokemons = await _cacheService.getPokemonList();

    // Abortar si el controlador fue destruido o se inició otra acción durante el await
    if (_disposed || idOperacion != _idOperacionActual) return;

    // Filtrar Pokémon únicos por nombre para evitar pares cuadruplicados
    final Map<String, PokemonResumen> unicosPorNombre = {};
    for (final p in todosLosPokemons) {
      unicosPorNombre.putIfAbsent(p.nombre, () => p);
    }
    final listaUnicos = unicosPorNombre.values.toList();

    if (listaUnicos.length < _dificultad.pares) {
      throw StateError(
        "No hay suficientes Pokémon únicos (${listaUnicos.length}) para generar ${_dificultad.pares} pares.",
      );
    }

    //Seleccionar N Pokémon al azar para esta partida
    listaUnicos.shuffle(_random);
    final seleccionados = listaUnicos.take(_dificultad.pares).toList();

    //Precargar en caché únicamente las imágenes de los Pokémon seleccionados (Task 1)
    await _cacheService.preloadPokemonImages(seleccionados);

    // Abortar si el controlador fue destruido o se inició otra acción durante la precarga
    if (_disposed || idOperacion != _idOperacionActual) return;

    //Crear los pares de cartas (boca arriba para memorización) y barajarlas
    final List<CartaMemorice> nuevasCartas = [];
    int contadorId = 0;
    for (final pokemon in seleccionados) {
      nuevasCartas.add(
        CartaMemorice(id: contadorId++, pokemon: pokemon, bocaArriba: true),
      );
      nuevasCartas.add(
        CartaMemorice(id: contadorId++, pokemon: pokemon, bocaArriba: true),
      );
    }
    nuevasCartas.shuffle(_random);
    _cartas = nuevasCartas;

    //Configurar fase de memorización inicial
    _fase = FaseMemorice.memorizando;
    segundosRestantes.value = _dificultad.segundosJuego;
    _notificarSegura();

    //Iniciar temporizador de vista previa (memorización)
    _timerMemorizacion = Timer(
      Duration(seconds: _dificultad.segundosMemorizacion),
      _iniciarFaseDeJuego,
    );
  }

  //Devuelve el juego a la pantalla de selección de dificultad inicial (para el botón "Inicio" de Task 4)
  void volverAlInicio() {
    _cancelarTimers();
    _idOperacionActual++; // Cancela cualquier carga asíncrona en curso
    _cartas = [];
    _primeraCartaSeleccionada = null;
    _esperandoOcultarPar = false;
    _errores = 0;
    _comboActual = 0;
    _mejorCombo = 0;
    segundosRestantes.value = 0;
    _fase = FaseMemorice.inicial;
    _notificarSegura();
  }

  //Gestiona el toque de una carta según su índice en la grilla (Task 3)
  void seleccionarCarta(int index) {
    if (tableroBloqueado) return;
    if (index < 0 || index >= _cartas.length) return;

    final cartaTocada = _cartas[index];

    // Ignorar toques sobre cartas que ya están volteadas o emparejadas
    if (cartaTocada.bocaArriba || cartaTocada.emparejada) return;

    cartaTocada._bocaArriba = true;

    // Si es la primera carta del par que se levanta:
    if (_primeraCartaSeleccionada == null) {
      _primeraCartaSeleccionada = cartaTocada;
      _notificarSegura();
      return;
    }

    // Si es la segunda carta del par, comparamos los Pokémon:
    final primeraCarta = _primeraCartaSeleccionada!;
    if (primeraCarta.pokemon.nombre == cartaTocada.pokemon.nombre) {
      _procesarAcierto(primeraCarta, cartaTocada);
    } else {
      _procesarError(primeraCarta, cartaTocada);
    }
  }

  void _procesarAcierto(CartaMemorice primera, CartaMemorice segunda) {
    primera._emparejada = true;
    segunda._emparejada = true;
    _primeraCartaSeleccionada = null;

    _comboActual++;
    if (_comboActual > _mejorCombo) {
      _mejorCombo = _comboActual;
    }

    // Verificar si todas las cartas del tablero han sido emparejadas (Victoria)
    final todasEmparejadas = _cartas.every((c) => c.emparejada);
    if (todasEmparejadas) {
      _cancelarTimers();
      _fase = FaseMemorice.victoria;
      _notificarSegura();
      _onPartidaFinalizada?.call(_dificultad, true, _mejorCombo);
    } else {
      _notificarSegura();
    }
  }

  void _procesarError(CartaMemorice primera, CartaMemorice segunda) {
    _errores++;
    _comboActual = 0;
    _esperandoOcultarPar = true;
    _notificarSegura();

    _timerOcultarPar = Timer(tiempoMuestraError, () {
      if (_disposed) return;
      primera._bocaArriba = false;
      segunda._bocaArriba = false;
      _primeraCartaSeleccionada = null;
      _esperandoOcultarPar = false;
      _notificarSegura();
    });
  }

  void _iniciarFaseDeJuego() {
    if (_disposed) return;
    for (final carta in _cartas) {
      carta._bocaArriba = false;
    }
    _fase = FaseMemorice.jugando;
    _notificarSegura();

    _timerJuego = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_disposed) {
        timer.cancel();
        return;
      }
      if (segundosRestantes.value > 0) {
        segundosRestantes.value--;
      }

      if (segundosRestantes.value <= 0) {
        _finalizarPorTiempoAgotado();
      }
    });
  }

  void _finalizarPorTiempoAgotado() {
    _cancelarTimers();
    _primeraCartaSeleccionada = null;
    _esperandoOcultarPar = false;
    _fase = FaseMemorice.derrota;
    _notificarSegura();
    _onPartidaFinalizada?.call(_dificultad, false, _mejorCombo);
  }

  void _notificarSegura() {
    if (!_disposed) {
      notifyListeners();
    }
  }

  void _cancelarTimers() {
    _timerMemorizacion?.cancel();
    _timerMemorizacion = null;
    _timerJuego?.cancel();
    _timerJuego = null;
    _timerOcultarPar?.cancel();
    _timerOcultarPar = null;
  }

  @override
  void dispose() {
    _disposed = true;
    _cancelarTimers();
    segundosRestantes.dispose();
    super.dispose();
  }
}