import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goalhub/features/news/presentation/cubit/news_cubit.dart';
import 'package:goalhub/features/news/presentation/cubit/news_state.dart';
import 'package:goalhub/features/news/presentation/widgets/news_card.dart';
import 'package:shimmer/shimmer.dart';

class NewsPage extends StatelessWidget {
  const NewsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Latest News', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: false,
      ),
      body: BlocBuilder<NewsCubit, NewsState>(
        builder: (context, state) {
          if (state is NewsInitial) {
            context.read<NewsCubit>().loadNews();
            return const _NewsLoadingSkeleton();
          }
          
          if (state is NewsLoading) {
            return const _NewsLoadingSkeleton();
          }

          if (state is NewsError) {
            return Center(child: Text(state.message));
          }

          if (state is NewsLoaded) {
            return RefreshIndicator(
              onRefresh: () => context.read<NewsCubit>().loadNews(),
              child: ListView.builder(
                itemCount: state.articles.length,
                itemBuilder: (context, index) => NewsCard(article: state.articles[index]),
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class _NewsLoadingSkeleton extends StatelessWidget {
  const _NewsLoadingSkeleton();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: ListView.builder(
        itemCount: 5,
        itemBuilder: (context, index) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(height: 200, color: Colors.white),
              const SizedBox(height: 8),
              Container(height: 20, width: double.infinity, color: Colors.white),
              const SizedBox(height: 4),
              Container(height: 20, width: 200, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}
