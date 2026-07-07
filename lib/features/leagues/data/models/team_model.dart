import 'package:goalhub/features/leagues/data/models/athlete_model.dart';
import 'package:goalhub/features/leagues/data/models/leader_model.dart';
import 'package:goalhub/features/leagues/domain/entities/team_entity.dart';
import 'package:goalhub/features/matches/data/models/match_model.dart';

class TeamModel extends TeamEntity {
  const TeamModel({
    required super.id,
    required super.name,
    required super.displayName,
    super.logo,
    super.location,
    super.roster,
    super.coach,
    super.venue,
    super.venueImage,
    super.leaders,
    super.recentMatches,
    super.upcomingMatches,
  });

  factory TeamModel.fromJson(Map<String, dynamic> json) {
    final team = json['team'] ?? json;
    
    // roster and athletes might come from /roster endpoint
    final athletes = json['athletes'] as List? ?? [];
    
    // coach might come from /roster endpoint (List) or team object (Object/List)
    String? coach;
    final coachData = json['coach'] ?? team['coach'];
    if (coachData is List && coachData.isNotEmpty) {
      coach = '${coachData.first['firstName'] ?? ''} ${coachData.first['lastName'] ?? ''}'.trim();
    } else if (coachData is Map) {
      coach = '${coachData['firstName'] ?? ''} ${coachData['lastName'] ?? ''}'.trim();
    }

    final venue = json['venue'] ?? team['venue'];
    final venueName = venue?['fullName']?.toString();
    final venueLogo = (venue?['images'] as List?)?.first?['href']?.toString();

    // leaders might come from /leaders endpoint
    final categoriesList = json['leaders'] as List?;
    final List<LeagueLeadersModel> parsedLeaders = [];
    if (categoriesList != null) {
      for (var category in categoriesList) {
        final stats = category['stats'] as List?;
        if (stats != null) {
          for (var stat in stats) {
            parsedLeaders.add(LeagueLeadersModel.fromJson({
              'name': stat['name'],
              'displayName': stat['displayName'],
              'leaders': stat['leaders'],
            }));
          }
        }
      }
    }

    // Parse matches if they exist in the JSON
    final List<MatchModel>? recentMatches = (json['recentMatches'] as List?)
        ?.map((m) => MatchModel.fromJson(m, '', '', 'soccer'))
        .toList();
    final List<MatchModel>? upcomingMatches = (json['upcomingMatches'] as List?)
        ?.map((m) => MatchModel.fromJson(m, '', '', 'soccer'))
        .toList();

    return TeamModel(
      id: team['id']?.toString() ?? '',
      name: team['name']?.toString() ?? '',
      displayName: team['displayName']?.toString() ?? '',
      location: team['location']?.toString(),
      logo: (team['logos'] as List?)?.first['href']?.toString(),
      coach: coach?.isNotEmpty == true ? coach : null,
      venue: venueName,
      venueImage: venueLogo,
      roster: athletes.map((a) => AthleteModel.fromJson(a)).toList(),
      leaders: parsedLeaders.isNotEmpty ? parsedLeaders : null,
      recentMatches: recentMatches,
      upcomingMatches: upcomingMatches,
    );
  }
}
