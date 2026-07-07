import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goalhub/features/leagues/presentation/cubit/leagues_cubit.dart';
import 'package:goalhub/features/leagues/presentation/cubit/leagues_state.dart';
import 'package:goalhub/features/leagues/presentation/pages/standings_page.dart';

class LeaguesPage extends StatelessWidget {
  const LeaguesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Leagues'),
      ),
      body: BlocBuilder<LeaguesCubit, LeaguesState>(
        builder: (context, state) {
          if (state is LeaguesLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is LeaguesLoaded) {
            final leagues = state.leagues;
            return ListView.builder(
              itemCount: leagues.length,
              itemBuilder: (context, index) {
                final league = leagues[index];
                return ListTile(
                  leading: league.logo != null
                      ? Image.network(league.logo!, width: 40, height: 40)
                      : const Icon(Icons.emoji_events),
                  title: Text(league.displayName),
                  subtitle: Text(league.name),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => StandingsPage(league: league),
                      ),
                    );
                  },
                );
              },
            );
          } else if (state is LeaguesError) {
            return Center(child: Text(state.message));
          }
          return const Center(child: Text('No leagues found'));
        },
      ),
    );
  }
}
