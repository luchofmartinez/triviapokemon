class Pokemon {
  final String name;
  final String imageUrl; // URL de la imagen del Pokémon
  final int? id; // <--- Nueva propiedad para el ID

  Pokemon({required this.name, required this.imageUrl, this.id});

  factory Pokemon.fromJson(Map<String, dynamic> json) {
    // Ejemplo de cómo obtener la URL de la imagen de PokéAPI
    // La estructura de la API puede variar, verifica la documentación
    final String imageUrl =
        json['sprites']['other']['official-artwork']['front_default'] ?? '';
    final int id = json['id'] as int;
    return Pokemon(name: json['name'], imageUrl: imageUrl, id: id);
  }
}
