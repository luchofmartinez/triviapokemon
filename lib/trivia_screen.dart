import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:whoisthatpokemon/cubit/pokemon_game_cubit.dart';
import 'package:whoisthatpokemon/cubit/pokemon_game_state.dart';
import 'package:whoisthatpokemon/pokemon.dart';
import 'package:whoisthatpokemon/pokemon_generation.dart';
import 'package:whoisthatpokemon/history_screen.dart';
// Importa tus otros widgets (como DropdownMenu) si es necesario

class PokemonTriviaScreen extends StatelessWidget {
  const PokemonTriviaScreen({super.key});

  void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.red.shade600,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _precachePokemonImages(
    BuildContext context,
    List<Pokemon> pokemonList,
  ) async {
    const int precacheLimit = 50;
    final List<Pokemon> toPrecache = pokemonList.take(precacheLimit).toList();

    for (final pokemon in toPrecache) {
      try {
        await precacheImage(
          NetworkImage(pokemon.imageUrl),
          context,
          onError: (exception, stackTrace) {},
        );
      } catch (e) {
        // Ignorar errores
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // --- LLAMADA INICIAL PARA PRECACHE ---
    // (Manejo para llamar a loadInitialGeneration con context la primera vez)
    // Esto es un poco 'trucado' en StatelessWidget, asegurémonos de que se llame.
    final cubit = context.read<PokemonGameCubit>();
    if (cubit.state.status == GameStatus.initial) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        cubit.loadInitialGeneration(context);
      });
    }
    // --- FIN DE LLAMADA INICIAL ---

