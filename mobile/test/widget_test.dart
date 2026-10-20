import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile/main.dart';
import 'package:mobile/services/session_service.dart';

void main() {
  setUp(() async {
    // Initialisiert SharedPreferences mit leeren Werten für Tests
    SharedPreferences.setMockInitialValues({});
    await SessionService.instance.init();
  });

  testWidgets('App starts and displays Login screen with CovoitGo branding', (WidgetTester tester) async {
    // App starten
    await tester.pumpWidget(const CovoitGoApp());
    await tester.pumpAndSettle();

    // Überprüfen, ob das CovoitGo Logo und Branding vorhanden sind
    expect(find.text('CovoitGo'), findsOneWidget);
    expect(find.text('Connexion'), findsOneWidget);
    expect(find.text('Je me connecte en tant que :'), findsOneWidget);
    expect(find.text('Passager'), findsOneWidget);
    expect(find.text('Conducteur'), findsOneWidget);

    // Formularfelder und Buttons
    expect(find.byType(TextFormField), findsNWidgets(2)); // Email & Mot de passe
    expect(find.widgetWithText(ElevatedButton, 'Se connecter'), findsOneWidget);
    expect(find.text("S'inscrire"), findsOneWidget);
  });
}
