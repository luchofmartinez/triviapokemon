import 'package:flutter/material.dart';
import 'package:whoisthatpokemon/app_theme.dart';
import 'package:whoisthatpokemon/trivia_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Trivia Pokémon',
      theme: AppTheme.darkTheme,
      home: const PokemonTriviaScreen(),
    );
  }
}
