import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dio/dio.dart'; // Asegúrate de importar Dio
import 'package:whoisthatpokemon/cubit/pokemon_game_cubit.dart';
import 'package:whoisthatpokemon/repository/pokemon_repository.dart';
import 'package:whoisthatpokemon/trivia_screen.dart';

void main() {
  // Puedes crear tu instancia de Dio aquí
  final dio = Dio();

  runApp(MyApp(dio: dio));
}

class MyApp extends StatelessWidget {
  final Dio dio;
  const MyApp({super.key, required this.dio});

  @override
  Widget build(BuildContext context) {
    // 1. Proveemos el Repositorio, que usa la instancia de Dio
    return RepositoryProvider(
      create: (context) => PokemonRepository(dio: dio),

      // 2. Proveemos el Cubit, que a su vez usa el Repositorio
      child: BlocProvider(
        create:
            (context) => PokemonGameCubit(
              pokemonRepository: RepositoryProvider.of<PokemonRepository>(
                context,
              ),
            ),
        child: MaterialApp(
          title: '¿Quién es ese Pokémon?',
          debugShowCheckedModeBanner: false,

          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.red),
            appBarTheme: AppBarTheme(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              elevation: 4.0,
              centerTitle: true,
              titleTextStyle: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade700,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 30,
                  vertical: 15,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
            useMaterial3: true,
          ),
          home: const PokemonTriviaScreen(),
        ),
      ),
    );
  }
}
