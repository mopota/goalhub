import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goalhub/core/widgets/goalhub_image.dart';
import 'package:goalhub/features/leagues/domain/entities/athlete_entity.dart';
import 'package:goalhub/features/matches/domain/repositories/match_repository.dart';

class PlayerDetailsPage extends StatelessWidget {
  final String athleteId;
  final String leagueSlug;
  final String playerName;

  const PlayerDetailsPage({
    super.key,
    required this.athleteId,
    required this.leagueSlug,
    required this.playerName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(playerName),
      ),
      body: FutureBuilder<AthleteEntity>(
        future: context.read<MatchRepository>().getAthleteDetails(leagueSlug, athleteId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: Text('No data found'));
          }

          final athlete = snapshot.data!;
          final headshot = athlete.headshot ?? 'https://a.espncdn.com/i/headshots/soccer/players/full/$athleteId.png';
          
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Center(
                  child: Hero(
                    tag: 'player_$athleteId',
                    child: Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Theme.of(context).colorScheme.primary, width: 4),
                      ),
                      child: ClipOval(
                        child: GoalHubImage(imageUrl: headshot, fit: BoxFit.cover),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  athlete.displayName,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                if (athlete.position != null)
                  Text(
                    athlete.position!,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey),
                  ),
                const SizedBox(height: 16),
                if (athlete.teamName != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (athlete.teamLogo != null)
                          GoalHubImage(imageUrl: athlete.teamLogo!, width: 30, height: 30),
                        const SizedBox(width: 8),
                        Text(
                          athlete.teamName!,
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                      ],
                    ),
                  ),
                
                // Club Details (especially for National Team players)
                if (athlete.clubName != null && athlete.clubName != athlete.teamName)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (athlete.clubLogo != null)
                          GoalHubImage(imageUrl: athlete.clubLogo!, width: 24, height: 24),
                        const SizedBox(width: 6),
                        Text(
                          athlete.clubName!,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 24),
                
                // Position Specific Stats
                if (athlete.stats != null && athlete.stats!.isNotEmpty) ...[
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                      childAspectRatio: 1.5,
                    ),
                    itemCount: athlete.stats!.length,
                    itemBuilder: (context, index) {
                      final stat = athlete.stats![index];
                      return Card(
                        elevation: 0,
                        color: Theme.of(context).colorScheme.primaryContainer.withAlpha(50),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              stat.displayValue,
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                            Text(
                              stat.displayName,
                              style: Theme.of(context).textTheme.labelSmall,
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                ],

                _buildInfoCard(context, [
                  _InfoItem(label: 'Jersey', value: athlete.jersey ?? 'N/A'),
                  _InfoItem(label: 'Age', value: athlete.age ?? 'N/A'),
                  _InfoItem(label: 'Height', value: athlete.height ?? 'N/A'),
                  _InfoItem(label: 'Weight', value: athlete.weight ?? 'N/A'),
                  _InfoItem(label: 'Nationality', value: athlete.nationality ?? 'N/A'),
                  _InfoItem(label: 'Birth Place', value: athlete.birthPlace ?? 'N/A'),
                ]),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context, List<_InfoItem> items) {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainerHighest.withAlpha(80),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: items.map((item) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(item.label, style: const TextStyle(fontWeight: FontWeight.w500)),
                Text(item.value, style: const TextStyle(color: Colors.grey)),
              ],
            ),
          )).toList(),
        ),
      ),
    );
  }
}

class _InfoItem {
  final String label;
  final String value;
  _InfoItem({required this.label, required this.value});
}
