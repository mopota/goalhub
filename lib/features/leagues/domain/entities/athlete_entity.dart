import 'package:equatable/equatable.dart';

class AthleteStat extends Equatable {
  final String name;
  final String displayName;
  final String displayValue;

  const AthleteStat({
    required this.name,
    required this.displayName,
    required this.displayValue,
  });

  @override
  List<Object?> get props => [name, displayName, displayValue];
}

class AthleteEntity extends Equatable {
  final String id;
  final String fullName;
  final String displayName;
  final String shortName;
  final String? headshot;
  final String? position;
  final String? age;
  final String? height;
  final String? weight;
  final String? jersey;
  final String? nationality;
  final String? birthPlace;
  final String? teamName;
  final String? teamLogo;
  final String? clubName;
  final String? clubLogo;
  final List<AthleteStat>? stats;

  const AthleteEntity({
    required this.id,
    required this.fullName,
    required this.displayName,
    required this.shortName,
    this.headshot,
    this.position,
    this.age,
    this.height,
    this.weight,
    this.jersey,
    this.nationality,
    this.birthPlace,
    this.teamName,
    this.teamLogo,
    this.clubName,
    this.clubLogo,
    this.stats,
  });

  @override
  List<Object?> get props => [
        id,
        fullName,
        displayName,
        shortName,
        headshot,
        position,
        age,
        height,
        weight,
        jersey,
        nationality,
        birthPlace,
        teamName,
        teamLogo,
        clubName,
        clubLogo,
        stats,
      ];
}
