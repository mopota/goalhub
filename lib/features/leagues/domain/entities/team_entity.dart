import 'package:equatable/equatable.dart';
import 'package:goalhub/features/leagues/domain/entities/athlete_entity.dart';
import 'package:goalhub/features/leagues/domain/entities/leader_entity.dart';
import 'package:goalhub/features/matches/domain/entities/match_entity.dart';

class TeamEntity extends Equatable {
  final String id;
  final String name;
  final String displayName;
  final String? logo;
  final String? location;
  final List<AthleteEntity>? roster;
  final String? coach;
  final String? venue;
  final String? venueImage;
  final List<LeagueLeadersEntity>? leaders;
  final List<MatchEntity>? recentMatches;
  final List<MatchEntity>? upcomingMatches;

  const TeamEntity({
    required this.id,
    required this.name,
    required this.displayName,
    this.logo,
    this.location,
    this.roster,
    this.coach,
    this.venue,
    this.venueImage,
    this.leaders,
    this.recentMatches,
    this.upcomingMatches,
  });

  @override
  List<Object?> get props => [
        id,
        name,
        displayName,
        logo,
        location,
        roster,
        coach,
        venue,
        venueImage,
        leaders,
        recentMatches,
        upcomingMatches,
      ];
}
