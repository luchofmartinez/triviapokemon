import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:whoisthatpokemon/cubit/pokemon_game_cubit.dart';
import 'package:whoisthatpokemon/cubit/pokemon_game_state.dart';

class AnswerOptionsGrid extends StatelessWidget {
  const AnswerOptionsGrid({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cubit = context.read<PokemonGameCubit>();

    // Este widget se reconstruye SÓLO si cambian estos valores
    final status = context.select((PokemonGameCubit cubit) => cubit.state.status);
    final options = context.select((PokemonGameCubit cubit) => cubit.state.answerOptions);
    final currentPokemon = context.select((PokemonGameCubit cubit) => cubit.state.currentPokemon);
    final selectedAnswer = context.select((PokemonGameCubit cubit) => cubit.state.selectedAnswer);

    // Si no estamos en estas fases, no muestra nada
    if (status != GameStatus.inProgress && status != GameStatus.roundOver) {
      return const SizedBox.shrink();
    }

    final bool isRevealed = status == GameStatus.roundOver;

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 2.0,
      children: options.map((option) {
        // --- Lógica de Estilo ---
        Color buttonColor;
        Color textColor;
        Color borderColor;
        double elevation;
        final bool isLongName = option.length > 10;

        if (isRevealed) {
          if (option.toLowerCase() == currentPokemon!.name.toLowerCase()) {
            buttonColor = Colors.green.shade700;
            textColor = Colors.white;
            borderColor = Colors.green.shade900;
            elevation = 8.0;
          } else if (option == selectedAnswer) {
            buttonColor = Colors.red.shade700;
            textColor = Colors.white;
            borderColor = Colors.red.shade900;
            elevation = 8.0;
          } else {
            buttonColor = theme.colorScheme.surfaceContainer.withOpacity(0.5);
            textColor = theme.colorScheme.onSurface.withOpacity(0.5);
            borderColor = theme.colorScheme.outline.withOpacity(0.3);
            elevation = 0.0;
          }
        } else {
          buttonColor = theme.colorScheme.surfaceContainer;
          textColor = theme.colorScheme.onSurface;
          borderColor = theme.colorScheme.outlineVariant;
          elevation = 3.0;
        }
        // --- Fin de Lógica de Estilo ---

        return ElevatedButton(
          onPressed: isRevealed ? null : () => cubit.submitAnswer(option),
          style: ElevatedButton.styleFrom(
            backgroundColor: buttonColor,
            foregroundColor: textColor,
            disabledBackgroundColor: buttonColor,
            disabledForegroundColor: textColor,
            elevation: elevation,
            side: BorderSide(color: borderColor, width: 2.0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.0),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
          child: Text(
            option.toUpperCase(),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: isLongName ? 14 : 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      }).toList(),
    );
  }
}