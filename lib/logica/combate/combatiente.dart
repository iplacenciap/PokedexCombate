import '../../datos/pokemon.dart';
import 'movimiento_ataque.dart';
import 'tipo_combate.dart';

class AtributosCombate {
  AtributosCombate({
    required this.psMaximos,
    required this.ataque,
    required this.defensa,
    required this.ataqueEspecial,
    required this.defensaEspecial,
    required this.velocidad,
  }) {
    for (final entrada in {
      'psMaximos': psMaximos,
      'ataque': ataque,
      'defensa': defensa,
      'ataqueEspecial': ataqueEspecial,
      'defensaEspecial': defensaEspecial,
      'velocidad': velocidad,
    }.entries) {
      if (entrada.value <= 0) {
        throw ArgumentError.value(
          entrada.value,
          entrada.key,
          'Debe ser positivo',
        );
      }
    }
  }

  final int psMaximos;
  final int ataque;
  final int defensa;
  final int ataqueEspecial;
  final int defensaEspecial;
  final int velocidad;

  factory AtributosCombate.desdeBase(Map<String, int> base) {
    int atributo(String clave, int incremento) {
      final valor = base[clave];
      if (valor == null || valor <= 0) {
        throw ArgumentError.value(
          valor,
          clave,
          'Se requiere un atributo base positivo',
        );
      }
      return valor + incremento;
    }

    return AtributosCombate(
      psMaximos: atributo('hp', 70),
      ataque: atributo('attack', 30),
      defensa: atributo('defense', 30),
      ataqueEspecial: atributo('special-attack', 30),
      defensaEspecial: atributo('special-defense', 30),
      velocidad: atributo('speed', 30),
    );
  }
}

class Combatiente {
  Combatiente({
    required this.idPokemon,
    required this.nombre,
    required Iterable<TipoCombate> tipos,
    required this.atributos,
    required Iterable<MovimientoAtaque> movimientos,
  }) : tipos = List.unmodifiable(tipos),
       movimientos = List.unmodifiable(movimientos) {
    if (idPokemon <= 0) throw ArgumentError.value(idPokemon, 'idPokemon');
    if (nombre.trim().isEmpty) throw ArgumentError.value(nombre, 'nombre');

    if (this.tipos.isEmpty ||
        this.tipos.length > 2 ||
        this.tipos.toSet().length != this.tipos.length) {
      throw ArgumentError.value(
        this.tipos,
        'tipos',
        'Se requieren uno o dos tipos distintos',
      );
    }

    final ids = this.movimientos.map((movimiento) => movimiento.id).toSet();
    if (this.movimientos.isEmpty ||
        this.movimientos.length > 4 ||
        ids.length != this.movimientos.length) {
      throw ArgumentError.value(
        this.movimientos,
        'movimientos',
        'Se requieren entre uno y cuatro movimientos distintos',
      );
    }
  }

  factory Combatiente.desdePokemon(
    Pokemon pokemon, {
    required Iterable<MovimientoAtaque> movimientos,
  }) => Combatiente(
    idPokemon: pokemon.id,
    nombre: pokemon.nombre,
    tipos: pokemon.tipos.map(TipoCombate.desdeApi),
    atributos: AtributosCombate.desdeBase(pokemon.estadisticas),
    movimientos: movimientos,
  );

  final int idPokemon;
  final String nombre;
  final List<TipoCombate> tipos;
  final AtributosCombate atributos;
  final List<MovimientoAtaque> movimientos;
}

class EquipoCombate {
  EquipoCombate(Iterable<Combatiente> integrantes)
    : integrantes = List.unmodifiable(integrantes) {
    if (this.integrantes.isEmpty) {
      throw ArgumentError.value(
        integrantes,
        'integrantes',
        'El equipo está vacío',
      );
    }
  }

  final List<Combatiente> integrantes;
}
