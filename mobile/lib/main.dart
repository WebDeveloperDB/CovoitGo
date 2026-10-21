// Importiert die grundlegenden Flutter-Bausteine (Widgets, Farben, Material Design).
import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'screens/inscription_screen.dart';
import 'screens/passager_accueil_screen.dart';
import 'screens/conducteur_accueil_screen.dart';
import 'services/session_service.dart';

// Die "main" Funktion ist der Startpunkt der gesamten App.
void main() async {
  // Stellt sicher, dass die Flutter-Bindings vor der Initialisierung von SharedPreferences bereit sind
  WidgetsFlutterBinding.ensureInitialized();
  
  // Gespeicherte JWT-Sitzung laden 
  await SessionService.instance.init();

  runApp(const CovoitGoApp());
}

/// Konfiguriert das Material 3 Design-System und das Routing der App.
/// Bei bestehendem gültigen Token wird automatisch das passende Dashboard geöffnet.
class CovoitGoApp extends StatelessWidget {
  const CovoitGoApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Falls der Benutzer bereits angemeldet ist, direkt zur passenden Startseite führen
    Widget startScreen = const LoginScreen();
    if (SessionService.instance.estConnecte) {
      if (SessionService.instance.estConducteur) {
        startScreen = const ConducteurAccueilScreen();
      } else {
        startScreen = const PassagerAccueilScreen();
      }
    }

    return MaterialApp(
      title: 'CovoitGo',
      debugShowCheckedModeBanner: false,
      
      // CovoitGo Farbschema & Theme
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1E463D)),
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),

      // Haupteinstiegspunkt: Automatische Erkennung der Sitzung
      home: startScreen,

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
