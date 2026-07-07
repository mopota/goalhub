import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goalhub/features/leagues/domain/entities/league_entity.dart';
import 'package:goalhub/features/leagues/presentation/cubit/leagues_cubit.dart';
import 'package:goalhub/features/leagues/presentation/cubit/leagues_state.dart';
import 'package:goalhub/features/leagues/domain/entities/standing_entity.dart';
import 'package:goalhub/features/leagues/presentation/pages/team_details_page.dart';
import 'package:goalhub/features/matches/presentation/pages/player_details_page.dart';
import 'package:goalhub/core/widgets/goalhub_image.dart';

import '../../../../core/settings/settings_cubit.dart';
import '../../domain/entities/leader_entity.dart';

import 'package:goalhub/core/utils/translation_service.dart';

class StandingsPage extends StatefulWidget {
  final LeagueEntity league;

  const StandingsPage({super.key, required this.league});

  @override
  State<StandingsPage> createState() => _StandingsPageState();
}

class _StandingsPageState extends State<StandingsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    final String leagueIdOrSlug = widget.league.slug.isNotEmpty ? widget.league.slug : widget.league.id;
    context.read<LeaguesCubit>().fetchLeagueDetails(leagueIdOrSlug);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final language = context.read<SettingsCubit>().state.language;
    final isArabic = language == 'ar';

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.league.displayName),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: isArabic ? 'الترتيب' : 'Table'),
            Tab(text: isArabic ? 'الهدافين' : 'Top Scorers'),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          final String leagueIdOrSlug = widget.league.slug.isNotEmpty ? widget.league.slug : widget.league.id;
          await context.read<LeaguesCubit>().fetchLeagueDetails(leagueIdOrSlug);
        },
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildTableTab(),
            _buildLeadersTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildTableTab() {
    return BlocBuilder<LeaguesCubit, LeaguesState>(
      builder: (context, state) {
        if (state is LeaguesLoading) {
          return const Center(child: CircularProgressIndicator());
        } else if (state is LeaguesLoaded && state.standings != null) {
          final standings = state.standings!;
          final language = context.read<SettingsCubit>().state.language;
          final isArabic = language == 'ar';
          
          if (standings.isEmpty) return Center(child: Text(isArabic ? 'لا توجد بيانات متاحة' : 'No standings data available'));
          
          // Group standings by groupName
          final Map<String, List<StandingEntity>> groupedStandings = {};
          for (var s in standings) {
            final group = s.groupName ?? 'Standings';
            groupedStandings.putIfAbsent(group, () => []).add(s);
          }

          final groups = groupedStandings.keys.toList();

          return ListView.builder(
            itemCount: groups.length,
            itemBuilder: (context, index) {
              final rawGroupName = groups[index];
              final groupItems = groupedStandings[rawGroupName]!;
              
              String groupName = rawGroupName;
              if (rawGroupName.contains('Group')) {
                final groupLetter = rawGroupName.split(' ').last;
                groupName = isArabic ? 'المجموعة $groupLetter' : rawGroupName;
              } else if (rawGroupName == 'Standings') {
                groupName = isArabic ? 'جدول الترتيب' : 'Standings';
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (rawGroupName != 'Standings' || groups.length > 1)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                      child: Text(
                        groupName,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columnSpacing: 16,
                      showCheckboxColumn: false,
                      columns: [
                        DataColumn(label: Text(isArabic ? '#' : '#')),
                        DataColumn(label: Text(isArabic ? 'الفريق' : 'Team')),
                        DataColumn(label: Text(isArabic ? 'لعب' : 'P')),
                        DataColumn(label: Text(isArabic ? 'ف' : 'W')),
                        DataColumn(label: Text(isArabic ? 'ت' : 'D')),
                        DataColumn(label: Text(isArabic ? 'خ' : 'L')),
                        DataColumn(label: Text(isArabic ? 'ف.أ' : 'GD')),
                        DataColumn(label: Text(isArabic ? 'نقاط' : 'Pts')),
                      ],
                      rows: groupItems.map((s) {
                        return DataRow(
                          onSelectChanged: (selected) {
                            if (selected != null && selected) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => TeamDetailsPage(
                                    leagueId: widget.league.id,
                                    teamId: s.teamId,
                                    teamName: s.teamName,
                                    teamLogo: s.teamLogo,
                                  ),
                                ),
                              );
                            }
                          },
                          cells: [
                            DataCell(Text(s.rank)),
                            DataCell(Row(
                              children: [
                                if (s.teamLogo != null)
                                  GoalHubImage(imageUrl: s.teamLogo!, width: 24, height: 24),
                                const SizedBox(width: 8),
                                SizedBox(
                                  width: 120,
                                  child: Text(
                                    s.teamName,
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            )),
                            DataCell(Text(s.played)),
                            DataCell(Text(s.won)),
                            DataCell(Text(s.drawn)),
                            DataCell(Text(s.lost)),
                            DataCell(Text(s.goalsDifference)),
                            DataCell(Text(s.points, style: const TextStyle(fontWeight: FontWeight.bold))),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ],
              );
            },
          );
        } else if (state is LeaguesError) {
          return Center(child: Text(state.message));
        }
        return const Center(child: Text('Loading table...'));
      },
    );
  }

  Widget _buildLeadersTab() {
    return BlocBuilder<LeaguesCubit, LeaguesState>(
      builder: (context, state) {
        final language = context.read<SettingsCubit>().state.language;
        final isArabic = language == 'ar';

        if (state is LeaguesLoading) {
          return const Center(child: CircularProgressIndicator());
        } else if (state is LeaguesLoaded && state.leaders != null) {
          // Robust selection of goals/scoring category
          final goalsCategory = state.leaders!.firstWhere(
            (c) {
              final n = c.name.toLowerCase();
              return n == 'goals' || n == 'scoring' || n == 'points' || n.contains('goal');
            },
            orElse: () => state.leaders!.isNotEmpty ? state.leaders![0] : const LeagueLeadersEntity(name: '', displayName: '', leaders: []),
          );
          
          if (goalsCategory.leaders.isEmpty) return Center(child: Text(isArabic ? 'لا توجد بيانات متاحة' : 'No stats data available'));

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: goalsCategory.leaders.length,
            separatorBuilder: (context, index) => const Divider(),
            itemBuilder: (context, index) {
              final leader = goalsCategory.leaders[index];
              return ListTile(
                leading: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(leader.rank, style: Theme.of(context).textTheme.bodySmall),
                    const SizedBox(width: 12),
                    Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(shape: BoxShape.circle),
                      child: ClipOval(
                        child: leader.headshot != null 
                          ? GoalHubImage(imageUrl: leader.headshot!)
                          : const Icon(Icons.person),
                      ),
                    ),
                  ],
                ),
                title: Text(leader.displayName, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Row(
                  children: [
                    if (leader.teamLogo != null)
                      Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: Image.network(leader.teamLogo!, width: 16, height: 16),
                      ),
                    Text(leader.teamName, style: const TextStyle(fontSize: 12)),
                  ],
                ),
                trailing: Text(
                  leader.displayValue,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PlayerDetailsPage(
                        athleteId: leader.athleteId,
                        leagueSlug: widget.league.id,
                        playerName: leader.displayName,
                      ),
                    ),
                  );
                },
              );
            },
          );
        } else if (state is LeaguesError) {
          return Center(child: Text(state.message));
        }
        return const Center(child: Text('Loading statistics...'));
      },
    );
  }
}
