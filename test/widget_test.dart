import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:noteon/main.dart';

void main() {
  testWidgets('NoteOn app loads successfully smoke test', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(child: NoteOnApp(isFirebaseReady: false)),
    );
    await tester.pumpAndSettle();

    // Verify NoteOn launched
    expect(find.byType(NoteOnApp), findsOneWidget);
  });
}
