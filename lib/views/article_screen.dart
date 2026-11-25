import 'package:flutter/material.dart';

import '../models/article.dart';
import '../viewmodels/feed_view_model.dart';
import '../widgets/credibility_chip.dart';
import 'report_screen.dart';

class ArticleScreen extends StatefulWidget {
  final Article article;
  final FeedViewModel viewModel;

  const ArticleScreen({
    super.key,
    required this.article,
    required this.viewModel,
  });

  @override
  State<ArticleScreen> createState() => _ArticleScreenState();
}

class _ArticleScreenState extends State<ArticleScreen> {
  // The story shown on this screen. Retry can replace it with a new result.
  late Article article = widget.article;
  bool retrying = false;

  FeedViewModel get viewModel => widget.viewModel;

  // Runs the headline check again for the same link
  Future<void> retry() async {
    setState(() => retrying = true);

    final newArticle = await viewModel.checkLink(article.url);
    if (!mounted) return;

    setState(() {
      retrying = false;
      if (newArticle != null) {
        article = newArticle;
      }
    });

    // The page itself could not be read (for example no internet)
    if (newArticle == null && viewModel.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(viewModel.errorMessage!)),
      );
    }
  }

  Widget _compareBox(String label, String text) {
    return Container(
        width: double.infinity,
         margin: const EdgeInsets.only(top: 10),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF6F2E9),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(text),
           ],
        ),
    );
  }

  String _verdict() {
    final label = article.matchLabel;
    if (label == 'Matches') {
      return 'The headline matches the article.';
    }
    if (label == 'Partly matches') {
      return 'The headline only partly matches the article.';
    }
    if (label == "Doesn't match") {
      return 'This headline may be misleading.';
    }
    return 'The headline could not be checked. The reason is shown under "Why this rating".';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Article')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: CredibilityChip(credibility: article.credibility),
          ),
         
          const SizedBox(height: 12),
         
          Text(
            article.title,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
         
          const SizedBox(height: 8),
         
          Text(
            '${article.source} - ${article.timeAgo}',
            style: const TextStyle(color: Colors.grey),
          ),
          if (article.url.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              article.url,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
         
          const SizedBox(height: 16),

          // An error result is never saved, so hide Save and Report for it
          if (article.match != 'error')
          Row(
            children: [
              ListenableBuilder(
                listenable: viewModel,
                builder: (context, child) {
                  final saved = viewModel.isSaved(article);
                  return OutlinedButton.icon(
                    onPressed: () => viewModel.toggleSaved(article),
                    icon: Icon(saved ? Icons.bookmark : Icons.bookmark_border),
                    label: Text(saved ? 'Saved' : 'Save'),
                  );
                },
              ),
         
              const SizedBox(width: 12),
         
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ReportScreen(
                        feedViewModel: viewModel,
                        article: article,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.flag_outlined),
                label: const Text('Report'),
              ),
            ],
          ),
         
          const SizedBox(height: 20),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.black12),
            ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Headline Check',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  Text(
                    article.matchWithPercent,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  
                  const SizedBox(height: 4),
                  
                  Text(_verdict()),

                  // Retry button, only when the check failed
                  if (article.match == 'error' && article.url.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: retrying ? null : retry,
                      icon: retrying
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.refresh),
                      label: Text(retrying ? 'Checking...' : 'Retry'),
                    ),
                  ],
                  _compareBox('Headline says', article.title),
                  _compareBox('Article says', article.articleSays),
                ],
              ),
            ),
            const SizedBox(height: 20),

            const Text(
              'Why this rating',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 6),
            
            Text(article.whyRating),
            ],
       ),
     );
  }
}
