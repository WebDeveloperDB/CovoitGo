// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mobile/main.dart';

void main() {
  testWidgets('App starts and displays role selection', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const CovoitGoApp());

    // Verify that the title and role buttons are displayed.
    expect(find.text('Qui êtes-vous ?'), findsOneWidget);
    expect(find.text('Je suis Passager'), findsOneWidget);
    expect(find.text('Je suis Conducteur'), findsOneWidget);
  });
}
