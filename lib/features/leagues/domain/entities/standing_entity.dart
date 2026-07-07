import 'package:equatable/equatable.dart';

class StandingEntity extends Equatable {
  final String teamId;
  final String teamName;
  final String? teamLogo;
  final String rank;
  final String points;
  final String played;
  final String won;
  final String drawn;
  final String lost;
  final String goalsFor;
  final String goalsAgainst;
  final String goalsDifference;
  final String? form; // Last 5 matches form (W, L, D)
  final String? note; // Promotion/Relegation note
  final String? groupName; // e.g. Group A, Group B

  const StandingEntity({
    required this.teamId,
    required this.teamName,
    this.teamLogo,
    required this.rank,
    required this.points,
    required this.played,
    required this.won,
    required this.drawn,
    required this.lost,
    required this.goalsFor,
    required this.goalsAgainst,
    required this.goalsDifference,
    this.form,
    this.note,
    this.groupName,
  });

  @override
  List<Object?> get props => [
        teamId,
        teamName,
        teamLogo,
        rank,
        points,
        played,
        won,
        drawn,
        lost,
        goalsFor,
        goalsAgainst,
        goalsDifference,
        form,
        note,
        groupName,
      ];
}
