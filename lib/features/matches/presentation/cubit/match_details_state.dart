import 'package:equatable/equatable.dart';
import 'package:goalhub/features/matches/domain/entities/details/match_detail_entity.dart';

abstract class MatchDetailsState extends Equatable {
  const MatchDetailsState();

  @override
  List<Object?> get props => [];
}

class MatchDetailsInitial extends MatchDetailsState {}

class MatchDetailsLoading extends MatchDetailsState {}

class MatchDetailsLoaded extends MatchDetailsState {
  final MatchDetailEntity detail;

  const MatchDetailsLoaded(this.detail);

  @override
  List<Object?> get props => [detail];
}

class MatchDetailsError extends MatchDetailsState {
  final String message;

  const MatchDetailsError(this.message);

  @override
  List<Object?> get props => [message];
}
