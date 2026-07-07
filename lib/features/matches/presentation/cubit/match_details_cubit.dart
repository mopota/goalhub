import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goalhub/core/utils/translation_service.dart';
import 'package:goalhub/features/matches/domain/entities/details/match_detail_entity.dart';
import 'package:goalhub/features/matches/domain/entities/details/match_event_entity.dart';
import 'package:goalhub/features/matches/domain/entities/details/match_lineup_entity.dart';
import 'package:goalhub/features/matches/domain/repositories/match_repository.dart';
import 'package:goalhub/features/matches/presentation/cubit/match_details_state.dart';
import 'package:logger/logger.dart';

class MatchDetailsCubit extends Cubit<MatchDetailsState> {
  final MatchRepository repository;
  final TranslationService translationService;
  final Logger _logger = Logger();
  Timer? _refreshTimer;

  MatchDetailsCubit(this.repository, this.translationService) : super(MatchDetailsInitial());

  Future<void> loadMatchDetails(String leagueSlug, String eventId, {bool isLive = false, bool isFinished = false, String lang = 'en', String? homeTeamId, String? awayTeamId}) async {
    print('[GoalHub Debug] Loading match details for eventId: $eventId (lang: $lang)');
    if (state is! MatchDetailsLoaded) {
      emit(MatchDetailsLoading());
    }
    
    try {
      MatchDetailEntity detail = await repository.getMatchDetails(leagueSlug, eventId, lang: lang);
      if (isClosed) return;
      print('[GoalHub Debug] Received match details from repository');
      
      // Check if lineups are missing (common for upcoming matches)
      final lineupsAreEmpty = detail.lineups == null || 
                              (detail.lineups!.homeStarters.isEmpty && detail.lineups!.awayStarters.isEmpty);

      if (lineupsAreEmpty && homeTeamId != null && awayTeamId != null) {
        print('[GoalHub Debug] Lineups missing for upcoming match, fetching last match lineups as prediction...');
        try {
          final results = await Future.wait([
            repository.getLastMatchLineup(leagueSlug, homeTeamId, lang: lang),
            repository.getLastMatchLineup(leagueSlug, awayTeamId, lang: lang),
          ]);
          
          final homePrevLineup = results[0];
          final awayPrevLineup = results[1];

          if (homePrevLineup != null || awayPrevLineup != null) {
             List<MatchPlayerEntity> extractStarters(MatchLineupEntity? lineup, String targetTeamId) {
               if (lineup == null) return [];
               if (lineup.homeTeamId == targetTeamId) return lineup.homeStarters;
               if (lineup.awayTeamId == targetTeamId) return lineup.awayStarters;
               // Fallback: if we can't match IDs, return the one that isn't empty
               return lineup.homeStarters.isNotEmpty ? lineup.homeStarters : lineup.awayStarters;
             }

             final predictedLineup = MatchLineupEntity(
               homeTeamId: homeTeamId,
               homeStarters: extractStarters(homePrevLineup, homeTeamId),
               homeBench: const [],
               homeFormation: homePrevLineup?.homeTeamId == homeTeamId ? homePrevLineup?.homeFormation : homePrevLineup?.awayFormation,
               homeCoach: homePrevLineup?.homeTeamId == homeTeamId ? homePrevLineup?.homeCoach : homePrevLineup?.awayCoach,
               awayTeamId: awayTeamId,
               awayStarters: extractStarters(awayPrevLineup, awayTeamId),
               awayBench: const [],
               awayFormation: awayPrevLineup?.awayTeamId == awayTeamId ? awayPrevLineup?.awayFormation : awayPrevLineup?.homeFormation,
               awayCoach: awayPrevLineup?.awayTeamId == awayTeamId ? awayPrevLineup?.awayCoach : awayPrevLineup?.homeCoach,
             );

             // Only override if we actually got some starters
             if (predictedLineup.homeStarters.isNotEmpty || predictedLineup.awayStarters.isNotEmpty) {
                detail = detail.copyWith(
                  lineups: predictedLineup,
                  isPredictedLineup: true,
                );
                print('[GoalHub Debug] Predicted lineups applied successfully');
             }
          }
        } catch (e) {
          print('[GoalHub Debug] Predicted lineup fetch failed: $e');
        }
      }
      
      if (lang == 'ar') {
        print('[GoalHub Debug] Starting Arabic translation for match details');
        try {
          final translatedDetail = await _translateDetail(detail);
          if (isClosed) return;
          final finalDetail = _processSubstitutions(translatedDetail);
          print('[GoalHub Debug] Match details translation completed');
          emit(MatchDetailsLoaded(finalDetail));
        } catch (e) {
          if (isClosed) return;
          print('[GoalHub Debug] Match details translation FAILED: $e. Using original.');
          final finalDetail = _processSubstitutions(detail);
          emit(MatchDetailsLoaded(finalDetail));
        }
      } else {
        if (isClosed) return;
        final finalDetail = _processSubstitutions(detail);
        emit(MatchDetailsLoaded(finalDetail));
      }
      
      _checkHiddenSections(detail);
      
      if (isLive) {
        _startLiveRefresh(leagueSlug, eventId, lang: lang);
      }
    } catch (e) {
      if (isClosed) return;
      print('[GoalHub Debug] Error in loadMatchDetails: $e');
      _logger.e('Error loading match details: $e');
      if (state is! MatchDetailsLoaded) {
        emit(const MatchDetailsError('Failed to load match details. Please try again later.'));
      }
    }
  }

