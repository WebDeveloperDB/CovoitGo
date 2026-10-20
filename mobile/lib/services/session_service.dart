import 'package:shared_preferences/shared_preferences.dart';

/// ZENTRALER SITZUNGS- UND AUTHENTIFIZIERUNGS-MANAGER (SESSION SERVICE) - Ticket FR403-887
/// 
/// Verwaltet das JWT-Token, die Benutzer-ID, Name, E-Mail und Rolle in der mobilen App.
/// Speichert alle Sitzungsdaten persistent mit SharedPreferences, damit der Benutzer
/// beim Schließen und erneuten Öffnen der App angemeldet bleibt.
class SessionService {
  static final SessionService instance = SessionService._init();
  SessionService._init();

  String? _token;
  String? _userId;
  String? _email;
  String? _nom;
  String? _prenom;
  String? _role;

  // Schlüssel für den persistenten Speicher (SharedPreferences)
  static const String _keyToken = 'jwt_token';
  static const String _keyUserId = 'user_id';
  static const String _keyEmail = 'user_email';
  static const String _keyNom = 'user_nom';
  static const String _keyPrenom = 'user_prenom';
  static const String _keyRole = 'user_role';

  // Schnelle Getter für den Zugriff aus allen Screens und Services
  String? get token => _token;
  String? get userId => _userId;
  String? get email => _email;
  String? get nom => _nom;
  String? get prenom => _prenom;
  String? get role => _role;

  /// Gibt an, ob aktuell ein gültiges Token hinterlegt ist
  bool get estConnecte => _token != null && _token!.isNotEmpty;

  /// Prüft, ob der angemeldete Nutzer ein Fahrer ist
  bool get estConducteur => _role == 'CONDUCTEUR';

  /// Prüft, ob der angemeldete Nutzer ein Mitfahrer ist
  bool get estPassager => _role == 'PASSAGER';

  /// Liefert den vollen Namen für die Begrüßung (z.B. "Jean Dupont")
  String get nomComplet {
    if (_prenom != null && _nom != null) {
      return '$_prenom $_nom';
    }
    return _prenom ?? _nom ?? 'Utilisateur';
  }

  /// Initialisiert die Sitzung aus dem lokalen Gerätespeicher beim App-Start
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(_keyToken);
    _userId = prefs.getString(_keyUserId);
    _email = prefs.getString(_keyEmail);
    _nom = prefs.getString(_keyNom);
    _prenom = prefs.getString(_keyPrenom);
    _role = prefs.getString(_keyRole);
  }

  /// Speichert die vom Backend empfangenen Authentifizierungsdaten (JWT-Token & Profil)
  Future<void> sauvegarderSession({
    required String token,
    required String id,
    required String email,
    required String nom,
    required String prenom,
    required String role,
  }) async {
    _token = token;
    _userId = id;
    _email = email;
    _nom = nom;
    _prenom = prenom;
    _role = role;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyToken, token);
    await prefs.setString(_keyUserId, id);
    await prefs.setString(_keyEmail, email);
    await prefs.setString(_keyNom, nom);
    await prefs.setString(_keyPrenom, prenom);
    await prefs.setString(_keyRole, role);
  }

  /// Meldet den Benutzer ab und löscht alle Token und Profildaten aus dem Speicher
  Future<void> deconnexion() async {
    _token = null;
    _userId = null;
    _email = null;
    _nom = null;
    _prenom = null;
    _role = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyToken);
    await prefs.remove(_keyUserId);
    await prefs.remove(_keyEmail);
    await prefs.remove(_keyNom);
    await prefs.remove(_keyPrenom);
    await prefs.remove(_keyRole);
  }
}