    return BlocListener<PokemonGameCubit, PokemonGameState>(
      listenWhen: (prev, curr) => prev.status != curr.status,
      listener: (context, state) {
        if (state.status == GameStatus.finished) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder:
                  (context) => HistoryScreen(
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
      child: BlocBuilder<PokemonGameCubit, PokemonGameState>(
        builder: (context, state) {
          final theme = Theme.of(context);
          final bool isLoading = state.status == GameStatus.loading;
          final bool hasGameStarted =
              state.status != GameStatus.initial &&
              state.status != GameStatus.loading &&
              state.status != GameStatus.ready;

          return Scaffold(
            appBar: AppBar(
              title: const Text('¿Quién es ese Pokémon?'),
              actions: [
                if (hasGameStarted && state.status != GameStatus.finished)
                  Row(
                    children: [
                      TextButton(
                        onPressed:
                            () => context.read<PokemonGameCubit>().resetGame(),
                        child: const Text(
                          'Reiniciar',
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                      ),
                      TextButton(
                        onPressed:
                            () => context.read<PokemonGameCubit>().finishGame(),
                        child: const Text(
                          'Finalizar',
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
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
                    theme.scaffoldBackgroundColor,
                    theme.colorScheme.primary.withOpacity(0.2),
                  ],
                ),
              ),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // --- Dropdown de Generación ---
                      if (!hasGameStarted)
                        DropdownMenu<PokemonGeneration>(
                          initialSelection: state.selectedGeneration,
                          onSelected:
                              isLoading
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
                            fillColor:
                                theme.colorScheme.surfaceContainerHighest,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30.0),
                              borderSide: BorderSide(
                                color: theme.colorScheme.outlineVariant,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30.0),
                              borderSide: BorderSide(
                                color: theme.colorScheme.outlineVariant,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30.0),
                              borderSide: BorderSide(
                                color: theme.colorScheme.primary,
                                width: 2.0,
                              ),
                            ),
                          ),
                          dropdownMenuEntries:
                              PokemonGeneration.generations.map<
                                DropdownMenuEntry<PokemonGeneration>
                              >((PokemonGeneration value) {
                                return DropdownMenuEntry<PokemonGeneration>(
                                  value: value,
                                  label: value.name,
                                  style: MenuItemButton.styleFrom(
                                    textStyle: theme.textTheme.bodyLarge
                                        ?.copyWith(
                                          color: theme.colorScheme.onSurface,
                                        ),
                                  ),
                                );
                              }).toList(),
                        ),

                      const SizedBox(height: 20),

                      // --- NUEVO WIDGET: SLIDER DE PREGUNTAS ---
                      if (state.status == GameStatus.ready ||
                          (state.status == GameStatus.loading &&
                              !hasGameStarted))
                        _buildGameLengthSelector(
                          context,
                          theme,
                          state,
                        ), // <-- CAMBIAR A ESTA

                      const SizedBox(height: 20),

                      // --- FIN DE SLIDER ---
                      _buildPokemonImage(theme, state),

                      const SizedBox(height: 20),

                      if (isLoading)
                        const Column(
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 10),
                            Text('Cargando Pokémon...'),
                          ],
                        ),

                      if (state.status == GameStatus.ready)
                        FilledButton.icon(
                          onPressed:
                              () =>
                                  context.read<PokemonGameCubit>().startGame(),
                          icon: const Icon(Icons.play_arrow, size: 28),
                          label: Text(
                            // --- TEXTO DE BOTÓN ACTUALIZADO ---
                            '¡Comenzar (${state.selectedGameLength} preguntas)!',
                            style: const TextStyle(fontSize: 20),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.shade600,
                          ),
                        ),

                      if (state.status == GameStatus.inProgress ||
                          state.status == GameStatus.roundOver)
                        _buildAnswerOptions(context, theme, state),

                      if (state.status == GameStatus.error)
                        Column(
                          children: [
                            Icon(
                              Icons.wifi_off,
                              size: 60,
                              color: theme.colorScheme.error,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              state.errorMessage ?? 'Error desconocido',
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 20),
                            FilledButton.icon(
                              icon: const Icon(Icons.refresh),
                              label: const Text('Reintentar'),
                              onPressed: () {
                                context
                                    .read<PokemonGameCubit>()
                                    .loadInitialGeneration(context);
                              },
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // --- NUEVO WIDGET HELPER PARA EL CONTADOR ---
  Widget _buildGameLengthSelector(
    BuildContext context,
    ThemeData theme,
    PokemonGameState state,
  ) {
    // Deshabilitamos los botones si está cargando
    final bool isEnabled = state.status == GameStatus.ready;
    final cubit = context.read<PokemonGameCubit>();

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
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // --- Botón de Restar (-) ---
              IconButton.filledTonal(
                icon: const Icon(Icons.remove),
                iconSize: 28,
                // Deshabilitar si no está listo O si el valor es 1
                onPressed:
                    (!isEnabled || state.selectedGameLength <= 1)
                        ? null
                        : () {
                          cubit.changeGameLength(state.selectedGameLength - 1);
                        },
              ),

              // --- Texto del Valor ---
              // Usamos un 'Container' para darle un ancho fijo y que no "salte"
              Container(
                width: 80, // Ancho fijo
                alignment: Alignment.center,
                child: Text(
                  '${state.selectedGameLength}',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              // --- Botón de Sumar (+) ---
              IconButton.filled(
                icon: const Icon(Icons.add),
                iconSize: 28,
                // Deshabilitar si no está listo O si llegó al máximo
                onPressed:
                    (!isEnabled ||
                            state.selectedGameLength >=
                                state.maxPokemonInGeneration)
                        ? null
                        : () {
                          cubit.changeGameLength(state.selectedGameLength + 1);
                        },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPokemonImage(ThemeData theme, PokemonGameState state) {
    final bool isRevealed = state.status == GameStatus.roundOver;

    if (state.currentPokemon == null) {
      return Container(
        width: 250,
        height: 250,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceVariant,
          borderRadius: BorderRadius.circular(25),
        ),
        child:
            (state.status == GameStatus.loading)
                ? const CircularProgressIndicator()
                : const Text('Selecciona una generación'),
      );
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
                color: Colors.black.withOpacity(0.4),
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
                      state.currentPokemon!.imageUrl,
                      key: ValueKey<String>(state.currentPokemon!.imageUrl),
                      fit: BoxFit.contain,
                    )
                    : Image.network(
                      state.currentPokemon!.imageUrl,
                      key: ValueKey<String>(state.currentPokemon!.imageUrl),
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
                color: theme.colorScheme.secondary.withOpacity(0.9),
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 5,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Text(
                state.currentPokemon!.name.toUpperCase(),
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

  Widget _buildAnswerOptions(
    BuildContext context,
    ThemeData theme,
    PokemonGameState state,
  ) {
    final bool isRevealed = state.status == GameStatus.roundOver;

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 2.0, // <-- Un poco más anchos (rectangulares)
      children:
          state.answerOptions.map((option) {
            // --- Lógica de Estilo ---
            Color buttonColor;
            Color textColor;
            Color borderColor;
            double elevation;

            // Ajusta el tamaño de fuente si el nombre es muy largo
            final bool isLongName = option.length > 10;

            if (isRevealed) {
              if (option.toLowerCase() ==
                  state.currentPokemon!.name.toLowerCase()) {
                // --- ESTADO: CORRECTO ---
                buttonColor = Colors.green.shade700;
                textColor = Colors.white;
                borderColor = Colors.green.shade900;
                elevation = 8.0; // Lo levantamos
              } else if (option == state.selectedAnswer) {
                // --- ESTADO: INCORRECTO (Seleccionado) ---
                buttonColor = Colors.red.shade700;
                textColor = Colors.white;
                borderColor = Colors.red.shade900;
                elevation = 8.0; // Lo levantamos
              } else {
                // --- ESTADO: INCORRECTO (No seleccionado) ---
                buttonColor = theme.colorScheme.surfaceContainer.withOpacity(
                  0.5,
                );
                textColor = theme.colorScheme.onSurface.withOpacity(0.5);
                borderColor = theme.colorScheme.outline.withOpacity(0.3);
                elevation = 0.0; // Lo aplanamos
              }
            } else {
              // --- ESTADO: POR DEFECTO (Esperando respuesta) ---
              buttonColor =
                  theme
                      .colorScheme
                      .surfaceContainer; // Un color de "carta" neutro
              textColor = theme.colorScheme.onSurface; // Color de texto normal
              borderColor = theme.colorScheme.outlineVariant; // Borde sutil
              elevation = 3.0;
            }
            // --- Fin de Lógica de Estilo ---

            return ElevatedButton(
              onPressed:
                  isRevealed
                      ? null // El botón se deshabilita
                      : () {
                        context.read<PokemonGameCubit>().submitAnswer(option);
                      },
              style: ElevatedButton.styleFrom(
                // --- Aplicamos los estilos ---
                backgroundColor: buttonColor,
                foregroundColor: textColor,
                disabledBackgroundColor:
                    buttonColor, // Forzamos el color al deshabilitar
                disabledForegroundColor:
                    textColor, // Forzamos el color al deshabilitar
                elevation: elevation,

                // --- Borde (la clave del nuevo diseño) ---
                side: BorderSide(color: borderColor, width: 2.0),

                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    16.0,
                  ), // Un poco más cuadrado
                ),

                // Padding ajustado
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
              ),
              child: Text(
                option.toUpperCase(),
                textAlign: TextAlign.center,
                maxLines: 2, // Permitimos 2 líneas para nombres largos
                overflow:
                    TextOverflow.ellipsis, // Corta el texto si es aún más largo
                style: TextStyle(
                  // Ajustamos el tamaño de fuente si es un nombre largo
                  fontSize: isLongName ? 14 : 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            );
          }).toList(),
    );
  }
}
