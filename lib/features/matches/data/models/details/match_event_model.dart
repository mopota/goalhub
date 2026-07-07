import 'package:goalhub/features/matches/domain/entities/details/match_event_entity.dart';

class MatchEventModel extends MatchEventEntity {
  const MatchEventModel({
    required super.id,
    required super.minute,
    required super.type,
    required super.teamId,
    required super.playerName,
    super.playerNameOut,
    required super.description,
  });

  factory MatchEventModel.fromJson(Map<String, dynamic> json) {
    final typeJson = json['type'] ?? {};
    final typeName = typeJson['text']?.toString().toLowerCase() ?? '';
    
    MatchEventType type = MatchEventType.other;
    if (typeName.contains('goal')) {
      type = MatchEventType.goal;
    } else if (typeName.contains('yellow card')) {
      type = MatchEventType.yellowCard;
    } else if (typeName.contains('red card')) {
      type = MatchEventType.redCard;
    } else if (typeName.contains('substitution')) {
      type = MatchEventType.substitution;
    }

    final clock = json['clock'] ?? {};
    final athlete = json['athlete'] ?? {};
    final athleteOut = json['athleteOut'] ?? {};
    final team = json['team'] ?? {};

    return MatchEventModel(
      id: json['id'] ?? '',
      minute: clock['displayValue'] ?? '0\'',
      type: type,
      teamId: team['id']?.toString() ?? '',
      playerName: athlete['displayName'] ?? '',
      playerNameOut: athleteOut['displayName'],
      description: json['text'] ?? '',
    );
  }
}
