import '../database/database_helper.dart';
import '../models/trajet.dart';
import '../models/demande.dart';
import 'api_service.dart';

// Ergebnis einer Synchronisation (wie viele Einträge wurden übertragen)
class SyncResult {
  final int pushedTrajets;
  final int pushedDemandes;
  final int pulledTrajets;
  final int pulledDemandes;
  final int conflitsResolus;
  final List<String> errors;

  SyncResult({
    this.pushedTrajets = 0,
    this.pushedDemandes = 0,
    this.pulledTrajets = 0,
    this.pulledDemandes = 0,
    this.conflitsResolus = 0,
    this.errors = const [],
  });

  bool get hasErrors => errors.isNotEmpty;
  bool get isSuccess => errors.isEmpty;

  @override
  String toString() {
    return 'SyncResult(pushedTrajets: $pushedTrajets, pushedDemandes: $pushedDemandes, '
        'pulledTrajets: $pulledTrajets, pulledDemandes: $pulledDemandes, '
        'conflitsResolus: $conflitsResolus, errors: ${errors.length})';
  }
}

// Dieser Service kümmert sich um den Datenabgleich zwischen SQLite und MongoDB
class SyncService {
  final DatabaseHelper _dbHelper;

  SyncService({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  // Führt den kompletten Abgleich in beide Richtungen aus
  Future<SyncResult> synchroniserTout({String token = ''}) async {
    int pushedT = 0;
    int pushedD = 0;
    int pulledT = 0;
    int pulledD = 0;
    int conflits = 0;
    final List<String> errors = [];

    // Schritt 1: Lokale Änderungen an den Server senden (Push)
    try {
      pushedT = await pushPendingTrajets();
    } catch (e) {
      errors.add("Fehler beim Hochladen der Fahrten: $e");
    }

    try {
      pushedD = await pushPendingDemandes(token: token);
    } catch (e) {
      errors.add("Fehler beim Hochladen der Anfragen: $e");
    }

    // Schritt 2: Neue Daten vom Server abrufen (Pull)
    try {
      final pullTrajetResult = await pullRemoteTrajets();
      pulledT = pullTrajetResult['pulled'] ?? 0;
      conflits += pullTrajetResult['conflits'] ?? 0;
    } catch (e) {
      errors.add("Fehler beim Herunterladen der Fahrten: $e");
    }

    try {
      pulledD = await pullRemoteDemandes();
    } catch (e) {
      errors.add("Fehler beim Herunterladen der Anfragen: $e");
    }

    return SyncResult(
      pushedTrajets: pushedT,
      pushedDemandes: pushedD,
      pulledTrajets: pulledT,
      pulledDemandes: pulledD,
      conflitsResolus: conflits,
      errors: errors,
    );
  }

  // Sendet offline erstellte Fahrten (synced = 0) an die API
  Future<int> pushPendingTrajets() async {
    final pendingTrajets = await _dbHelper.getPendingTrajets();
    int count = 0;

    for (final trajet in pendingTrajets) {
      try {
        final success = await ApiService.creerTrajet(trajet.toApiJson());
        if (success) {
          // Temporären Offline-Eintrag aus SQLite löschen, da pullRemoteTrajets()
          // gleich danach den echten MongoDB-Eintrag vom Server abruft
          await _dbHelper.deleteTrajet(trajet.id);
          count++;
        }
      } catch (e) {
        // Bei Netzwerkproblemen bleibt die Fahrt in SQLite für den nächsten Versuch
        print('Synchronisation fehlgeschlagen für Fahrt ${trajet.id}: $e');
      }
    }

    return count;
  }

  // Sendet offline erstellte Buchungsanfragen (synced = 0) an die API
  Future<int> pushPendingDemandes({String token = ''}) async {
    final pendingDemandes = await _dbHelper.getPendingDemandes();
    int count = 0;

    for (final demande in pendingDemandes) {
      try {
        final success = await ApiService.envoyerDemande(
          demande.idTrajet,
          demande.toApiJson(),
          token,
        );
        if (success) {
          // Temporäre Offline-Anfrage aus SQLite löschen, da pullRemoteDemandes()
          // die offizielle Anfrage vom Server abruft
          await _dbHelper.deleteDemande(demande.id);
          count++;
        }
      } catch (e) {
        print('Synchronisation fehlgeschlagen für Anfrage ${demande.id}: $e');
      }
    }

    return count;
  }

  // Holt aktive Fahrten vom Server und aktualisiert die lokale SQLite-Datenbank
  Future<Map<String, int>> pullRemoteTrajets() async {
    int pulled = 0;
    int conflits = 0;

    final List<dynamic> remoteData = await ApiService.getMesTrajetsActifs();

    for (final item in remoteData) {
      try {
        final remoteTrajet = Trajet.fromJson(item as Map<String, dynamic>);

        // Duplikate bereinigen: Falls ein temporärer Eintrag mit denselben Daten existiert
        final localTrajets = await _dbHelper.getAllTrajets();
        for (final local in localTrajets) {
          if (local.id != remoteTrajet.id &&
              local.heureDepart == remoteTrajet.heureDepart &&
              (local.departLatitude - remoteTrajet.departLatitude).abs() < 0.001 &&
              (local.destinationLatitude - remoteTrajet.destinationLatitude).abs() < 0.001) {
            await _dbHelper.deleteTrajet(local.id);
          }
        }

        final localTrajet = await _dbHelper.getTrajetById(remoteTrajet.id);

        if (localTrajet == null) {
          // Neue Fahrt vom Server: lokal einfügen
          await _dbHelper.insertTrajet(remoteTrajet);
          pulled++;
        } else {
          if (localTrajet.synced == 1) {
            // Keine ungespeicherten lokalen Änderungen: mit Serverdaten aktualisieren
            await _dbHelper.updateTrajet(remoteTrajet);
            pulled++;
          } else {
            // Konflikt: Lokal gab es Änderungen (synced = 0)
            // Lösung: Neueste Änderung gewinnt (Last-Write-Wins)
            final remoteDate = DateTime.tryParse(remoteTrajet.lastModified) ?? DateTime(1970);
            final localDate = DateTime.tryParse(localTrajet.lastModified) ?? DateTime(1970);

            if (remoteDate.isAfter(localDate)) {
              // Serverdaten sind neuer: überschreiben
              await _dbHelper.updateTrajet(remoteTrajet);
              conflits++;
            }
          }
        }
      } catch (e) {
        print('Fehler beim Verarbeiten einer Server-Fahrt: $e');
      }
    }

    return {'pulled': pulled, 'conflits': conflits};
  }

  // Holt die passenden Buchungsanfragen vom Server
  Future<int> pullRemoteDemandes() async {
    final localTrajets = await _dbHelper.getAllTrajets();
    int count = 0;

    for (final trajet in localTrajets) {
      if (trajet.id.isEmpty) continue;

      try {
        final List<dynamic> remoteDemandes = await ApiService.getDemandesPourTrajet(trajet.id);
        for (final item in remoteDemandes) {
          final remoteDemande = Demande.fromJson(item as Map<String, dynamic>);

          // Duplikate bereinigen: Falls eine temporäre Anfrage für denselben Passagier existiert
                    // Duplikate nur bereinigen, wenn es ein temporärer SQLite-Entwurf derselben ID ist
          final currentDemandes = await _dbHelper.getAllDemandes();
          for (final local in currentDemandes) {
            if (local.id.startsWith('temp_') &&
                local.idTrajet == remoteDemande.idTrajet &&
                local.idPassager == remoteDemande.idPassager) {
              await _dbHelper.deleteDemande(local.id);
            }
          }


          final localDemande = await _dbHelper.getDemandeById(remoteDemande.id);

          if (localDemande == null) {
            await _dbHelper.insertDemande(remoteDemande);
            count++;
          } else if (localDemande.synced == 1) {
            await _dbHelper.updateDemande(remoteDemande);
            count++;
          }
        }
      } catch (e) {
        print('Erreur rapatriement demandes pour trajet ${trajet.id}: $e');
      }
    }

    return count;
  }
}
