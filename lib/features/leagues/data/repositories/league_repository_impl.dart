import 'package:goalhub/features/leagues/data/data_sources/league_remote_data_source.dart';
import 'package:goalhub/features/leagues/domain/entities/athlete_entity.dart';
import 'package:goalhub/features/leagues/domain/entities/league_entity.dart';
import 'package:goalhub/features/leagues/domain/entities/leader_entity.dart';
import 'package:goalhub/features/leagues/domain/entities/standing_entity.dart';
import 'package:goalhub/features/leagues/domain/entities/team_entity.dart';
import 'package:goalhub/features/leagues/domain/repositories/league_repository.dart';

class LeagueRepositoryImpl implements LeagueRepository {
  final LeagueRemoteDataSource remoteDataSource;

  LeagueRepositoryImpl(this.remoteDataSource);

  @override
  Future<List<LeagueEntity>> getSoccerLeagues({String lang = 'en'}) async {
    return await remoteDataSource.discoverLeagues('soccer', lang: lang);
  }

  @override
  Future<List<StandingEntity>> getStandings(String leagueId, {String lang = 'en'}) async {
    return await remoteDataSource.getStandings(leagueId, lang: lang);
  }

  @override
  Future<List<LeagueLeadersEntity>> getLeagueLeaders(String leagueId, {String lang = 'en'}) async {
    return await remoteDataSource.getLeagueLeaders(leagueId, lang: lang);
  }

  @override
  Future<AthleteEntity> getAthleteDetails(String athleteId, {String lang = 'en'}) async {
    return await remoteDataSource.getAthleteDetails(athleteId, lang: lang);
  }

  @override
  Future<TeamEntity> getTeamDetails(String leagueId, String teamId, {String lang = 'en'}) async {
    return await remoteDataSource.getTeamDetails(leagueId, teamId, lang: lang);
  }

  @override
  Future<Map<String, dynamic>> search(String query, {String lang = 'en'}) async {
    return await remoteDataSource.search(query, lang: lang);
  }
}
