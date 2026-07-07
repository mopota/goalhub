import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goalhub/core/constants/country_timezones.dart';
import 'package:goalhub/core/settings/settings_cubit.dart';
import 'package:goalhub/core/widgets/goalhub_image.dart';
import 'package:goalhub/features/leagues/presentation/pages/team_details_page.dart';
import 'package:goalhub/features/matches/domain/entities/match_entity.dart';
import 'package:goalhub/features/matches/presentation/pages/match_details_page.dart';
import 'package:intl/intl.dart';

class MatchCard extends StatelessWidget {
  final MatchEntity match;

  const MatchCard({super.key, required this.match});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final settings = context.watch<SettingsCubit>().state;
    final convertedTime = CountryTimezones.convertToCountryTime(match.date, settings.country);

    // Logic: Only show score if the match is LIVE or FINISHED.
    // This avoids the "Upcoming 1 - 1" contradiction.
    final bool showScoreCenter = match.isLive || match.isFinished;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 0,
      color: match.isLive 
          ? colorScheme.primaryContainer.withAlpha(77) 
          : colorScheme.surfaceContainerHighest.withAlpha(77),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: match.isLive ? colorScheme.primary : Colors.transparent,
          width: 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MatchDetailsPage(match: match),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        if (match.leagueLogo.isNotEmpty)
                          Hero(
                            tag: 'league_logo_${match.id}',
                            child: GoalHubImage(
                              imageUrl: match.leagueLogo,
                              height: 20,
                              width: 20,
                              fit: BoxFit.contain,
                              memCacheHeight: 40,
                              memCacheWidth: 40,
                            ),
                          ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Hero(
                            tag: 'league_name_${match.id}',
                            child: Material(
                              color: Colors.transparent,
                              child: Text(
                                match.leagueName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (match.isLive)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: colorScheme.error,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            match.status == 'HT' ? 'HT' : (match.displayClock.contains("'") ? match.displayClock : '${match.displayClock}\''),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: colorScheme.onError,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          match.status,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: match.isFinished ? colorScheme.onSurfaceVariant : colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (match.isFinished)
                          Text(
                            DateFormat('MMM d').format(convertedTime),
                            style: theme.textTheme.labelSmall?.copyWith(fontSize: 9),
                          ),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildTeamWidget(
                      context,
                      id: match.homeTeamId,
                      name: match.homeTeamName,
                      logo: match.homeTeamLogo,
                      heroTag: 'home_logo_${match.id}',
                    ),
                  ),
                  Flexible(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (showScoreCenter)
                            Hero(
                              tag: 'score_${match.id}',
                              child: Material(
                                color: Colors.transparent,
                                child: Text(
                                  '${match.homeScore} - ${match.awayScore}',
                                  style: theme.textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: match.isLive ? colorScheme.primary : colorScheme.onSurface,
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            )
                          else
                            Column(
                              children: [
                                Text(
                                  DateFormat('hh:mm a').format(convertedTime),
                                  style: theme.textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.onSurface,
                                  ),
                                ),
                                Text(
                                  DateFormat('EEE, MMM d').format(convertedTime),
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          if (match.isLive)
                            Padding(
                              padding: const EdgeInsets.only(top: 4.0),
                              child: Text(
                                'LIVE',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: colorScheme.error,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: _buildTeamWidget(
                      context,
                      id: match.awayTeamId,
                      name: match.awayTeamName,
                      logo: match.awayTeamLogo,
                      heroTag: 'away_logo_${match.id}',
                    ),
                  ),
                ],
              ),
              if (match.venue != null && match.venue!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Divider(height: 1, color: colorScheme.outlineVariant),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.location_on_outlined, size: 14, color: colorScheme.onSurfaceVariant),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        match.venue!,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTeamWidget(BuildContext context, {
    required String id,
    required String name,
    required String logo,
    required String heroTag,
  }) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TeamDetailsPage(
              leagueId: match.leagueSlug,
              teamId: id,
              teamName: name,
              teamLogo: logo,
            ),
          ),
        );
      },
      borderRadius: BorderRadius.circular(8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Hero(
            tag: heroTag,
            child: GoalHubImage(
              imageUrl: logo,
              height: 48,
              width: 48,
              fit: BoxFit.contain,
              memCacheHeight: 100,
              memCacheWidth: 100,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            name,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}
