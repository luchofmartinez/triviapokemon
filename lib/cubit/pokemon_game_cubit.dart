// lib/cubit/pokemon_game_cubit.dart
import 'dart:math';
import 'package:bloc/bloc.dart';
import 'package:flutter/widgets.dart'; // Importado para el [BuildContext] opcional
import 'package:whoisthatpokemon/cubit/pokemon_game_state.dart';
import 'package:whoisthatpokemon/repository/pokemon_repository.dart';
import 'package:whoisthatpokemon/game_attempt.dart';
import 'package:whoisthatpokemon/pokemon.dart';
import 'package:whoisthatpokemon/pokemon_generation.dart';

class PokemonGameCubit extends Cubit<PokemonGameState> {
  final PokemonRepository _pokemonRepository;
  final Random _random = Random();
  final int _numberOfOptions = 4;

  PokemonGameCubit({required PokemonRepository pokemonRepository})
    : _pokemonRepository = pokemonRepository,
      super(PokemonGameState.initial()) {
    // No llames a 'loadInitialGeneration' aquí si la UI lo va a hacer
    // con el context para el precaching.
    // Si no usas precaching, puedes dejar: loadInitialGeneration();
  }

  /// Carga la lista de Pokémon para la generación en el estado actual.
  /// Esta función AHORA también limpia el estado del juego anterior.
  Future<void> loadInitialGeneration([BuildContext? context]) async {
    emit(
      state.copyWith(
        status: GameStatus.loading,
        allPokemon: [],
        clearCurrentPokemon: true,
        score: 0,
        pokemonGuessedCount: 0,
        gameHistory: [],
        answerOptions: [],
        clearSelectedAnswer: true,

        // --- CAMBIO AQUÍ ---
        // Asegura que el 'max' se actualice al 'límite' de la generación seleccionada
        maxPokemonInGeneration: state.selectedGeneration.limit,
        // Resetea la longitud del juego si excede el nuevo máximo
        selectedGameLength:
            state.selectedGameLength > state.selectedGeneration.limit
                ? 5 // Resetea a 5
                : state.selectedGameLength,
        // --- FIN DE CAMBIO ---
      ),
    );

    try {
      final pokemonList = await _pokemonRepository.fetchPokemonList(
        state.selectedGeneration,
      );

      emit(state.copyWith(status: GameStatus.ready, allPokemon: pokemonList));
    } catch (e) {
      emit(
        state.copyWith(
          status: GameStatus.error,
          errorMessage: 'Error al cargar Pokémon. Revisa tu conexión.',
        ),
      );
    }
  }

  /// Llamado cuando el usuario cambia la generación en el Dropdown.
  Future<void> changeGeneration(
    PokemonGeneration newGeneration, [
    BuildContext? context,
  ]) async {
    // --- CAMBIO AQUÍ ---
    // Resetea la longitud seleccionada si es mayor que el límite de la *nueva* generación
    int newGameLength = state.selectedGameLength;
    if (newGameLength > newGeneration.limit) {
      newGameLength = 5; // O `newGeneration.limit`, pero 5 es un default seguro
    }

    emit(
      state.copyWith(
        selectedGeneration: newGeneration,
        selectedGameLength: newGameLength,
        maxPokemonInGeneration:
            newGeneration.limit, // Actualiza el max de inmediato
      ),
    );
    // --- FIN DE CAMBIO ---

    await loadInitialGeneration(context);
  }

  // --- NUEVO MÉTODO ---
  /// Llamado cuando el usuario cambia el Slider de número de preguntas.
  void changeGameLength(int newLength) {
    // Valida por si acaso, aunque el Slider debe controlarlo
    if (newLength > 0 && newLength <= state.maxPokemonInGeneration) {
      emit(state.copyWith(selectedGameLength: newLength));
    }
  }
  // --- FIN DE NUEVO MÉTODO ---

  /// Llamado cuando el usuario presiona "¡Comenzar!".
  void startGame() {
    emit(
      state.copyWith(
        score: 0,
        pokemonGuessedCount: 0,
        gameHistory: [],
        // Aseguramos que el juego comience con la longitud seleccionada
        status: GameStatus.inProgress,
      ),
    );
    _loadNextPokemon();
  }

  /// Llamado cuando el usuario selecciona una respuesta.
  Future<void> submitAnswer(String selectedAnswer) async {
    // ... (lógica de 'isCorrect', 'newScore', 'newHistory', 'newGuessCount') ...
    if (state.status == GameStatus.roundOver) return;

    final bool isCorrect =
        selectedAnswer.toLowerCase() ==
        state.currentPokemon!.name.toLowerCase();
    final int newScore = isCorrect ? state.score + 1 : state.score;
    final newHistory = List<GameAttempt>.from(state.gameHistory)..add(
      GameAttempt(
        pokemonName: state.currentPokemon!.name,
        userAnswer: selectedAnswer,
        isCorrect: isCorrect,
      ),
    );
    final newGuessCount = state.pokemonGuessedCount + 1;

    emit(
      state.copyWith(
        status: GameStatus.roundOver,
        isLastAnswerCorrect: isCorrect,
        selectedAnswer: selectedAnswer,
        score: newScore,
        gameHistory: newHistory,
        pokemonGuessedCount: newGuessCount,
      ),
    );

    await Future.delayed(const Duration(seconds: 2));

    // --- CAMBIO AQUÍ ---
    // Compara contra 'selectedGameLength' en lugar de 'totalPokemonPerGame'
    if (newGuessCount >= state.selectedGameLength) {
      emit(state.copyWith(status: GameStatus.finished));
    } else {
      _loadNextPokemon();
    }
    // --- FIN DE CAMBIO ---
  }

  /// Llamado cuando el usuario presiona "Reiniciar".
  void resetGame() {
    // Ahora 'loadInitialGeneration' se encarga de TODO el reseteo.
    loadInitialGeneration();
  }

  /// Llamado cuando el usuario presiona "Finalizar".
  void finishGame() {
    emit(state.copyWith(status: GameStatus.finished));
  }

  // --- FUNCIONES PRIVADAS (Helpers) ---

  void _loadNextPokemon() {
    if (state.allPokemon.isEmpty) {
      emit(
        state.copyWith(
          status: GameStatus.error,
          errorMessage: 'No hay Pokémon en la lista.',
        ),
      );
      return;
    }

    final Pokemon newPokemon =
        state.allPokemon[_random.nextInt(state.allPokemon.length)];
    final List<String> options = _generateAnswerOptions(newPokemon.name);

    emit(
      state.copyWith(
        status: GameStatus.inProgress,
        currentPokemon: newPokemon,
        answerOptions: options,
        clearSelectedAnswer: true,
      ),
    );
  }

  List<String> _generateAnswerOptions(String correctPokemonName) {
    List<String> options = [correctPokemonName];
    Set<String> uniqueOptions = {correctPokemonName};

    while (options.length < _numberOfOptions) {
      Pokemon randomPokemon =
          state.allPokemon[_random.nextInt(state.allPokemon.length)];
      if (!uniqueOptions.contains(randomPokemon.name)) {
        options.add(randomPokemon.name);
        uniqueOptions.add(randomPokemon.name);
      }
    }
    options.shuffle();
    return options;
  }
}
