// lib/cubit/pokemon_game_state.dart
import 'package:equatable/equatable.dart';
import 'package:whoisthatpokemon/game_attempt.dart';
import 'package:whoisthatpokemon/pokemon.dart';
import 'package:whoisthatpokemon/pokemon_generation.dart';

enum GameStatus {
  initial,
  loading,
  ready,
  finished,
  error,
  inProgress, // <-- Me di cuenta que faltaba este, lo agrego por si acaso
  roundOver,  // <-- Me di cuenta que faltaba este, lo agrego por si acaso
}

class PokemonGameState extends Equatable {
  final GameStatus status;
  
  // --- CAMBIO 1: Hacer nulable ---
  final PokemonGeneration? selectedGeneration;
  
  final List<Pokemon> allPokemon;
  final Pokemon? currentPokemon;
  final List<String> answerOptions;
  final int score;
  final int pokemonGuessedCount;
  final int selectedGameLength;
  final int maxPokemonInGeneration;
  final List<GameAttempt> gameHistory;
  final String? selectedAnswer;
  final bool? isLastAnswerCorrect;
  final String? errorMessage;

  const PokemonGameState({
    this.status = GameStatus.initial,
    
    // --- CAMBIO 2: Aceptar nulable ---
    this.selectedGeneration,
    
    this.allPokemon = const [],
    this.currentPokemon,
    this.answerOptions = const [],
    this.score = 0,
    this.pokemonGuessedCount = 0,
    this.selectedGameLength = 5,
    this.maxPokemonInGeneration = 0, // <-- Cambiado a 0 por defecto
    this.gameHistory = const [],
    this.selectedAnswer,
    this.isLastAnswerCorrect,
    this.errorMessage,
  });

  /// Constructor para el estado inicial del juego.
  factory PokemonGameState.initial() {
    // --- CAMBIO 3: No seleccionar ninguna generación ---
    return const PokemonGameState(
      status: GameStatus.initial,
      selectedGeneration: null,
      maxPokemonInGeneration: 0, // No hay max hasta que se elija
      selectedGameLength: 5,
    );
  }

  PokemonGameState copyWith({
    GameStatus? status,
    
    // --- CAMBIO 4: Wrapper para permitir 'null' explícito ---
    // Esto es un truco para poder setear 'null'
    // Si pasamos 'PokemonGeneration? selectedGeneration', copyWith(selectedGeneration: null)
    // sería ignorado por el '??'.
    NullableWrapper<PokemonGeneration?>? selectedGeneration,
    
    List<Pokemon>? allPokemon,
    Pokemon? currentPokemon,
    List<String>? answerOptions,
    int? score,
    int? pokemonGuessedCount,
    int? selectedGameLength,
    int? maxPokemonInGeneration,
    List<GameAttempt>? gameHistory,
    String? selectedAnswer,
    bool? isLastAnswerCorrect,
    String? errorMessage,
    bool clearSelectedAnswer = false,
    bool clearCurrentPokemon = false,
  }) {
    return PokemonGameState(
      status: status ?? this.status,
      
      // --- CAMBIO 5: Lógica del wrapper ---
      selectedGeneration: selectedGeneration != null
          ? selectedGeneration.value
          : this.selectedGeneration,
          
      allPokemon: allPokemon ?? this.allPokemon,
      currentPokemon: clearCurrentPokemon
          ? null
          : (currentPokemon ?? this.currentPokemon),
      answerOptions: answerOptions ?? this.answerOptions,
      score: score ?? this.score,
      pokemonGuessedCount: pokemonGuessedCount ?? this.pokemonGuessedCount,
      selectedGameLength: selectedGameLength ?? this.selectedGameLength,
      maxPokemonInGeneration:
          maxPokemonInGeneration ?? this.maxPokemonInGeneration,
      gameHistory: gameHistory ?? this.gameHistory,
      selectedAnswer:
          clearSelectedAnswer ? null : selectedAnswer ?? this.selectedAnswer,
      isLastAnswerCorrect: clearSelectedAnswer
          ? null
          : isLastAnswerCorrect ?? this.isLastAnswerCorrect,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        selectedGeneration, // <-- CAMBIO 6: Añadido a props
        allPokemon,
        currentPokemon,
        answerOptions,
        score,
        pokemonGuessedCount,
        selectedGameLength,
        maxPokemonInGeneration,
        gameHistory,
        selectedAnswer,
        isLastAnswerCorrect,
        errorMessage,
      ];
}

// --- CAMBIO 7: Clase helper para el 'copyWith' nulable ---
class NullableWrapper<T> {
  final T value;
  const NullableWrapper(this.value);
}