import 'package:equatable/equatable.dart';
import 'package:goalhub/features/matches/domain/entities/details/match_event_entity.dart';
import 'package:goalhub/features/matches/domain/entities/details/match_lineup_entity.dart';
import 'package:goalhub/features/matches/domain/entities/details/match_stats_entity.dart';

class MatchDetailEntity extends Equatable {
  final List<MatchStatsEntity>? statistics;
  final List<MatchEventEntity>? timeline;
  final MatchLineupEntity? lineups;
  final List<String>? commentary;
  final String? venue;
  final String? referee;
  final String? attendance;
  final String? weather;
  final List<String>? broadcasts;
  final String? odds;
  final bool isPredictedLineup;
  
  // New fields for real-time scoreboard updates
  final String? homeScore;
  final String? awayScore;
  final String? status;
  final String? displayClock;
  final bool isLive;

  const MatchDetailEntity({
    this.statistics,
    this.timeline,
    this.lineups,
    this.commentary,
    this.venue,
    this.referee,
    this.attendance,
    this.weather,
    this.broadcasts,
    this.odds,
    this.isPredictedLineup = false,
    this.homeScore,
    this.awayScore,
    this.status,
    this.displayClock,
    this.isLive = false,
  });

  MatchDetailEntity copyWith({
    List<MatchStatsEntity>? statistics,
    List<MatchEventEntity>? timeline,
    MatchLineupEntity? lineups,
    List<String>? commentary,
    String? venue,
    String? referee,
    String? weather,
    String? odds,
    bool? isPredictedLineup,
    String? homeScore,
    String? awayScore,
    String? status,
    String? displayClock,
    bool? isLive,
  }) {
    return MatchDetailEntity(
      statistics: statistics ?? this.statistics,
      timeline: timeline ?? this.timeline,
      lineups: lineups ?? this.lineups,
      commentary: commentary ?? this.commentary,
      venue: venue ?? this.venue,
      referee: referee ?? this.referee,
      attendance: attendance,
      weather: weather ?? this.weather,
      broadcasts: broadcasts,
      odds: odds ?? this.odds,
      isPredictedLineup: isPredictedLineup ?? this.isPredictedLineup,
      homeScore: homeScore ?? this.homeScore,
      awayScore: awayScore ?? this.awayScore,
      status: status ?? this.status,
      displayClock: displayClock ?? this.displayClock,
      isLive: isLive ?? this.isLive,
    );
  }

  @override
  List<Object?> get props => [
    statistics, timeline, lineups, commentary, venue, referee, attendance,
    weather, broadcasts, odds, isPredictedLineup,
    homeScore, awayScore, status, displayClock, isLive
  ];
}
