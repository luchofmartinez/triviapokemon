import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:whoisthatpokemon/game_attempt.dart';
import 'package:whoisthatpokemon/pokemon.dart'; // Assuming this is your Pokemon model
import 'package:whoisthatpokemon/pokemon_generation.dart'; // Assuming this defines PokemonGeneration
import 'package:whoisthatpokemon/history_screen.dart'; // <-- AÑADE ESTA LÍNEA

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
  int _pokemonCount =
      2; // <-- Cantidad de Pokémon a adivinar por juego (PARÁMETRO)
  int _pokemonGuessedCount = 0; // <-- Contador de Pokémon adivinados/intentados
  final TextEditingController _guessController = TextEditingController();
  String _feedbackMessage = '';
  bool _isGameOver = false;
  bool _isRevealed = false; // New state to reveal the Pokemon
  bool _hasGameStarted = false;

  List<Pokemon> _allPokemon = [];
  PokemonGeneration? _selectedGeneration;
  final Random _random = Random();

  // Animation for feedback message
  late AnimationController _feedbackAnimationController;
  late Animation<double> _feedbackFadeAnimation;
  late Animation<Offset> _feedbackSlideAnimation;

  List<GameAttempt> _gameHistory = []; // <-- AÑADE ESTA LÍNEA

  @override
  void initState() {
    super.initState();
    _selectedGeneration = PokemonGeneration.generations.first;

    _feedbackAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _feedbackFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _feedbackAnimationController,
        curve: Curves.easeIn,
      ),
    );
    _feedbackSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _feedbackAnimationController,
        curve: Curves.easeOut,
      ),
    );

    // Cargar la primera lista de Pokémon sin iniciar el juego
    _fetchPokemonList(loadOnly: true); // Llama con un nuevo parámetro
  }

  @override
  void dispose() {
    _guessController.dispose();
    _feedbackAnimationController.dispose();
    super.dispose();
  }

  // --- API Calls and Game Logic ---

  Future<void> _fetchPokemonList({bool loadOnly = false}) async {
    // MODIFICA LA FIRMA
    if (_selectedGeneration == null) {
      _showFeedback('No se ha seleccionado una generación.', isError: true);
      return;
    }

    setState(() {
      _feedbackMessage = 'Cargando Pokémon de ${_selectedGeneration!.name}...';
      _allPokemon.clear();
      _currentPokemon = null; // Clear current Pokemon while loading
      _isGameOver =
          false; // Asegurar que no esté en estado de Game Over al cargar
      _isRevealed = false; // Resetear la revelación
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
        _loadNewPokemon(); // Siempre cargar un nuevo Pokémon
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
    if (_allPokemon.isEmpty) {
      _showFeedback(
        'No hay Pokémon disponibles para esta generación.',
        isError: true,
      );
      return;
    }

    setState(() {
      _feedbackMessage = '';
      _guessController.clear();
      _isGameOver = false;
      _isRevealed = false; // Reset reveal state for new Pokemon
    });

    final randomIndex = _random.nextInt(_allPokemon.length);
    final selectedPokemonName = _allPokemon[randomIndex].name;
    final selectedPokemonUrl = _allPokemon[randomIndex].imageUrl;

    try {
      final response = await http.get(Uri.parse(selectedPokemonUrl));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _currentPokemon = Pokemon.fromJson(data);
        });
      } else {
        _showFeedback(
          'Error al cargar los detalles del Pokémon.',
          isError: true,
        );
      }
    } catch (e) {
      _showFeedback('Error de red al cargar el Pokémon: $e', isError: true);
    }
  }

  void _checkAnswer() {
    if (_isGameOver || _currentPokemon == null) return;

    final userGuess = _guessController.text.trim().toLowerCase();
    final correctName = _currentPokemon!.name.toLowerCase();

    setState(() {
      _attempts++;
      _isRevealed = true;

      if (userGuess == correctName) {
        _score += 10;
        _feedbackMessage = '¡Correcto! Es ${_currentPokemon!.name}.';
        _showFeedback(
          '¡Correcto! Es ${_currentPokemon!.name}.',
          isCorrect: true,
        );
        _gameHistory.add(
          GameAttempt(
            pokemonName: _currentPokemon!.name,
            userAnswer: userGuess,
            isCorrect: true,
          ),
        );
      } else {
        _score = (_score - 5).clamp(0, double.infinity).toInt();
        _feedbackMessage =
            'Incorrecto. Era ${_currentPokemon!.name}. ¡Intenta de nuevo!';
        _showFeedback(
          'Incorrecto! Era ${_currentPokemon!.name}.',
          isError: true,
        );
        _gameHistory.add(
          GameAttempt(
            pokemonName: _currentPokemon!.name,
            userAnswer: userGuess,
            isCorrect: false,
          ),
        );
      }
      _pokemonGuessedCount++;
    });

    Future.delayed(const Duration(seconds: 5), () {
      if (_pokemonGuessedCount >= _pokemonCount) {
        _isGameOver = true;
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
      _guessController.clear();
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
    // Opcionalmente, puedes mostrar un SnackBar rápido de "Game Over" antes de navegar
    // _showFeedback('¡Juego Terminado!', isWarning: true);
  }

  Widget _buildPokemonImage() {
    // Usar _currentPokemon?.imageUrl para acceder de forma segura
    final imageUrl = _currentPokemon?.imageUrl;

    return Container(
      width:
          MediaQuery.of(context).size.width *
          0.7, // 70% del ancho de la pantalla
      height:
          MediaQuery.of(context).size.width *
          0.7, // Mantener proporción cuadrada
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
                            : 'Cargando Pokémon...', // Mostrar mensaje de carga o error
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
                  // <-- ENVUELVE EL IMAGE.NETWORK EN UN STACK
                  children: [
                    ColorFiltered(
                      colorFilter:
                          _isRevealed
                              ? const ColorFilter.mode(
                                Colors.transparent,
                                BlendMode
                                    .multiply, // No aplicar filtro si está revelado
                              )
                              : const ColorFilter.mode(
                                Colors.black,
                                BlendMode
                                    .srcATop, // Aplica filtro negro para silueta
                              ),
                      child: Image.network(
                        imageUrl,
                        fit: BoxFit.contain, // O BoxFit.cover si prefieres
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

  Widget _buildScoreBoard() {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      color: Colors.blue.shade100,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              'Puntaje: $_score',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.indigo.shade800,
                // fontFamily: 'PokemonFont', // Example for custom font
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Pokémon adivinado: $_pokemonGuessedCount / $_pokemonCount', // <-- NUEVO TEXTO
              style: const TextStyle(fontSize: 18, color: Colors.blueGrey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGuessInput() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: TextField(
        controller: _guessController,
        decoration: InputDecoration(
          labelText: '¿Quién es ese Pokémon?',
          labelStyle: TextStyle(color: Colors.grey.shade700),
          hintText: 'Ej: Pikachu',
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20.0),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20.0),
            borderSide: BorderSide(color: Colors.blue.shade400, width: 2),
          ),
          suffixIcon: IconButton(
            icon: Icon(Icons.clear, color: Colors.grey.shade600),
            onPressed: () {
              _guessController.clear();
            },
          ),
          prefixIcon: Icon(Icons.catching_pokemon, color: Colors.red.shade600),
        ),
        enabled: !_isGameOver, // Disable input when game is over
        onSubmitted: (_) => _checkAnswer(),
        textInputAction: TextInputAction.done,
        style: const TextStyle(fontSize: 18, color: Colors.black),
        textAlign: TextAlign.center,
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
        actions: [],
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
                            _selectedGeneration = PokemonGeneration.generations
                                .firstWhere(
                                  (gen) => gen.offset == newValue,
                                  orElse:
                                      () => PokemonGeneration.generations.first,
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
                      style: const TextStyle(color: Colors.white, fontSize: 16),
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

                if (_hasGameStarted) ...[
                  const SizedBox(height: 25),
                  _buildPokemonImage(),
                  const SizedBox(height: 30),
                  _buildScoreBoard(),
                  const SizedBox(height: 25),
                  _buildGuessInput(),
                  const SizedBox(height: 15),
                  FilledButton.icon(
                    onPressed: _isGameOver ? null : _checkAnswer,
                    icon: const Icon(Icons.send),
                    label: const Text(
                      'Adivinar',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
                // const SizedBox(height: 20),
                // if (_isGameOver) ...[
                //   const SizedBox(height: 20),
                //   _buildFeedbackMessage(),
                //   const SizedBox(height: 30),
                //   ElevatedButton.icon(
                //     onPressed: _resetGame,
                //     icon: const Icon(Icons.refresh),
                //     label: const Text(
                //       'Jugar de Nuevo',
                //       style: TextStyle(
                //         fontSize: 18,
                //         fontWeight: FontWeight.bold,
                //       ),
                //     ),
                //     style: ElevatedButton.styleFrom(
                //       backgroundColor: Colors.orange.shade600,
                //       foregroundColor: Colors.white,
                //       padding: const EdgeInsets.symmetric(
                //         horizontal: 30,
                //         vertical: 15,
                //       ),
                //       shape: RoundedRectangleBorder(
                //         borderRadius: BorderRadius.circular(30),
                //       ),
                //       elevation: 8,
                //     ),
                //   ),
                // ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
