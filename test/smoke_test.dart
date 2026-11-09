import 'package:campuslink/app.dart';
import 'package:campuslink/data/local_repository.dart';
import 'package:campuslink/data/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('app boots in demo mode and shows the login screen', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          repositoryProvider.overrideWithValue(LocalRepository(prefs)),
          isDemoModeProvider.overrideWithValue(true),
        ],
        child: const CampusLinkApp(),
      ),
    );
    // The login screen has a looping gradient animation, so pumpAndSettle
    // would never return. Pump a few frames instead.
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.textContaining('CampusLink'), findsWidgets);
  });
}
