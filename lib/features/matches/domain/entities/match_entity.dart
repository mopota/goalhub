import 'package:equatable/equatable.dart';

class MatchEntity extends Equatable {
  final String id;
  final DateTime date;
  final String status;
  final String displayClock;
  final String leagueName;
  final String leagueLogo;
  final String leagueSlug;
  final String homeTeamId;
  final String homeTeamName;
  final String homeTeamLogo;
  final String homeScore;
  final String awayTeamId;
  final String awayTeamName;
  final String awayTeamLogo;
  final String awayScore;
  final String? venue;
  final bool isLive;
  final bool isFinished;

  const MatchEntity({
    required this.id,
    required this.date,
    required this.status,
    required this.displayClock,
    required this.leagueName,
    required this.leagueLogo,
    required this.leagueSlug,
    required this.homeTeamId,
    required this.homeTeamName,
    required this.homeTeamLogo,
    required this.homeScore,
    required this.awayTeamId,
    required this.awayTeamName,
    required this.awayTeamLogo,
    required this.awayScore,
    this.venue,
    required this.isLive,
    required this.isFinished,
  });

  MatchEntity copyWith({
    String? status,
    String? leagueName,
    String? homeTeamName,
    String? awayTeamName,
    String? venue,
  }) {
    return MatchEntity(
      id: id,
      date: date,
      status: status ?? this.status,
      displayClock: displayClock,
      leagueName: leagueName ?? this.leagueName,
      leagueLogo: leagueLogo,
      leagueSlug: leagueSlug,
      homeTeamId: homeTeamId,
      homeTeamName: homeTeamName ?? this.homeTeamName,
      homeTeamLogo: homeTeamLogo,
      homeScore: homeScore,
      awayTeamId: awayTeamId,
      awayTeamName: awayTeamName ?? this.awayTeamName,
      awayTeamLogo: awayTeamLogo,
      awayScore: awayScore,
      venue: venue ?? this.venue,
      isLive: isLive,
      isFinished: isFinished,
    );
  }

  @override
  List<Object?> get props => [
        id,
        date,
        status,
        displayClock,
        leagueName,
        leagueLogo,
        leagueSlug,
        homeTeamId,
        homeTeamName,
        homeTeamLogo,
        homeScore,
        awayTeamId,
        awayTeamName,
        awayTeamLogo,
        awayScore,
        venue,
        isLive,
        isFinished,
      ];
}
