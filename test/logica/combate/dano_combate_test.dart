import 'package:flutter_test/flutter_test.dart';
import 'package:proyecto_pokedex/logica/combate/combatiente.dart';
import 'package:proyecto_pokedex/logica/combate/dano_combate.dart';
import 'package:proyecto_pokedex/logica/combate/efectividad_tipos.dart';
import 'package:proyecto_pokedex/logica/combate/movimiento_ataque.dart';
import 'package:proyecto_pokedex/logica/combate/tipo_combate.dart';

MovimientoAtaque golpe(TipoCombate tipo, {int poder = 40}) => MovimientoAtaque(
  id: 1,
  nombre: 'Ataque de prueba',
  tipo: tipo,
  categoria: CategoriaAtaque.especial,
  poder: poder,
);

Combatiente pokemon(List<TipoCombate> tipos) => Combatiente(
  idPokemon: 1,
  nombre: 'Pokémon de prueba',
  tipos: tipos,
  atributos: AtributosCombate(
    psMaximos: 100,
    ataque: 40,
    defensa: 40,
    ataqueEspecial: 40,
    defensaEspecial: 40,
    velocidad: 40,
  ),
  movimientos: [golpe(tipos.first)],
);

void main() {
  group('Efectividad por tipo', () {
    test('aplica la relación en la dirección del ataque', () {
      expect(efectividadTipo(TipoCombate.agua, [TipoCombate.fuego]), 2);
      expect(efectividadTipo(TipoCombate.fuego, [TipoCombate.agua]), 0.5);
      expect(efectividadTipo(TipoCombate.agua, [TipoCombate.fantasma]), 1);
      expect(efectividadTipo(TipoCombate.acero, [TipoCombate.hada]), 2);
    });

    test('multiplica los dos factores sin depender del orden del defensor', () {
      expect(
        efectividadTipo(TipoCombate.hielo, [
          TipoCombate.dragon,
          TipoCombate.volador,
        ]),
        4,
      );
      expect(
        efectividadTipo(TipoCombate.fuego, [
          TipoCombate.dragon,
          TipoCombate.agua,
        ]),
        0.25,
      );
      expect(
        efectividadTipo(TipoCombate.planta, [
          TipoCombate.volador,
          TipoCombate.agua,
        ]),
        1,
      );
      expect(
        efectividadTipo(TipoCombate.planta, [
          TipoCombate.agua,
          TipoCombate.volador,
        ]),
        1,
      );
    });

    test('la inmunidad prevalece sobre una debilidad del segundo tipo', () {
      expect(
        efectividadTipo(TipoCombate.electrico, [
          TipoCombate.agua,
          TipoCombate.tierra,
        ]),
        0,
      );
      expect(
        efectividadTipo(TipoCombate.lucha, [
          TipoCombate.fantasma,
          TipoCombate.normal,
        ]),
        0,
      );
    });
  });

  group('Daño por tipos', () {
    final atacante = pokemon([TipoCombate.fuego]);
    final objetivo = pokemon([TipoCombate.planta, TipoCombate.bicho]);

    test('aplica afinidad, efectividad doble y variación a la base', () {
      final ataque = golpe(TipoCombate.fuego);
      expect(calcularDano(atacante, objetivo, ataque), (
        puntos: 72,
        efectividad: 4.0,
      ));
      expect(
        calcularDano(atacante, objetivo, ataque, variacion: 85).puntos,
        61,
      );
      expect(
        calcularDano(pokemon([TipoCombate.agua]), objetivo, ataque).puntos,
        48,
      );
    });

    test('daño mínimo de uno para un acierto resistido sin inmunidad', () {
      final defensa = pokemon([TipoCombate.dragon, TipoCombate.agua]);
      expect(
        calcularDano(atacante, defensa, golpe(TipoCombate.fuego, poder: 1)),
        (puntos: 1, efectividad: 0.25),
      );
    });

    test('la inmunidad mantiene daño cero incluso con afinidad', () {
      final fantasma = pokemon([TipoCombate.fantasma, TipoCombate.veneno]);
      expect(
        calcularDano(
          pokemon([TipoCombate.normal]),
          fantasma,
          golpe(TipoCombate.normal),
        ),
        (puntos: 0, efectividad: 0.0),
      );
    });
  });
}
