import 'package:flutter/material.dart';

import '../models/article.dart';
import '../viewmodels/feed_view_model.dart';
import '../viewmodels/report_view_model.dart';


class ReportScreen extends StatefulWidget {
  final FeedViewModel feedViewModel;
  final Article? article;

  const ReportScreen({super.key, required this.feedViewModel, this.article});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  final ReportViewModel viewModel = ReportViewModel();
  final TextEditingController commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    viewModel.selectArticle(widget.article);
  }

  @override
  void dispose() {
    commentController.dispose();
    viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Report article')),
      body: ListenableBuilder(
        listenable: Listenable.merge([viewModel, widget.feedViewModel]),
        builder: (context, child) {
          if (viewModel.submitted) {
            return _sentView();
          }
          return _formView();
      },
      ),
    );
  }

  Widget _sentView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle_outline, size: 56),
            const SizedBox(height: 12),
            const Text(
              'Report sent',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            
            const SizedBox(height: 8),
            
            const Text(
              'Thanks! Reviewers will check this story so its label can be '
              'fixed if needed.',
              textAlign: TextAlign.center,
            ),
           
            const SizedBox(height: 16),
           
            if (widget.article != null)
              FilledButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Back to article'),
              )
            else
              FilledButton(
                onPressed: () {
                  commentController.clear();
                  viewModel.reset();
                },
                child: const Text('Report another story'),
              ),
            ],
          ),
          ),
    );
  }

  Widget _formView() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (widget.article != null)
          Card(
            child: ListTile(
              title: Text(widget.article!.title),
              subtitle: Text(widget.article!.source),
            ),
          )

        else
          DropdownButton<Article>(
            isExpanded: true,
            hint: const Text('Choose a story to report'),
            value: viewModel.article,
            items: widget.feedViewModel.articles.map((story) {
              return DropdownMenuItem<Article>(
                value: story,
                child: Text(story.title, overflow: TextOverflow.ellipsis),
              );
            }).toList(),
            onChanged: viewModel.selectArticle,
          ),
       
        const SizedBox(height: 16),
       
        const Text(
          'Why are you reporting this?',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        for (final reason in ReportViewModel.reasons)
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            title: Text(reason),
            value: viewModel.isSelected(reason),
            onChanged: (checked) => viewModel.toggleReason(reason),
          ),
        
        const SizedBox(height: 8),
        
        TextField(
          controller: commentController,
          onChanged: viewModel.setComment,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Add a comment (optional)',
            border: OutlineInputBorder(),
          ),
        ),
       
        const SizedBox(height: 16),
       
        FilledButton(
          onPressed: viewModel.canSubmit
              ? () {
                  widget.feedViewModel.addReport(
                    viewModel.article!,
                    viewModel.selectedReasons,
                    viewModel.comment,
                  );
                  viewModel.submit();
                }
              : null,
          child: const Text('Submit report'),
           ),
        ],
      );
  }
}
