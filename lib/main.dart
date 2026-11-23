import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/database/rent_khata_repository.dart';
import 'core/localization/app_strings.dart';
import 'core/localization/locale_provider.dart';
import 'core/theme/app_theme.dart';
import 'features/dashboard/presentation/dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  RentKhataState initialDbState = const RentKhataState();
  AppLanguage initialLang = AppLanguage.english;

  try {
    final prefs = await SharedPreferences.getInstance();

    final savedDbJson = prefs.getString(RentKhataRepository.dbStorageKey);
    if (savedDbJson != null && savedDbJson.isNotEmpty) {
      initialDbState = RentKhataState.fromJson(
        Map<String, dynamic>.from(jsonDecode(savedDbJson) as Map),
      );
    }

    final savedLang = prefs.getString(LanguageNotifier.langStorageKey);
    if (savedLang == 'hinglish') {
      initialLang = AppLanguage.hinglish;
    }
  } catch (e) {
    debugPrint('RentKhata startup restore error: $e');
  }

  runApp(
    ProviderScope(
      overrides: [
        rentKhataRepositoryProvider.overrideWith((ref) => RentKhataRepository(initialDbState)),
        languageProvider.overrideWith((ref) => LanguageNotifier(initialLang)),
      ],
      child: const RentManagerApp(),
    ),
  );
}

class RentManagerApp extends StatelessWidget {
  const RentManagerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RentKhata',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const DashboardScreen(),
    );
  }
}
