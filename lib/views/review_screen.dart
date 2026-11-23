import 'package:flutter/material.dart';

import '../viewmodels/feed_view_model.dart';

class ReviewScreen extends StatelessWidget {
  final FeedViewModel viewModel;

  const ReviewScreen({super.key, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    if (!viewModel.isReviewer) {
      return Scaffold(
        appBar: AppBar(title: const Text('Reviews')),
        body: const Center(child: Text('Only reviewers can open this screen.')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Reports to review')),
      body: ListenableBuilder(
        listenable: viewModel,
        builder: (context, child) {
          final reports = viewModel.reports;

          if (reports.isEmpty) {
            return const Center(child: Text('No reports to review.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: reports.length,
            itemBuilder: (context, index) {
              final report = reports[index];
              
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        report.articleTitle,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          ),
                         ),

                      const SizedBox(height: 8),

                      Text('Reasons: ${report.reasons.join(', ')}'),
                        if (report.comment.isNotEmpty) ...[
                         const SizedBox(height: 4),
                          Text('Comment: ${report.comment}'),
                        ],

                      const SizedBox(height: 4),

                        Text(
                          'Reported by ${report.reportedBy}',
                          style: const TextStyle(color: Colors.grey),
                        ),

                      const SizedBox(height: 12),

                      Row(
                        children: [
                          OutlinedButton(
                            onPressed: () => viewModel.dismissReport(report),
                            child: const Text('Dismiss'),
                          ),
                          const SizedBox(width: 12),
                          FilledButton(
                            onPressed: () => viewModel.markUnverified(report),
                            child: const Text('Mark Unverified'),
                          ),
                          ],
                         ),
                      ],
                    ),
                ),
               );
            },
            );
        },
      ),
    );
  }
}
