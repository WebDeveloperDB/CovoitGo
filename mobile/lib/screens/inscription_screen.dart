import 'package:flutter/material.dart';
import 'passager_accueil_screen.dart';
import 'conducteur_accueil_screen.dart';
import '../services/api_service.dart';
import '../services/session_service.dart';

/// Ermöglicht neuen Nutzern, ein Konto mit Name, E-Mail,
/// Passwort und ihrer Hauptrolle (Passager oder Conducteur) über das Spring Boot Backend zu erstellen.
class InscriptionScreen extends StatefulWidget {
  const InscriptionScreen({super.key});

  @override
  State<InscriptionScreen> createState() => _InscriptionScreenState();
}

class _InscriptionScreenState extends State<InscriptionScreen> {
  // Schlüssel zur Steuerung und Validierung des Registrierungsformulars
  final _formKey = GlobalKey<FormState>();

  // Text-Controller für die Eingabefelder
  final TextEditingController _nomController = TextEditingController();
  final TextEditingController _prenomController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  // Standardmäßig ausgewählte Rolle ('PASSAGER' oder 'CONDUCTEUR')
  // Dies ist der Initialwert - der Nutzer kann ihn im Formular mit einem Klick umschalten!
  String _selectedRole = 'PASSAGER';
  bool _obscurePassword = true;        // Passwort verbergen
  bool _obscureConfirmPassword = true; // Passwort-Bestätigung verbergen
  bool _isLoading = false;             // Ladeindikator

  @override
  void dispose() {
    _nomController.dispose();
    _prenomController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // Funktion zum Erstellen des Kontos über die Backend-API & Weiterleiten
  void _creerCompte() async {
    // 1. Validierung aller Pflichtfelder
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // Echter API-Aufruf zu POST /api/auth/register
    final result = await ApiService.register(
      nom: _nomController.text.trim(),
      prenom: _prenomController.text.trim(),
      email: _emailController.text.trim(),
      motDePasse: _passwordController.text,
      role: _selectedRole,
    );

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (result['success'] == true) {
      final role = SessionService.instance.role ?? _selectedRole;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Compte créé avec succès ! Bienvenue ${_prenomController.text.trim()}.'),
          backgroundColor: const Color(0xFF1E463D),
          duration: const Duration(seconds: 2),
        ),
      );

      // 2. Automatische Weiterleitung zur passenden Startseite je nach Rolle
      if (role == 'PASSAGER') {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const PassagerAccueilScreen()),
          (route) => false,
        );
      } else {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const ConducteurAccueilScreen()),
          (route) => false,
        );
      }
    } else {
      // Fehlermeldung bei bereits vergebener E-Mail oder Validierungsfehlern
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Erreur lors de la création du compte.'),
          backgroundColor: Colors.red.shade700,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF1E463D); // Tannengrün
    const accentColor = Color(0xFFE29E4A);  // Warmes Orange
    const bgColor = Color(0xFFF4F2EC);      // Beige

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: primaryColor,
        elevation: 0,
        title: const Text('Inscription', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Créer mon compte CovoitGo',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: primaryColor,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Rejoignez la communauté de covoiturage solidaire.',
                            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                          ),
                          const SizedBox(height: 20),

                          // Gewünschte Hauptrolle (Passager oder Conducteur)
                          const Text(
                            'Je souhaite être principalement :',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              // Option: Passager
                              Expanded(
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(10),
                                  onTap: () => setState(() => _selectedRole = 'PASSAGER'),
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
                              // Option: Conducteur
                              Expanded(
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(10),
                                  onTap: () => setState(() => _selectedRole = 'CONDUCTEUR'),
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

                          // Zeile: Nachname & Vorname (Nom & Prénom)
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _nomController,
                                  decoration: InputDecoration(
                                    labelText: 'Nom',
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                    filled: true,
                                    fillColor: Colors.white,
                                  ),
                                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Requis' : null,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextFormField(
                                  controller: _prenomController,
                                  decoration: InputDecoration(
                                    labelText: 'Prénom',
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                    filled: true,
                                    fillColor: Colors.white,
                                  ),
                                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Requis' : null,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Eingabefeld: E-Mail
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: InputDecoration(
                              labelText: 'Adresse e-mail',
                              hintText: 'votre.email@domaine.fr',
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
                                return 'Format d\'e-mail invalide';
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
                                icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: Colors.grey),
                                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                              ),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Veuillez saisir un mot de passe';
                              }
                              if (value.length < 6) {
                                return 'Au moins 6 caractères requis';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Eingabefeld: Passwort-Bestätigung (muss mit Passwort übereinstimmen)
                          TextFormField(
                            controller: _confirmPasswordController,
                            obscureText: _obscureConfirmPassword,
                            decoration: InputDecoration(
                              labelText: 'Confirmer le mot de passe',
                              prefixIcon: const Icon(Icons.lock_outline, color: primaryColor),
                              suffixIcon: IconButton(
                                icon: Icon(_obscureConfirmPassword ? Icons.visibility_off : Icons.visibility, color: Colors.grey),
                                onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                              ),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Veuillez confirmer votre mot de passe';
                              }
                              if (value != _passwordController.text) {
                                return 'Les mots de passe ne correspondent pas';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 24),

                          // Button: Registrierung absenden
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
                              onPressed: _isLoading ? null : _creerCompte,
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2.5),
                                    )
                                  : const Text(
                                      'Créer mon compte',
                                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Link zurück zum Login-Bildschirm
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Vous avez déjà un compte ? ",
                        style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: const Text(
                          "Se connecter",
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
