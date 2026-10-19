// Importiert die grundlegenden Flutter-Bausteine (Widgets, Farben, Material Design).
import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'screens/inscription_screen.dart';
import 'screens/passager_accueil_screen.dart';
import 'screens/conducteur_accueil_screen.dart';

// Die "main" Funktion ist der Startpunkt der gesamten App.
void main() {
  runApp(const CovoitGoApp());
}

/// Konfiguriert das Material 3 Design-System und das Routing der App.
/// Der Haupt-Startbildschirm ist ab sofort der LoginScreen.
class CovoitGoApp extends StatelessWidget {
  const CovoitGoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CovoitGo',
      debugShowCheckedModeBanner: false,
      
      // CovoitGo Farbschema & Theme
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1E463D)),
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),

      // Haupteinstiegspunkt: Anmeldebildschirm (Login)
      home: const LoginScreen(),

      // Benanntes Routingsystem für einfache Navigation
      routes: {
        '/login': (context) => const LoginScreen(),
        '/inscription': (context) => const InscriptionScreen(),
        '/passager': (context) => const PassagerAccueilScreen(),
        '/conducteur': (context) => const ConducteurAccueilScreen(),
      },
    );
  }
}

