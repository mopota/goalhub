import 'package:goalhub/features/leagues/domain/entities/leader_entity.dart';

class LeaderModel extends LeaderEntity {
  const LeaderModel({
    required super.athleteId,
    required super.displayName,
    super.headshot,
    required super.teamName,
    super.teamLogo,
    required super.value,
    required super.displayValue,
    required super.rank,
  });

  factory LeaderModel.fromJson(Map<String, dynamic> json) {
    final athlete = json['athlete'];
    final team = athlete['team'];
    
    return LeaderModel(
      athleteId: athlete['id']?.toString() ?? '',
      displayName: athlete['displayName']?.toString() ?? '',
      headshot: athlete['headshot']?['href']?.toString(),
      teamName: team['displayName']?.toString() ?? team['abbreviation']?.toString() ?? '',
      teamLogo: (team['logos'] as List?)?.first['href']?.toString(),
      value: json['value']?.toString() ?? '0',
      displayValue: json['displayValue']?.toString() ?? '0',
      rank: json['rank']?.toString() ?? '0',
    );
  }
}

class LeagueLeadersModel extends LeagueLeadersEntity {
  const LeagueLeadersModel({
    required super.name,
    required super.displayName,
    required super.leaders,
  });

  factory LeagueLeadersModel.fromJson(Map<String, dynamic> json) {
    final leadersList = json['leaders'] as List? ?? [];
    return LeagueLeadersModel(
      name: json['name']?.toString() ?? '',
      displayName: json['displayName']?.toString() ?? '',
      leaders: leadersList.map((l) => LeaderModel.fromJson(l)).toList(),
    );
  }
}
