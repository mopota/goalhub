import 'package:goalhub/features/leagues/domain/entities/standing_entity.dart';

class StandingModel extends StandingEntity {
  const StandingModel({
    required super.teamId,
    required super.teamName,
    super.teamLogo,
    required super.rank,
    required super.points,
    required super.played,
    required super.won,
    required super.drawn,
    required super.lost,
    required super.goalsFor,
    required super.goalsAgainst,
    required super.goalsDifference,
    super.form,
    super.note,
    super.groupName,
  });

  factory StandingModel.fromJson(Map<String, dynamic> json, {String? groupName}) {
    try {
      final team = json['team'];
      final stats = json['stats'] as List? ?? [];

      String getValue(String name) {
        final stat = stats.firstWhere(
          (s) => s['name'] == name || s['abbreviation'] == name || s['shortDisplayName'] == name,
          orElse: () => null,
        );
        if (stat == null) return '0';
        return (stat['displayValue'] ?? stat['value'] ?? '0').toString();
      }

      final model = StandingModel(
        teamId: team['id']?.toString() ?? '',
        teamName: team['displayName']?.toString() ?? team['name']?.toString() ?? '',
        teamLogo: (team['logos'] as List?)?.first['href']?.toString(),
        rank: getValue('rank'),
        points: getValue('points'),
        played: getValue('gamesPlayed'),
        won: getValue('wins'),
        drawn: getValue('ties'),
        lost: getValue('losses'),
        goalsFor: getValue('goalsFor'),
        goalsAgainst: getValue('goalsAgainst'),
        goalsDifference: getValue('pointDifference'),
        form: json['note']?['description']?.toString(),
        note: json['note']?['description']?.toString(),
        groupName: groupName,
      );
      return model;
    } catch (e) {
      print('[GoalHub Debug] Error parsing standing entry: $e');
      rethrow;
    }
  }
}
