import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goalhub/features/leagues/domain/repositories/league_repository.dart';
import 'package:goalhub/core/widgets/goalhub_image.dart';
import 'package:goalhub/features/matches/presentation/pages/player_details_page.dart';
import 'package:goalhub/features/leagues/presentation/pages/team_details_page.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _controller = TextEditingController();
  List<dynamic> _results = [];
  bool _isLoading = false;

  Future<void> _onSearch(String query) async {
    if (query.isEmpty) return;
    setState(() => _isLoading = true);
    try {
      final data = await context.read<LeagueRepository>().search(query);
      setState(() {
        _results = data['results'] ?? [];
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Search for teams, players...',
            border: InputBorder.none,
          ),
          onSubmitted: _onSearch,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => _onSearch(_controller.text),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _results.length,
              itemBuilder: (context, index) {
                final result = _results[index];
                final String? type = result['type']?.toString();
                final String? displayName = result['displayName']?.toString();
                final String? logo = result['image']?['href']?.toString();
                final String? id = result['id']?.toString();

                if (id == null || displayName == null) return const SizedBox.shrink();

                return ListTile(
                  leading: logo != null
                      ? GoalHubImage(imageUrl: logo, width: 40, height: 40)
                      : const CircleAvatar(child: Icon(Icons.search)),
                  title: Text(displayName),
                  subtitle: Text(type ?? ''),
                  onTap: () {
                    if (type == 'athlete') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PlayerDetailsPage(
                            athleteId: id,
                            leagueSlug: 'soccer',
                            playerName: displayName,
                          ),
                        ),
                      );
                    } else if (type == 'team') {
                       Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TeamDetailsPage(
                            leagueId: 'soccer',
                            teamId: id,
                            teamName: displayName,
                            teamLogo: logo,
                          ),
                        ),
                      );
                    }
                  },
                );
              },
            ),
    );
  }
}
