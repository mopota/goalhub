import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goalhub/features/leagues/domain/entities/leader_entity.dart';
import 'package:goalhub/features/leagues/domain/entities/standing_entity.dart';
import 'package:goalhub/features/leagues/domain/repositories/league_repository.dart';
import '../../domain/entities/league_entity.dart';
import 'leagues_state.dart';

class LeaguesCubit extends Cubit<LeaguesState> {
  final LeagueRepository repository;

  LeaguesCubit(this.repository) : super(LeaguesInitial());

  Future<void> fetchLeagues({String lang = 'en'}) async {
    emit(LeaguesLoading());
    try {
      final leagues = await repository.getSoccerLeagues(lang: lang);
      emit(LeaguesLoaded(leagues: leagues));
    } catch (e) {
      emit(LeaguesError(e.toString()));
    }
  }

  Future<void> fetchLeagueDetails(String leagueId, {String lang = 'en'}) async {
    final currentState = state;
    if (currentState is LeaguesLoaded) {
      print('[GoalHub Debug] fetchLeagueDetails for leagueId: $leagueId');
      
      try {
        final results = await Future.wait([
          repository.getStandings(leagueId, lang: lang),
          repository.getLeagueLeaders(leagueId, lang: lang),
        ]);
        
        if (state is LeaguesLoaded) {
          emit((state as LeaguesLoaded).copyWith(
            standings: results[0] as List<StandingEntity>,
            leaders: results[1] as List<LeagueLeadersEntity>,
          ));
        }
      } catch (e) {
        print('[GoalHub Debug] fetchLeagueDetails error: $e');
        // Try to at least show standings if leaders failed or vice versa
        try {
           final standings = await repository.getStandings(leagueId, lang: lang);
           if (state is LeaguesLoaded) {
             emit((state as LeaguesLoaded).copyWith(standings: standings));
           }
        } catch (_) {}
      }
    }
  }

  Future<void> fetchAthleteDetails(String athleteId, {String lang = 'en'}) async {
    final currentState = state;
    if (currentState is LeaguesLoaded) {
      emit(LeaguesLoading());
      try {
        final athlete = await repository.getAthleteDetails(athleteId, lang: lang);
        emit(currentState.copyWith(athlete: athlete));
      } catch (e) {
        emit(LeaguesError(e.toString()));
      }
    }
  }

  Future<void> fetchTeamDetails(String leagueId, String teamId, {String lang = 'en'}) async {
    final currentState = state;
    List<LeagueEntity> leagues = [];
    if (currentState is LeaguesLoaded) {
      leagues = currentState.leagues;
    }
    
    emit(LeaguesLoading());
    try {
      final team = await repository.getTeamDetails(leagueId, teamId, lang: lang);
      emit(LeaguesLoaded(leagues: leagues, team: team));
    } catch (e) {
      emit(LeaguesError(e.toString()));
    }
  }
}
