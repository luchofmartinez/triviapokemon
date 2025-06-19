// Define esta clase en el mismo archivo trivia_screen.dart o en un nuevo archivo models/game_attempt.dart
class GameAttempt {
  final String pokemonName;
  final String? userAnswer; // Puede ser null si el tiempo se acaba o se omite
  final bool isCorrect;

  GameAttempt({
    required this.pokemonName,
    this.userAnswer,
    required this.isCorrect,
  });
}
