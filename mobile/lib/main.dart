// Importiert die grundlegenden Flutter-Bausteine (Widgets, Farben, Material Design).
import 'package:flutter/material.dart';
import 'screens/passager_accueil_screen.dart';

// Die "main" Funktion ist der Startpunkt der gesamten App.
// Wenn die App auf dem Handy startet, sucht das System genau nach dieser "main" Funktion.
void main() {
  // runApp startet die App und übergibt das allererste "Widget" (CovoitGoApp).
  // Ein Widget ist in Flutter alles, was man auf dem Bildschirm sieht.
  runApp(const CovoitGoApp());
}

// Dies ist das Haupt-Widget (das Fundament) unserer App. 
// Es ist "Stateless" (Zustandslos), weil sich die Grundeinstellungen (wie Farbe/Titel) 
// der App selbst nicht ständig ändern.
class CovoitGoApp extends StatelessWidget {
  const CovoitGoApp({super.key});

  // Die "build"-Methode ist die wichtigste Methode in Flutter.
  // Sie zeichnet (baut) die Benutzeroberfläche auf den Bildschirm.
  @override
  Widget build(BuildContext context) {
    // MaterialApp ist ein fertiges Grundgerüst von Google.
    // Es gibt uns Navigation und ein schönes Design (Material Design).
    return MaterialApp(
      // Der Titel der App (wird z.B. im Task-Manager des Handys angezeigt).
      title: 'CovoitGo',
      
      // Das Theme (Design) unserer App. Hier definieren wir Farben und Schriftarten.
      theme: ThemeData(
        // Wir setzen die Hauptfarbe der App auf ein schönes Blau (passend für CovoitGo).
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        // Wir nutzen das moderne Material 3 Design.
        useMaterial3: true,
      ),
      
      // "home" definiert den allerersten Bildschirm (Screen), 
      // der angezeigt wird, direkt wenn die App startet.
      home: const PassagerAccueilScreen(),
    );
  }
}

// Dies ist ein einfacher Platzhalter-Bildschirm für den Anfang.
// Später werden wir diesen Code in den Ordner "screens" auslagern.
class AccueilScreen extends StatelessWidget {
  const AccueilScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // "Scaffold" ist wie eine weiße Leinwand für eine Seite.
    // Es bietet automatisch Platz für eine Kopfzeile (AppBar) und den Inhalt (Body).
    return Scaffold(
      // Die obere Kopfzeile (App Bar).
      appBar: AppBar(
        // Die Hintergrundfarbe der Leiste holen wir uns aus unserem Theme (von oben).
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        // Der Text, der oben in der Leiste steht.
        title: const Text('CovoitGo - Accueil'),
      ),
      
      // Der Hauptbereich der Seite (Body).
      body: const Center(
        // Center zentriert alles, was sich darin (in "child") befindet.
        child: Text(
          'Willkommen bei CovoitGo',
          textAlign: TextAlign.center, // Text wird zentriert geschrieben
          style: TextStyle(fontSize: 18), // Wir machen die Schrift etwas größer
        ),
      ),
    );
  }
}
