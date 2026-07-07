import 'package:equatable/equatable.dart';

class NewsArticle extends Equatable {
  final String id;
  final String title;
  final String description;
  final String imageUrl;
  final DateTime publishedAt;
  final String? source;
  final String url;

  const NewsArticle({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.publishedAt,
    this.source,
    required this.url,
  });

  NewsArticle copyWith({
    String? title,
    String? description,
  }) {
    return NewsArticle(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      imageUrl: imageUrl,
      publishedAt: publishedAt,
      source: source,
      url: url,
    );
  }

  @override
  List<Object?> get props => [id, title, description, imageUrl, publishedAt, source, url];
}
