import 'package:goalhub/features/leagues/domain/entities/league_entity.dart';
import 'package:logger/logger.dart';

class LeagueModel extends LeagueEntity {
  const LeagueModel({
    required super.id,
    required super.uid,
    required super.slug,
    required super.abbreviation,
    required super.name,
    required super.shortName,
    required super.displayName,
    super.logo,
    super.scoreboardRef,
    super.calendarRef,
    super.seasonsRef,
    super.eventsRef,
    super.selfRef,
  });

  factory LeagueModel.fromJson(Map<String, dynamic> json) {
    final logger = Logger();
    
    String? resolveRef(dynamic refObj) {
      if (refObj == null) return null;
      String? ref;
      if (refObj is Map) {
        ref = refObj['\$ref']?.toString();
      } else if (refObj is String) {
        ref = refObj;
      }
      
      if (ref != null) {
        return ref.replaceAll('.pvt', '.com');
      }
      return null;
    }

    final String selfRef = resolveRef(json['\$ref']) ?? '';
    final String id = json['id']?.toString() ?? '';
    
    // Extract the Core ID (e.g., eng.1) from the self $ref URL if possible
    String slug = json['slug']?.toString() ?? '';
    final uri = Uri.tryParse(selfRef);
    if (uri != null && uri.pathSegments.isNotEmpty) {
      final lastSegment = uri.pathSegments.last;
      if (lastSegment != 'leagues') {
        slug = lastSegment;
      }
    }
    
    if (slug.isEmpty) slug = id;

    final logos = json['logos'] as List? ?? [];
    String? logoUrl;
    if (logos.isNotEmpty) {
      logoUrl = logos[0]['href']?.toString();
    }

    String? scoreboardRef = resolveRef(json['scoreboard']);
    String? calendarRef = resolveRef(json['calendar']);
    
    if (scoreboardRef == null && selfRef.isNotEmpty) {
      scoreboardRef = '$selfRef/scoreboard'.replaceAll('?lang=en&region=us', '');
    }
    if (calendarRef == null && selfRef.isNotEmpty) {
      calendarRef = '$selfRef/calendar'.replaceAll('?lang=en&region=us', '');
    }

    if (json['name'] == null) {
      logger.w('League name returned null | ID=$id | Slug=$slug');
    }

    return LeagueModel(
      id: id,
      uid: json['uid']?.toString() ?? '',
      slug: slug,
      abbreviation: json['abbreviation']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Unknown League',
      shortName: json['shortName']?.toString() ?? '',
      displayName: json['displayName']?.toString() ?? '',
      logo: logoUrl,
      scoreboardRef: scoreboardRef,
      calendarRef: calendarRef,
      seasonsRef: resolveRef(json['seasons']),
      eventsRef: resolveRef(json['events']),
      selfRef: selfRef,
    );
  }
}
