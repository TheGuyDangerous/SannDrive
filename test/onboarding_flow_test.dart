import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sanndrive/app.dart';
import 'package:sanndrive/shared/core/form_factor.dart';
import 'package:sanndrive/ui/desktop/desktop_login.dart';
import 'package:sanndrive/ui/desktop/desktop_onboarding.dart';
import 'package:sanndrive/ui/mobile/mobile_login.dart';
import 'package:sanndrive/ui/mobile/mobile_onboarding.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('Onboarding shows without credentials; demo reaches login',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const ProviderScope(child: SannDriveApp()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump(const Duration(milliseconds: 350));

    final onboarding =
        isDesktopPlatform ? DesktopOnboarding : MobileOnboarding;
    expect(find.byType(onboarding), findsOneWidget);
    expect(find.text('Try the demo instead'), findsOneWidget);

    await tester.ensureVisible(find.text('Try the demo instead'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('Try the demo instead'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));

    final login = isDesktopPlatform ? DesktopLogin : MobileLogin;
    expect(find.byType(login), findsOneWidget);
  });
}
