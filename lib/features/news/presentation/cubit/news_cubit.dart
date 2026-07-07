import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goalhub/core/settings/settings_cubit.dart';
import 'package:goalhub/core/utils/translation_service.dart';
import 'package:goalhub/features/news/domain/repositories/news_repository.dart';
import 'package:goalhub/features/news/presentation/cubit/news_state.dart';

import '../../domain/entities/news_article.dart';

class NewsCubit extends Cubit<NewsState> {
  final NewsRepository repository;
  final SettingsCubit settingsCubit;
  final TranslationService translationService;
  StreamSubscription? _settingsSubscription;

  NewsCubit(this.repository, this.settingsCubit, this.translationService) : super(NewsInitial()) {
    _settingsSubscription = settingsCubit.stream.listen((state) {
      loadNews();
    });
  }

  Future<void> loadNews() async {
    print('[GoalHub Debug] Loading news...');
    emit(NewsLoading());
    try {
      String lang = settingsCubit.state.language;
      // ESPN news API usually supports en, es, pt. If user selected something else like ar, default to en for news.
      String fetchLang = lang;
      if (fetchLang != 'en' && fetchLang != 'es' && fetchLang != 'pt') {
        fetchLang = 'en';
      }
      
      print('[GoalHub Debug] Fetching news from repository (lang: $fetchLang)');
      final articles = await repository.getNews(lang: fetchLang);
      print('[GoalHub Debug] Received ${articles.length} news articles');
      
      // Auto-translate if app language is Arabic and API returned English (or other)
      if (lang == 'ar' && fetchLang != 'ar' && articles.isNotEmpty) {
        print('[GoalHub Debug] Starting batch translation for news');
        final List<String> textsToTranslate = [];
        for (var article in articles) {
          textsToTranslate.add(article.title);
          textsToTranslate.add(article.description);
        }

        try {
          final translatedTexts = await translationService.translateList(textsToTranslate);
          print('[GoalHub Debug] News translation completed');

          final List<NewsArticle> translatedArticles = [];
          for (int i = 0; i < articles.length; i++) {
            translatedArticles.add(articles[i].copyWith(
              title: translatedTexts[i * 2],
              description: translatedTexts[i * 2 + 1],
            ));
          }
          emit(NewsLoaded(translatedArticles));
        } catch (e) {
          print('[GoalHub Debug] News translation FAILED: $e. Falling back to original.');
          emit(NewsLoaded(articles));
        }
      } else {
        emit(NewsLoaded(articles));
      }
    } catch (e) {
      print('[GoalHub Debug] Error loading news: $e');
      emit(NewsError(e.toString()));
    }
  }

  @override
  Future<void> close() {
    _settingsSubscription?.cancel();
    return super.close();
  }
}
