import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goalhub/features/leagues/domain/entities/team_entity.dart';
import 'package:goalhub/features/leagues/presentation/cubit/leagues_cubit.dart';
import 'package:goalhub/features/leagues/presentation/cubit/leagues_state.dart';
import 'package:goalhub/core/widgets/goalhub_image.dart';
import 'package:goalhub/core/network/image_repository.dart';
import 'package:goalhub/features/matches/domain/entities/match_entity.dart';
import 'package:goalhub/features/matches/presentation/pages/player_details_page.dart';
import 'package:goalhub/features/matches/presentation/widgets/match_card.dart';

class TeamDetailsPage extends StatefulWidget {
  final String leagueId;
  final String teamId;
  final String teamName;
  final String? teamLogo;

  const TeamDetailsPage({
    super.key,
    required this.leagueId,
    required this.teamId,
    required this.teamName,
    this.teamLogo,
  });

  @override
  State<TeamDetailsPage> createState() => _TeamDetailsPageState();
}

class _TeamDetailsPageState extends State<TeamDetailsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    context.read<LeaguesCubit>().fetchTeamDetails(widget.leagueId, widget.teamId);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LeaguesCubit, LeaguesState>(
      builder: (context, state) {
        if (state is LeaguesLoading) {
          return Scaffold(
            appBar: AppBar(title: Text(widget.teamName)),
            body: const Center(child: CircularProgressIndicator()),
          );
        } else if (state is LeaguesLoaded && state.team != null) {
          final team = state.team!;
          return Scaffold(
            body: NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) {
                return [
                  SliverAppBar(
                    expandedHeight: 200.0,
                    pinned: true,
                    flexibleSpace: FlexibleSpaceBar(
                      title: Text(team.displayName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      background: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Theme.of(context).colorScheme.primary,
                              Theme.of(context).colorScheme.primary.withAlpha(150),
                            ],
                          ),
                        ),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              GoalHubImage(
                                name: team.displayName,
                                type: ImageType.team,
                                secondaryName: team.location,
                                height: 80, 
                                width: 80,
                              ),
                              const SizedBox(height: 8),
                              if (team.location != null)
                                Text(
                                  team.location!,
                                  style: const TextStyle(color: Colors.white70),
                                ),
                              const SizedBox(height: 12),
                              _buildFormGuide(team),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: _SliverAppBarDelegate(
                      TabBar(
                        controller: _tabController,
                        labelColor: Theme.of(context).colorScheme.primary,
                        unselectedLabelColor: Colors.grey,
                        indicatorColor: Theme.of(context).colorScheme.primary,
                        isScrollable: true,
                        tabs: const [
                          Tab(text: 'Results'),
                          Tab(text: 'Fixtures'),
                          Tab(text: 'Roster'),
                          Tab(text: 'Leaders'),
                          Tab(text: 'Overview'),
                        ],
                      ),
                    ),
                  ),
                ];
              },
              body: TabBarView(
                controller: _tabController,
                children: [
                  _buildMatchesList(context, team.recentMatches),
                  _buildMatchesList(context, team.upcomingMatches),
                  _buildRoster(context, team),
                  _buildLeaders(context, team),
                  _buildOverview(context, team),
                ],
              ),
            ),
          );
        } else if (state is LeaguesError) {
          return Scaffold(
            appBar: AppBar(title: Text(widget.teamName)),
            body: Center(child: Text(state.message)),
          );
        }
        return Scaffold(
          appBar: AppBar(title: Text(widget.teamName)),
          body: const Center(child: Text('No data found')),
        );
      },
    );
  }

  Widget _buildFormGuide(TeamEntity team) {
    if (team.recentMatches == null || team.recentMatches!.isEmpty) {
      return const SizedBox.shrink();
    }

    // Take last 5 finished matches
    final last5 = team.recentMatches!.where((m) => m.isFinished).take(5).toList();
    if (last5.isEmpty) return const SizedBox.shrink();

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: last5.map((m) {
        final bool isHome = m.homeTeamId == team.id;
        final int homeScore = int.tryParse(m.homeScore) ?? 0;
        final int awayScore = int.tryParse(m.awayScore) ?? 0;

        String result = 'D';
        Color color = Colors.grey;

        if (homeScore == awayScore) {
          result = 'D';
          color = Colors.grey;
        } else if (isHome) {
          if (homeScore > awayScore) {
            result = 'W';
            color = Colors.green;
          } else {
            result = 'L';
            color = Colors.red;
          }
        } else {
          if (awayScore > homeScore) {
            result = 'W';
            color = Colors.green;
          } else {
            result = 'L';
            color = Colors.red;
          }
        }

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 2),
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: color.withAlpha(200),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white24),
          ),
          child: Center(
            child: Text(
              result,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMatchesList(BuildContext context, List<MatchEntity>? matches) {
    if (matches == null || matches.isEmpty) {
      return const Center(child: Text('No matches available'));
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 8),
      itemCount: matches.length,
      itemBuilder: (context, index) {
        return MatchCard(match: matches[index]);
      },
    );
  }

  Widget _buildRoster(BuildContext context, TeamEntity team) {
    if (team.roster == null || team.roster!.isEmpty) {
      return const Center(child: Text('No roster information available'));
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 8),
      itemCount: team.roster!.length,
      itemBuilder: (context, index) {
        final athlete = team.roster![index];
        return ListTile(
          leading: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(shape: BoxShape.circle),
                child: ClipOval(
                  child: GoalHubImage(
                    name: athlete.displayName,
                    type: ImageType.player,
                    secondaryName: team.displayName,
                  ),
                ),
              ),
              Positioned(
                right: -4,
                bottom: -4,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                  child: GoalHubImage(
                    name: team.displayName,
                    type: ImageType.team,
                    width: 16, 
                    height: 16,
                  ),
                ),
              ),
            ],
          ),
          title: Text(athlete.displayName, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text(athlete.position ?? ''),
          trailing: Text(athlete.jersey ?? '', style: const TextStyle(color: Colors.grey)),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PlayerDetailsPage(
                  athleteId: athlete.id,
                  leagueSlug: widget.leagueId,
                  playerName: athlete.displayName,
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildLeaders(BuildContext context, TeamEntity team) {
    if (team.leaders == null || team.leaders!.isEmpty) {
      return const Center(child: Text('No statistical leaders available'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: team.leaders!.length,
      itemBuilder: (context, index) {
        final category = team.leaders![index];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                category.displayName,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            ...category.leaders.map((leader) => ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(shape: BoxShape.circle),
                child: ClipOval(
                  child: GoalHubImage(
                    name: leader.displayName,
                    type: ImageType.player,
                    secondaryName: team.displayName,
                  ),
                ),
              ),
              title: Text(leader.displayName, style: const TextStyle(fontSize: 14)),
              trailing: Text(
                leader.displayValue,
                style: TextStyle(
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
                      leagueSlug: widget.leagueId,
                      playerName: leader.displayName,
                    ),
                  ),
                );
              },
            )),
            const Divider(),
          ],
        );
      },
    );
  }

  Widget _buildOverview(BuildContext context, TeamEntity team) {
    // Extract unique leagues from matches
    final Set<String> leaguesSet = {};
    if (team.recentMatches != null) {
      for (var m in team.recentMatches!) {
        leaguesSet.add(m.leagueName);
      }
    }
    if (team.upcomingMatches != null) {
      for (var m in team.upcomingMatches!) {
        leaguesSet.add(m.leagueName);
      }
    }
    final List<String> leagues = leaguesSet.toList()..sort();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (leagues.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Text('Leagues & Tournaments', style: Theme.of(context).textTheme.titleSmall),
          ),
          Wrap(
            spacing: 8,
            children: leagues.map((l) => Chip(
              label: Text(l, style: const TextStyle(fontSize: 12)),
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            )).toList(),
          ),
          const Divider(),
        ],
        if (team.coach != null) ...[
          _buildInfoItem(context, Icons.person, 'Coach', team.coach!),
          const Divider(),
        ],
        if (team.venue != null) ...[
          _buildInfoItem(context, Icons.stadium, 'Stadium', team.venue!),
          if (team.venueImage != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: GoalHubImage(
                  imageUrl: team.venueImage!.contains('espncdn.com') ? null : team.venueImage,
                ),
              ),
            ),
          const Divider(),
        ],
        if (team.location != null) ...[
          _buildInfoItem(context, Icons.location_on, 'Location', team.location!),
          const Divider(),
        ],
      ],
    );
  }

  Widget _buildInfoItem(BuildContext context, IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.labelSmall),
              Text(value, style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
        ],
      ),
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._tabBar);

  final TabBar _tabBar;

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}
