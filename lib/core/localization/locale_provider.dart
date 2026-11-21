import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app_strings.dart';

/// State notifier for user's selected language
class LanguageNotifier extends StateNotifier<AppLanguage> {
  LanguageNotifier() : super(AppLanguage.hinglish); // Default to Hinglish for maximum Indian PG adoption

  void setLanguage(AppLanguage lang) {
    state = lang;
  }

  void toggleLanguage() {
    state = state == AppLanguage.english ? AppLanguage.hinglish : AppLanguage.english;
  }
}

/// Provider for accessing current language across all widgets
final languageProvider = StateNotifierProvider<LanguageNotifier, AppLanguage>((ref) {
  return LanguageNotifier();
});

/// Extension method on WidgetRef to easily retrieve localized strings
extension LocalizationExtension on WidgetRef {
  String tr(String key) {
    final currentLang = watch(languageProvider);
    return AppStrings.get(key, currentLang);
  }
}
