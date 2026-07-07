import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goalhub/core/settings/settings_cubit.dart';
import 'package:goalhub/core/settings/settings_repository.dart';
import 'package:goalhub/features/leagues/data/data_sources/league_remote_data_source.dart';
import 'package:goalhub/features/leagues/data/repositories/league_repository_impl.dart';
import 'package:goalhub/features/leagues/domain/repositories/league_repository.dart';
import 'package:goalhub/features/matches/data/data_sources/match_remote_data_source.dart';
import 'package:goalhub/features/matches/data/repositories/match_repository_impl.dart';
import 'package:goalhub/features/matches/domain/repositories/match_repository.dart';
import 'package:goalhub/features/navigation/main_navigation_page.dart';
import 'package:goalhub/features/news/data/data_sources/news_remote_data_source.dart';
import 'package:goalhub/features/news/data/repositories/news_repository_impl.dart';
import 'package:goalhub/features/news/domain/repositories/news_repository.dart';
import 'package:goalhub/core/utils/translation_service.dart';
import 'package:goalhub/features/leagues/presentation/cubit/leagues_cubit.dart';
import 'package:goalhub/features/news/presentation/cubit/news_cubit.dart';
import 'package:goalhub/features/onboarding/presentation/pages/onboarding_page.dart';
import 'package:goalhub/features/matches/presentation/cubit/matches_cubit.dart';
import 'package:goalhub/core/network/image_repository.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('en_US', null);
  await initializeDateFormatting('ar', null);
  
  final prefs = await SharedPreferences.getInstance();
  final settingsRepository = SettingsRepository(prefs);
  
  final dio = Dio();
  final translationService = TranslationService();
  final imageRepository = ImageRepository(dio, prefs);
  
  // Data Sources
  final leagueRemoteDataSource = LeagueRemoteDataSourceImpl(dio);
  final matchRemoteDataSource = MatchRemoteDataSourceImpl(dio);
  final newsRemoteDataSource = NewsRemoteDataSourceImpl(dio);
  
  // Repositories
  final LeagueRepository leagueRepository = LeagueRepositoryImpl(leagueRemoteDataSource);
  final MatchRepository matchRepository = MatchRepositoryImpl(matchRemoteDataSource, leagueRepository);
  final NewsRepository newsRepository = NewsRepositoryImpl(newsRemoteDataSource);
  
  runApp(
    MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: settingsRepository),
        RepositoryProvider<LeagueRepository>.value(value: leagueRepository),
        RepositoryProvider<MatchRepository>.value(value: matchRepository),
        RepositoryProvider<NewsRepository>.value(value: newsRepository),
        RepositoryProvider<TranslationService>.value(value: translationService),
        RepositoryProvider<ImageRepository>.value(value: imageRepository),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (context) => SettingsCubit(settingsRepository),
          ),
          BlocProvider(
            create: (context) => MatchesCubit(
              matchRepository, 
              context.read<SettingsCubit>(),
              context.read<TranslationService>(),
            )..loadInitialMatches(),
          ),
          BlocProvider(
            create: (context) => LeaguesCubit(leagueRepository)..fetchLeagues(),
          ),
          BlocProvider(
            create: (context) => NewsCubit(
              newsRepository, 
              context.read<SettingsCubit>(),
              context.read<TranslationService>(),
            )..loadNews(),
          ),
        ],
        child: const GoalHubApp(),
      ),
    ),
  );
}

class GoalHubApp extends StatelessWidget {
  const GoalHubApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsCubit, SettingsState>(
      builder: (context, state) {
        ThemeMode themeMode;
        switch (state.themeMode) {
          case 'light':
            themeMode = ThemeMode.light;
            break;
          case 'dark':
            themeMode = ThemeMode.dark;
            break;
          default:
            themeMode = ThemeMode.system;
        }

        return MaterialApp(
          title: 'GoalHub',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            useMaterial3: true,
            colorSchemeSeed: Colors.green,
            brightness: Brightness.light,
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            colorSchemeSeed: Colors.green,
            brightness: Brightness.dark,
          ),
          themeMode: themeMode,
          locale: Locale(state.language),
          supportedLocales: const [
            Locale('en'),
            Locale('ar'),
          ],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: state.isOnboardingCompleted 
              ? const MainNavigationPage() 
              : const OnboardingPage(),
        );
      },
    );
  }
}
