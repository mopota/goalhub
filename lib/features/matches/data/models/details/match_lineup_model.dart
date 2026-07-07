import 'package:goalhub/features/matches/domain/entities/details/match_lineup_entity.dart';

class MatchLineupModel extends MatchLineupEntity {
  const MatchLineupModel({
    super.homeTeamId,
    required super.homeStarters,
    required super.homeBench,
    super.homeCoach,
    super.homeFormation,
    super.awayTeamId,
    required super.awayStarters,
    required super.awayBench,
    super.awayCoach,
    super.awayFormation,
  });

  factory MatchLineupModel.fromJson(List<dynamic> rosters) {
    MatchLineupSide parseSide(Map<String, dynamic> roster) {
      final entries = roster['roster'] as List? ?? [];
      final starters = entries
          .where((e) => e['starter'] == true)
          .map((e) => MatchPlayerModel.fromJson(e))
          .toList();
      final bench = entries
          .where((e) => e['starter'] == false)
          .map((e) => MatchPlayerModel.fromJson(e))
          .toList();
      
      final coachingStaff = roster['coachingStaff'] as List? ?? [];
      String? coach;
      if (coachingStaff.isNotEmpty) {
        coach = coachingStaff[0]['athlete']?['displayName'];
      }

      return MatchLineupSide(
        starters: starters,
        bench: bench,
        coach: coach,
        formation: roster['formation'],
      );
    }

    final homeRoster = rosters.firstWhere((r) => r['homeAway'] == 'home', orElse: () => {});
    final awayRoster = rosters.firstWhere((r) => r['homeAway'] == 'away', orElse: () => {});

    final homeSide = parseSide(homeRoster);
    final awaySide = parseSide(awayRoster);

    return MatchLineupModel(
      homeTeamId: homeRoster['team']?['id']?.toString(),
      homeStarters: homeSide.starters,
      homeBench: homeSide.bench,
      homeCoach: homeSide.coach,
      homeFormation: homeSide.formation,
      awayTeamId: awayRoster['team']?['id']?.toString(),
      awayStarters: awaySide.starters,
      awayBench: awaySide.bench,
      awayCoach: awaySide.coach,
      awayFormation: awaySide.formation,
    );
  }
}

class MatchLineupSide {
  final List<MatchPlayerEntity> starters;
  final List<MatchPlayerEntity> bench;
  final String? coach;
  final String? formation;

  MatchLineupSide({
    required this.starters,
    required this.bench,
    this.coach,
    this.formation,
  });
}

class MatchPlayerModel extends MatchPlayerEntity {
  const MatchPlayerModel({
    required super.id,
    required super.name,
    required super.jersey,
    required super.position,
    super.positionAbbreviation,
    super.photo,
    super.x,
    super.y,
    super.isCaptain,
    super.rating,
    super.stats,
  });

  factory MatchPlayerModel.fromJson(Map<String, dynamic> json) {
    final athlete = json['athlete'] ?? {};
    final id = athlete['id']?.toString() ?? '';
    final position = json['position'] ?? {};
    
    // Attempt to get coordinates if available
    double? xVal;
    double? yVal;
    if (json['position'] != null) {
      xVal = json['x']?.toDouble() ?? position['x']?.toDouble();
      yVal = json['y']?.toDouble() ?? position['y']?.toDouble();
    }

    final photoUrl = null;

    // Parse statistics if available
    final Map<String, String> parsedStats = {};
    final statsList = json['statistics'] as List? ?? [];
    if (statsList.isNotEmpty) {
      for (var statCategory in statsList) {
        final statsItems = statCategory['stats'] as List? ?? [];
        for (var statItem in statsItems) {
          final name = statItem['name']?.toString();
          final displayValue = statItem['displayValue']?.toString();
          if (name != null && displayValue != null) {
            parsedStats[name] = displayValue;
          }
        }
      }
    }

    return MatchPlayerModel(
      id: id,
      name: athlete['displayName'] ?? '',
      jersey: json['jersey'] ?? '',
      position: position['displayName'] ?? '',
      positionAbbreviation: position['abbreviation'],
      photo: photoUrl,
      x: xVal,
      y: yVal,
      isCaptain: json['captain'] == true,
      rating: json['rating']?.toDouble() ?? json['value']?.toDouble(),
      stats: parsedStats.isNotEmpty ? parsedStats : null,
    );
  }
}
