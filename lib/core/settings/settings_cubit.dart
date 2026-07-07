import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:goalhub/core/settings/settings_repository.dart';

class SettingsState extends Equatable {
  final String language;
  final String country;
  final bool isOnboardingCompleted;
  final String themeMode;

  const SettingsState({
    required this.language,
    required this.country,
    required this.isOnboardingCompleted,
    required this.themeMode,
  });

  @override
  List<Object> get props => [language, country, isOnboardingCompleted, themeMode];

  SettingsState copyWith({
    String? language,
    String? country,
    bool? isOnboardingCompleted,
    String? themeMode,
  }) {
    return SettingsState(
      language: language ?? this.language,
      country: country ?? this.country,
      isOnboardingCompleted: isOnboardingCompleted ?? this.isOnboardingCompleted,
      themeMode: themeMode ?? this.themeMode,
    );
  }
}

class SettingsCubit extends Cubit<SettingsState> {
  final SettingsRepository repository;

  SettingsCubit(this.repository)
      : super(SettingsState(
          language: repository.language,
          country: repository.country,
          isOnboardingCompleted: repository.isOnboardingCompleted,
          themeMode: repository.themeMode,
        ));

  void updateLanguage(String lang) async {
    await repository.setLanguage(lang);
    emit(state.copyWith(language: lang));
  }

  void updateThemeMode(String theme) async {
    await repository.setThemeMode(theme);
    emit(state.copyWith(themeMode: theme));
  }

  void updateCountry(String country) async {
    await repository.setCountry(country);
    emit(state.copyWith(country: country));
  }

  void completeOnboarding() async {
    await repository.completeOnboarding();
    emit(state.copyWith(isOnboardingCompleted: true));
  }
}