  MatchDetailEntity _processSubstitutions(MatchDetailEntity detail) {
    if (detail.lineups == null || detail.timeline == null) return detail;

    final events = detail.timeline!;
    final lineups = detail.lineups!;

    MatchPlayerEntity updatePlayer(MatchPlayerEntity p) {
      bool isOut = false;
      bool isIn = false;
      String? time;

      for (var e in events) {
        if (e.type == MatchEventType.substitution) {
          // Normalize names for matching (remove spaces/caps)
          final eName = e.playerName.toLowerCase().trim();
          final eNameOut = e.playerNameOut?.toLowerCase().trim();
          final pName = p.name.toLowerCase().trim();

          if (eName == pName) {
            isIn = true;
            time = e.minute;
          }
          if (eNameOut == pName) {
            isOut = true;
            time = e.minute;
          }
        }
      }

      return p.copyWith(isSubbedOut: isOut, isSubbedIn: isIn, subTime: time);
    }

    return detail.copyWith(
      lineups: lineups.copyWith(
        homeStarters: lineups.homeStarters.map(updatePlayer).toList(),
        homeBench: lineups.homeBench.map(updatePlayer).toList(),
        awayStarters: lineups.awayStarters.map(updatePlayer).toList(),
        awayBench: lineups.awayBench.map(updatePlayer).toList(),
      ),
    );
  }

