import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:proyecto_pokedex/api/pokedex_session_cache_service.dart';
import 'package:proyecto_pokedex/datos/almacenamiento_perfil.dart';
import 'package:proyecto_pokedex/datos/perfil_jugador.dart';
import 'package:proyecto_pokedex/datos/pokemon_resumen.dart';
import 'package:proyecto_pokedex/logica/coleccion_servicio.dart';
import 'package:proyecto_pokedex/logica/gestor_progreso.dart';
import 'package:proyecto_pokedex/logica/sistema_gacha.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main(){
  setUp((){
    SharedPreferences.setMockInitialValues({});
  });  

  test("cobra y agrega el premio a la colección",()async{
    final perfil = PerfilJugador(saldoMonedas: 500);
    final coleccion = ColeccionServicio();
    final sistema = _crearSistema(perfil, coleccion);

    final resultado = await sistema.realizarTirada();

    expect(resultado?.premio.id, 25);
    expect(resultado?.repetido, false);
    expect(resultado?.compensacion, 0);

    expect(perfil.saldoMonedas, 100);
    expect(coleccion.estaObtenido(25), true);
  });

  test("con saldo insuficiente no cobra ni agrega un Pokémon",()async{
    final perfil = PerfilJugador(saldoMonedas: 300);
    final coleccion = ColeccionServicio();
    final sistema = _crearSistema(perfil, coleccion);

    final resultado = await sistema.realizarTirada();

    expect(resultado, null);
    expect(perfil.saldoMonedas, 300);
    expect(coleccion.estaObtenido(25), false);
  });

  test("si el premio es repetido devuelve la mitad del costo de la tirada",()async{
    final perfil = PerfilJugador(saldoMonedas: 400);
    final coleccion = ColeccionServicio();
    await coleccion.agregarPokemon(25);
    final sistema = _crearSistema(perfil, coleccion);

    final resultado = await sistema.realizarTirada();

    expect(resultado?.premio.id, 25);
    expect(resultado?.repetido, true);
    expect(resultado?.compensacion, 200);

    expect(perfil.saldoMonedas, 200);
    expect(coleccion.cantidadObtenidos, 1);
    expect(coleccion.estaObtenido(25), true);
  });

  test("si falla al guardar reembolsa y revierte el Pokémon",()async{
    final perfil = PerfilJugador(saldoMonedas: 400);
    final coleccion = ColeccionServicio(
      persistirColeccion: () async {
        throw StateError("Fallo al guardar la colección");
      },
    );
    final sistema = _crearSistema(perfil, coleccion);

    await expectLater(sistema.realizarTirada(), throwsStateError);

    expect(perfil.saldoMonedas, 400);
    expect(coleccion.estaObtenido(25), false);
    expect(coleccion.cantidadObtenidos, 0);

    final guardado = await AlmacenamientoPerfil().cargarPerfil();
    expect(guardado.saldoMonedas, 400);
  });

  test("si la lista esta vacia no cobra",()async{
    final perfil = PerfilJugador(saldoMonedas: 400);
    final sistema = _crearSistema(perfil, ColeccionServicio(), pokemons: []);

    await expectLater(sistema.realizarTirada(), throwsStateError);

    expect(perfil.saldoMonedas, 400);
  });
}

SistemaGacha _crearSistema(PerfilJugador perfil, ColeccionServicio coleccion, {List<PokemonResumen>? pokemons}){
  final cache = PokemonSessionCacheService(
    fetchPokemonList: () async => pokemons ?? [_pikachu], 
    preloadImage: (_) async {}
  );

  return SistemaGacha(
    cacheService: cache, 
    coleccionServicio: coleccion, 
    gestor: GestorProgreso(perfil: perfil),
    random: Random(1)
  );
}

final _pikachu = PokemonResumen(
  id: 25, nombre: "Pikachu", 
  urlImagen: "", 
  tipos: ["electrico"], 
  generacion: 1
);