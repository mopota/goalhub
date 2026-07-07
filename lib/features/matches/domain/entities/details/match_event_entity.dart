import 'package:equatable/equatable.dart';

enum MatchEventType {
  goal,
  yellowCard,
  redCard,
  substitution,
  other
}

class MatchEventEntity extends Equatable {
  final String id;
  final String minute;
  final MatchEventType type;
  final String teamId;
  final String playerName;
  final String? playerNameOut; // For substitutions
  final String description;

  const MatchEventEntity({
    required this.id,
    required this.minute,
    required this.type,
    required this.teamId,
    required this.playerName,
    this.playerNameOut,
    required this.description,
  });

  MatchEventEntity copyWith({
    String? playerName,
    String? playerNameOut,
    String? description,
  }) {
    return MatchEventEntity(
      id: id,
      minute: minute,
      type: type,
      teamId: teamId,
      playerName: playerName ?? this.playerName,
      playerNameOut: playerNameOut ?? this.playerNameOut,
      description: description ?? this.description,
    );
  }

  @override
  List<Object?> get props => [id, minute, type, teamId, playerName, playerNameOut, description];
}
