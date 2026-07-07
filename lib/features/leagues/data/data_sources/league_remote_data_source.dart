import 'package:dio/dio.dart';
import 'package:goalhub/core/network/api_endpoints.dart';
import 'package:goalhub/features/leagues/data/models/athlete_model.dart';
import 'package:goalhub/features/leagues/data/models/leader_model.dart';
import 'package:goalhub/features/leagues/data/models/league_model.dart';
import 'package:goalhub/features/leagues/data/models/standing_model.dart';
import 'package:goalhub/features/leagues/data/models/team_model.dart';

abstract class LeagueRemoteDataSource {
  Future<List<LeagueModel>> discoverLeagues(String sport, {String lang = 'en'});
  Future<LeagueModel> getLeagueDetails(String url, {String lang = 'en'});
  Future<List<StandingModel>> getStandings(String leagueId, {String lang = 'en'});
  Future<List<LeagueLeadersModel>> getLeagueLeaders(String leagueId, {String lang = 'en'});
  Future<AthleteModel> getAthleteDetails(String athleteId, {String lang = 'en'});
  Future<TeamModel> getTeamDetails(String leagueId, String teamId, {String lang = 'en'});
  Future<Map<String, dynamic>> search(String query, {String lang = 'en'});
}

class LeagueRemoteDataSourceImpl implements LeagueRemoteDataSource {
  final Dio dio;

  LeagueRemoteDataSourceImpl(this.dio);

