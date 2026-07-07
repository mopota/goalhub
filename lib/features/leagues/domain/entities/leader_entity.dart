import 'package:equatable/equatable.dart';

class LeaderEntity extends Equatable {
  final String athleteId;
  final String displayName;
  final String? headshot;
  final String teamName;
  final String? teamLogo;
  final String value; // The stat value (e.g., number of goals)
  final String displayValue;
  final String rank;

  const LeaderEntity({
    required this.athleteId,
    required this.displayName,
    this.headshot,
    required this.teamName,
    this.teamLogo,
    required this.value,
    required this.displayValue,
    required this.rank,
  });

  @override
  List<Object?> get props => [
        athleteId,
        displayName,
        headshot,
        teamName,
        teamLogo,
        value,
        displayValue,
        rank,
      ];
}

class LeagueLeadersEntity extends Equatable {
  final String name; // e.g., "Goals", "Assists"
  final String displayName;
  final List<LeaderEntity> leaders;

  const LeagueLeadersEntity({
    required this.name,
    required this.displayName,
    required this.leaders,
  });

  @override
  List<Object?> get props => [name, displayName, leaders];
}
