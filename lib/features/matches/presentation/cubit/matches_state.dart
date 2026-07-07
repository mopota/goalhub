import 'package:equatable/equatable.dart';
import 'package:goalhub/features/matches/domain/entities/match_entity.dart';

abstract class MatchesState extends Equatable {
  const MatchesState();

  @override
  List<Object?> get props => [];
}

class MatchesInitial extends MatchesState {}

class MatchesLoading extends MatchesState {}

class MatchesLoaded extends MatchesState {
  final Map<String, List<MatchEntity>> matchesByDate;
  final List<String> loadedDates;
  final bool isLoadingMore;

  const MatchesLoaded({
    required this.matchesByDate,
    required this.loadedDates,
    this.isLoadingMore = false,
  });

  @override
  List<Object?> get props => [matchesByDate, loadedDates, isLoadingMore];
}

class MatchesError extends MatchesState {
  final String message;

  const MatchesError(this.message);

  @override
  List<Object?> get props => [message];
}
