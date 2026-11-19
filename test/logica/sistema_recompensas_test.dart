import 'package:flutter_test/flutter_test.dart';
import 'package:proyecto_pokedex/logica/enums/dificultad_memorice.dart';
import 'package:proyecto_pokedex/logica/sistema_recompensas.dart';

void main() {
  test('Calcula correctamente las recompensas del PokeGuesser',(){
  
    //casos normales
    expect(SistemaRecompensas.recompensaPokeguesser(victoria: true, intentosIncorrectos: 0), 1600);
    expect(SistemaRecompensas.recompensaPokeguesser(victoria: true, intentosIncorrectos: 6), 400);
    expect(SistemaRecompensas.recompensaPokeguesser(victoria: false, intentosIncorrectos: 7), 200);

    //casos borde
    expect(SistemaRecompensas.recompensaPokeguesser(victoria: true, intentosIncorrectos: 7), 200);
    expect(SistemaRecompensas.recompensaPokeguesser(victoria: true, intentosIncorrectos: -1), 200);
  });

  test('Memorice entrega recompensa base seún la dificultad', (){
    for(final dificultad in DificultadMemorice.values){
      expect(SistemaRecompensas.recompensaMemorice(
        victoria: true, 
        intentosIncorrectos: 0, 
        dificultad: dificultad
      ), dificultad.recompensa);
    }
  });

  test('Memorice descuenta 20 monedas por error, hasta un máximo de 10', (){
    expect(SistemaRecompensas.recompensaMemorice(
        victoria: true, 
        intentosIncorrectos: 1, 
        dificultad: DificultadMemorice.facil
      ), 480);
    expect(SistemaRecompensas.recompensaMemorice(
        victoria: true, 
        intentosIncorrectos: 10, 
        dificultad: DificultadMemorice.facil
      ), 300);
    expect(SistemaRecompensas.recompensaMemorice(
        victoria: true, 
        intentosIncorrectos: 11, 
        dificultad: DificultadMemorice.facil
      ), 300);
  });

  test('Memorice no entrega monedas al perder o con intentos negativos', (){
    expect(SistemaRecompensas.recompensaMemorice(
        victoria: false, 
        intentosIncorrectos: 0, 
        dificultad: DificultadMemorice.dificil
      ), 0);
    expect(SistemaRecompensas.recompensaMemorice(
        victoria: true, 
        intentosIncorrectos: -1, 
        dificultad: DificultadMemorice.dificil
      ), 0);
  });
}
