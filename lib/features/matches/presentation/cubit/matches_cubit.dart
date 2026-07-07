import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goalhub/core/settings/settings_cubit.dart';
import 'package:goalhub/core/utils/translation_service.dart';
import 'package:goalhub/features/matches/domain/entities/match_entity.dart';
import 'package:goalhub/features/matches/domain/repositories/match_repository.dart';
import 'package:goalhub/features/matches/presentation/cubit/matches_state.dart';
import 'package:intl/intl.dart';

class MatchesCubit extends Cubit<MatchesState> {
  final MatchRepository repository;
  final SettingsCubit settingsCubit;
  final TranslationService translationService;
  Timer? _refreshTimer;
  StreamSubscription? _settingsSubscription;
  
  MatchesCubit(this.repository, this.settingsCubit, this.translationService) : super(MatchesInitial()) {
    _settingsSubscription = settingsCubit.stream.listen((state) {
      _matchesByDate.clear();
      _loadedDates.clear();
      loadInitialMatches();
    });
  }

  final Map<String, List<MatchEntity>> _matchesByDate = {};
  final List<String> _loadedDates = [];

  Future<void> loadInitialMatches() async {
    emit(MatchesLoading());
    try {
      await _fetchDate(DateTime.now());
      _emitLoaded();
      _startLiveRefresh();
    } catch (e) {
      emit(MatchesError(e.toString()));
    }
  }

  Future<void> loadDate(DateTime date) async {
    final dateStr = DateFormat('yyyy-MM-dd', 'en_US').format(date);
    if (_matchesByDate.containsKey(dateStr) && _loadedDates.contains(dateStr)) {
      _emitLoaded();
      return;
    }

    emit(MatchesLoading());
    try {
      await _fetchDate(date);
      _emitLoaded();
    } catch (e) {
      emit(MatchesError(e.toString()));
    }
  }

  Future<void> _fetchDate(DateTime date) async {
    final dateStr = DateFormat('yyyy-MM-dd', 'en_US').format(date);
    print('[GoalHub Debug] Fetching matches for date: $dateStr');
    try {
      final apiDate = dateStr.replaceAll('-', '');
      final lang = settingsCubit.state.language;
      final matches = await repository.getUnifiedTimeline(
        date: apiDate, 
        lang: lang
      );
      
      print('[GoalHub Debug] Received ${matches.length} matches from repository');
      
      if (lang == 'ar' && matches.isNotEmpty) {
        print('[GoalHub Debug] Starting batch translation for Arabic');
        // Collect all texts to translate in one go
        final List<String> toTranslate = [];
        for (var match in matches) {
          toTranslate.add(match.status);
          toTranslate.add(match.leagueName);
          toTranslate.add(match.homeTeamName);
          toTranslate.add(match.awayTeamName);
        }

        try {
          final translated = await translationService.translateList(toTranslate);
          print('[GoalHub Debug] Batch translation completed successfully. Translated ${translated.length / 4} matches.');
          
          final List<MatchEntity> translatedMatches = [];
          for (int i = 0; i < matches.length; i++) {
            // Safety check for indices
            final status = (i * 4 < translated.length) ? translated[i * 4] : matches[i].status;
            final league = (i * 4 + 1 < translated.length) ? translated[i * 4 + 1] : matches[i].leagueName;
            final home = (i * 4 + 2 < translated.length) ? translated[i * 4 + 2] : matches[i].homeTeamName;
            final away = (i * 4 + 3 < translated.length) ? translated[i * 4 + 3] : matches[i].awayTeamName;

            translatedMatches.add(matches[i].copyWith(
              status: status,
              leagueName: league,
              homeTeamName: home,
              awayTeamName: away,
            ));
          }
          _matchesByDate[dateStr] = translatedMatches;
        } catch (e) {
          print('[GoalHub Debug] Translation Exception in Cubit: $e');
          _matchesByDate[dateStr] = matches;
        }
      } else {
        _matchesByDate[dateStr] = matches;
      }

      if (!_loadedDates.contains(dateStr)) {
        _loadedDates.add(dateStr);
        _loadedDates.sort();
      }
    } catch (e) {
      print('[GoalHub Debug] Error in _fetchDate: $e');
      rethrow;
    }
  }

  void _emitLoaded({bool isLoadingMore = false}) {
    emit(MatchesLoaded(
      matchesByDate: Map.from(_matchesByDate),
      loadedDates: List.from(_loadedDates),
      isLoadingMore: isLoadingMore,
    ));
  }

  void _startLiveRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) async {
      final todayStr = DateFormat('yyyy-MM-dd', 'en_US').format(DateTime.now());
      final todayMatches = _matchesByDate[todayStr] ?? [];
      
      final hasLiveMatches = todayMatches.any((m) => m.isLive);
      if (hasLiveMatches) {
        try {
          await _fetchDate(DateTime.now());
          _emitLoaded();
        } catch (_) {}
      }
    });
  }
  
  Future<void> refresh() async {
    _refreshTimer?.cancel();
    await loadInitialMatches();
  }

  @override
  Future<void> close() {
    _refreshTimer?.cancel();
    _settingsSubscription?.cancel();
    return super.close();
  }
}
