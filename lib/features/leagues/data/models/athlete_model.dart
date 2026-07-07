import 'package:goalhub/features/leagues/domain/entities/athlete_entity.dart';

class AthleteModel extends AthleteEntity {
  const AthleteModel({
    required super.id,
    required super.fullName,
    required super.displayName,
    required super.shortName,
    super.headshot,
    super.position,
    super.age,
    super.height,
    super.weight,
    super.jersey,
    super.nationality,
    super.birthPlace,
    super.teamName,
    super.teamLogo,
    super.clubName,
    super.clubLogo,
    super.stats,
  });

  factory AthleteModel.fromJson(Map<String, dynamic> json) {
    try {
      final athlete = json['athlete'] ?? json;
      
      // Stats parsing from site API (common/v3)
      final statsSummary = athlete['statsSummary']?['statistics'] as List?;
      List<AthleteStat>? parsedStats;
      if (statsSummary != null) {
        parsedStats = statsSummary.map((s) => AthleteStat(
          name: s['name']?.toString() ?? '',
          displayName: s['displayName']?.toString() ?? '',
          displayValue: s['displayValue']?.toString() ?? '0',
        )).toList();
      }

      // Try to get team info from various possible locations
      final teamData = athlete['team'] ?? athlete['defaultTeam'];
      String? teamName;
      String? teamLogo;
      
      if (teamData is Map) {
        teamName = teamData['displayName'] ?? teamData['name'];
        final logos = teamData['logos'] as List?;
        if (logos != null && logos.isNotEmpty) {
          teamLogo = logos[0]['href']?.toString();
        }
      }

      final model = AthleteModel(
        id: athlete['id']?.toString() ?? '',
        fullName: athlete['fullName']?.toString() ?? athlete['displayName']?.toString() ?? '',
        displayName: athlete['displayName']?.toString() ?? '',
        shortName: athlete['shortName']?.toString() ?? '',
        headshot: athlete['headshot'] is Map ? athlete['headshot']['href']?.toString() : null,
        position: athlete['position'] is Map ? athlete['position']['displayName']?.toString() : athlete['position']?.toString(),
        age: athlete['age']?.toString(),
        height: athlete['displayHeight']?.toString(),
        weight: athlete['displayWeight']?.toString(),
        jersey: athlete['jersey']?.toString(),
        nationality: athlete['citizenship']?.toString() ?? athlete['nationality']?.toString(),
        birthPlace: athlete['birthPlace'] is Map ? athlete['birthPlace']['city']?.toString() : athlete['birthPlace']?.toString(),
        teamName: teamName,
        teamLogo: teamLogo,
        clubName: athlete['club']?.toString() ?? teamName,
        clubLogo: teamLogo,
        stats: parsedStats,
      );
      return model;
    } catch (e, stack) {
      print('[GoalHub Debug] Error parsing athlete JSON: $e');
      print('[GoalHub Debug] StackTrace: $stack');
      rethrow;
    }
  }
}
