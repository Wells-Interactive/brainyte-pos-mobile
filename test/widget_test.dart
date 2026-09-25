import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:brainyte_pos/main.dart';

void main() {
  testWidgets('app starts smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: BrainytePosApp()));
    expect(find.text('Sign In'), findsOneWidget);
  });
}
