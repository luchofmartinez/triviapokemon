import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:whoisthatpokemon/cubit/pokemon_game_cubit.dart';
import 'package:whoisthatpokemon/cubit/pokemon_game_state.dart';
import 'package:whoisthatpokemon/pokemon.dart';
import 'package:whoisthatpokemon/history_screen.dart';

// --- Importa los nuevos widgets que crearemos ---
import 'package:whoisthatpokemon/widgets/game_setup_controls.dart';
import 'package:whoisthatpokemon/widgets/game_status_widgets.dart';
import 'package:whoisthatpokemon/widgets/pokemon_image_display.dart';
import 'package:whoisthatpokemon/widgets/answer_options_grid.dart';

class PokemonTriviaScreen extends StatelessWidget {
  const PokemonTriviaScreen({super.key});

  // --- Las funciones de "efectos" (no UI) se quedan aquí ---
  
  void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade600,
      ),
    );
  }

  Future<void> _precachePokemonImages(
      BuildContext context, List<Pokemon> pokemonList) async {
    // ... (Tu lógica de precarga se mantiene igual)
    const int precacheLimit = 50;
    final List<Pokemon> toPrecache = pokemonList.take(precacheLimit).toList();
    for (final pokemon in toPrecache) {
      try {
        await precacheImage(NetworkImage(pokemon.imageUrl), context,
            onError: (e, s) {});
      } catch (e) {
        // Ignorar
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // --- Llamada inicial para cargar/precargar ---
    final cubit = context.read<PokemonGameCubit>();
    if (cubit.state.status == GameStatus.initial) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        cubit.loadInitialGeneration(context);
      });
    }

    return BlocListener<PokemonGameCubit, PokemonGameState>(
      // El Listener se mantiene igual para manejar efectos
      listenWhen: (prev, curr) => prev.status != curr.status,
      listener: (context, state) {
        if (state.status == GameStatus.finished) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => HistoryScreen(
                finalScore: state.score,
                totalAttempts: state.pokemonGuessedCount,
                gameHistory: state.gameHistory,
              ),
            ),
          );
        }
        if (state.status == GameStatus.error && state.errorMessage != null) {
          _showErrorSnackBar(context, state.errorMessage!);
        }
        if (state.status == GameStatus.ready && state.allPokemon.isNotEmpty) {
          _precachePokemonImages(context, state.allPokemon);
        }
      },
      // --- YA NO USAMOS BlocBuilder AQUÍ ---
      // El Scaffold se construye una vez. Los widgets internos
      // usarán context.watch o BlocSelector para reconstruirse.
      child: Scaffold(
        appBar: AppBar(
          title: const Text('¿Quién es ese Pokémon?'),
          // El AppBar también puede ser su propio widget,
          // pero por ahora lo dejamos aquí
          actions: [
            // Usamos BlocSelector para reconstruir SÓLO este Row
            BlocSelector<PokemonGameCubit, PokemonGameState, bool>(
              selector: (state) =>
                  state.status != GameStatus.initial &&
                  state.status != GameStatus.loading &&
                  state.status != GameStatus.ready &&
                  state.status != GameStatus.finished,
              builder: (context, hasGameStarted) {
                if (!hasGameStarted) return const SizedBox.shrink();
                
                return Row(
                  children: [
                    TextButton(
                      onPressed: () => cubit.resetGame(),
                      child: const Text('Reiniciar',
                          style: TextStyle(color: Colors.white)),
                    ),
                    TextButton(
                      onPressed: () => cubit.finishGame(),
                      child: const Text('Finalizar',
                          style: TextStyle(color: Colors.white)),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Theme.of(context).scaffoldBackgroundColor,
                Theme.of(context).colorScheme.primary.withOpacity(0.2),
              ],
            ),
          ),
          child: const SingleChildScrollView(
            physics: BouncingScrollPhysics(),
            child: Padding(
              padding: EdgeInsets.all(20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // --- ESTE ES EL NUEVO CUERPO ---
                  // 1. Elige generación y número de preguntas
                  GameSetupControls(),
                  SizedBox(height: 20),
                  
                  // 2. Muestra la imagen del Pokémon
                  PokemonImageDisplay(),
                  SizedBox(height: 20),

                  // 3. Muestra (Cargando / Botón Empezar / Error)
                  GameStatusWidgets(),

                  // 4. Muestra la cuadrícula de respuestas
                  AnswerOptionsGrid(),
                  // --- FIN DEL NUEVO CUERPO ---
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}