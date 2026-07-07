import 'package:equatable/equatable.dart';

class MatchLineupEntity extends Equatable {
  final String? homeTeamId;
  final List<MatchPlayerEntity> homeStarters;
  final List<MatchPlayerEntity> homeBench;
  final String? homeCoach;
  final String? homeFormation;
  final String? awayTeamId;
  final List<MatchPlayerEntity> awayStarters;
  final List<MatchPlayerEntity> awayBench;
  final String? awayCoach;
  final String? awayFormation;

  const MatchLineupEntity({
    this.homeTeamId,
    required this.homeStarters,
    required this.homeBench,
    this.homeCoach,
    this.homeFormation,
    this.awayTeamId,
    required this.awayStarters,
    required this.awayBench,
    this.awayCoach,
    this.awayFormation,
  });

  MatchLineupEntity copyWith({
    String? homeTeamId,
    List<MatchPlayerEntity>? homeStarters,
    List<MatchPlayerEntity>? homeBench,
    String? homeCoach,
    String? homeFormation,
    String? awayTeamId,
    List<MatchPlayerEntity>? awayStarters,
    List<MatchPlayerEntity>? awayBench,
    String? awayCoach,
    String? awayFormation,
  }) {
    return MatchLineupEntity(
      homeTeamId: homeTeamId ?? this.homeTeamId,
      homeStarters: homeStarters ?? this.homeStarters,
      homeBench: homeBench ?? this.homeBench,
      homeCoach: homeCoach ?? this.homeCoach,
      homeFormation: homeFormation ?? this.homeFormation,
      awayTeamId: awayTeamId ?? this.awayTeamId,
      awayStarters: awayStarters ?? this.awayStarters,
      awayBench: awayBench ?? this.awayBench,
      awayCoach: awayCoach ?? this.awayCoach,
      awayFormation: awayFormation ?? this.awayFormation,
    );
  }

  @override
  List<Object?> get props => [
    homeTeamId, homeStarters, homeBench, homeCoach, homeFormation,
    awayTeamId, awayStarters, awayBench, awayCoach, awayFormation
  ];
}

class MatchPlayerEntity extends Equatable {
  final String id;
  final String name;
  final String jersey;
  final String position;
  final String? positionAbbreviation;
  final String? photo;
  final double? x;
  final double? y;
  final bool isSubbedOut;
  final bool isSubbedIn;
  final String? subTime;
  final double? rating;
  final bool isCaptain;
  final Map<String, String>? stats;

  const MatchPlayerEntity({
    required this.id,
    required this.name,
    required this.jersey,
    required this.position,
    this.positionAbbreviation,
    this.photo,
    this.x,
    this.y,
    this.isSubbedOut = false,
    this.isSubbedIn = false,
    this.subTime,
    this.rating,
    this.isCaptain = false,
    this.stats,
  });

  MatchPlayerEntity copyWith({
    String? name,
    String? position,
    String? positionAbbreviation,
    String? photo,
    double? x,
    double? y,
    bool? isSubbedOut,
    bool? isSubbedIn,
    String? subTime,
    double? rating,
    bool? isCaptain,
    Map<String, String>? stats,
  }) {
    return MatchPlayerEntity(
      id: id,
      name: name ?? this.name,
      jersey: jersey,
      position: position ?? this.position,
      positionAbbreviation: positionAbbreviation ?? this.positionAbbreviation,
      photo: photo ?? this.photo,
      x: x ?? this.x,
      y: y ?? this.y,
      isSubbedOut: isSubbedOut ?? this.isSubbedOut,
      isSubbedIn: isSubbedIn ?? this.isSubbedIn,
      subTime: subTime ?? this.subTime,
      rating: rating ?? this.rating,
      isCaptain: isCaptain ?? this.isCaptain,
      stats: stats ?? this.stats,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        jersey,
        position,
        positionAbbreviation,
        photo,
        x,
        y,
        isSubbedOut,
        isSubbedIn,
        subTime,
        rating,
        isCaptain,
        stats,
      ];
}
