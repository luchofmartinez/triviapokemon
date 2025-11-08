// lib/history_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:whoisthatpokemon/cubit/pokemon_game_cubit.dart';
import 'package:whoisthatpokemon/game_attempt.dart'; 
import 'package:whoisthatpokemon/trivia_screen.dart';

class HistoryScreen extends StatelessWidget {
  final int finalScore;
  final int totalAttempts;
  final List<GameAttempt> gameHistory;

  const HistoryScreen({
    super.key,
    required this.finalScore,
    required this.totalAttempts,
    required this.gameHistory,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Filtramos las respuestas correctas e incorrectas
    final List<GameAttempt> correctAttempts =
        gameHistory.where((attempt) => attempt.isCorrect).toList();
    final List<GameAttempt> incorrectAttempts =
        gameHistory.where((attempt) => !attempt.isCorrect).toList();

    return Scaffold(
      appBar: AppBar(
        // Usamos los colores del tema definidos en main.dart
        title: const Text('Historial de la Partida'),
        // No mostramos el botón de "atrás"
        automaticallyImplyLeading: false,
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          // Gradiente sutil usando los colores del tema
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.scaffoldBackgroundColor,
              theme.colorScheme.primary.withOpacity(0.2),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // --- Tarjeta de Puntuación ---
                Card(
                  elevation: 5,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  margin: const EdgeInsets.only(bottom: 20),
                  color: theme.cardColor,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Text(
                          'Puntuación Final: $finalScore',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Total de preguntas: $totalAttempts',
                          style: TextStyle(
                            fontSize: 18,
                            color: theme.textTheme.bodyMedium?.color,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),

                // --- Lista de Resultados ---
                Expanded(
                  child: ListView(
                    physics: const BouncingScrollPhysics(),
                    children: [
                      // --- Respuestas Correctas ---
                      if (correctAttempts.isNotEmpty) ...[
                        Text(
                          'Respuestas Correctas:',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade700,
                          ),
                        ),
                        const SizedBox(height: 10),
                        ...correctAttempts.map((attempt) {
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 5),
                            elevation: 2,
                            child: ListTile(
                              leading: Icon(
                                Icons.check_circle,
                                color: Colors.green.shade700,
                              ),
                              title: Text(
                                attempt.pokemonName.toUpperCase(),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(
                                'Tu respuesta: ${attempt.userAnswer ?? 'N/A'}',
                              ),
                            ),
                          );
                        }),
                        const SizedBox(height: 20),
                      ],

                      // --- Respuestas Incorrectas ---
                      if (incorrectAttempts.isNotEmpty) ...[
                        Text(
                          'Respuestas Incorrectas:',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.error,
                          ),
                        ),
                        const SizedBox(height: 10),
                        ...incorrectAttempts.map((attempt) {
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 5),
                            elevation: 2,
                            child: ListTile(
                              leading: Icon(
                                Icons.cancel,
                                color: theme.colorScheme.error,
                              ),
                              title: Text(
                                attempt.pokemonName.toUpperCase(),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.error,
                                ),
                              ),
                              subtitle: Text(
                                'Tu respuesta: ${attempt.userAnswer ?? 'N/A'}',
                              ),
                            ),
                          );
                        }),
                      ],

                      // --- Si no hay historial ---
                      if (correctAttempts.isEmpty && incorrectAttempts.isEmpty)
                        Center(
                          child: Text(
                            'No hay historial para mostrar.',
                            style: theme.textTheme.bodyMedium,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // --- Botón Volver a Jugar (ACCIÓN CORREGIDA) ---
                ElevatedButton.icon(
                  onPressed: () {
                    // 1. Le decimos al Cubit que se reinicie
                    context.read<PokemonGameCubit>().resetGame();

                    // 2. Navegamos de vuelta a la pantalla de juego
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (context) => const PokemonTriviaScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text(
                    'Volver a Jugar',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  // Usamos el estilo del tema definido en main.dart
                  style: theme.elevatedButtonTheme.style?.copyWith(
                    // Podemos sobrescribir algo si es necesario,
                    // por ejemplo, para que sea verde
                    backgroundColor:
                        MaterialStateProperty.all(Colors.green.shade600),
                    foregroundColor:
                        MaterialStateProperty.all(Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}