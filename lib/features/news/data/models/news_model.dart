import 'package:goalhub/features/news/domain/entities/news_article.dart';

class NewsModel extends NewsArticle {
  const NewsModel({
    required super.id,
    required super.title,
    required super.description,
    required super.imageUrl,
    required super.publishedAt,
    super.source,
    required super.url,
  });

  factory NewsModel.fromJson(Map<String, dynamic> json) {
    String extractImageUrl(Map<String, dynamic> json) {
      final images = json['images'] as List? ?? [];
      if (images.isNotEmpty) {
        final first = images[0];
        if (first is String) return first;
        if (first is Map) {
          return first['url']?.toString() ?? first['href']?.toString() ?? '';
        }
      }
      return '';
    }

    final imageUrl = extractImageUrl(json);
    
    final links = json['links'] ?? {};
    final webLink = links['web'] ?? {};
    final url = webLink['href'] ?? json['url']?.toString() ?? '';

    return NewsModel(
      id: json['dataSourceIdentifier'] ?? json['id']?.toString() ?? '',
      title: json['headline'] ?? json['title'] ?? '',
      description: json['description'] ?? '',
      imageUrl: imageUrl,
      publishedAt: DateTime.tryParse(json['published'] ?? '') ?? DateTime.now(),
      source: 'GoalHub News',
      url: url,
    );
  }
}
