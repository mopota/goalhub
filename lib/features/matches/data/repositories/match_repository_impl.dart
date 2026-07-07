import 'package:goalhub/features/leagues/domain/entities/athlete_entity.dart';
import 'package:goalhub/features/leagues/domain/repositories/league_repository.dart';
import 'package:goalhub/features/matches/data/data_sources/match_remote_data_source.dart';
import 'package:goalhub/features/matches/domain/entities/match_entity.dart';
import 'package:goalhub/features/matches/domain/entities/details/match_detail_entity.dart';
import 'package:goalhub/features/matches/domain/repositories/match_repository.dart';
import 'package:intl/intl.dart';
import 'package:logger/logger.dart';

import '../../domain/entities/details/match_lineup_entity.dart';

class MatchRepositoryImpl implements MatchRepository {
  final MatchRemoteDataSource remoteDataSource;
  final LeagueRepository leagueRepository;
  final Logger _logger = Logger();

  MatchRepositoryImpl(this.remoteDataSource, this.leagueRepository);

  @override
  Future<List<MatchEntity>> getUnifiedTimeline({String? date, String lang = 'en'}) async {
    try {
      // Comprehensive list of leagues as requested (Arabic, European, Americas, Asian, African)
      final List<String> majorLeagues = [
        'all', 
        // European Top Leagues & Cups
        'eng.1', 'esp.1', 'ger.1', 'ita.1', 'fra.1', 'ned.1', 'por.1', 'tur.1', 'bel.1', 'sco.1', 'rus.1', 'ukr.1', 'gre.1', 'aut.1', 'sui.1',
        'uefa.champions', 'uefa.europa', 'uefa.conf.league', 'uefa.nations', 'uefa.euro', 'uefa.super_cup',
        'eng.fa', 'eng.league_cup', 'esp.copa_del_rey', 'ger.dfb_pokal', 'ita.coppa_italia', 'fra.coupe_de_france',
        // Arabic & Middle East
        'egy.1', 'ksa.1', 'mar.1', 'tun.1', 'uae.1', 'qat.1', 'alg.1', 'irq.1', 'jor.1', 'kuw.1', 'lib.1', 'oma.1', 'bhr.1',
        'egy.cup', 'ksa.kings_cup', 'uafa.club.championship', 'gulf.cup',
        // Americas
        'arg.1', 'bra.1', 'usa.1', 'mex.1', 'col.1', 'chi.1', 'ecu.1', 'uru.1', 'par.1', 'ven.1',
        'conmebol.libertadores', 'conmebol.sudamericana', 'conmebol.copa_america', 'concacaf.champions', 'concacaf.gold_cup',
        // Asian & African
        'afc.champions', 'asia.cup', 'chn.1', 'jpn.1', 'aus.1', 'kor.1', 'ind.1',
        'caf.champions', 'caf.confed', 'caf.nations', 'rsa.1', 'caf.super_cup',
        // Global
        'fifa.world', 'fifa.friendly'
      ];

      String? apiDateRange;
      if (date != null && date.length == 8) {
        final year = int.parse(date.substring(0, 4));
        final month = int.parse(date.substring(4, 6));
        final day = int.parse(date.substring(6, 8));
        final requestedDate = DateTime(year, month, day);
        
        // Window: Yesterday to Tomorrow to handle all timezones (crucial for dawn matches in Egypt)
        final start = DateFormat('yyyyMMdd').format(requestedDate.subtract(const Duration(days: 1)));
        final end = DateFormat('yyyyMMdd').format(requestedDate.add(const Duration(days: 1)));
        apiDateRange = '$start-$end';
      } else {
        final now = DateTime.now();
        final start = DateFormat('yyyyMMdd').format(now.subtract(const Duration(days: 1)));
        final end = DateFormat('yyyyMMdd').format(now.add(const Duration(days: 1)));
        apiDateRange = '$start-$end';
      }

      print('[GoalHub Debug] Global search range: $apiDateRange');

      final List<MatchEntity> allMatches = [];
      final Set<String> matchIds = {};
      final List<Future<List<MatchEntity>>> fetchFutures = [];
      
      // Fetch all leagues using the 3-day range to catch timezone overflows (e.g. dawn matches)
      for (var slug in majorLeagues) {
        fetchFutures.add(remoteDataSource.getMatches(slug, date: apiDateRange, lang: lang).then((v) => v as List<MatchEntity>));
      }

      final results = await Future.wait(fetchFutures.map((f) => f.catchError((Object error) {
        return <MatchEntity>[];
      })));

      for (var result in results) {
        for (var match in result) {
          if (!matchIds.contains(match.id)) {
            // CRITICAL: We filter based on the USER'S LOCAL DATE
            // This ensures matches at 1 AM, 3 AM, or late PM all show up on the correct day.
            final matchLocalDateStr = DateFormat('yyyyMMdd').format(match.date.toLocal());
            
            if (date == null || matchLocalDateStr == date) {
              allMatches.add(match);
              matchIds.add(match.id);
            }
          }
        }
      }

      print('[GoalHub Debug] Total unique matches displayed: ${allMatches.length}');
      
      // Sort: Live first, then by date/time
      allMatches.sort((a, b) {
        if (a.isLive && !b.isLive) return -1;
        if (!a.isLive && b.isLive) return 1;
        return a.date.compareTo(b.date);
      });

      return allMatches;
    } catch (e) {
      _logger.e('Global aggregation failure: $e');
      rethrow;
    }
  }

  @override
  Future<MatchDetailEntity> getMatchDetails(String leagueSlug, String eventId, {String lang = 'en'}) async {
    try {
      return await remoteDataSource.getMatchDetails(leagueSlug, eventId, lang: lang);
    } catch (e) {
      _logger.e('Failed to fetch match details: $e');
      rethrow;
    }
  }

  @override
  Future<AthleteEntity> getAthleteDetails(String leagueSlug, String athleteId, {String lang = 'en'}) async {
    return await leagueRepository.getAthleteDetails(athleteId, lang: lang);
  }

  @override
  Future<MatchLineupEntity?> getLastMatchLineup(String leagueSlug, String teamId, {String lang = 'en'}) async {
    print('[GoalHub Debug] Attempting to fetch last match lineup for team: $teamId (Slug: $leagueSlug)');
    try {
      // CRITICAL: ESPN team schedule API does NOT support 'all' as a league slug.
      // If we got 'all', we must try to use a real league. 
      // Common catch-all leagues in ESPN that often work for team schedules:
      final slugsToTry = leagueSlug == 'all' 
          ? ['eng.1', 'esp.1', 'ger.1', 'ita.1', 'fra.1', 'usa.1', 'fifa.world'] 
          : [leagueSlug, 'usa.1', 'eng.1'];

      String? lastMatchId;
      String? successfulSlug;

      for (var slug in slugsToTry) {
        lastMatchId = await remoteDataSource.getLastFinishedMatchId(slug, teamId, lang: lang);
        if (lastMatchId != null) {
          successfulSlug = slug;
          break;
        }
      }

      if (lastMatchId != null && successfulSlug != null) {
        print('[GoalHub Debug] Found last match ID: $lastMatchId using slug: $successfulSlug');
        final details = await remoteDataSource.getMatchDetails(successfulSlug, lastMatchId, lang: lang);
        if (details.lineups != null) {
          return details.lineups;
        }
      }
      return null;
    } catch (e) {
      print('[GoalHub Debug] Failed to fetch last match lineup: $e');
      return null;
    }
  }
}
