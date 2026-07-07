import 'package:flutter/material.dart';
import 'package:goalhub/core/widgets/goalhub_image.dart';
import 'package:goalhub/features/matches/domain/entities/details/match_lineup_entity.dart';

import 'package:goalhub/features/matches/presentation/pages/player_details_page.dart';

class MatchPitchLineup extends StatelessWidget {
  final List<MatchPlayerEntity> starters;
  final List<MatchPlayerEntity> bench;
  final bool isHome;
  final String teamLogo;
  final String leagueSlug;
  final String? formation;
  final Function(MatchPlayerEntity)? onPlayerTap;

  const MatchPitchLineup({
    super.key,
    required this.starters,
    required this.bench,
    required this.isHome,
    required this.teamLogo,
    required this.leagueSlug,
    this.formation,
    this.onPlayerTap,
  });

  @override
  Widget build(BuildContext context) {
    // 1. All players to show: Starters + Subbed In
    final List<MatchPlayerEntity> playersToShow = [
      ...starters,
      ...bench.where((p) => p.isSubbedIn),
    ];

    // Find the highest rating in this team to show a star
    double maxRating = 0;
    for (var p in playersToShow) {
      if (p.rating != null && p.rating! > maxRating) maxRating = p.rating!;
    }
    // Also check bench for max rating
    for (var p in bench) {
      if (p.rating != null && p.rating! > maxRating) maxRating = p.rating!;
    }

    // 2. Parse formation (e.g., "4-2-3-1")
    // Clean formation string (remove letters like 4-2-3-1 etc)
    final cleanedFormation = (formation ?? '4-4-2').replaceAll(RegExp(r'[^0-9\-]'), '');
    final formationParts = cleanedFormation.split('-').map((e) => int.tryParse(e) ?? 0).where((e) => e > 0).toList();
    
    // 3. Group players into formation rows
    final Map<int, List<MatchPlayerEntity>> rows = {};
    rows[0] = []; // GK always row 0
    for (int i = 1; i <= formationParts.length; i++) {
      rows[i] = [];
    }

    final List<MatchPlayerEntity> pool = List.from(playersToShow);
    
    if (pool.isEmpty) {
      return const SizedBox.shrink();
    }
    
    // Extract GK
    final gk = pool.firstWhere(
      (p) => p.positionAbbreviation?.toUpperCase().startsWith('8') ?? false,
      orElse: () => pool.first,
    );
    rows[0]!.add(gk);
    pool.remove(gk);

    // Sort remaining pool by depth (back to front)
    pool.sort((a, b) => _getDepthScore(a.positionAbbreviation).compareTo(_getDepthScore(b.positionAbbreviation)));

    // Distribute into rows based on formation parts
    int poolIdx = 0;
    for (int rowIdx = 1; rowIdx <= formationParts.length; rowIdx++) {
      int count = formationParts[rowIdx - 1];
      for (int i = 0; i < count && poolIdx < pool.length; i++) {
        rows[rowIdx]!.add(pool[poolIdx++]);
      }
    }
    
    // Handle leftovers (e.g. if formation count < starters count)
    while (poolIdx < pool.length) {
      rows[formationParts.length]!.add(pool[poolIdx++]);
    }

    // 4. Build Widgets
    final List<Widget> playerWidgets = [];
    final pitchWidth = MediaQuery.of(context).size.width - 40;
    final pitchHeight = pitchWidth * 1.5;

    final int totalRows = rows.keys.length;
    final double rowSpacing = 100.0 / totalRows; // Use 80% of field for tactical rows

    rows.forEach((rowIdx, group) {
      if (group.isEmpty) return;
      
      // Calculate Y: GK at bottom, Strikers at top
      // We reverse the logic: row 0 (GK) is at ~90%, last row is at ~10%
      final double yPercent = 90.0 - (rowIdx * rowSpacing);
      
      for (int i = 0; i < group.length; i++) {
        final player = group[i];
        
        double xPercent;
        if (group.length == 1) {
          xPercent = 50;
        } else {
          // Spread evenly between 10% and 90% width
          xPercent = 10 + (i * (80 / (group.length - 1)));
        }

        playerWidgets.add(_PositionedPlayer(
          player: player,
          pitchWidth: pitchWidth,
          pitchHeight: pitchHeight,
          isHome: isHome,
          teamLogo: teamLogo,
          leagueSlug: leagueSlug,
          customX: xPercent,
          customY: yPercent,
          isTopRated: maxRating > 0 && player.rating == maxRating,
          onTap: onPlayerTap != null ? () => onPlayerTap!(player) : null,
        ));
      }
    });

    return Container(
      width: pitchWidth,
      height: pitchHeight,
      margin: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF2E7D32),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white24, width: 4),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Stack(
        children: [
          _buildPitchMarkings(pitchWidth, pitchHeight),
          ...playerWidgets,
        ],
      ),
    );
  }

  // Depth score for sorting: lower is further back (Defense), higher is further front (Attack)
  int _getDepthScore(String? pos) {
    if (pos == null) return 50;
    final p = pos.toUpperCase().replaceAll('-', '').replaceAll(' ', '');
    if (p.startsWith('G')) return 0;
    if (p.contains('B') || p == 'LD' || p == 'RD' || p == 'CD' || p == 'LWB' || p == 'RWB') return 20;
    if (p.contains('DM')) return 40;
    if (p == 'CM' || p == 'M' || p == 'MC') return 50;
    if (p.contains('AM') || p == 'LM' || p == 'RM') return 70;
    if (p == 'LW' || p == 'RW' || p == 'SS' || p == 'CF' || p == 'LF' || p == 'RF') return 90;
    if (p == 'ST' || p.startsWith('S') || p == 'F') return 100;
    return 50;
  }

  Widget _buildPitchMarkings(double width, double height) {
    return Stack(
      children: [
        // Grass pattern (Simulated)
        for (int i = 0; i < 6; i++)
          Positioned(
            top: (i * 2) * (height / 12),
            left: 0,
            right: 0,
            child: Container(
              height: height / 12,
              color: Colors.white.withOpacity(0.05),
            ),
          ),
        // Center circle
        Center(
          child: Container(
            width: width * 0.3,
            height: width * 0.3,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white24, width: 2),
              shape: BoxShape.circle,
            ),
          ),
        ),
        // Penalty areas
        Positioned(
          top: 0,
          left: width * 0.2,
          right: width * 0.2,
          child: Container(
            height: height * 0.15,
            decoration: const BoxDecoration(
              border: Border(
                left: BorderSide(color: Colors.white24, width: 2),
                right: BorderSide(color: Colors.white24, width: 2),
                bottom: BorderSide(color: Colors.white24, width: 2),
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 0,
          left: width * 0.2,
          right: width * 0.2,
          child: Container(
            height: height * 0.15,
            decoration: const BoxDecoration(
              border: Border(
                left: BorderSide(color: Colors.white24, width: 2),
                right: BorderSide(color: Colors.white24, width: 2),
                top: BorderSide(color: Colors.white24, width: 2),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PositionedPlayer extends StatelessWidget {
  final MatchPlayerEntity player;
  final double pitchWidth;
  final double pitchHeight;
  final bool isHome;
  final String teamLogo;
  final String leagueSlug;
  final double? customX;
  final double? customY;
  final bool isTopRated;
  final VoidCallback? onTap;

  const _PositionedPlayer({
    required this.player,
    required this.pitchWidth,
    required this.pitchHeight,
    required this.isHome,
    required this.teamLogo,
    required this.leagueSlug,
    this.customX,
    this.customY,
    this.isTopRated = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // X and Y are 0-100 percentages.
    double xPos = customX ?? player.x ?? 50;
    double yPos = customY ?? player.y ?? 50;

    return Positioned(
      top: (yPos / 100.0) * pitchHeight - 35,
      left: (xPos / 100.0) * pitchWidth - 25,
      child: GestureDetector(
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
                // Rating badge (Bottom left of headshot)
                if (player.rating != null)
                  Positioned(
                    bottom: -2,
                    left: -8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: _getRatingColor(player.rating!),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.black26),
                      ),
                      child: Text(
                        player.rating!.toStringAsFixed(1),
                        style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),

                // Top Rated Star
                if (isTopRated)
                  Positioned(
                    top: -12,
                    child: Icon(Icons.star, color: Colors.amber[600], size: 18),
                  ),

                // Captain C
                if (player.isCaptain)
                  Positioned(
                    top: -2,
                    left: -2,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(color: Colors.amber, shape: BoxShape.circle),
                      child: const Text('C', style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold)),
                    ),
                  ),

                // Player headshot
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isTopRated ? Colors.amber : Colors.white, 
                      width: isTopRated ? 3 : 2
                    ),
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 4, offset: const Offset(0, 2)),
                    ],
                  ),
                  child: ClipOval(
                    child: player.photo != null
                        ? GoalHubImage(
                            imageUrl: player.photo!,
                            fit: BoxFit.cover,
                            errorWidget: Container(
                              color: Colors.grey[800],
                              child: Center(
                                child: Text(
                                  player.jersey,
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          )
                        : Container(
                            color: Colors.grey[800],
                            child: Center(
                              child: Text(
                                player.jersey,
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                  ),
                ),
                
                // Substitution indicators
                if (player.isSubbedOut)
                  const Positioned(
                    bottom: 0,
                    right: -6,
                    child: Icon(Icons.arrow_downward, color: Colors.red, size: 18),
                  ),
                if (player.isSubbedIn)
                  const Positioned(
                    bottom: 0,
                    left: -6,
                    child: Icon(Icons.arrow_upward, color: Colors.green, size: 18),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                player.name.split(' ').last,
                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
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
}
