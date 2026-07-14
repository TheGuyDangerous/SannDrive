import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sanndrive/app.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('Boots into the app shell', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const ProviderScope(child: SannDriveApp()));
    await tester.pump();
    expect(find.byType(SannDriveApp), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));
  });
}