  Future<MatchDetailEntity> _translateDetail(MatchDetailEntity detail) async {
    // Collect all unique texts that need translation to batch them
    final List<String> toTranslate = [];
    
    // Info fields
    if (detail.venue != null) toTranslate.add(detail.venue!);
    if (detail.referee != null) toTranslate.add(detail.referee!);
    if (detail.weather != null) toTranslate.add(detail.weather!);
    if (detail.odds != null) toTranslate.add(detail.odds!);

    // Stats display names
    final stats = detail.statistics ?? [];
    for (var s in stats) {
      toTranslate.add(s.displayName);
    }

    // Commentary
    final commentary = detail.commentary ?? [];
    toTranslate.addAll(commentary);

    // Timeline
    final events = detail.timeline ?? [];
    for (var e in events) {
      toTranslate.add(e.playerName);
      if (e.playerNameOut != null) toTranslate.add(e.playerNameOut!);
      toTranslate.add(e.description);
    }

    // Lineups
    final l = detail.lineups;
    if (l != null) {
      if (l.homeCoach != null) toTranslate.add(l.homeCoach!);
      if (l.awayCoach != null) toTranslate.add(l.awayCoach!);
      
      for (var p in [...l.homeStarters, ...l.homeBench, ...l.awayStarters, ...l.awayBench]) {
        toTranslate.add(p.name);
        toTranslate.add(p.position);
        // Do NOT translate positionAbbreviation to keep mapping logic working
      }
    }

    // Perform batch translation
    final translated = await translationService.translateList(toTranslate);
    int cursor = 0;

    String? next() => cursor < translated.length ? translated[cursor++] : null;

    // Map back
    final translatedVenue = detail.venue != null ? next() : null;
    final translatedReferee = detail.referee != null ? next() : null;
    final translatedWeather = detail.weather != null ? next() : null;
    final translatedOdds = detail.odds != null ? next() : null;

    final translatedStatsList = stats.map((s) {
       final translatedDisplay = TranslationService.translateTerm(s.displayName) ?? next() ?? s.displayName;
       return s.copyWith(displayName: translatedDisplay);
    }).toList();
    
    final translatedCommentary = commentary.map((_) => next() ?? '').toList();
    
    final translatedEvents = events.map((e) {
      final pName = next() ?? e.playerName;
      final pNameOut = e.playerNameOut != null ? next() : null;
      final desc = next() ?? e.description;
      return e.copyWith(playerName: pName, playerNameOut: pNameOut, description: desc);
    }).toList();

    MatchLineupEntity? translatedLineups;
    if (l != null) {
      final hCoach = l.homeCoach != null ? next() : null;
      final aCoach = l.awayCoach != null ? next() : null;

      MatchPlayerEntity translatePlayer(MatchPlayerEntity p) {
        final name = next() ?? p.name;
        final pos = next() ?? p.position;
        // Keep the original abbreviation for pitch mapping
        return p.copyWith(name: name, position: pos, positionAbbreviation: p.positionAbbreviation);
      }

      translatedLineups = l.copyWith(
        homeStarters: l.homeStarters.map(translatePlayer).toList(),
        homeBench: l.homeBench.map(translatePlayer).toList(),
        awayStarters: l.awayStarters.map(translatePlayer).toList(),
        awayBench: l.awayBench.map(translatePlayer).toList(),
        homeCoach: hCoach,
        awayCoach: aCoach,
      );
    }

    return detail.copyWith(
      statistics: translatedStatsList,
      venue: translatedVenue,
      referee: translatedReferee,
      weather: translatedWeather,
      odds: translatedOdds,
      commentary: translatedCommentary,
      timeline: translatedEvents,
      lineups: translatedLineups,
    );
  }

  void _startLiveRefresh(String leagueSlug, String eventId, {String lang = 'en'}) {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      try {
        final detail = await repository.getMatchDetails(leagueSlug, eventId, lang: lang);
        if (isClosed) return;
        
        if (lang == 'ar') {
          final translatedDetail = await _translateDetail(detail);
          if (isClosed) return;
          emit(MatchDetailsLoaded(translatedDetail));
        } else {
          if (isClosed) return;
          emit(MatchDetailsLoaded(detail));
        }
      } catch (e) {
        _logger.w('Live refresh failed: $e');
      }
    });
  }

  void _checkHiddenSections(dynamic detail) {
    final sections = {
      'Statistics': detail.statistics,
      'Timeline': detail.timeline,
      'Lineups': detail.lineups,
      'Commentary': detail.commentary,
    };

    sections.forEach((name, data) {
      if (data == null || (data is List && data.isEmpty)) {
        _logger.i('[GoalHub] Section Hidden\nSection: $name\nReason: Endpoint returned null or empty');
      }
    });
  }

  @override
  Future<void> close() {
    _refreshTimer?.cancel();
    return super.close();
  }
}
