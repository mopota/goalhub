import 'package:goalhub/features/news/data/data_sources/news_remote_data_source.dart';
import 'package:goalhub/features/news/domain/entities/news_article.dart';
import 'package:goalhub/features/news/domain/repositories/news_repository.dart';

class NewsRepositoryImpl implements NewsRepository {
  final NewsRemoteDataSource remoteDataSource;

  NewsRepositoryImpl(this.remoteDataSource);

  @override
  Future<List<NewsArticle>> getNews({String? leagueSlug, int limit = 20, String lang = 'en'}) async {
    return await remoteDataSource.getNews(leagueSlug: leagueSlug, limit: limit, lang: lang);
  }
}
