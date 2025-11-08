// lib/cubit/pokemon_game_state.dart
import 'package:equatable/equatable.dart';
import 'package:whoisthatpokemon/game_attempt.dart';
import 'package:whoisthatpokemon/pokemon.dart';
import 'package:whoisthatpokemon/pokemon_generation.dart';

enum GameStatus {
  initial,
  loading,
  ready,
  inProgress,
  roundOver,
  finished,
  error,
}

class PokemonGameState extends Equatable {
  final GameStatus status;
  final PokemonGeneration selectedGeneration;
  final List<Pokemon> allPokemon;
  final Pokemon? currentPokemon;
  final List<String> answerOptions;
  final int score;
  final int pokemonGuessedCount;

  // --- 1. CAMBIOS AQUÍ ---
  final int selectedGameLength; // Renombrado de 'totalPokemonPerGame'
  final int maxPokemonInGeneration; // Nuevo campo
  // --- FIN DE CAMBIOS ---

  final List<GameAttempt> gameHistory;
  final String? selectedAnswer;
  final bool? isLastAnswerCorrect;
  final String? errorMessage;

  const PokemonGameState({
    this.status = GameStatus.initial,
    required this.selectedGeneration,
    this.allPokemon = const [],
    this.currentPokemon,
    this.answerOptions = const [],
    this.score = 0,
    this.pokemonGuessedCount = 0,

    // --- 2. CAMBIOS AQUÍ ---
    this.selectedGameLength = 5, // Renombrado y valor por defecto
    required this.maxPokemonInGeneration, // Ahora es requerido

    // --- FIN DE CAMBIOS ---
    this.gameHistory = const [],
    this.selectedAnswer,
    this.isLastAnswerCorrect,
    this.errorMessage,
  });

  /// Constructor para el estado inicial del juego.
  factory PokemonGameState.initial() {
    final firstGen = PokemonGeneration.generations.first;
    return PokemonGameState(
      selectedGeneration: firstGen,
      // --- 3. CAMBIOS AQUÍ ---
      maxPokemonInGeneration:
          firstGen.limit, // Inicializa con el límite de la Gen 1
      selectedGameLength: 5, // Valor por defecto
      // --- FIN DE CAMBIOS ---
    );
  }

  PokemonGameState copyWith({
    GameStatus? status,
    PokemonGeneration? selectedGeneration,
    List<Pokemon>? allPokemon,
    Pokemon? currentPokemon,
    List<String>? answerOptions,
    int? score,
    int? pokemonGuessedCount,

    // --- 4. CAMBIOS AQUÍ ---
    int? selectedGameLength,
    int? maxPokemonInGeneration,

    // --- FIN DE CAMBIOS ---
    List<GameAttempt>? gameHistory,
    String? selectedAnswer,
    bool? isLastAnswerCorrect,
    String? errorMessage,
    bool clearSelectedAnswer = false,
    bool clearCurrentPokemon = false,
  }) {
    return PokemonGameState(
      status: status ?? this.status,
      selectedGeneration: selectedGeneration ?? this.selectedGeneration,
      allPokemon: allPokemon ?? this.allPokemon,
      currentPokemon:
          clearCurrentPokemon ? null : (currentPokemon ?? this.currentPokemon),
      answerOptions: answerOptions ?? this.answerOptions,
      score: score ?? this.score,
      pokemonGuessedCount: pokemonGuessedCount ?? this.pokemonGuessedCount,

      // --- 5. CAMBIOS AQUÍ ---
      selectedGameLength: selectedGameLength ?? this.selectedGameLength,
      maxPokemonInGeneration:
          maxPokemonInGeneration ?? this.maxPokemonInGeneration,

      // --- FIN DE CAMBIOS ---
      gameHistory: gameHistory ?? this.gameHistory,
      selectedAnswer:
          clearSelectedAnswer ? null : selectedAnswer ?? this.selectedAnswer,
      isLastAnswerCorrect:
          clearSelectedAnswer
              ? null
              : isLastAnswerCorrect ?? this.isLastAnswerCorrect,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    status,
    selectedGeneration,
    allPokemon,
    currentPokemon,
    answerOptions,
    score,
    pokemonGuessedCount,

    // --- 6. CAMBIOS AQUÍ ---
    selectedGameLength,
    maxPokemonInGeneration,

    // --- FIN DE CAMBIOS ---
    gameHistory,
    selectedAnswer,
    isLastAnswerCorrect,
    errorMessage,
  ];
}
