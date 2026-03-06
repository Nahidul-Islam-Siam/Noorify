// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:first_project/main.dart';
import 'package:first_project/screens/daily_activity_screen.dart';

void main() {
  testWidgets('Shows splash then opens Daily Activity home', (
    WidgetTester tester,
  ) async {
    final view = tester.view;
    view.physicalSize = const Size(1080, 2400);
    view.devicePixelRatio = 1.0;
    addTearDown(() {
      view.resetPhysicalSize();
      view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(const MyApp());

    expect(find.byKey(const Key('opening_splash_image')), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 1900));
    await tester.pump();

    expect(find.byType(DailyActivityScreen), findsOneWidget);
  });
}
