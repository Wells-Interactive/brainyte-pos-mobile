import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:brainyte_pos/core/providers/auth_provider.dart';
import 'package:brainyte_pos/features/settings/settings_screen.dart';
import 'package:brainyte_pos/main.dart';

void main() {
  testWidgets('app starts smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: BrainytePosApp()));
    expect(find.text('Sign In'), findsOneWidget);
  });

  testWidgets('customer settings show profile and password fields', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          userNameProvider.overrideWith((ref) => Future.value('Jane Doe')),
          authStateProvider.overrideWith((ref) => Future.value('customer')),
        ],
        child: const SettingsScreen(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Profile details'), findsOneWidget);
    expect(find.text('Email'), findsWidgets);
    expect(find.text('Phone number'), findsWidgets);
    expect(find.text('Address'), findsWidgets);
    expect(find.text('Change Password'), findsOneWidget);
  });
}
