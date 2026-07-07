import 'package:goalhub/features/matches/data/models/details/match_event_model.dart';
import 'package:goalhub/features/matches/data/models/details/match_lineup_model.dart';
import 'package:goalhub/features/matches/data/models/details/match_stats_model.dart';
import 'package:goalhub/features/matches/domain/entities/details/match_detail_entity.dart';

class MatchDetailModel extends MatchDetailEntity {
  const MatchDetailModel({
    super.statistics,
    super.timeline,
    super.lineups,
    super.commentary,
    super.venue,
    super.referee,
    super.attendance,
    super.weather,
    super.broadcasts,
    super.odds,
    super.isPredictedLineup,
  });

  factory MatchDetailModel.fromSummaryJson(Map<String, dynamic> json) {
    // ... existing stats parsing ...
    final boxscore = json['boxscore'] ?? {};
    final statisticsJson = boxscore['statistics'] as List? ?? [];
    
    List<MatchStatsModel>? stats;
    if (statisticsJson.length >= 2) {
      final homeStats = statisticsJson[0]['statistics'] as List? ?? [];
      final awayStats = statisticsJson[1]['statistics'] as List? ?? [];
      
      stats = [];
      for (var i = 0; i < homeStats.length; i++) {
        final hStat = homeStats[i];
        final aStat = awayStats.firstWhere(
          (s) => s['name'] == hStat['name'],
          orElse: () => <String, dynamic>{},
        );
        if (aStat.isNotEmpty) {
          stats.add(MatchStatsModel.fromJson(hStat, aStat));
        }
      }
    } else if (boxscore['teams'] != null) {
      // Fallback: Some versions of the API put stats under boxscore -> teams
      final teams = boxscore['teams'] as List;
      if (teams.length >= 2) {
        final homeStats = teams[0]['statistics'] as List? ?? [];
        final awayStats = teams[1]['statistics'] as List? ?? [];
        
        stats = [];
        for (var hStat in homeStats) {
          final aStat = awayStats.firstWhere(
            (s) => s['name'] == hStat['name'],
            orElse: () => <String, dynamic>{},
          );
          if (aStat.isNotEmpty) {
            stats.add(MatchStatsModel.fromJson(hStat, aStat));
          }
        }
      }
    }

    final plays = json['plays'] as List? ?? [];
    final keyEvents = json['keyEvents'] as List? ?? [];
    
    // Combine plays and keyEvents, removing duplicates by ID if necessary
    // Usually keyEvents are a subset of plays with more detail for goals/cards
    final allEventsJson = plays.isNotEmpty ? plays : keyEvents;
    final timeline = allEventsJson.map((p) => MatchEventModel.fromJson(p)).toList();

    final rosterJson = json['rosters'] as List?;
    MatchLineupModel? lineups;
    if (rosterJson != null) {
      lineups = MatchLineupModel.fromJson(rosterJson);
    }

    final commentaryJson = json['commentary'] as List? ?? [];
    final commentary = commentaryJson.map((c) => c['text']?.toString() ?? '').toList();

    final gameInfo = json['gameInfo'] ?? {};
    final venue = gameInfo['venue']?['fullName'];
    final attendance = gameInfo['attendance']?.toString();
    
    final officialsJson = gameInfo['officials'] as List? ?? [];
    String? referee;
    if (officialsJson.isNotEmpty) {
      referee = officialsJson[0]['displayName'];
    }

    final weatherJson = json['weather'];
    String? weather;
    if (weatherJson != null) {
      weather = '${weatherJson['displayValue'] ?? ''} ${weatherJson['temperature'] ?? ''}°F';
    }

    final competitions = json['header']?['competitions'] as List? ?? [];
    final comp = competitions.isNotEmpty ? competitions[0] : {};
    
    final broadcastsJson = comp['broadcasts'] as List? ?? [];
    final broadcasts = broadcastsJson.map((b) => b['media']?['shortName']?.toString() ?? '').where((s) => s.isNotEmpty).toList();

    final oddsJson = json['pickcenter'] as List? ?? [];
    String? odds;
    if (oddsJson.isNotEmpty) {
      odds = oddsJson[0]['details'];
    }

    // Header info for scoreboard
    final header = json['header'] ?? {};
    final competitionsHeader = header['competitions'] as List? ?? [];
    final compHeader = competitionsHeader.isNotEmpty ? competitionsHeader[0] : {};
    
    final statusObj = compHeader['status'] ?? {};
    final statusStr = statusObj['type']?['shortDetail']?.toString() ?? statusObj['type']?['description']?.toString();
    final clockStr = statusObj['displayClock']?.toString();
    final state = statusObj['type']?['state']?.toString().toLowerCase();
    
    final competitors = compHeader['competitors'] as List? ?? [];
    String? hScore;
    String? aScore;
    
    for (var c in competitors) {
      if (c['homeAway'] == 'home') {
        hScore = c['score']?.toString();
      } else if (c['homeAway'] == 'away') {
        aScore = c['score']?.toString();
      }
    }

    return MatchDetailModel(
      statistics: stats,
      timeline: timeline,
      lineups: lineups,
      commentary: commentary,
      venue: venue,
      referee: referee,
      attendance: attendance,
      weather: weather,
      broadcasts: broadcasts,
      odds: odds,
      homeScore: hScore,
      awayScore: aScore,
      status: statusStr,
      displayClock: clockStr,
      isLive: state == 'in',
    );
  }
}
