import 'package:goalhub/features/matches/domain/entities/details/match_stats_entity.dart';

class MatchStatsModel extends MatchStatsEntity {
  const MatchStatsModel({
    required super.name,
    required super.displayName,
    required super.homeValue,
    required super.awayValue,
    required super.homePercent,
    required super.awayPercent,
  });

  factory MatchStatsModel.fromJson(Map<String, dynamic> homeJson, Map<String, dynamic> awayJson) {
    final name = homeJson['name'] ?? '';
    var displayName = homeJson['displayName'] ?? '';
    if (displayName.toString().isEmpty) {
      displayName = name;
    }
    final homeValue = homeJson['displayValue'] ?? '0';
    final awayValue = awayJson['displayValue'] ?? '0';

    double parsePercent(String? value) {
      if (value == null) return 0.0;
      final cleaned = value.replaceAll('%', '');
      return (double.tryParse(cleaned) ?? 0.0) / 100.0;
    }

    // Possession needs special handling if it's in %
    double hP = 0.5;
    double aP = 0.5;
    
    if (name.toLowerCase().contains('possession')) {
      hP = parsePercent(homeValue);
      aP = parsePercent(awayValue);
    } else {
      final hV = double.tryParse(homeValue) ?? 0.0;
      final aV = double.tryParse(awayValue) ?? 0.0;
      final total = hV + aV;
      if (total > 0) {
        hP = hV / total;
        aP = aV / total;
      }
    }

    return MatchStatsModel(
      name: name,
      displayName: displayName,
      homeValue: homeValue,
      awayValue: awayValue,
      homePercent: hP,
      awayPercent: aP,
    );
  }
}
