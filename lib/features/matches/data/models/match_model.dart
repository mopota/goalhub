import 'package:goalhub/features/matches/domain/entities/match_entity.dart';

class MatchModel extends MatchEntity {
  const MatchModel({
    required super.id,
    required super.date,
    required super.status,
    required super.displayClock,
    required super.leagueName,
    required super.leagueLogo,
    required super.leagueSlug,
    required super.homeTeamId,
    required super.homeTeamName,
    required super.homeTeamLogo,
    required super.homeScore,
    required super.awayTeamId,
    required super.awayTeamName,
    required super.awayTeamLogo,
    required super.awayScore,
    super.venue,
    required super.isLive,
    required super.isFinished,
  });

  factory MatchModel.fromJson(Map<String, dynamic> json, String fallbackLeagueName, String fallbackLeagueLogo, String leagueSlug) {
    final id = json['id'] ?? '';
    final dateStr = json['date'] ?? '';
    final date = DateTime.tryParse(dateStr) ?? DateTime.now();
    
    final statusObj = json['status'] ?? {};
    final type = statusObj['type'] ?? {};
    final state = type['state']?.toString().toLowerCase() ?? 'pre';
    final completed = type['completed'] == true;
    final description = type['description']?.toString() ?? '';
    
    // Core Status Logic
    final isLive = state == 'in';
    final isFinished = state == 'post' || completed || description.toLowerCase().contains('final');

    // status Label: Used in the card header
    String statusLabel = description;
    if (isFinished) {
      statusLabel = 'FT';
    } else if (isLive) {
      if (description.toLowerCase().contains('halftime')) {
        statusLabel = 'HT';
      } else {
        statusLabel = 'LIVE';
      }
    } else {
      statusLabel = 'Upcoming';
    }

    final displayClock = statusObj['displayClock']?.toString() ?? '';

    final competitions = json['competitions'] as List? ?? [];
    final comp = competitions.isNotEmpty ? competitions[0] : {};
    
    // Try to extract league specific info if available in the event JSON
    // Sometimes ESPN includes 'league' or 'season' info in the event itself
    final leagueObj = json['league'] ?? {};
    final String actualLeagueName = leagueObj['name'] ?? fallbackLeagueName;
    
    String extractLeagueLogo(Map league) {
      final logos = league['logos'] as List?;
      if (logos != null && logos.isNotEmpty) {
        final first = logos[0];
        if (first is String) return first;
        if (first is Map) return first['href']?.toString() ?? '';
      }
      return fallbackLeagueLogo;
    }
    final String actualLeagueLogo = extractLeagueLogo(leagueObj);

    final competitors = comp['competitors'] as List? ?? [];
    final homeCompetitor = competitors.firstWhere(
      (c) => c['homeAway']?.toString().toLowerCase() == 'home', 
      orElse: () => {}
    );
    final awayCompetitor = competitors.firstWhere(
      (c) => c['homeAway']?.toString().toLowerCase() == 'away', 
      orElse: () => {}
    );

    final homeTeam = homeCompetitor['team'] ?? {};
    final awayTeam = awayCompetitor['team'] ?? {};

    String extractLogo(Map team, String teamId) {
      if (team['logo'] != null && team['logo'].toString().isNotEmpty) {
        return team['logo'].toString();
      }
      final logos = team['logos'] as List?;
      if (logos != null && logos.isNotEmpty) {
        final firstLogo = logos[0];
        if (firstLogo is String) return firstLogo;
        if (firstLogo is Map) return firstLogo['href']?.toString() ?? '';
      }
      return '';
    }

    final venueObj = comp['venue'] ?? {};
    final venue = venueObj['fullName'];

    final homeTeamId = homeTeam['id']?.toString() ?? '';
    final awayTeamId = awayTeam['id']?.toString() ?? '';

    String extractScore(dynamic scoreData) {
      if (scoreData == null) return '0';
      if (scoreData is Map) {
        if (scoreData.containsKey('displayValue')) {
          return scoreData['displayValue'].toString();
        }
        if (scoreData.containsKey('value')) {
          return scoreData['value'].toString();
        }
        return '0'; // Likely a {$ref: ...} object
      }
      final s = scoreData.toString();
      return s.contains(r'$ref') ? '0' : s;
    }

    return MatchModel(
      id: id,
      date: date,
      status: statusLabel,
      displayClock: displayClock,
      leagueName: actualLeagueName,
      leagueLogo: actualLeagueLogo,
      leagueSlug: leagueSlug,
      homeTeamId: homeTeamId,
      homeTeamName: homeTeam['displayName'] ?? homeTeam['name'] ?? 'Home',
      homeTeamLogo: extractLogo(homeTeam, homeTeamId),
      homeScore: extractScore(homeCompetitor['score']),
      awayTeamId: awayTeamId,
      awayTeamName: awayTeam['displayName'] ?? awayTeam['name'] ?? 'Away',
      awayTeamLogo: extractLogo(awayTeam, awayTeamId),
      awayScore: extractScore(awayCompetitor['score']),
      venue: venue,
      isLive: isLive,
      isFinished: isFinished,
    );
  }
}
