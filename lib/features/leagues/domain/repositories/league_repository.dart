import 'package:goalhub/features/leagues/domain/entities/athlete_entity.dart';
import 'package:goalhub/features/leagues/domain/entities/league_entity.dart';
import 'package:goalhub/features/leagues/domain/entities/leader_entity.dart';
import 'package:goalhub/features/leagues/domain/entities/standing_entity.dart';
import 'package:goalhub/features/leagues/domain/entities/team_entity.dart';

abstract class LeagueRepository {
  Future<List<LeagueEntity>> getSoccerLeagues({String lang = 'en'});
  Future<List<StandingEntity>> getStandings(String leagueId, {String lang = 'en'});
  Future<List<LeagueLeadersEntity>> getLeagueLeaders(String leagueId, {String lang = 'en'});
  Future<AthleteEntity> getAthleteDetails(String athleteId, {String lang = 'en'});
  Future<TeamEntity> getTeamDetails(String leagueId, String teamId, {String lang = 'en'});
  Future<Map<String, dynamic>> search(String query, {String lang = 'en'});
}
