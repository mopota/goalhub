import 'package:equatable/equatable.dart';

class LeagueEntity extends Equatable {
  final String id;
  final String uid;
  final String slug;
  final String abbreviation;
  final String name;
  final String shortName;
  final String displayName;
  final String? logo;
  final String? scoreboardRef;
  final String? calendarRef;
  final String? seasonsRef;
  final String? eventsRef;
  final String? selfRef;

  const LeagueEntity({
    required this.id,
    required this.uid,
    required this.slug,
    required this.abbreviation,
    required this.name,
    required this.shortName,
    required this.displayName,
    this.logo,
    this.scoreboardRef,
    this.calendarRef,
    this.seasonsRef,
    this.eventsRef,
    this.selfRef,
  });

  @override
  List<Object?> get props => [
        id,
        uid,
        slug,
        abbreviation,
        name,
        shortName,
        displayName,
        logo,
        scoreboardRef,
        calendarRef,
        seasonsRef,
        eventsRef,
        selfRef,
      ];
}
