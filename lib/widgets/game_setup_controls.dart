import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:whoisthatpokemon/cubit/pokemon_game_cubit.dart';
import 'package:whoisthatpokemon/cubit/pokemon_game_state.dart';
import 'package:whoisthatpokemon/pokemon_generation.dart';

class GameSetupControls extends StatelessWidget {
  const GameSetupControls({super.key});

  @override
  Widget build(BuildContext context) {
    // Este widget SÓLO se reconstruye si cambia el status
    final status = context.select((PokemonGameCubit cubit) => cubit.state.status);
    final bool hasGameStarted = status != GameStatus.initial &&
        status != GameStatus.loading &&
        status != GameStatus.ready;

    // Si el juego ya empezó, no muestra nada
    if (hasGameStarted) {
      return const SizedBox.shrink();
    }

    return const Column(
      children: [
        _GenerationSelector(),
        SizedBox(height: 20),
        _GameLengthSelector(),
      ],
    );
  }
}

// --- Widget privado para el Dropdown ---
class _GenerationSelector extends StatelessWidget {
  const _GenerationSelector();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Este widget SÓLO se reconstruye si cambian estos dos valores
    final generation = context.select((PokemonGameCubit cubit) => cubit.state.selectedGeneration);
    final isLoading = context.select((PokemonGameCubit cubit) => cubit.state.status == GameStatus.loading);

    return DropdownMenu<PokemonGeneration>(
      initialSelection: generation,
      onSelected: isLoading
          ? null
          : (PokemonGeneration? newValue) {
              if (newValue != null) {
                context
                    .read<PokemonGameCubit>()
                    .changeGeneration(newValue, context);
              }
            },
      expandedInsets: EdgeInsets.zero,
      label: const Text('Generación'),
      textStyle: theme.textTheme.titleMedium?.copyWith(
        color: theme.colorScheme.onSurface,
        fontWeight: FontWeight.w600,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: theme.colorScheme.surfaceContainerHighest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30.0),
          borderSide: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30.0),
          borderSide: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30.0),
          borderSide: BorderSide(color: theme.colorScheme.primary, width: 2.0),
        ),
      ),
      dropdownMenuEntries: PokemonGeneration.generations
          .map<DropdownMenuEntry<PokemonGeneration>>(
              (PokemonGeneration value) {
        return DropdownMenuEntry<PokemonGeneration>(
          value: value,
          label: value.name,
          style: MenuItemButton.styleFrom(
            textStyle: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurface,
            ),
          ),
        );
      }).toList(),
    );
  }
}

// --- Widget privado para el Contador ---
class _GameLengthSelector extends StatelessWidget {
  const _GameLengthSelector();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cubit = context.read<PokemonGameCubit>();

    // Este widget SÓLO se reconstruye si cambian estos tres valores
    final state = context.watch<PokemonGameCubit>().state;
    final gameLength = state.selectedGameLength;
    final maxGameLength = state.maxPokemonInGeneration;
    final isEnabled = state.status == GameStatus.ready;


    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20.0),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        children: [
          Text(
            'Número de Preguntas:',
            style: theme.textTheme.titleMedium
                ?.copyWith(color: theme.colorScheme.onSurface),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              IconButton.filledTonal(
                icon: const Icon(Icons.remove),
                iconSize: 28,
                onPressed: (!isEnabled || gameLength <= 1)
                    ? null
                    : () => cubit.changeGameLength(gameLength - 1),
              ),
              Container(
                width: 80,
                alignment: Alignment.center,
                child: Text(
                  '$gameLength',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton.filled(
                icon: const Icon(Icons.add),
                iconSize: 28,
                onPressed: (!isEnabled || gameLength >= maxGameLength)
                    ? null
                    : () => cubit.changeGameLength(gameLength + 1),
              ),
            ],
          ),
        ],
      ),
    );
  }
}