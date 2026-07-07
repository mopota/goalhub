import 'package:dio/dio.dart';
import 'package:goalhub/core/network/api_endpoints.dart';
import 'package:goalhub/features/matches/data/models/match_model.dart';
import 'package:goalhub/features/matches/data/models/details/match_detail_model.dart';

abstract class MatchRemoteDataSource {
  Future<List<MatchModel>> getMatches(String leagueSlug, {String? date, String lang = 'en'});
  Future<MatchDetailModel> getMatchDetails(String leagueSlug, String eventId, {String lang = 'en'});
  Future<String?> getLastFinishedMatchId(String leagueSlug, String teamId, {String lang = 'en'});
}

class MatchRemoteDataSourceImpl implements MatchRemoteDataSource {
  final Dio dio;

  MatchRemoteDataSourceImpl(this.dio);

  @override
  Future<String?> getLastFinishedMatchId(String leagueSlug, String teamId, {String lang = 'en'}) async {
    try {
      final url = 'https://site.api.espn.com/apis/site/v2/sports/soccer/$leagueSlug/teams/$teamId/schedule?lang=$lang';
      final response = await dio.get(url);
      if (response.statusCode == 200) {
        final events = response.data['events'] as List? ?? [];
        final finishedEvents = events.where((e) {
          final status = e['status']?['type']?['state']?.toString().toLowerCase();
          return status == 'post';
        }).toList();
        
        if (finishedEvents.isNotEmpty) {
          // Events are usually chronological, take the last one
          return finishedEvents.last['id']?.toString();
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  @override
  Future<List<MatchModel>> getMatches(String leagueSlug, {String? date, String lang = 'en'}) async {
    try {
      final isToday = date == null || date.contains(DateTime.now().year.toString());
      final cacheBuster = isToday ? '&_t=${DateTime.now().millisecondsSinceEpoch}' : '';
      
      final response = await dio.get(GoalHubApi.scoreboard('soccer', leagueSlug, dates: date, lang: lang) + cacheBuster);
      
      if (response.statusCode == 200) {
        final data = response.data;
        final leagues = data['leagues'] as List? ?? [];
        final league = leagues.isNotEmpty ? leagues[0] : {};
        final leagueName = league['name'] ?? '';
        
        String extractLeagueLogo(Map league) {
          final logos = league['logos'] as List?;
          if (logos != null && logos.isNotEmpty) {
            final first = logos[0];
            if (first is String) return first;
            if (first is Map) return first['href']?.toString() ?? '';
          }
          return '';
        }
        
        final leagueLogo = extractLeagueLogo(league);

        final events = data['events'] as List? ?? [];
        return events.map((json) => MatchModel.fromJson(json, leagueName, leagueLogo, leagueSlug)).toList();
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
  Future<MatchDetailModel> getMatchDetails(String leagueSlug, String eventId, {String lang = 'en'}) async {
    try {
      final cacheBuster = '&_t=${DateTime.now().millisecondsSinceEpoch}';
      final response = await dio.get(GoalHubApi.matchSummary('soccer', leagueSlug, eventId, lang: lang) + cacheBuster);
      
      if (response.statusCode == 200) {
        return MatchDetailModel.fromSummaryJson(response.data);
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
