import 'package:dio/dio.dart';
import 'package:goalhub/core/network/api_endpoints.dart';
import 'package:goalhub/features/news/data/models/news_model.dart';

abstract class NewsRemoteDataSource {
  Future<List<NewsModel>> getNews({String? leagueSlug, int limit = 20, String lang = 'en'});
}

class NewsRemoteDataSourceImpl implements NewsRemoteDataSource {
  final Dio dio;

  NewsRemoteDataSourceImpl(this.dio);

  @override
  Future<List<NewsModel>> getNews({String? leagueSlug, int limit = 20, String lang = 'en'}) async {
    try {
      final String url = GoalHubApi.news('soccer', league: leagueSlug, limit: limit, lang: lang);

      final response = await dio.get(url);
      if (response.statusCode == 200) {
        final List articles = response.data['articles'] ?? [];
        return articles.map((json) => NewsModel.fromJson(json)).toList();
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
