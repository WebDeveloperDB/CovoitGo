import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile/services/session_service.dart';

void main() {
  group('SessionService Unit Tests (FR403-887)', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await SessionService.instance.init();
    });

    test('Initialzustand: Nicht angemeldet', () {
      final session = SessionService.instance;
      expect(session.estConnecte, false);
      expect(session.token, isNull);
      expect(session.userId, isNull);
      expect(session.email, isNull);
    });

    test('sauvegarderSession speichert Token und Benutzerdaten persistent', () async {
      final session = SessionService.instance;

      await session.sauvegarderSession(
        token: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.test',
        id: '670c1e8f9a12b34c56d78e90',
        email: 'passager@covoitgo.fr',
        nom: 'Dupont',
        prenom: 'Jean',
        role: 'PASSAGER',
      );

      expect(session.estConnecte, true);
      expect(session.token, 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.test');
      expect(session.userId, '670c1e8f9a12b34c56d78e90');
      expect(session.email, 'passager@covoitgo.fr');
      expect(session.nomComplet, 'Jean Dupont');
      expect(session.estPassager, true);
      expect(session.estConducteur, false);

      // Verifizieren, dass die Daten tatsächlich in SharedPreferences stehen
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('jwt_token'), 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.test');
      expect(prefs.getString('user_role'), 'PASSAGER');
    });

    test('deconnexion löscht Token und alle Sitzungsdaten vollständig', () async {
      final session = SessionService.instance;

      await session.sauvegarderSession(
        token: 'token_secret_123',
        id: 'cond_456',
        email: 'conducteur@covoitgo.fr',
        nom: 'Martin',
        prenom: 'Sophie',
        role: 'CONDUCTEUR',
      );

      expect(session.estConnecte, true);
      expect(session.estConducteur, true);

      // Abmelden
      await session.deconnexion();

      expect(session.estConnecte, false);
      expect(session.token, isNull);
      expect(session.userId, isNull);
      expect(session.email, isNull);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('jwt_token'), isNull);
      expect(prefs.getString('user_role'), isNull);
    });
  });
}
