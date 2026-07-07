import 'package:equatable/equatable.dart';
import 'package:goalhub/features/leagues/domain/entities/athlete_entity.dart';
import 'package:goalhub/features/leagues/domain/entities/league_entity.dart';
import 'package:goalhub/features/leagues/domain/entities/leader_entity.dart';
import 'package:goalhub/features/leagues/domain/entities/standing_entity.dart';
import 'package:goalhub/features/leagues/domain/entities/team_entity.dart';

abstract class LeaguesState extends Equatable {
  const LeaguesState();

  @override
  List<Object?> get props => [];
}

class LeaguesInitial extends LeaguesState {}

class LeaguesLoading extends LeaguesState {}

class LeaguesLoaded extends LeaguesState {
  final List<LeagueEntity> leagues;
  final List<StandingEntity>? standings;
  final List<LeagueLeadersEntity>? leaders;
  final AthleteEntity? athlete;
  final TeamEntity? team;

  const LeaguesLoaded({
    required this.leagues,
    this.standings,
    this.leaders,
    this.athlete,
    this.team,
  });

  @override
  List<Object?> get props => [leagues, standings, leaders, athlete, team];

  LeaguesLoaded copyWith({
    List<LeagueEntity>? leagues,
    List<StandingEntity>? standings,
    List<LeagueLeadersEntity>? leaders,
    AthleteEntity? athlete,
    TeamEntity? team,
  }) {
    return LeaguesLoaded(
      leagues: leagues ?? this.leagues,
      standings: standings ?? this.standings,
      leaders: leaders ?? this.leaders,
      athlete: athlete ?? this.athlete,
      team: team ?? this.team,
    );
  }
}

class LeaguesError extends LeaguesState {
  final String message;

  const LeaguesError(this.message);

  @override
  List<Object?> get props => [message];
}
