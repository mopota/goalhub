import 'package:goalhub/features/news/domain/entities/news_article.dart';

abstract class NewsRepository {
  Future<List<NewsArticle>> getNews({String? leagueSlug, int limit = 20, String lang = 'en'});
}
