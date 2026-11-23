import 'package:flutter/material.dart';

import '../viewmodels/feed_view_model.dart';
import '../widgets/article_card.dart';
import 'article_screen.dart';

class SavedScreen extends StatelessWidget {
  final FeedViewModel viewModel;
  final VoidCallback onBrowseFeed; 

  const SavedScreen({
    super.key,
    required this.viewModel,
    required this.onBrowseFeed,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Saved')),
        body: ListenableBuilder(
          listenable: viewModel,
          builder: (context, child) {
            final saved = viewModel.savedArticles;

          // Empty state
            if (saved.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.bookmark_border, size: 56),
                      const SizedBox(height: 12),
                      const Text(
                        'Nothing saved yet',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                    ),
                     
                      const SizedBox(height: 8),

                      const Text(
                        'Tap Save on a story to read it properly later '
                        'instead of sharing it right away.',
                        textAlign: TextAlign.center,
                      ),
                     
                      const SizedBox(height: 16),

                      FilledButton(
                        onPressed: onBrowseFeed,
                        child: const Text('Browse feed'),
                        ),
                      ],
                    ),
                ),
               );
              }

          return ListView.builder(
             padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: saved.length,
                itemBuilder: (context, index) {
                  final article = saved[index];
                return ArticleCard(
                  article: article,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ArticleScreen(
                          article: article,
                          viewModel: viewModel,
                         ),
                      ),
                  );
                   },
                );
            },
            );
        },
        ),
      );
  }
}
