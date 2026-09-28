// Importiert die grundlegenden Flutter-Bausteine (Widgets, Farben, Material Design).
import 'package:flutter/material.dart';
import 'screens/passager_accueil_screen.dart';
import 'screens/conducteur_accueil_screen.dart';

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
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1E463D)),
        useMaterial3: true,
      ),
      home: const AccueilScreen(), // Startseite ist jetzt die Rollenauswahl
    );
  }
}

// Temporärer Bildschirm, um beim Testen zwischen Passagier und Fahrer zu wechseln,
// solange wir noch keinen echten Login haben.
class AccueilScreen extends StatelessWidget {
  const AccueilScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // "Scaffold" ist wie eine weiße Leinwand für eine Seite.
    // Es bietet automatisch Platz für eine Kopfzeile (AppBar) und den Inhalt (Body).
    return Scaffold(
      backgroundColor: const Color(0xFFF4F2EC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E463D),
        title: const Text('Mode Test', style: TextStyle(color: Colors.white)),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Qui êtes-vous ?',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1E463D)),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.person, color: Colors.black87),
                  label: const Text('Je suis Passager', style: TextStyle(fontSize: 18, color: Colors.black87)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE29E4A),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const PassagerAccueilScreen()),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.directions_car, color: Colors.black87),
                  label: const Text('Je suis Conducteur', style: TextStyle(fontSize: 18, color: Colors.black87)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE29E4A),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ConducteurAccueilScreen()),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
