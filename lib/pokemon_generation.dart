import 'package:equatable/equatable.dart'; // <-- 1. Importar

class PokemonGeneration extends Equatable {
  // <-- 2. Extender
  final String name;
  final int offset;
  final int limit;

  const PokemonGeneration({
    // <-- 3. Hacer el constructor 'const' (opcional pero recomendado)
    required this.name,
    required this.offset,
    required this.limit,
  });

  // Lista de generaciones
  static List<PokemonGeneration> get generations => [
    const PokemonGeneration(
      name: 'Generación 1 (Kanto)',
      offset: 0,
      limit: 151,
    ),
    const PokemonGeneration(
      name: 'Generación 2 (Johto)',
      offset: 151,
      limit: 100,
    ),
    const PokemonGeneration(
      name: 'Generación 3 (Hoenn)',
      offset: 251,
      limit: 135,
    ),
    const PokemonGeneration(
      name: 'Generación 4 (Sinnoh)',
      offset: 386,
      limit: 107,
    ),
    const PokemonGeneration(
      name: 'Generación 5 (Unova)',
      offset: 493,
      limit: 156,
    ),
    const PokemonGeneration(
      name: 'Generación 6 (Kalos)',
      offset: 649,
      limit: 72,
    ),
    const PokemonGeneration(
      name: 'Generación 7 (Alola)',
      offset: 721,
      limit: 88,
    ),
    const PokemonGeneration(
      name: 'Generación 8 (Galar)',
      offset: 809,
      limit: 96,
    ),
    const PokemonGeneration(
      name: 'Generación 9 (Paldea)',
      offset: 905,
      limit: 120,
    ),
  ];

  // <-- 4. Sobrescribir 'props'
  @override
  List<Object?> get props => [name, offset, limit];
}
