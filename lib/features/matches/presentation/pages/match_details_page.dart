import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goalhub/core/constants/country_timezones.dart';
import 'package:goalhub/core/settings/settings_cubit.dart';
import 'package:goalhub/core/widgets/goalhub_image.dart';
import 'package:goalhub/features/matches/domain/entities/details/match_detail_entity.dart';
import 'package:goalhub/features/matches/domain/entities/details/match_event_entity.dart';
import 'package:goalhub/features/matches/domain/entities/details/match_lineup_entity.dart';
import 'package:goalhub/features/matches/domain/entities/details/match_stats_entity.dart';
import 'package:goalhub/features/matches/domain/entities/match_entity.dart';
import 'package:goalhub/features/matches/presentation/cubit/match_details_cubit.dart';
import 'package:goalhub/features/matches/presentation/cubit/match_details_state.dart';
import 'package:goalhub/features/matches/domain/repositories/match_repository.dart';
import 'package:goalhub/features/matches/presentation/widgets/match_pitch_lineup.dart';
import 'package:goalhub/features/matches/presentation/pages/player_details_page.dart';
import 'package:intl/intl.dart';

import '../../../../core/utils/translation_service.dart';

class MatchDetailsPage extends StatefulWidget {
  final MatchEntity match;

  const MatchDetailsPage({super.key, required this.match});

  @override
  State<MatchDetailsPage> createState() => _MatchDetailsPageState();
}

class _MatchDetailsPageState extends State<MatchDetailsPage> {
  int _selectedTabIndex = 0;
  int _selectedLineupTeamIndex = 0; // 0 for Home, 1 for Away

