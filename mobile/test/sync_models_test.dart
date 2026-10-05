import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/models/trajet.dart';
import 'package:mobile/models/demande.dart';
import 'package:mobile/services/sync_service.dart';

void main() {
  group('Trajet Model & Sync Tests', () {
    test('Trajet toMap and fromMap for SQLite persistence', () {
      final trajet = Trajet(
        id: 't-001',
        idConducteur: 'cond-001',
        departLatitude: 48.0792,
        departLongitude: 7.3582,
        destinationLatitude: 47.5862,
        destinationLongitude: 7.5645,
        heureDepart: '2026-10-15T08:00:00Z',
        capacite: 4,
        placesDisponibles: 4,
        statut: 'ACTIVE',
        synced: 0,
        lastModified: '2026-10-02T10:00:00Z',
      );

      final map = trajet.toMap();
      expect(map['id'], 't-001');
      expect(map['synced'], 0);
      expect(map['depart_latitude'], 48.0792);

      final fromDb = Trajet.fromMap(map);
      expect(fromDb.id, trajet.id);
      expect(fromDb.departLatitude, trajet.departLatitude);
      expect(fromDb.synced, 0);
    });

    test('Trajet fromJson parses nested MongoDB response correctly', () {
      final mongoJson = {
        'id': '66f1a8c9e4b0123456789abc',
        'idConducteur': 'cond-001',
        'depart': {
          'latitude': 48.0794,
          'longitude': 7.3585,
        },
        'destination': {
          'latitude': 47.7508,
          'longitude': 7.3359,
        },
        'heureDepart': '2026-09-10T18:00:00Z',
        'capacite': 3,
        'placesDisponibles': 2,
        'statut': 'ACTIVE',
        'creeLe': '2026-09-09T08:00:00Z',
        'misAJourLe': '2026-09-09T09:30:00Z',
      };

      final trajet = Trajet.fromJson(mongoJson);
      expect(trajet.id, '66f1a8c9e4b0123456789abc');
      expect(trajet.departLatitude, 48.0794);
      expect(trajet.destinationLongitude, 7.3359);
      expect(trajet.synced, 1);
      expect(trajet.lastModified, '2026-09-09T09:30:00Z');
    });

    test('Trajet copyWith updates synced status', () {
      final localTrajet = Trajet(
        id: 't-local',
        idConducteur: 'cond-001',
        departLatitude: 48.0,
        departLongitude: 7.0,
        destinationLatitude: 47.0,
        destinationLongitude: 7.5,
        heureDepart: '2026-10-15T08:00:00Z',
        capacite: 3,
        placesDisponibles: 3,
        statut: 'ACTIVE',
        synced: 0,
        lastModified: '2026-10-02T10:00:00Z',
      );

      final syncedTrajet = localTrajet.copyWith(synced: 1);
      expect(syncedTrajet.synced, 1);
      expect(syncedTrajet.id, localTrajet.id);
    });

    test('Trajet toApiJson matches CreerTrajetRequete format', () {
      final trajet = Trajet(
        id: 't-001',
        idConducteur: 'cond-001',
        departLatitude: 48.0792,
        departLongitude: 7.3582,
        destinationLatitude: 47.5862,
        destinationLongitude: 7.5645,
        heureDepart: '2026-10-15T08:00:00Z',
        capacite: 4,
        placesDisponibles: 4,
        statut: 'ACTIVE',
        synced: 0,
        lastModified: '2026-10-02T10:00:00Z',
      );

      final apiJson = trajet.toApiJson();
      expect(apiJson.containsKey('depart'), isTrue);
      expect(apiJson['depart']['latitude'], 48.0792);
      expect(apiJson.containsKey('destination'), isTrue);
      expect(apiJson['capacite'], 4);
    });
  });

  group('Demande Model & Sync Tests', () {
    test('Demande toMap and fromMap for SQLite', () {
      final demande = Demande(
        id: 'd-001',
        idTrajet: 't-001',
        idPassager: 'pass-001',
        placesDemandees: 2,
        statut: 'PENDING',
        motif: 'Voyage travail',
        synced: 0,
        lastModified: '2026-10-02T10:00:00Z',
      );

      final map = demande.toMap();
      expect(map['id'], 'd-001');
      expect(map['synced'], 0);
      expect(map['placesDemandees'], 2);

      final fromDb = Demande.fromMap(map);
      expect(fromDb.id, demande.id);
      expect(fromDb.synced, 0);
    });

    test('Demande fromJson parses MongoDB response', () {
      final json = {
        'id': '60f719c4d5',
        'idTrajet': '60f719a3b2',
        'idPassager': 'pass-001',
        'placesDemandees': 1,
        'statut': 'ACCEPTED',
        'motif': '',
        'creeLe': '2026-09-09T08:30:00Z',
      };

      final demande = Demande.fromJson(json);
      expect(demande.id, '60f719c4d5');
      expect(demande.statut, 'ACCEPTED');
      expect(demande.synced, 1);
    });
  });

  group('SyncResult Tests', () {
    test('SyncResult reports success and errors properly', () {
      final successResult = SyncResult(
        pushedTrajets: 2,
        pushedDemandes: 1,
        pulledTrajets: 3,
        pulledDemandes: 2,
      );
      expect(successResult.isSuccess, isTrue);
      expect(successResult.hasErrors, isFalse);

      final errorResult = SyncResult(
        errors: ['Erreur réseau lors du push'],
      );
      expect(errorResult.isSuccess, isFalse);
      expect(errorResult.hasErrors, isTrue);
    });
  });
}
