import 'package:goalhub/features/leagues/domain/entities/athlete_entity.dart';
import 'package:goalhub/features/matches/domain/entities/match_entity.dart';
import 'package:goalhub/features/matches/domain/entities/details/match_detail_entity.dart';
import 'package:goalhub/features/matches/domain/entities/details/match_lineup_entity.dart';

abstract class MatchRepository {
  Future<List<MatchEntity>> getUnifiedTimeline({String? date, String lang = 'en'});
  Future<MatchDetailEntity> getMatchDetails(String leagueSlug, String eventId, {String lang = 'en'});
  Future<AthleteEntity> getAthleteDetails(String leagueSlug, String athleteId, {String lang = 'en'});
  Future<MatchLineupEntity?> getLastMatchLineup(String leagueSlug, String teamId, {String lang = 'en'});
}
