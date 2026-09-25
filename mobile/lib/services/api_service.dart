import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // WICHTIG: Wenn du einen Android-Emulator benutzt, bedeutet "localhost" (127.0.0.1) den Emulator selbst.
  // Um auf das Backend auf deinem Computer (Host) zuzugreifen, benutzt Android "10.0.2.2"
  static const String baseUrl = 'http://10.0.2.2:8080/api';

  // ==========================================
  // US1: Fahrten suchen (Für den Passagier)
  // ==========================================
  static Future<List<dynamic>> rechercherTrajets({
    required double latDepart,
    required double lonDepart,
    required double latArrivee,
    required double lonArrivee,
    required String heureDepart,
    required int places,
  }) async {
    // Die URL für das Backend zusammenbauen
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
        // Erfolgreich: JSON in eine Dart-Liste umwandeln
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
  // US2: Fahrt erstellen (Für den Fahrer)
  // ==========================================
  static Future<bool> creerTrajet(Map<String, dynamic> trajetData) async {
    final url = Uri.parse('$baseUrl/trajets');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(trajetData),
      );

      if (response.statusCode == 201) {
        print('Trajet créé avec succès !');
        return true;
      } else {
        print('Erreur lors de la création (Code ${response.statusCode})');
        return false;
      }
    } catch (e) {
      print('Erreur de connexion : $e');
      return false;
    }
  }

  // ==========================================
  // US3: Gérer une demande & Envoi d'une demande
  // ==========================================

  // Passager : Envoyer une demande de covoiturage
  static Future<bool> envoyerDemande(String trajetId, Map<String, dynamic> demandeData, String token) async {
    final url = Uri.parse('$baseUrl/trajets/$trajetId/demandes');

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(demandeData),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        print('Demande envoyée avec succès !');
        return true;
      } else {
        print('Erreur lors de l\'envoi de la demande (Code ${response.statusCode})');
        return false;
      }
    } catch (e) {
      print('Erreur de connexion : $e');
      return false;
    }
  }

  // Conducteur : Accepter ou refuser une demande
  static Future<bool> gererDemande(String trajetId, String demandeId, String statut, String motif, String token) async {
    final url = Uri.parse('$baseUrl/trajets/$trajetId/demandes/$demandeId');

    try {
      final response = await http.patch(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
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
}
