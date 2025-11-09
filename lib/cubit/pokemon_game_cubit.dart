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
    // --- CAMBIO 1: NO llamar a loadInitialGeneration() aquí ---
  }

  /// Carga la lista de Pokémon para la generación en el estado actual.
  Future<void> loadInitialGeneration([BuildContext? context]) async {
    // --- CAMBIO 2: Guardián por si no hay generación ---
    if (state.selectedGeneration == null) {
      emit(state.copyWith(
          status: GameStatus.error,
          errorMessage: 'Por favor, selecciona una generación.'));
      return;
    }

    emit(state.copyWith(
      status: GameStatus.loading,
      allPokemon: [],
      clearCurrentPokemon: true,
      score: 0,
      pokemonGuessedCount: 0,
      gameHistory: [],
      answerOptions: [],
      clearSelectedAnswer: true,
      maxPokemonInGeneration: state.selectedGeneration!.limit, // '!' es seguro por el guardián
      selectedGameLength:
          state.selectedGameLength > state.selectedGeneration!.limit
              ? 5
              : state.selectedGameLength,
    ));

    try {
      final pokemonList =
          await _pokemonRepository.fetchPokemonList(state.selectedGeneration!); // '!' es seguro
          
      emit(state.copyWith(
        status: GameStatus.ready,
        allPokemon: pokemonList,
      ));

      // ... (Tu lógica de precarga)
    } catch (e) {
      emit(state.copyWith(
        status: GameStatus.error,
        errorMessage: 'Error al cargar Pokémon. Revisa tu conexión.',
      ));
    }
  }

  /// Llamado cuando el usuario cambia la generación en el Dropdown.
  Future<void> changeGeneration(PokemonGeneration newGeneration,
      [BuildContext? context]) async {
    int newGameLength = state.selectedGameLength;
    if (newGameLength > newGeneration.limit) {
      newGameLength = 5;
    }

    // --- CAMBIO 3: Usar el wrapper para setear la generación ---
    emit(state.copyWith(
      selectedGeneration: NullableWrapper(newGeneration),
      selectedGameLength: newGameLength,
      maxPokemonInGeneration: newGeneration.limit,
    ));

    // Ahora que la generación está seteada, cargamos los datos
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
    // --- CAMBIO 4: Resetea al estado inicial (con 'null') ---
    emit(PokemonGameState.initial());
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
