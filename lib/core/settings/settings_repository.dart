import 'package:shared_preferences/shared_preferences.dart';

class SettingsRepository {
  static const String _langKey = 'selected_language';
  static const String _countryKey = 'selected_country';
  static const String _onboardingKey = 'onboarding_completed';
  static const String _themeKey = 'selected_theme';

  final SharedPreferences _prefs;

  SettingsRepository(this._prefs);

  String get language => _prefs.getString(_langKey) ?? 'en';
  String get country => _prefs.getString(_countryKey) ?? 'Egypt';
  bool get isOnboardingCompleted => _prefs.getBool(_onboardingKey) ?? false;
  String get themeMode => _prefs.getString(_themeKey) ?? 'system';

  Future<void> setLanguage(String lang) async {
    await _prefs.setString(_langKey, lang);
  }

  Future<void> setCountry(String country) async {
    await _prefs.setString(_countryKey, country);
  }

  Future<void> completeOnboarding() async {
    await _prefs.setBool(_onboardingKey, true);
  }

  Future<void> setThemeMode(String theme) async {
    await _prefs.setString(_themeKey, theme);
  }
}
