import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goalhub/core/constants/country_timezones.dart';
import 'package:goalhub/core/settings/settings_cubit.dart';
import 'package:goalhub/features/matches/presentation/cubit/matches_cubit.dart';
import 'package:goalhub/features/matches/presentation/cubit/matches_state.dart';
import 'package:goalhub/features/matches/presentation/widgets/match_card.dart';
import 'package:goalhub/features/search/presentation/pages/search_page.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';

class MatchesPage extends StatefulWidget {
  const MatchesPage({super.key});

  @override
  State<MatchesPage> createState() => _MatchesPageState();
}

class _MatchesPageState extends State<MatchesPage> {
  DateTime _selectedDate = DateTime.now();
  String? _selectedLeague;

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      if (context.mounted) {
        context.read<MatchesCubit>().loadDate(picked);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('GoalHub', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SearchPage()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.calendar_month),
            onPressed: () => _selectDate(context),
          ),
          IconButton(
            icon: const Icon(Icons.today),
            onPressed: () {
              setState(() {
                _selectedDate = DateTime.now();
              });
              context.read<MatchesCubit>().loadDate(DateTime.now());
            },
          ),
        ],
      ),
      body: BlocBuilder<MatchesCubit, MatchesState>(
        builder: (context, state) {
          if (state is MatchesInitial || state is MatchesLoading) {
            return const _MatchesLoadingSkeleton();
          }

          if (state is MatchesError) {
            return _ErrorState(message: state.message);
          }

          if (state is MatchesLoaded) {
            final dateStr = DateFormat('yyyy-MM-dd', 'en_US').format(_selectedDate);
            final allMatches = state.matchesByDate[dateStr] ?? [];
            final isToday = DateFormat('yyyy-MM-dd', 'en_US').format(DateTime.now()) == dateStr;

            // Extract unique leagues for the horizontal scroll
            final leagues = allMatches.map((m) => m.leagueName).toSet().toList()..sort();
            
            final matches = _selectedLeague == null 
                ? allMatches 
                : allMatches.where((m) => m.leagueName == _selectedLeague).toList();

            if (allMatches.isEmpty) {
              return const _EmptyState();
            }

            return RefreshIndicator(
              onRefresh: () => context.read<MatchesCubit>().loadDate(_selectedDate),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  // Horizontal League Filter
                  if (leagues.isNotEmpty)
                    Container(
                      height: 50,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: leagues.length + 1,
                        itemBuilder: (context, index) {
                          final isAll = index == 0;
                          final leagueName = isAll ? null : leagues[index - 1];
                          final isSelected = _selectedLeague == leagueName;
                          final displayName = isAll ? 'All' : leagues[index - 1];

                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: FilterChip(
                              label: Text(displayName),
                              selected: isSelected,
                              onSelected: (selected) {
                                setState(() {
                                  _selectedLeague = selected ? leagueName : null;
                                });
                              },
                              labelStyle: TextStyle(
                                fontSize: 12,
                                color: isSelected ? Colors.white : null,
                              ),
                              selectedColor: Theme.of(context).colorScheme.primary,
                              checkmarkColor: Colors.white,
                            ),
                          );
                        },
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                    child: BlocBuilder<SettingsCubit, SettingsState>(
                      builder: (context, settings) {
                        final displayDate = CountryTimezones.convertToCountryTime(_selectedDate, settings.country);
                        return Text(
                          isToday 
                              ? (settings.language == 'ar' ? 'اليوم' : 'TODAY') 
                              : DateFormat('EEEE, MMM d', settings.language).format(displayDate).toUpperCase(),
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isToday 
                                ? Theme.of(context).colorScheme.primary 
                                : Theme.of(context).colorScheme.onSurfaceVariant,
                            letterSpacing: 1.2,
                          ),
                        );
                      },
                    ),
                  ),
                  ...matches.map((match) => MatchCard(match: match)),
                  const SizedBox(height: 24),
                ],
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class _MatchesLoadingSkeleton extends StatelessWidget {
  const _MatchesLoadingSkeleton();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: ListView.builder(
        itemCount: 5,
        itemBuilder: (context, index) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Container(
            height: 120,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.sports_soccer, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text('No matches found'),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => context.read<MatchesCubit>().refresh(),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  const _ErrorState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.read<MatchesCubit>().refresh(),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