  @override
  Widget build(BuildContext context) {
    final settingsCubit = context.read<SettingsCubit>();
    final translationService = context.read<TranslationService>();
    return BlocProvider(
      create: (context) => MatchDetailsCubit(context.read<MatchRepository>(), translationService)
        ..loadMatchDetails(
          widget.match.leagueSlug, 
          widget.match.id, 
          isLive: widget.match.isLive,
          isFinished: widget.match.isFinished,
          lang: settingsCubit.state.language,
          homeTeamId: widget.match.homeTeamId,
          awayTeamId: widget.match.awayTeamId,
        ),
      child: Scaffold(
        body: BlocBuilder<MatchDetailsCubit, MatchDetailsState>(
          builder: (context, state) {
            final detail = (state is MatchDetailsLoaded) ? state.detail : null;
            
            return CustomScrollView(
              slivers: [
                _buildAppBar(context, detail),
                if (state is MatchDetailsLoaded) ...[
                  _buildTabs(context, state.detail),
                  _buildContent(context, state.detail),
                ] else if (state is MatchDetailsLoading)
                  const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (state is MatchDetailsError)
                  SliverFillRemaining(
                    child: Center(child: Text(state.message)),
                  )
                else
                  const SliverFillRemaining(child: SizedBox.shrink()),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, MatchDetailEntity? detail) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    // Use data from detail if available, otherwise fallback to widget.match
    final hScore = detail?.homeScore ?? widget.match.homeScore;
    final aScore = detail?.awayScore ?? widget.match.awayScore;
    final isLive = detail?.isLive ?? widget.match.isLive;
    final clock = detail?.displayClock ?? widget.match.displayClock;
    final status = detail?.status ?? widget.match.status;

    return SliverAppBar(
      expandedHeight: 280,
      pinned: true,
      backgroundColor: colorScheme.surface,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                colorScheme.primaryContainer.withAlpha(100),
                colorScheme.surface,
              ],
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 40),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _TeamHeader(
                      name: widget.match.homeTeamName,
                      logo: widget.match.homeTeamLogo,
                      isHome: true,
                      heroTag: 'home_logo_${widget.match.id}',
                    ),
                    Column(
                      children: [
                        Hero(
                          tag: 'score_${widget.match.id}',
                          child: Material(
                            color: Colors.transparent,
                            child: Text(
                              '$hScore - $aScore',
                              style: theme.textTheme.displayMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onSurface,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: isLive ? colorScheme.error : colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            isLive ? 'LIVE $clock' : status,
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: isLive ? colorScheme.onError : colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    _TeamHeader(
                      name: widget.match.awayTeamName,
                      logo: widget.match.awayTeamLogo,
                      isHome: false,
                      heroTag: 'away_logo_${widget.match.id}',
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (widget.match.leagueLogo.isNotEmpty) ...[
                      Hero(
                        tag: 'league_logo_${widget.match.id}',
                        child: GoalHubImage(
                          imageUrl: widget.match.leagueLogo,
                          height: 24,
                          width: 24,
                          fit: BoxFit.contain,
                          memCacheHeight: 60,
                          memCacheWidth: 60,
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Hero(
                      tag: 'league_name_${widget.match.id}',
                      child: Material(
                        color: Colors.transparent,
                        child: Text(
                          widget.match.leagueName,
                          style: theme.textTheme.titleSmall,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<String> _getTabList(MatchDetailEntity detail) {
    final List<String> tabs = ['Info'];
    if (detail.lineups != null) tabs.add('Lineups');
    if (detail.statistics != null && detail.statistics!.isNotEmpty) tabs.add('Stats');
    if (detail.timeline != null && detail.timeline!.isNotEmpty) tabs.add('Timeline');
    if (detail.commentary != null && detail.commentary!.isNotEmpty) tabs.add('Commentary');
    return tabs;
  }

  Widget _buildTabs(BuildContext context, MatchDetailEntity detail) {
    final List<String> tabs = _getTabList(detail);

    return SliverPersistentHeader(
      pinned: true,
      delegate: _SliverAppBarDelegate(
        selectedTabIndex: _selectedTabIndex,
        child: Container(
          color: Theme.of(context).colorScheme.surface,
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Center(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SegmentedButton<int>(
                segments: List.generate(tabs.length, (index) {
                  IconData icon;
                  switch (tabs[index]) {
                    case 'Info': icon = Icons.info_outline; break;
                    case 'Lineups': icon = Icons.groups; break;
                    case 'Stats': icon = Icons.bar_chart; break;
                    case 'Timeline': icon = Icons.history; break;
                    case 'Commentary': icon = Icons.comment; break;
                    default: icon = Icons.help_outline;
                  }
                  return ButtonSegment(
                    value: index,
                    label: Text(tabs[index]),
                    icon: Icon(icon),
                  );
                }),
                selected: {_selectedTabIndex},
                onSelectionChanged: (newSelection) {
                  setState(() {
                    _selectedTabIndex = newSelection.first;
                  });
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, MatchDetailEntity detail) {
    final List<String> tabs = _getTabList(detail);

    if (_selectedTabIndex >= tabs.length) return const SliverToBoxAdapter(child: SizedBox.shrink());

    final selectedTab = tabs[_selectedTabIndex];

    switch (selectedTab) {
      case 'Info': return _buildInfo(detail);
      case 'Lineups': return _buildLineups(detail.lineups, detail.isPredictedLineup);
      case 'Stats': return _buildStats(detail.statistics);
      case 'Timeline': return _buildTimeline(detail.timeline);
      case 'Commentary': return _buildCommentary(detail.commentary);
      default: return const SliverToBoxAdapter(child: SizedBox.shrink());
    }
  }

  void _showPlayerMatchStats(BuildContext context, MatchPlayerEntity player) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[600],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Theme.of(context).colorScheme.primary.withAlpha(100), width: 2),
                    ),
                    child: ClipOval(
                      child: player.photo != null 
                        ? GoalHubImage(imageUrl: player.photo!, fit: BoxFit.cover)
                        : const Icon(Icons.person, size: 30),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          player.name,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '${player.position} #${player.jersey}',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  if (player.rating != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _getRatingColor(player.rating!),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        player.rating!.toStringAsFixed(1),
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                ],
              ),
            ),
            const Divider(),
            Expanded(
              child: player.stats == null || player.stats!.isEmpty
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.analytics_outlined, size: 64, color: Colors.grey.withAlpha(100)),
                      const SizedBox(height: 16),
                      const Text(
                        'Match stats are not yet available',
                        style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PlayerDetailsPage(
                                athleteId: player.id,
                                leagueSlug: widget.match.leagueSlug,
                                playerName: player.name,
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.person_search),
                        label: const Text('View Full Career Profile'),
                      ),
                    ],
                  )
                : ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    child: Text(
                      'MATCH PERFORMANCE',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        letterSpacing: 1.5,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                  ...player.stats!.entries.map((stat) {
                    final String displayName = stat.key
                        .replaceAll(RegExp(r'(?<=[a-z])(?=[A-Z])'), ' ')
                        .toUpperCase();
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(displayName, style: const TextStyle(fontWeight: FontWeight.w500)),
                          Text(
                            stat.value,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PlayerDetailsPage(
                            athleteId: player.id,
                            leagueSlug: widget.match.leagueSlug,
                            playerName: player.name,
                          ),
                        ),
                      );
                    },
                    child: const Text('View Full Season Profile'),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getRatingColor(double rating) {
    if (rating >= 8.0) return Colors.green[700]!;
    if (rating >= 7.0) return Colors.green[400]!;
    if (rating >= 6.0) return Colors.orange[400]!;
    return Colors.red[400]!;
  }

  Widget _buildTimeline(List<MatchEventEntity>? timeline) {
    if (timeline == null || timeline.isEmpty) {
      return const SliverFillRemaining(child: Center(child: Text('No events recorded')));
    }

    // Sort timeline by minute
    final sortedTimeline = List<MatchEventEntity>.from(timeline)
      ..sort((a, b) {
        final aMin = int.tryParse(a.minute.replaceAll('\'', '').split('+')[0]) ?? 0;
        final bMin = int.tryParse(b.minute.replaceAll('\'', '').split('+')[0]) ?? 0;
        return bMin.compareTo(aMin);
      });

    return SliverPadding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final event = sortedTimeline[index];
            final isHome = event.teamId == widget.match.homeTeamId;

            return _TimelineEventRow(event: event, isHome: isHome);
          },
          childCount: sortedTimeline.length,
        ),
      ),
    );
  }

  Widget _buildStats(List<MatchStatsEntity>? stats) {
    if (stats == null || stats.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());
    
    return SliverPadding(
      padding: const EdgeInsets.all(16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final stat = stats[index];
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Column(
                children: [
                  Row(
                    children: [
                      SizedBox(
                        width: 45,
                        child: Text(stat.homeValue, style: const TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.start),
                      ),
                      Expanded(
                        child: Text(
                          stat.displayName.toUpperCase(), 
                          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            letterSpacing: 1.2,
                            fontSize: 10,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      SizedBox(
                        width: 45,
                        child: Text(stat.awayValue, style: const TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.end),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: RotatedBox(
                          quarterTurns: 2,
                          child: LinearProgressIndicator(
                            value: stat.homePercent,
                            backgroundColor: Colors.transparent,
                            color: Theme.of(context).colorScheme.primary,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: LinearProgressIndicator(
                          value: stat.awayPercent,
                          backgroundColor: Colors.transparent,
                          color: Theme.of(context).colorScheme.secondary,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
          childCount: stats.length,
        ),
      ),
    );
  }

  Widget _buildLineups(MatchLineupEntity? lineups, bool isPredicted) {
    if (lineups == null) return const SliverToBoxAdapter(child: SizedBox.shrink());
    
    final currentStarters = _selectedLineupTeamIndex == 0 ? lineups.homeStarters : lineups.awayStarters;
    final currentBench = _selectedLineupTeamIndex == 0 ? lineups.homeBench : lineups.awayBench;
    final currentCoach = _selectedLineupTeamIndex == 0 ? lineups.homeCoach : lineups.awayCoach;
    final currentFormation = _selectedLineupTeamIndex == 0 ? lineups.homeFormation : lineups.awayFormation;
    
    final subbedIn = currentBench.where((p) => p.isSubbedIn).toList();
    final remainingBench = currentBench.where((p) => !p.isSubbedIn).toList();

    return SliverPadding(
      padding: const EdgeInsets.all(16),
      sliver: SliverList(
        delegate: SliverChildListDelegate([
          Center(
            child: SegmentedButton<int>(
              segments: [
                ButtonSegment(value: 0, label: Text(widget.match.homeTeamName)),
                ButtonSegment(value: 1, label: Text(widget.match.awayTeamName)),
              ],
              selected: {_selectedLineupTeamIndex},
              onSelectionChanged: (newSelection) {
                setState(() {
                  _selectedLineupTeamIndex = newSelection.first;
                });
              },
            ),
          ),
          const SizedBox(height: 16),
          
          MatchPitchLineup(
            starters: currentStarters,
            bench: currentBench,
            isHome: _selectedLineupTeamIndex == 0,
            teamLogo: _selectedLineupTeamIndex == 0 ? widget.match.homeTeamLogo : widget.match.awayTeamLogo,
            leagueSlug: widget.match.leagueSlug,
            formation: currentFormation,
            onPlayerTap: (player) => _showPlayerMatchStats(context, player),
          ),
          if (isPredicted)
             Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Center(
                child: Text(
                  context.read<SettingsCubit>().state.language == 'ar' 
                    ? '* تشكيل متوقع (بناءً على المباراة السابقة)'
                    : '* PREDICTED LINEUP (BASED ON PREVIOUS MATCH)',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Colors.orange,
                    fontWeight: FontWeight.bold,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ),
          
          const SizedBox(height: 24),

          if (subbedIn.isNotEmpty) ...[
            _buildSectionHeader('Substitutes Performance'),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 16,
                crossAxisSpacing: 8,
                childAspectRatio: 0.8,
              ),
              itemCount: subbedIn.length,
              itemBuilder: (context, index) => _PlayerGridItem(
                player: subbedIn[index],
                leagueSlug: widget.match.leagueSlug,
                onTap: () => _showPlayerMatchStats(context, subbedIn[index]),
              ),
            ),
            const SizedBox(height: 24),
          ],

          if (currentCoach != null) ...[
            _buildSectionHeader('Manager'),
            const SizedBox(height: 12),
            Card(
              child: ListTile(
                leading: const CircleAvatar(child: Icon(Icons.person)),
                title: Text(currentCoach),
                subtitle: const Text('Head Coach'),
              ),
            ),
            const SizedBox(height: 24),
          ],

          if (remainingBench.isNotEmpty) ...[
            _buildSectionHeader('Substitutes'),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 16,
                crossAxisSpacing: 8,
                childAspectRatio: 0.8,
              ),
              itemCount: remainingBench.length,
              itemBuilder: (context, index) => _PlayerGridItem(
                player: remainingBench[index],
                leagueSlug: widget.match.leagueSlug,
                onTap: () => _showPlayerMatchStats(context, remainingBench[index]),
              ),
            ),
          ],
        ]),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withAlpha(128),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildCommentary(List<String>? commentary) {
    if (commentary == null || commentary.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());
    
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) => ListTile(
          title: Text(commentary[index]),
          leading: const Icon(Icons.chat_bubble_outline, size: 16),
        ),
        childCount: commentary.length,
      ),
    );
  }

  Widget _buildInfo(MatchDetailEntity detail) {
    final settings = context.read<SettingsCubit>().state;
    final convertedTime = CountryTimezones.convertToCountryTime(widget.match.date, settings.country);

    return SliverPadding(
      padding: const EdgeInsets.all(16),
      sliver: SliverList(
        delegate: SliverChildListDelegate([
          _InfoRow(label: 'Venue', value: detail.venue ?? widget.match.venue ?? 'N/A', icon: Icons.location_on_outlined),
          _InfoRow(label: 'Referee', value: detail.referee ?? 'N/A', icon: Icons.person_outline),
          _InfoRow(label: 'Attendance', value: detail.attendance ?? 'N/A', icon: Icons.people_outline),
          _InfoRow(label: 'Weather', value: detail.weather ?? 'N/A', icon: Icons.cloud_outlined),
          _InfoRow(label: 'Broadcasts', value: detail.broadcasts?.join(', ') ?? 'N/A', icon: Icons.tv_outlined),
          _InfoRow(label: 'Odds', value: detail.odds ?? 'N/A', icon: Icons.monetization_on_outlined),
          _InfoRow(label: 'Date', value: DateFormat('EEEE, MMM d, yyyy').format(convertedTime), icon: Icons.calendar_today_outlined),
          _InfoRow(label: 'Time', value: DateFormat('hh:mm a').format(convertedTime), icon: Icons.access_time),
        ]),
      ),
    );
  }
}

class _TimelineEventRow extends StatelessWidget {
  final MatchEventEntity event;
  final bool isHome;

  const _TimelineEventRow({required this.event, required this.isHome});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          if (isHome) ...[
            Expanded(child: _EventContent(event: event, isHome: true)),
            _MinuteIndicator(minute: event.minute),
            const Expanded(child: SizedBox.shrink()),
          ] else ...[
            const Expanded(child: SizedBox.shrink()),
            _MinuteIndicator(minute: event.minute),
            Expanded(child: _EventContent(event: event, isHome: false)),
          ],
        ],
      ),
    );
  }
}

class _MinuteIndicator extends StatelessWidget {
  final String minute;
  const _MinuteIndicator({required this.minute});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Center(
        child: Text(
          minute,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
        ),
      ),
    );
  }
}

class _EventContent extends StatelessWidget {
  final MatchEventEntity event;
  final bool isHome;

  const _EventContent({required this.event, required this.isHome});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: isHome ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isHome) _EventIcon(type: event.type),
            const SizedBox(width: 8),
            Text(
              event.playerName,
              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 8),
            if (isHome) _EventIcon(type: event.type),
          ],
        ),
        Text(
          event.description,
          style: theme.textTheme.bodySmall,
          textAlign: isHome ? TextAlign.right : TextAlign.left,
        ),
      ],
    );
  }
}

class _EventIcon extends StatelessWidget {
  final MatchEventType type;
  const _EventIcon({required this.type});

  @override
  Widget build(BuildContext context) {
    switch (type) {
      case MatchEventType.goal:
        return const Icon(Icons.sports_soccer, color: Colors.green, size: 20);
      case MatchEventType.yellowCard:
        return Container(width: 14, height: 18, 
            margin: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: Colors.yellow,
              borderRadius: BorderRadius.circular(2)
            ));
      case MatchEventType.redCard:
        return Container(width: 14, height: 18, 
            margin: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(2)
            ));
      case MatchEventType.substitution:
        return const Icon(Icons.sync, color: Colors.blue, size: 20);
      default:
        return const Icon(Icons.info_outline, size: 20);
    }
  }
}

class _PlayerGridItem extends StatelessWidget {
  final MatchPlayerEntity player;
  final String leagueSlug;
  final VoidCallback? onTap;

  const _PlayerGridItem({required this.player, required this.leagueSlug, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap ?? () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PlayerDetailsPage(
              athleteId: player.id,
              leagueSlug: leagueSlug,
              playerName: player.name,
            ),
          ),
        );
      },
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.grey[900],
                  border: Border.all(color: Colors.white24),
                ),
                child: ClipOval(
                  child: player.photo != null
                      ? GoalHubImage(imageUrl: player.photo!)
                      : Center(child: Text(player.jersey, style: const TextStyle(color: Colors.white))),
                ),
              ),
              if (player.rating != null)
                Positioned(
                  bottom: -4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      color: _getRatingColor(player.rating!),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      player.rating!.toStringAsFixed(1),
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              if (player.isSubbedIn)
                const Positioned(
                  top: 0,
                  left: -4,
                  child: Icon(Icons.arrow_upward, color: Colors.green, size: 16),
                ),
              if (player.isSubbedOut)
                const Positioned(
                  top: 0,
                  right: -4,
                  child: Icon(Icons.arrow_downward, color: Colors.red, size: 16),
                ),
            ],
          ),
          const SizedBox(height: 9),
          Text(
            player.name.split(' ').last,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            player.positionAbbreviation ?? player.position,
            style: const TextStyle(fontSize: 9, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Color _getRatingColor(double rating) {
    if (rating >= 8.0) return Colors.green[700]!;
    if (rating >= 7.0) return Colors.green[400]!;
    if (rating >= 6.0) return Colors.orange[400]!;
    return Colors.red[400]!;
  }
}

class _TeamHeader extends StatelessWidget {
  final String name;
  final String logo;
  final bool isHome;
  final String heroTag;

  const _TeamHeader({required this.name, required this.logo, required this.isHome, required this.heroTag});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Hero(
          tag: heroTag,
          child: GoalHubImage(
            imageUrl: logo,
            height: 80,
            width: 80,
            fit: BoxFit.contain,
            memCacheHeight: 180,
            memCacheWidth: 160,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: 100,
          child: Text(
            name,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _InfoRow({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.labelSmall),
              Text(value, style: Theme.of(context).textTheme.bodyLarge),
            ],
          ),
        ],
      ),
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  final int selectedTabIndex;

  _SliverAppBarDelegate({required this.child, required this.selectedTabIndex});

  @override
  double get minExtent => 64.0;
  @override
  double get maxExtent => 64.0;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return child;
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return oldDelegate.selectedTabIndex != selectedTabIndex;
  }
}
