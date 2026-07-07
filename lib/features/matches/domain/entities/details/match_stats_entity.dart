import 'package:equatable/equatable.dart';

class MatchStatsEntity extends Equatable {
  final String name;
  final String displayName;
  final String homeValue;
  final String awayValue;
  final double homePercent;
  final double awayPercent;

  const MatchStatsEntity({
    required this.name,
    required this.displayName,
    required this.homeValue,
    required this.awayValue,
    required this.homePercent,
    required this.awayPercent,
  });

  MatchStatsEntity copyWith({
    String? displayName,
  }) {
    return MatchStatsEntity(
      name: name,
      displayName: displayName ?? this.displayName,
      homeValue: homeValue,
      awayValue: awayValue,
      homePercent: homePercent,
      awayPercent: awayPercent,
    );
  }

  @override
  List<Object?> get props => [name, displayName, homeValue, awayValue, homePercent, awayPercent];
}
