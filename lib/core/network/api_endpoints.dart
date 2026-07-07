class GoalHubApi {
  static const String siteBaseUrl = 'https://site.api.espn.com/apis/site/v2/sports';
  static const String coreBaseUrl = 'https://sports.core.api.espn.com/v2/sports';
  static const String newsBaseUrl = 'https://now.core.api.espn.com/v1/sports/news';

  static String leagues(String sport, {String lang = 'en'}) {
    return '$coreBaseUrl/$sport/leagues?limit=200&lang=$lang';
  }

  static String scoreboard(String sport, String league, {String? dates, String lang = 'en'}) {
    final String leaguePath = (league == 'all' || league.isEmpty) ? '' : '/$league';
    String url = '$siteBaseUrl/$sport$leaguePath/scoreboard?lang=$lang';
    if (dates != null) {
      url += '&dates=$dates';
    }
    return url;
  }

  static String news(String sport, {String? league, int limit = 20, String lang = 'en'}) {
    final leaguePath = league ?? 'all';
    return '$siteBaseUrl/$sport/$leaguePath/news?limit=$limit&lang=$lang';
  }

  static String matchSummary(String sport, String league, String eventId, {String lang = 'en'}) {
    return '$siteBaseUrl/$sport/$league/summary?event=$eventId&lang=$lang';
  }

  static String athlete(String sport, String league, String athleteId, {String lang = 'en'}) {
    return '$coreBaseUrl/$sport/leagues/$league/athletes/$athleteId?lang=$lang';
  }

  static String standings(String sport, String league, {String lang = 'en'}) {
    return 'https://site.api.espn.com/apis/v2/sports/$sport/$league/standings?lang=$lang';
  }
// ... rest of the endpoints ...

  static String event(String sport, String league, String eventId) {
    return '$coreBaseUrl/$sport/leagues/$league/events/$eventId';
  }

  static String competition(String sport, String league, String eventId, String competitionId) {
    return '$coreBaseUrl/$sport/leagues/$league/events/$eventId/competitions/$competitionId';
  }

  static String status(String sport, String league, String eventId, String competitionId) {
    return '$coreBaseUrl/$sport/leagues/$league/events/$eventId/competitions/$competitionId/status';
  }

  static String situation(String sport, String league, String eventId, String competitionId) {
    return '$coreBaseUrl/$sport/leagues/$league/events/$eventId/competitions/$competitionId/situation';
  }

  static String plays(String sport, String league, String eventId, String competitionId) {
    return '$coreBaseUrl/$sport/leagues/$league/events/$eventId/competitions/$competitionId/plays';
  }

  static String commentaries(String sport, String league, String eventId, String competitionId) {
    return '$coreBaseUrl/$sport/leagues/$league/events/$eventId/competitions/$competitionId/commentaries';
  }

  static String officials(String sport, String league, String eventId, String competitionId) {
    return '$coreBaseUrl/$sport/leagues/$league/events/$eventId/competitions/$competitionId/officials';
  }

  static String odds(String sport, String league, String eventId, String competitionId) {
    return '$coreBaseUrl/$sport/leagues/$league/events/$eventId/competitions/$competitionId/odds';
  }

  static String leaders(String sport, String league, String eventId, String competitionId, String teamId) {
    return '$coreBaseUrl/$sport/leagues/$league/events/$eventId/competitions/$competitionId/competitors/$teamId/leaders';
  }

  static String teamStatistics(String sport, String league, String eventId, String competitionId, String teamId) {
    return '$coreBaseUrl/$sport/leagues/$league/events/$eventId/competitions/$competitionId/competitors/$teamId/statistics';
  }

  static String roster(String sport, String league, String eventId, String competitionId, String teamId) {
    return '$coreBaseUrl/$sport/leagues/$league/events/$eventId/competitions/$competitionId/competitors/$teamId/roster';
  }

  static String playerStatistics(String sport, String league, String eventId, String competitionId, String teamId, String playerId, String statId) {
    return '$coreBaseUrl/$sport/leagues/$league/events/$eventId/competitions/$competitionId/competitors/$teamId/roster/$playerId/statistics/$statId';
  }
}
