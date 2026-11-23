import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_strings.dart';

/// State notifier for user's selected language (Defaults to English)
class LanguageNotifier extends StateNotifier<AppLanguage> {
  static const String langStorageKey = 'rentkhata_user_lang';

  LanguageNotifier([super.initialLang = AppLanguage.english]);

  void setLanguage(AppLanguage lang) {
    state = lang;
    _persistLang();
  }

  void toggleLanguage() {
    state = state == AppLanguage.english ? AppLanguage.hinglish : AppLanguage.english;
    _persistLang();
  }

  void _persistLang() {
    try {
      SharedPreferences.getInstance().then((prefs) {
        prefs.setString(langStorageKey, state.name);
      }).catchError((_) {});
    } catch (_) {}
  }
}

/// Provider for accessing current language across all widgets
final languageProvider = StateNotifierProvider<LanguageNotifier, AppLanguage>((ref) {
  return LanguageNotifier(AppLanguage.english);
});

/// Extension method on WidgetRef to easily retrieve localized strings
extension LocalizationExtension on WidgetRef {
  String tr(String key) {
    final currentLang = watch(languageProvider);
    return AppStrings.get(key, currentLang);
  }

  bool get isEnglish => watch(languageProvider) == AppLanguage.english;
}
