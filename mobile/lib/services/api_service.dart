import 'dart:convert';
import 'package:http/http.dart' as http;
import 'session_service.dart';

/// ZENTRALER API-SERVICE FÜR DIE KOMMUNIKATION MIT DEM SPRING BOOT BACKEND
/// 
/// Beinhaltet Authentifizierung (Login, Register mit JWT-Token),
/// Suche nach Fahrten, Fahrterstellung sowie das Anfragen-Management.
class ApiService {
  // WICHTIG: Wenn du einen Android-Emulator benutzt, bedeutet "localhost" (127.0.0.1) den Emulator selbst.
  // Um auf das Backend auf deinem Computer (Host) zuzugreifen, benutzt Android "10.0.2.2"
  static const String baseUrl = 'http://10.0.2.2:8080/api';

  /// Erzeugt die Standard-HTTP-Header inklusive des JWT Bearer Tokens, falls angemeldet
  static Map<String, String> getAuthHeaders() {
    final headers = {'Content-Type': 'application/json'};
    final token = SessionService.instance.token;
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  // ==========================================
  // AUTHENTIFIZIERUNG (Login & Inscription) - Ticket FR403-887
  // ==========================================

  /// Meldet einen Benutzer an (POST /api/auth/login)
  /// 
  /// Sendet Email und Passwort an das Backend, empfängt das JWT-Token
  /// und speichert die Sitzung persistent in SharedPreferences.
  static Future<Map<String, dynamic>> login(String email, String motDePasse) async {
    final url = Uri.parse('$baseUrl/auth/login');
    try {
      print('Requête Login POST : $url pour $email');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'motDePasse': motDePasse,
        }),
      );

      final Map<String, dynamic> data = json.decode(response.body);

