import 'package:dio/dio.dart';
import 'package:whoisthatpokemon/pokemon.dart';
import 'package:whoisthatpokemon/pokemon_generation.dart';

class PokemonRepository {
  // 1. Usamos Dio
  final Dio _dio;

  // 2. Inyectamos Dio (o creamos uno nuevo)
  PokemonRepository({Dio? dio}) : _dio = dio ?? Dio();

  Future<List<Pokemon>> fetchPokemonList(PokemonGeneration generation) async {
    try {
      // 3. Dio maneja queryParameters de forma más limpia
      final response = await _dio.get(
        'https://pokeapi.co/api/v2/pokemon',
        queryParameters: {
          'offset': generation.offset,
          'limit': generation.limit,
        },
      );

      // 4. Dio decodifica el JSON automáticamente en 'response.data'
      if (response.statusCode == 200) {
        final data = response.data;
        // Aseguramos que 'results' sea tratado como una Lista
        final results = data['results'] as List;

        // 5. Usamos nuestro nuevo factory 'fromListResult'
        final List<Pokemon> pokemonList =
            results
                .map(
                  (item) =>
                      Pokemon.fromListResult(item as Map<String, dynamic>),
                )
                .toList();

        return pokemonList;
      } else {
        throw Exception(
          'Error al cargar la lista (Status: ${response.statusCode})',
        );
      }
    } on DioException catch (e) {
      // 6. Manejamos errores específicos de Dio (red, timeout, etc.)
      throw Exception('Error de red: ${e.message}');
    } catch (e) {
      // Capturamos cualquier otro error (ej. al mapear la lista)
      throw Exception('Error inesperado: ${e.toString()}');
    }
  }
}
