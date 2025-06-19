// Puedes mover esto a un archivo separado (ej. models/pokemon_generation.dart)
class PokemonGeneration {
  final String name;
  final int offset; // Índice de inicio en la PokéAPI (0-based)
  final int limit; // Cantidad de Pokémon en la generación

  PokemonGeneration({
    required this.name,
    required this.offset,
    required this.limit,
  });

  // Lista de generaciones de Pokémon con sus offsets y límites en la PokéAPI
  static List<PokemonGeneration> get generations => [
    PokemonGeneration(name: 'Generación 1 (Kanto)', offset: 0, limit: 151),
    PokemonGeneration(name: 'Generación 2 (Johto)', offset: 151, limit: 100),
    PokemonGeneration(name: 'Generación 3 (Hoenn)', offset: 251, limit: 135),
    PokemonGeneration(name: 'Generación 4 (Sinnoh)', offset: 386, limit: 107),
    PokemonGeneration(name: 'Generación 5 (Unova)', offset: 493, limit: 156),
    PokemonGeneration(name: 'Generación 6 (Kalos)', offset: 649, limit: 72),
    PokemonGeneration(name: 'Generación 7 (Alola)', offset: 721, limit: 88),
    PokemonGeneration(name: 'Generación 8 (Galar)', offset: 809, limit: 96),
    PokemonGeneration(name: 'Generación 9 (Paldea)', offset: 905, limit: 120),
  ];
}
