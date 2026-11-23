import 'package:flutter/material.dart';

import '../viewmodels/feed_view_model.dart';
import 'article_screen.dart';

class CheckLinkScreen extends StatefulWidget {
  final FeedViewModel viewModel;

  const CheckLinkScreen({super.key, required this.viewModel});

  @override
  State<CheckLinkScreen> createState() => _CheckLinkScreenState();
}

class _CheckLinkScreenState extends State<CheckLinkScreen> {
  final TextEditingController linkController = TextEditingController();

  @override
  void initState() {
    super.initState();
    widget.viewModel.clearError();
  }

  @override
  void dispose() {
    linkController.dispose();
    super.dispose();
  }

  Future<void> checkLink() async {
    final article = await widget.viewModel.checkLink(linkController.text);

    if (article != null && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) =>
              ArticleScreen(article: article, viewModel: widget.viewModel),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Check a link')),
      body: ListenableBuilder(
        listenable: widget.viewModel,
        builder: (context, child) {
          final checking = widget.viewModel.isChecking;
          final error = widget.viewModel.errorMessage;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                'Paste a news link. TrueFeed reads the article and compares '
                'it with the headline.',
              ),
             
              const SizedBox(height: 16),
             
              TextField(
                controller: linkController,
                enabled: !checking,
                keyboardType: TextInputType.url,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.link),
                  hintText: 'https://...',
                  border: OutlineInputBorder(),
                ),
              ),
             
              const SizedBox(height: 16),
             
              FilledButton(
                onPressed: checking ? null : checkLink,
                child: const Text('Check'),
              ),
             
              const SizedBox(height: 24),
             
              if (checking)
                const Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 12),
                    Text('Reading the article...'),
                  ],
                ),
              if (error != null)
                Text(error, style: const TextStyle(color: Colors.red)),
             ],
            );
          },
       ),
    );
  }
}
