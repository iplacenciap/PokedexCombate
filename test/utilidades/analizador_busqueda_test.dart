import 'package:flutter_test/flutter_test.dart';
import 'package:proyecto_pokedex/datos/pokemon_resumen.dart';
import 'package:proyecto_pokedex/utilidades/analizador_busqueda.dart';

void main() {
  group('Pruebas del Analizador de Búsqueda', () {
    
    final List<PokemonResumen> pokemonsDePrueba = [
      PokemonResumen(id: 1, nombre: 'Bulbasaur', urlImagen: '', tipos: ['grass', 'poison'], generacion: 1),
      PokemonResumen(id: 4, nombre: 'Charmander', urlImagen: '', tipos: ['fire'], generacion: 1),
      PokemonResumen(id: 7, nombre: 'Squirtle', urlImagen: '', tipos: ['water'], generacion: 1),
      PokemonResumen(id: 152, nombre: 'Chikorita', urlImagen: '', tipos: ['grass'], generacion: 2),
      PokemonResumen(id: 155, nombre: 'Cyndaquil', urlImagen: '', tipos: ['fire'], generacion: 2),
    ];

    test('Si no hay filtros, debe retornar la lista completa', () {
      final resultado = analizarYFiltrarBusqueda(allPokemon: pokemonsDePrueba);
      expect(resultado.length, 5);
    });

    test('Filtro por Nombre (coincidencia parcial)', () {
      final resultado = analizarYFiltrarBusqueda(
        allPokemon: pokemonsDePrueba,
        filtroNombre: 'char', 
      );
      expect(resultado.length, 1);
      expect(resultado.first.nombre, 'Charmander');
    });

    test('Filtro por Generación (única)', () {
      final resultado = analizarYFiltrarBusqueda(
        allPokemon: pokemonsDePrueba,
        filtroGeneracion: 2, 
      );
      expect(resultado.length, 2);
    });

    test('Filtro por Tipo (múltiple con nombres en inglés)', () {
      final resultado = analizarYFiltrarBusqueda(
        allPokemon: pokemonsDePrueba,
        filtrosTipo: ['fire', 'water'], 
      );
      expect(resultado.length, 3);
    });

    test('Filtro combinado (Nombre + Tipo + Generación)', () {
      final resultado = analizarYFiltrarBusqueda(
        allPokemon: pokemonsDePrueba,
        filtroNombre: 'quil',
        filtrosTipo: ['fire'],
        filtroGeneracion: 2,
      );
      expect(resultado.length, 1);
      expect(resultado.first.nombre, 'Cyndaquil');
    });

    test('Devuelve lista vacía si nada coincide', () {
      final resultado = analizarYFiltrarBusqueda(
        allPokemon: pokemonsDePrueba,
        filtroNombre: 'Agumon', 
      );
      expect(resultado.isEmpty, true);
    });
  });
}