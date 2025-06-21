import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:whoisthatpokemon/game_attempt.dart';
import 'package:whoisthatpokemon/pokemon.dart';
import 'package:whoisthatpokemon/pokemon_generation.dart';
import 'package:whoisthatpokemon/history_screen.dart';

class PokemonTriviaScreen extends StatefulWidget {
  const PokemonTriviaScreen({super.key});

  @override
  State<PokemonTriviaScreen> createState() => _PokemonTriviaScreenState();
}

class _PokemonTriviaScreenState extends State<PokemonTriviaScreen>
    with SingleTickerProviderStateMixin {
  Pokemon? _currentPokemon;
  int _score = 0;
  int _attempts = 0;
  final int _pokemonCount = 10;
  int _pokemonGuessedCount = 0;
  List<String> _answerOptions = [];
  final int _numberOfOptions = 4;

  String _feedbackMessage = '';
  bool _isGameOver = false;
  bool _isRevealed = false;
  bool _hasGameStarted = false;

  List<Pokemon> _allPokemon = [];
  PokemonGeneration? _selectedGeneration;
  final Random _random = Random();

  late AnimationController _feedbackAnimationController;
  late Animation<double> feedbackFadeAnimation;
  late Animation<Offset> feedbackSlideAnimation;

  List<GameAttempt> _gameHistory = [];

  @override
  void initState() {
    super.initState();
    _selectedGeneration = PokemonGeneration.generations.first;

    _feedbackAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    feedbackFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _feedbackAnimationController,
        curve: Curves.easeIn,
      ),
    );
    feedbackSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _feedbackAnimationController,
        curve: Curves.easeOut,
      ),
    );

    _fetchPokemonList(loadOnly: true);
  }

  @override
  void dispose() {
    _feedbackAnimationController.dispose();
    super.dispose();
  }

  Future<void> _fetchPokemonList({bool loadOnly = false}) async {
    if (_selectedGeneration == null) {
      _showFeedback('No se ha seleccionado una generación.', isError: true);
      return;
    }

    setState(() {
      _feedbackMessage = 'Cargando Pokémon de ${_selectedGeneration!.name}...';
      _allPokemon.clear();
      _currentPokemon = null;
      _isGameOver = false;
      _isRevealed = false;
    });

    try {
      final response = await http.get(
        Uri.parse(
          'https://pokeapi.co/api/v2/pokemon?offset=${_selectedGeneration!.offset}&limit=${_selectedGeneration!.limit}',
        ),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        for (var item in data['results']) {
          _allPokemon.add(Pokemon(name: item['name'], imageUrl: item['url']));
        }
        setState(() {
          _feedbackMessage = '';
        });
        _loadNewPokemon();
      } else {
        _showFeedback(
          'Error al cargar la lista de Pokémon de la generación.',
          isError: true,
        );
      }
    } catch (e) {
      _showFeedback('Error de red: $e', isError: true);
    }
  }

  Future<void> _loadNewPokemon() async {
    if (_selectedGeneration == null || _allPokemon.isEmpty) {
      _showFeedback(
        'No hay Pokémon cargados para la generación seleccionada.',
        isError: true,
      );
      return;
    }

    setState(() {
      _feedbackMessage = 'Adivina este Pokémon...';
    });

    final int randomIndex = _random.nextInt(_allPokemon.length);
    final Pokemon selectedBasicPokemon = _allPokemon[randomIndex];

    try {
      final response = await http.get(Uri.parse(selectedBasicPokemon.imageUrl));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _currentPokemon = Pokemon.fromJson(data);

        _answerOptions = _generateAnswerOptions(_currentPokemon!.name);
      } else {
        _showFeedback(
          'Error al cargar detalles del Pokémon: ${response.statusCode}',
          isError: true,
        );
        _currentPokemon = null;
      }
    } catch (e) {
      _showFeedback(
        'Error de red al cargar detalles del Pokémon: $e',
        isError: true,
      );
      _currentPokemon = null;
    }

    setState(() {
      _isRevealed = false;
      _feedbackMessage = 'Adivina este Pokémon...';
    });
  }

  List<String> _generateAnswerOptions(String correctName) {
    List<String> options = [correctName];
    while (options.length < _numberOfOptions) {
      final int randomIndex = _random.nextInt(_allPokemon.length);
      final String randomPokemonName = _allPokemon[randomIndex].name;

      if (randomPokemonName.toLowerCase() != correctName.toLowerCase() &&
          !options.contains(randomPokemonName)) {
        options.add(randomPokemonName);
      }
    }

    options.shuffle();
    return options;
  }

  void _checkAnswer(String selectedAnswer) {
    if (_currentPokemon == null) return;

    String correctName = _currentPokemon!.name.toLowerCase();
    String selectedGuess = selectedAnswer.trim().toLowerCase();

    setState(() {
      _attempts++;
      _isRevealed = true;

      if (selectedGuess == correctName) {
        _score += 10;
        _feedbackMessage = '¡Correcto! Es ${_currentPokemon!.name}.';
        _gameHistory.add(
          GameAttempt(
            pokemonName: _currentPokemon!.name,
            userAnswer: selectedAnswer,
            isCorrect: true,
          ),
        );
      } else {
        _score = (_score - 5).clamp(0, double.infinity).toInt();
        _feedbackMessage = 'Incorrecto. Era ${_currentPokemon!.name}.';
        _gameHistory.add(
          GameAttempt(
            pokemonName: _currentPokemon!.name,
            userAnswer: selectedAnswer,
            isCorrect: false,
          ),
        );
      }
      _pokemonGuessedCount++;
    });

    Future.delayed(const Duration(seconds: 2), () {
      if (_pokemonGuessedCount >= _pokemonCount) {
        _showGameOverDialog();
      } else {
        _loadNewPokemon();
      }
    });
  }

  void _resetGame() {
    setState(() {
      _score = 0;
      _attempts = 0;
      _feedbackMessage = '';
      _isGameOver = false;
      _isRevealed = false;
      _hasGameStarted = false;
      _gameHistory.clear();
      _pokemonGuessedCount = 0;
    });
    _fetchPokemonList(loadOnly: true);
  }

  void _showFeedback(
    String message, {
    bool isCorrect = false,
    bool isError = false,
    bool isWarning = false,
  }) {
    Color backgroundColor = Colors.blue;
    if (isCorrect) {
      backgroundColor = Colors.green.shade600;
    } else if (isError) {
      backgroundColor = Colors.red.shade600;
    } else if (isWarning) {
      backgroundColor = Colors.orange.shade600;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: backgroundColor,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(10),
      ),
    );
  }

  void _showGameOverDialog() {
    setState(() {
      _isGameOver = true;
    });

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder:
            (context) => HistoryScreen(
              finalScore: _score,
              totalAttempts: _attempts,
              gameHistory: _gameHistory,
            ),
      ),
    );
  }

  Widget _buildPokemonImage() {
    final imageUrl = _currentPokemon?.imageUrl;

    return Container(
      width: MediaQuery.of(context).size.width * 0.6,
      height: MediaQuery.of(context).size.width * 0.6,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            spreadRadius: 3,
            blurRadius: 7,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child:
            imageUrl == null || imageUrl.isEmpty
                ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.image_not_supported,
                        size: 50,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _feedbackMessage.isNotEmpty
                            ? _feedbackMessage
                            : 'Cargando Pokémon...',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                )
                : Stack(
                  fit: StackFit.expand,
                  children: [
                    ColorFiltered(
                      colorFilter:
                          _isRevealed
                              ? const ColorFilter.mode(
                                Colors.transparent,
                                BlendMode.multiply,
                              )
                              : const ColorFilter.mode(
                                Colors.black,
                                BlendMode.srcATop,
                              ),
                      child: Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Center(
                            child: Icon(
                              Icons.error_outline,
                              size: 50,
                              color: Colors.red.shade400,
                            ),
                          );
                        },
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Center(
                            child: CircularProgressIndicator(
                              value:
                                  loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                      : null,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.red.shade400,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    if (_isRevealed && _currentPokemon != null)
                      Positioned(
                        bottom: 10,
                        left: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          margin: const EdgeInsets.symmetric(horizontal: 10),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            _currentPokemon!.name.toUpperCase(),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '¿Quién es ese Pokémon?',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Colors.red.shade700,
        elevation: 0,
        centerTitle: true,
        actions: [
          if (_hasGameStarted && !_isGameOver)
            Row(
              children: [
                TextButton(
                  onPressed: _resetGame,
                  style: TextButton.styleFrom(foregroundColor: Colors.white),
                  child: const Text(
                    'Reiniciar',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ), // Color del texto
                ),
                const SizedBox(width: 8), // Espacio entre los botones
                TextButton(
                  onPressed: () {
                    // Finalizar el juego y navegar a la pantalla de historial
                    _showGameOverDialog();
                  },
                  style: TextButton.styleFrom(foregroundColor: Colors.white),
                  child: const Text(
                    'Finalizar',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ), // Color del texto
                ),
                const SizedBox(width: 8), // Un poco de margen al final
              ],
            ),
        ],
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.blue.shade200, Colors.yellow.shade100],
          ),
        ),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (!_hasGameStarted)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    margin: const EdgeInsets.only(bottom: 20.0),
                    decoration: BoxDecoration(
                      color: Colors.red.shade600,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          spreadRadius: 2,
                          blurRadius: 5,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        value: _selectedGeneration?.offset,
                        onChanged: (int? newValue) {
                          if (newValue != null) {
                            setState(() {
                              _selectedGeneration = PokemonGeneration
                                  .generations
                                  .firstWhere(
                                    (gen) => gen.offset == newValue,
                                    orElse:
                                        () =>
                                            PokemonGeneration.generations.first,
                                  );
                              if (!_hasGameStarted) {
                                _fetchPokemonList();
                              } else {
                                _resetGame();
                              }
                            });
                          }
                        },
                        items:
                            PokemonGeneration.generations
                                .map<DropdownMenuItem<int>>((
                                  PokemonGeneration gen,
                                ) {
                                  return DropdownMenuItem<int>(
                                    value: gen.offset,
                                    child: Text(
                                      gen.name,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                      ),
                                    ),
                                  );
                                })
                                .toList(),
                        dropdownColor: Colors.red.shade500,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                        iconEnabledColor: Colors.white,
                      ),
                    ),
                  ),

                if (!_hasGameStarted)
                  FilledButton.icon(
                    onPressed: () {
                      setState(() {
                        _hasGameStarted = true;
                        _pokemonGuessedCount = 0;
                        _score = 0;
                        _attempts = 0;
                        _gameHistory.clear();
                      });

                      _loadNewPokemon();
                    },
                    icon: const Icon(Icons.play_arrow),
                    label: const Text(
                      'Iniciar Juego',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                const SizedBox(height: 25),
                if (_hasGameStarted && _currentPokemon != null)
                  _buildPokemonImage(),
                const SizedBox(height: 30),
                if (_hasGameStarted && _currentPokemon != null)
                  Column(
                    children:
                        _answerOptions.map((option) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: ElevatedButton(
                              onPressed:
                                  _isGameOver || _isRevealed
                                      ? null
                                      : () => _checkAnswer(option),
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    Colors
                                        .blue
                                        .shade700, // Color de los botones
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 30,
                                  vertical: 15,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                elevation: 5,
                                minimumSize: const Size(
                                  double.infinity,
                                  50,
                                ), // Que ocupen el ancho disponible
                              ),
                              child: Text(
                                option
                                    .toUpperCase(), // Muestra la opción en mayúsculas
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
