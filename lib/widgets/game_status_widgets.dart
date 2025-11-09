import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:whoisthatpokemon/cubit/pokemon_game_cubit.dart';
import 'package:whoisthatpokemon/cubit/pokemon_game_state.dart';

class GameStatusWidgets extends StatelessWidget {
  const GameStatusWidgets({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // Este widget se reconstruye SÓLO si cambia el status
    final state = context.watch<PokemonGameCubit>().state;
    final status = state.status;

    switch (status) {
      case GameStatus.loading:
        return const Column(
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 10),
            Text('Cargando Pokémon...'),
          ],
        );

      case GameStatus.ready:
        return FilledButton.icon(
          onPressed: () => context.read<PokemonGameCubit>().startGame(),
          icon: const Icon(Icons.play_arrow, size: 28),
          label: Text(
            '¡Comenzar (${state.selectedGameLength} preguntas)!',
            style: const TextStyle(fontSize: 20),
          ),
          style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade600),
        );

      case GameStatus.error:
        return Column(
          children: [
            Icon(Icons.wifi_off, size: 60, color: theme.colorScheme.error),
            const SizedBox(height: 10),
            Text(state.errorMessage ?? 'Error desconocido',
                textAlign: TextAlign.center),
            const SizedBox(height: 20),
            FilledButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
              onPressed: () {
                context.read<PokemonGameCubit>().loadInitialGeneration(context);
              },
            ),
          ],
        );

      // Si el juego está en progreso, terminado, etc., no muestra nada
      default:
        return const SizedBox.shrink();
    }
  }
}