  @override
  Future<List<LeagueModel>> discoverLeagues(String sport, {String lang = 'en'}) async {
    try {
      final response = await dio.get(GoalHubApi.leagues(sport, lang: lang));
      if (response.statusCode == 200) {
        final items = response.data['items'] as List? ?? [];
        final List<Future<LeagueModel>> futures = [];

        for (var item in items) {
          String? ref = item['\$ref']?.toString();
          if (ref != null) {
            futures.add(getLeagueDetails(ref.replaceAll('.pvt', '.com'), lang: lang));
          }
        }

        return await Future.wait(futures);
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          type: DioExceptionType.badResponse,
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<LeagueModel> getLeagueDetails(String url, {String lang = 'en'}) async {
    try {
      final String connector = url.contains('?') ? '&' : '?';
      final response = await dio.get('$url${connector}lang=$lang');
      if (response.statusCode == 200) {
        return LeagueModel.fromJson(response.data);
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          type: DioExceptionType.badResponse,
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<List<StandingModel>> getStandings(String leagueId, {String lang = 'en'}) async {
    print('[GoalHub Debug] === START Fetching Standings ===');
    try {
      final cacheBuster = '&_t=${DateTime.now().millisecondsSinceEpoch}';
      final url = GoalHubApi.standings('soccer', leagueId, lang: lang) + cacheBuster;
      print('[GoalHub Debug] URL: $url');
      final response = await dio.get(url);
      
      if (response.statusCode == 200) {
        final List<StandingModel> allStandings = [];
        final data = response.data;
        
        void processStandings(dynamic standingsData, {String? groupName}) {
          if (standingsData == null) return;

          // If it's a list, process each element
          if (standingsData is List) {
            for (var item in standingsData) {
              processStandings(item, groupName: groupName);
            }
            return;
          }

          // Case 1: children (nested groups like World Cup or Champions League)
          if (standingsData['children'] != null) {
            final children = standingsData['children'] as List;
            for (var child in children) {
              final childName = child['name'] ?? child['displayName'] ?? groupName;
              processStandings(child, groupName: childName);
            }
          } 
          // Case 2: groups (alternative field name for children)
          else if (standingsData['groups'] != null) {
            final groups = standingsData['groups'] as List;
            for (var group in groups) {
              final groupNameFromData = group['name'] ?? group['displayName'] ?? groupName;
              processStandings(group, groupName: groupNameFromData);
            }
          }
          // Case 3: entries (the actual teams)
          else if (standingsData['entries'] != null) {
            final entries = standingsData['entries'] as List;
            final currentGroup = groupName ?? standingsData['name'] ?? standingsData['displayName'];
            for (var entry in entries) {
              allStandings.add(StandingModel.fromJson(entry, groupName: currentGroup));
            }
          }
          // Case 4: standalone standings field
          else if (standingsData['standings'] != null) {
             processStandings(standingsData['standings'], groupName: groupName);
          }
        }

        processStandings(data['standings']);
        
        // If we found nothing under 'standings', check top level 'children' or 'entries'
        if (allStandings.isEmpty) {
          processStandings(data);
        }
        
        print('[GoalHub Debug] === FINISH Standings Success (${allStandings.length} items) ===');
        return allStandings;
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          type: DioExceptionType.badResponse,
        );
      }
    } catch (e, stack) {
      print('[GoalHub Debug] !!! ERROR in getStandings: $e');
      print('[GoalHub Debug] StackTrace: $stack');
      rethrow;
    }
  }

  @override
  Future<List<LeagueLeadersModel>> getLeagueLeaders(String leagueId, {String lang = 'en'}) async {
    try {
      final cacheBuster = '&_t=${DateTime.now().millisecondsSinceEpoch}';
      final url = 'https://site.web.api.espn.com/apis/common/v3/sports/soccer/$leagueId/statistics/byathlete?lang=$lang$cacheBuster';
      final response = await dio.get(url);
      if (response.statusCode == 200) {
        final List<LeagueLeadersModel> allLeaders = [];
        final categories = response.data['categories'] as List? ?? [];
        for (var category in categories) {
          allLeaders.add(LeagueLeadersModel.fromJson(category));
        }
        return allLeaders;
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          type: DioExceptionType.badResponse,
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<AthleteModel> getAthleteDetails(String athleteId, {String lang = 'en'}) async {
    print('[GoalHub Debug] === START Fetching Athlete Details ===');
    print('[GoalHub Debug] Athlete ID: $athleteId');
    try {
      final url = 'https://site.web.api.espn.com/apis/common/v3/sports/soccer/athletes/$athleteId?lang=$lang';
      print('[GoalHub Debug] Fetching from: $url');
      final response = await dio.get(url);
      if (response.statusCode == 200) {
        print('[GoalHub Debug] Athlete data received successfully');
        return AthleteModel.fromJson(response.data);
      } else {
        print('[GoalHub Debug] Athlete API Error: ${response.statusCode}');
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          type: DioExceptionType.badResponse,
        );
      }
    } catch (e, stack) {
      print('[GoalHub Debug] !!! ERROR in getAthleteDetails: $e');
      print('[GoalHub Debug] StackTrace: $stack');
      rethrow;
    }
  }

  @override
  Future<TeamModel> getTeamDetails(String leagueId, String teamId, {String lang = 'en'}) async {
    print('[GoalHub Debug] === START Fetching Team Details ===');
    print('[GoalHub Debug] League: $leagueId, Team: $teamId');
    try {
      final rosterUrl = 'https://site.api.espn.com/apis/site/v2/sports/soccer/$leagueId/teams/$teamId/roster?lang=$lang';
      final leadersUrl = 'https://site.api.espn.com/apis/site/v2/sports/soccer/$leagueId/teams/$teamId/leaders?lang=$lang';
      final mainUrl = 'https://site.api.espn.com/apis/site/v2/sports/soccer/$leagueId/teams/$teamId?lang=$lang';
      final scheduleUrl = 'https://site.api.espn.com/apis/site/v2/sports/soccer/$leagueId/teams/$teamId/schedule?lang=$lang';
      
      print('[GoalHub Debug] Parallel fetching from 4 endpoints...');
      final responses = await Future.wait([
        dio.get(rosterUrl).then((r) { print('[GoalHub Debug] Roster data received'); return r; }),
        dio.get(leadersUrl).catchError((e) { print('[GoalHub Debug] Leaders not found (404)'); return Response(requestOptions: RequestOptions(path: ''), statusCode: 404); }),
        dio.get(mainUrl).then((r) { print('[GoalHub Debug] Main team data received'); return r; }),
        dio.get(scheduleUrl).then((r) { print('[GoalHub Debug] Schedule/Matches data received'); return r; }),
      ]);

      final rosterData = responses[0].data;
      final leadersData = responses[1].statusCode == 200 ? responses[1].data : null;
      final mainData = responses[2].statusCode == 200 ? responses[2].data : null;
      final scheduleData = responses[3].statusCode == 200 ? responses[3].data : null;
      
      if (leadersData != null && leadersData['leaders'] != null) {
        rosterData['leaders'] = leadersData['leaders'];
      }

      if (mainData != null && mainData['team'] != null) {
        final team = mainData['team'];
        rosterData['venue'] = team['venue'];
        if (rosterData['coach'] == null && team['coach'] != null) {
          rosterData['coach'] = team['coach'];
        }
      }

      if (scheduleData != null && scheduleData['events'] != null) {
        final events = scheduleData['events'] as List;
        final now = DateTime.now();
        
        final recent = events.where((e) {
          final date = DateTime.tryParse(e['date'] ?? '');
          return date != null && date.isBefore(now);
        }).toList().reversed.take(10).toList();

        final upcoming = events.where((e) {
          final date = DateTime.tryParse(e['date'] ?? '');
          return date != null && date.isAfter(now);
        }).toList().take(10).toList();

        rosterData['recentMatches'] = recent;
        rosterData['upcomingMatches'] = upcoming;
        
        print('[GoalHub Debug] Processed ${recent.length} recent and ${upcoming.length} upcoming matches');
      }

      print('[GoalHub Debug] === FINISH Team Details Success ===');
      return TeamModel.fromJson(rosterData);
    } catch (e, stack) {
      print('[GoalHub Debug] !!! ERROR in getTeamDetails: $e');
      print('[GoalHub Debug] StackTrace: $stack');
      rethrow;
    }
  }

  @override
  Future<Map<String, dynamic>> search(String query, {String lang = 'en'}) async {
    try {
      final url = 'https://site.web.api.espn.com/apis/search/v2?query=$query&limit=20&lang=$lang';
      final response = await dio.get(url);
      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          type: DioExceptionType.badResponse,
        );
      }
    } catch (e) {
      rethrow;
    }
  }
}
