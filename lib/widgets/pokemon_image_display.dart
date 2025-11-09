import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:whoisthatpokemon/cubit/pokemon_game_cubit.dart';
import 'package:whoisthatpokemon/cubit/pokemon_game_state.dart';

class PokemonImageDisplay extends StatelessWidget {
  const PokemonImageDisplay({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Este widget SÓLO se reconstruye si cambian estos valores
    final status = context.select(
      (PokemonGameCubit cubit) => cubit.state.status,
    );
    final pokemon = context.select(
      (PokemonGameCubit cubit) => cubit.state.currentPokemon,
    );

    final bool isRevealed = status == GameStatus.roundOver;

    // --- INICIO DE LA MODIFICACIÓN ---
    if (pokemon == null) {
      return const SizedBox.shrink();
    }

    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        Container(
          width: 250,
          height: 250,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                theme.colorScheme.primaryContainer,
                theme.colorScheme.secondaryContainer,
              ],
            ),
            borderRadius: BorderRadius.circular(25),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                spreadRadius: 4,
                blurRadius: 10,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 500),
            transitionBuilder: (Widget child, Animation<double> animation) {
              return ScaleTransition(scale: animation, child: child);
            },
            child:
                isRevealed
                    ? Image.network(
                      pokemon.imageUrl,
                      key: ValueKey<String>(pokemon.imageUrl),
                      fit: BoxFit.contain,
                    )
                    : Image.network(
                      pokemon.imageUrl,
                      key: ValueKey<String>("silhouette_${pokemon.imageUrl}"),
                      color: Colors.black,
                      colorBlendMode: BlendMode.srcIn,
                      fit: BoxFit.contain,
                    ),
          ),
        ),
        if (isRevealed)
          Positioned(
            bottom: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              margin: const EdgeInsets.symmetric(horizontal: 15),
              decoration: BoxDecoration(
                color: theme.colorScheme.secondary.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(15),
                // ... (tu sombra)
              ),
              child: Text(
                pokemon.name.toUpperCase(),
                style: TextStyle(
                  color: theme.colorScheme.onSecondary,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
