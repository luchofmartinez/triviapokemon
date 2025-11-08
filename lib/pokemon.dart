class Pokemon {
  final String name;
  final String imageUrl;
  final int? id;

  Pokemon({required this.name, required this.imageUrl, this.id});

  // 1. TU FACTORY (Perfecto para detalles de 1 Pokémon)
  factory Pokemon.fromJson(Map<String, dynamic> json) {
    final String imageUrl =
        json['sprites']['other']['official-artwork']['front_default'] ?? '';
    final int id = json['id'] as int;
    return Pokemon(name: json['name'], imageUrl: imageUrl, id: id);
  }

  // 2. NUEVO FACTORY (Necesario para la lista de la API)
  factory Pokemon.fromListResult(Map<String, dynamic> json) {
    final String name = json['name'];
    final String url =
        json['url']; // Ej: "https://pokeapi.co/api/v2/pokemon/1/"

    // Extraemos el ID de la URL
    final parts = url.split('/');
    final int id = int.tryParse(parts[parts.length - 2]) ?? 0;

    // Construimos la URL de la imagen de alta calidad
    final String imageUrl =
        'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/$id.png';

    return Pokemon(name: name, imageUrl: imageUrl, id: id);
  }
}
