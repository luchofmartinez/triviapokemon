import 'package:flutter/material.dart';
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
    final List<GameAttempt> correctAttempts =
        gameHistory.where((attempt) => attempt.isCorrect).toList();
    final List<GameAttempt> incorrectAttempts =
        gameHistory.where((attempt) => !attempt.isCorrect).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Historial de la Partida',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Colors.blue.shade700,
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.blue.shade100, Colors.purple.shade100],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  elevation: 5,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  margin: const EdgeInsets.only(bottom: 20),
                  color: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Text(
                          'Puntuación Final: $finalScore',
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.deepPurple,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Total de preguntas: $totalAttempts',
                          style: const TextStyle(
                            fontSize: 18,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: ListView(
                    children: [
                      if (correctAttempts.isNotEmpty) ...[
                        const Text(
                          'Respuestas Correctas:',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                        const SizedBox(height: 10),
                        ...correctAttempts.map((attempt) {
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 5),
                            elevation: 2,
                            color: Colors.green.shade50,
                            child: ListTile(
                              leading: const Icon(
                                Icons.check_circle,
                                color: Colors.green,
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

                      if (incorrectAttempts.isNotEmpty) ...[
                        const Text(
                          'Respuestas Incorrectas:',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                        const SizedBox(height: 10),
                        ...incorrectAttempts.map((attempt) {
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 5),
                            elevation: 2,
                            color: Colors.red.shade50,
                            child: ListTile(
                              leading: const Icon(
                                Icons.cancel,
                                color: Colors.red,
                              ),
                              title: Text(
                                attempt.pokemonName.toUpperCase(),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(
                                'Respuesta correcta: ${attempt.pokemonName.toUpperCase()} \nTu respuesta: ${attempt.userAnswer ?? 'N/A'}',
                              ),
                            ),
                          );
                        }),
                      ],
                      if (correctAttempts.isEmpty && incorrectAttempts.isEmpty)
                        const Center(
                          child: Text(
                            'No hay historial para mostrar.',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () {
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
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 30,
                      vertical: 15,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 8,
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
