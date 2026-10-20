import 'package:flutter/material.dart';
import 'passager_accueil_screen.dart';
import 'conducteur_accueil_screen.dart';
import 'inscription_screen.dart';
import '../services/api_service.dart';
import '../services/session_service.dart';

/// ANMELDE-BILDSCHIRM (LOGIN SCREEN) - Ticket FR403-677 & FR403-887
/// 
/// Ermöglicht dem Benutzer, sich als Mitfahrer (Passager) oder Fahrer (Conducteur) anzumelden.
/// Authentifiziert über das Spring Boot Backend via JWT-Token und speichert die Session persistent.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Schlüssel zur Steuerung und Validierung des Formulars
  final _formKey = GlobalKey<FormState>();

  // Text-Controller für die Eingabefelder (mit Standard-Testwerten vorbefüllt)
  final TextEditingController _emailController = TextEditingController(text: 'passager@covoitgo.fr');
  final TextEditingController _passwordController = TextEditingController(text: 'password123');

  // Standardmäßig ausgewählte Rolle beim Start ('PASSAGER' oder 'CONDUCTEUR')
  // Dies ist der Startwert. Klickt der Nutzer auf "Conducteur", ändert sich dieser Wert sofort.
  String _selectedRole = 'PASSAGER'; 
  bool _obscurePassword = true; // Passwort verbergen/anzeigen
  bool _isLoading = false;      // Zeigt Ladeindikator beim Anmelden

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Funktion zum Anmelden über die Backend-API & Weiterleiten
  void _seConnecter() async {
    // 1. Prüfen, ob alle Formularfelder gültig sind
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    // Echter API-Aufruf zu POST /api/auth/login
    final result = await ApiService.login(email, password);

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (result['success'] == true) {
      final role = SessionService.instance.role ?? _selectedRole;
      final prenom = SessionService.instance.prenom ?? '';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Connexion réussie ! Bienvenue $prenom.'),
          backgroundColor: const Color(0xFF1E463D),
          duration: const Duration(seconds: 2),
        ),
      );

      // 2. Automatisches Routing je nach erhaltener Benutzerrolle
      if (role == 'CONDUCTEUR') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const ConducteurAccueilScreen()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const PassagerAccueilScreen()),
        );
      }
    } else {
      // Fehlermeldung bei ungültigen Anmeldedaten oder Verbindungsproblemen
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Email ou mot de passe incorrect.'),
          backgroundColor: Colors.red.shade700,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // CovoitGo Farbpalette
    const primaryColor = Color(0xFF1E463D); // Tannengrün
    const accentColor = Color(0xFFE29E4A);  // Warmes Orange
    const bgColor = Color(0xFFF4F2EC);      // Helles Beige

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 1. CovoitGo Logo & Willkommenstitel
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: primaryColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.directions_car_filled_rounded,
                      size: 42,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'CovoitGo',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Le covoiturage solidaire au quotidien',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // 2. Anmeldekarte (Login Card)
                  Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Connexion',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: primaryColor,
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Rollen-Auswahl (Umschalter zwischen Passager und Conducteur)
                          const Text(
                            'Je me connecte en tant que :',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              // Button: Passager
                              Expanded(
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(10),
                                  onTap: () {
                                    // Beim Klick wird die Rolle auf PASSAGER gesetzt
                                    setState(() {
                                      _selectedRole = 'PASSAGER';
                                      if (_emailController.text.contains('conducteur')) {
                                        _emailController.text = 'passager@covoitgo.fr';
                                      }
                                    });
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    decoration: BoxDecoration(
                                      color: _selectedRole == 'PASSAGER' ? primaryColor : Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: _selectedRole == 'PASSAGER' ? primaryColor : Colors.grey.shade300,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.person,
                                          size: 18,
                                          color: _selectedRole == 'PASSAGER' ? Colors.white : Colors.black87,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          'Passager',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: _selectedRole == 'PASSAGER' ? Colors.white : Colors.black87,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              // Button: Conducteur
                              Expanded(
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(10),
                                  onTap: () {
                                    // Beim Klick wird die Rolle auf CONDUCTEUR gesetzt
                                    setState(() {
                                      _selectedRole = 'CONDUCTEUR';
                                      if (_emailController.text.contains('passager')) {
                                        _emailController.text = 'conducteur@covoitgo.fr';
                                      }
                                    });
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    decoration: BoxDecoration(
                                      color: _selectedRole == 'CONDUCTEUR' ? primaryColor : Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: _selectedRole == 'CONDUCTEUR' ? primaryColor : Colors.grey.shade300,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.directions_car,
                                          size: 18,
                                          color: _selectedRole == 'CONDUCTEUR' ? Colors.white : Colors.black87,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          'Conducteur',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: _selectedRole == 'CONDUCTEUR' ? Colors.white : Colors.black87,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Eingabefeld: E-Mail
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: InputDecoration(
                              labelText: 'Adresse e-mail',
                              hintText: 'exemple@covoitgo.fr',
                              prefixIcon: const Icon(Icons.email_outlined, color: primaryColor),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Veuillez saisir votre adresse e-mail';
                              }
                              if (!value.contains('@') || !value.contains('.')) {
                                return 'Veuillez saisir un e-mail valide';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Eingabefeld: Passwort
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            decoration: InputDecoration(
                              labelText: 'Mot de passe',
                              prefixIcon: const Icon(Icons.lock_outline, color: primaryColor),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                  color: Colors.grey,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Veuillez saisir votre mot de passe';
                              }
                              if (value.length < 6) {
                                return 'Le mot de passe doit comporter au moins 6 caractères';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 24),

                          // Anmelde-Button
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: accentColor,
                                foregroundColor: Colors.black87,
                                elevation: 1,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              onPressed: _isLoading ? null : _seConnecter,
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2.5),
                                    )
                                  : const Text(
                                      'Se connecter',
                                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 3. Link zur Registrierung (Inscription)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Pas encore de compte ? ",
                        style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const InscriptionScreen()),
                          );
                        },
                        child: const Text(
                          "S'inscrire",
                          style: TextStyle(
                            color: primaryColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
