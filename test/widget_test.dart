import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rent_manager/main.dart';
import 'package:rent_manager/core/utils/currency_formatter.dart';
import 'package:rent_manager/core/localization/app_strings.dart';
import 'package:rent_manager/core/localization/locale_provider.dart';

void main() {
  group('Step 1 & 2 Audit: Core Utilities & Localization Tests', () {
    test('CurrencyFormatter accurately formats Indian Rupees', () {
      expect(CurrencyFormatter.format(8140), '₹8,140');
      expect(CurrencyFormatter.format(142500), '₹1,42,500');
      expect(CurrencyFormatter.format(0), '₹0');
      expect(CurrencyFormatter.format(640.50), '₹640.50');
    });

    test('AppStrings returns localized text in English & Hinglish', () {
      expect(AppStrings.get('statusPaid', AppLanguage.english), 'Paid');
      expect(AppStrings.get('statusPaid', AppLanguage.hinglish), contains('जमा हो गया'));
      expect(AppStrings.get('statusOverdue', AppLanguage.hinglish), contains('बाकी है'));
    });

    test('LanguageNotifier toggles between English and Hinglish correctly', () {
      final notifier = LanguageNotifier();
      expect(notifier.state, AppLanguage.hinglish); // Default
      notifier.toggleLanguage();
      expect(notifier.state, AppLanguage.english);
      notifier.toggleLanguage();
      expect(notifier.state, AppLanguage.hinglish);
    });
  });

  group('Step 1 & 2 Audit: Widget Smoke & State Verification', () {
    testWidgets('App boots with ProviderScope, renders Dashboard and toggles language', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: RentManagerApp(),
        ),
      );

      // Verify that RentKhata dashboard loads
      expect(find.text('Setup Your PG / Hostel'), findsOneWidget);
      expect(find.text('⚡ Pre-load Kota PG Demo (Live Test)'), findsOneWidget);

      // Default language is Hinglish
      expect(find.text('English'), findsOneWidget); // Button shows 'English' to switch to English

      // Tap language switch button
      await tester.tap(find.text('English'));
      await tester.pumpAndSettle();

      // Now language is English, button shows 'हिंदी / Hinglish'
      expect(find.text('हिंदी / Hinglish'), findsOneWidget);
      expect(find.text('Total Collected'), findsOneWidget);
      expect(find.text('Pending Dues'), findsOneWidget);
    });
  });
}
