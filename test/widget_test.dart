import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sanndrive/app.dart';

void main() {
  testWidgets('Boots into the app shell', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: SannDriveApp()));
    await tester.pump();
    expect(find.byType(SannDriveApp), findsOneWidget);
  });
}
