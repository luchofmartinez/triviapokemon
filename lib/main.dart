import 'package:flutter/material.dart';
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
      theme: ThemeData(
        // Tema general para un estilo "Cartoony/Game-like" con base Material
        primaryColor: Colors.red.shade700, // Rojo principal para AppBars, etc.
        primarySwatch: Colors.red, // Mantener para generar tonos
        hintColor:
            Colors
                .amber
                .shade700, // Color de acento, puede ser un amarillo vibrante
        // font
        // EXCLUIDO: fontFamily: 'PokemonSolid', // Si añades una fuente personalizada
        // EXCLUIDO: fontFamily: 'Poppins', // Un buen default de Google Fonts
        textTheme: const TextTheme(
          // Define estilos de texto globales
          titleLarge: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ), // Para el título de la AppBar
          bodyMedium: TextStyle(
            fontSize: 16,
            color: Colors.black87,
          ), // Texto general
          labelLarge: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ), // Para texto de botones
        ),
        cardTheme: CardThemeData(
          elevation: 6,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor:
                Colors.blue.shade700, // Color principal de los botones
            foregroundColor: Colors.white, // Color del texto del botón
            padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 15),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(25),
            ),
            elevation: 7, // Un poco más de elevación para un toque "game-like"
            textStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor:
                Colors
                    .white, // Color de texto para TextButtons (como en AppBar)
            textStyle: const TextStyle(fontSize: 16),
          ),
        ),
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const PokemonTriviaScreen(),
    );
  }
}
