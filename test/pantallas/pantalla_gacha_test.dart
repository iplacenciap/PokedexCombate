import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:proyecto_pokedex/api/pokedex_session_cache_service.dart';
import 'package:proyecto_pokedex/datos/almacenamiento_perfil.dart';
import 'package:proyecto_pokedex/datos/perfil_jugador.dart';
import 'package:proyecto_pokedex/datos/pokemon_resumen.dart';
import 'package:proyecto_pokedex/logica/coleccion_servicio.dart';
import 'package:proyecto_pokedex/logica/gestor_progreso.dart';
import 'package:proyecto_pokedex/logica/sistema_gacha.dart';
import 'package:proyecto_pokedex/pantallas/pantalla_gacha.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main(){
  setUp((){
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets("realizar tirada cobra pokemonedas con saldo suficiente", (tester) async{
    final perfil = PerfilJugador(saldoMonedas: 500);
    final coleccion = ColeccionServicio();
    final sistema = _crearSistema(perfil, coleccion);
    
    await tester.pumpWidget(
      MaterialApp(home: PantallaGacha(sistema: sistema))
    );

    await tester.tap(find.byKey(const ValueKey('boton_tirar_gacha')));
    await tester.pumpAndSettle();

    expect(perfil.saldoMonedas, 100);
    expect(find.descendant(of: find.byKey(const ValueKey('resultado_gacha')), matching: find.text('Pikachu')), findsOneWidget);

    final perfilGuardado = await AlmacenamientoPerfil().cargarPerfil();
    expect(perfilGuardado.saldoMonedas, 100);
  });

  testWidgets("no realiza tirada si el saldo es insuficiente", (tester) async{
    final perfil = PerfilJugador(saldoMonedas: 300);

    final coleccion = ColeccionServicio();
    final sistema = _crearSistema(perfil, coleccion);
    
    await tester.pumpWidget(
      MaterialApp(home: PantallaGacha(sistema: sistema))
    );

    await AlmacenamientoPerfil().guardarPerfil(perfil);
    
    await tester.tap(find.byKey(const ValueKey('boton_tirar_gacha')));
    await tester.pumpAndSettle();

    expect(perfil.saldoMonedas, 300);
    expect(find.text("No tienes suficientes Pokémonedas"), findsOneWidget);

    //comprueba que no se guardo ningun cambio
    expect((await AlmacenamientoPerfil().cargarPerfil()).saldoMonedas, 300);
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
  );
}

final _pikachu = PokemonResumen(
  id: 25, nombre: "Pikachu", 
  urlImagen: "", 
  tipos: ["electrico"], 
  generacion: 1
);