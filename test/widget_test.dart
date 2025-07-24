// This is a basic Flutter widget test for the Greenstem Workshop Manager app.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:assignment/main.dart';

void main() {
  testWidgets('App launches with dashboard', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const GreenstemWorkshopApp());

    // Verify that the dashboard screen loads
    expect(find.text('Manager\'s Dashboard'), findsOneWidget);
    expect(find.text('Welcome back!'), findsOneWidget);
  });
}