      if (response.statusCode == 200) {
        // Erfolgreich: Session persistent speichern
        await SessionService.instance.sauvegarderSession(
          token: data['token'] ?? '',
          id: data['id'] ?? '',
          email: data['email'] ?? '',
          nom: data['nom'] ?? '',
          prenom: data['prenom'] ?? '',
          role: data['role'] ?? 'PASSAGER',
        );
        print('Connexion réussie pour ${data['email']} (Rôle: ${data['role']})');
        return {'success': true, 'data': data};
      } else {
        // Fehlerhafte Anmeldedaten (401) oder Validierungsfehler (400)
        final message = data['erreur'] ?? 'Email ou mot de passe incorrect';
        return {'success': false, 'message': message};
      }
    } catch (e) {
      print('Erreur réseau lors de la connexion : $e');
      return {
        'success': false,
        'message': 'Impossible de se connecter au serveur backend. Vérifiez votre connexion.'
      };
    }
  }

  /// Erstellt ein neues Benutzerkonto (POST /api/auth/register)
  /// 
  /// Speichert nach erfolgreicher Erstellung sofort das ausgestellte JWT-Token.
  static Future<Map<String, dynamic>> register({
    required String nom,
    required String prenom,
    required String email,
    required String motDePasse,
    required String role,
  }) async {
    final url = Uri.parse('$baseUrl/auth/register');
    try {
      print('Requête Register POST : $url pour $email (Rôle: $role)');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'nom': nom,
          'prenom': prenom,
          'email': email,
          'motDePasse': motDePasse,
          'role': role,
        }),
      );

      final Map<String, dynamic> data = json.decode(response.body);

      if (response.statusCode == 201) {
        // Erfolgreich registriert und automatisch angemeldet
        await SessionService.instance.sauvegarderSession(
          token: data['token'] ?? '',
          id: data['id'] ?? '',
          email: data['email'] ?? '',
          nom: data['nom'] ?? '',
          prenom: data['prenom'] ?? '',
          role: data['role'] ?? role,
        );
        print('Compte créé avec succès pour ${data['email']}');
        return {'success': true, 'data': data};
      } else {
        // Fehler (z.B. E-Mail existiert bereits - 400 Bad Request)
        final message = data['erreur'] ?? 'Erreur lors de la création du compte';
        return {'success': false, 'message': message};
      }
    } catch (e) {
      print('Erreur réseau lors de l\'inscription : $e');
      return {
        'success': false,
        'message': 'Impossible de se connecter au serveur backend. Vérifiez votre connexion.'
      };
    }
  }

  // ==========================================
  // HILFSMETHODEN FÜR KOORDINATEN & STÄDTE
  // ==========================================

  static Map<String, double> getCoordinates(String city) {
    final c = city.trim().toLowerCase();
    if (c.contains('mulhouse')) return {'lat': 47.7508, 'lon': 7.3359};
    if (c.contains('colmar')) return {'lat': 48.0794, 'lon': 7.3585};
    if (c.contains('strasbourg')) return {'lat': 48.5734, 'lon': 7.7521};
    if (c.contains('lyon')) return {'lat': 45.7640, 'lon': 4.8357};
    if (c.contains('paris')) return {'lat': 48.8566, 'lon': 2.3522};
    if (c.contains('huningue')) return {'lat': 47.5911, 'lon': 7.5842};
    if (c.contains('saint-louis')) return {'lat': 47.5844, 'lon': 7.5583};
    return {'lat': 48.0, 'lon': 7.0};
  }

  static bool isKnownCity(String city) {
    final c = city.trim().toLowerCase();
    return c.contains('mulhouse') ||
        c.contains('colmar') ||
        c.contains('strasbourg') ||
        c.contains('lyon') ||
        c.contains('paris') ||
        c.contains('huningue') ||
        c.contains('saint-louis');
  }

  static String getCityName(double lat, double lon) {
    if ((lat - 48.57).abs() < 0.15) return 'Strasbourg';
    if ((lat - 47.75).abs() < 0.15) return 'Mulhouse';
    if ((lat - 48.07).abs() < 0.15) return 'Colmar';
    if ((lat - 45.76).abs() < 0.15) return 'Lyon';
    if ((lat - 48.85).abs() < 0.15) return 'Paris';
    if ((lat - 47.59).abs() < 0.1) return 'Huningue';
    if ((lat - 47.58).abs() < 0.1) return 'Saint-Louis';
    return 'Lieu ($lat, $lon)';
  }

  // ==========================================
  // US1: Fahrten suchen (Für den Passagier) - Öffentliche Route
  // ==========================================
  static Future<List<dynamic>> rechercherTrajets({
    required double latDepart,
    required double lonDepart,
    required double latArrivee,
    required double lonArrivee,
    required String heureDepart,
    required int places,
  }) async {
    final url = Uri.parse(
        '$baseUrl/trajets/recherche'
        '?latitudeDepart=$latDepart'
        '&longitudeDepart=$lonDepart'
        '&latitudeArrivee=$latArrivee'
        '&longitudeArrivee=$lonArrivee'
        '&heureDepart=$heureDepart'
        '&places=$places'
    );

    try {
      print('Requête API GET : $url');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        print('Erreur API (Code ${response.statusCode}): ${response.body}');
        return [];
      }
    } catch (e) {
      print('Erreur de connexion au backend : $e');
      return [];
    }
  }

  // ==========================================
  // US2: Fahrt erstellen (Für den Fahrer) - Gesicherte Route mit Bearer Token
  // ==========================================
  static Future<bool> creerTrajet(Map<String, dynamic> trajetData) async {
    final url = Uri.parse('$baseUrl/trajets');

    try {
      final response = await http.post(
        url,
        headers: getAuthHeaders(),
        body: json.encode(trajetData),
      );

      if (response.statusCode == 201) {
        print('Trajet créé avec succès !');
        return true;
      } else {
        print('Erreur lors de la création (Code ${response.statusCode}): ${response.body}');
        return false;
      }
    } catch (e) {
      print('Erreur de connexion : $e');
      return false;
    }
  }

  // ==========================================
  // US3: Gérer une demande & Envoi d'une demande - Gesicherte Routen
  // ==========================================

  // Passager : Envoyer une demande de covoiturage (retourne le code HTTP: 201/200 succès, 409 conflit/doublon, -1 hors-ligne)
  static Future<int> envoyerDemande(String trajetId, Map<String, dynamic> demandeData, [String? token]) async {
    final url = Uri.parse('$baseUrl/trajets/$trajetId/demandes');
    final actualToken = (token != null && token.isNotEmpty)
        ? token
        : (SessionService.instance.token ?? '');

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          if (actualToken.isNotEmpty) 'Authorization': 'Bearer $actualToken',
        },
        body: json.encode(demandeData),
      );

      print('Envoi demande réponse code: ${response.statusCode}');
      return response.statusCode;
    } catch (e) {
      print('Erreur de connexion (mode hors-ligne) : $e');
      return -1;
    }
  }

  // Conducteur : Accepter ou refuser une demande
  static Future<bool> gererDemande(String trajetId, String demandeId, String statut, String motif, [String? token]) async {
    final url = Uri.parse('$baseUrl/trajets/$trajetId/demandes/$demandeId');
    final actualToken = (token != null && token.isNotEmpty)
        ? token
        : (SessionService.instance.token ?? '');

    try {
      final response = await http.patch(
        url,
        headers: {
          'Content-Type': 'application/json',
          if (actualToken.isNotEmpty) 'Authorization': 'Bearer $actualToken',
        },
        body: json.encode({
          'statut': statut,
          'motif': motif,
        }),
      );

      if (response.statusCode == 200) {
        print('Demande gérée avec succès ($statut) !');
        return true;
      } else {
        print('Erreur lors de la gestion de la demande (Code ${response.statusCode})');
        return false;
      }
    } catch (e) {
      print('Erreur de connexion : $e');
      return false;
    }
  }

  // ==========================================
  // US3 (Conducteur): Fetch active trips and pending requests - Gesicherte Routen
  // ==========================================

  // Fetch active trips (conducteur)
  static Future<List<dynamic>> getMesTrajetsActifs() async {
    final url = Uri.parse('$baseUrl/trajets/mes-trajets');
    try {
      final response = await http.get(
        url,
        headers: getAuthHeaders(),
      );
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
    } catch (e) {
      print('Erreur lors de la récupération des trajets: $e');
    }
    return [];
  }

  // Fetch pending requests for a specific trip
  static Future<List<dynamic>> getDemandesPourTrajet(String trajetId) async {
    final url = Uri.parse('$baseUrl/trajets/$trajetId/demandes');
    try {
      final response = await http.get(
        url,
        headers: getAuthHeaders(),
      );
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
    } catch (e) {
      print('Erreur lors de la récupération des demandes: $e');
    }
    return [];
  }

  // Delete a trip
  static Future<bool> supprimerTrajet(String trajetId) async {
    final url = Uri.parse('$baseUrl/trajets/$trajetId');
    try {
      final response = await http.delete(
        url,
        headers: getAuthHeaders(),
      );
      if (response.statusCode == 204) {
        return true;
      }
    } catch (e) {
      print('Erreur lors de la suppression: $e');
    }
    return false;
  }
}
