import 'package:flutter/material.dart';

import '../viewmodels/feed_view_model.dart';
import '../widgets/article_card.dart';
import 'article_screen.dart';
import 'check_link_screen.dart';

class HomeScreen extends StatelessWidget {
  final FeedViewModel viewModel;
  final String userName;
  final String roleLabel; 
  final VoidCallback onLogout;

  const HomeScreen({
    super.key,
    required this.viewModel,
    required this.userName,
    required this.roleLabel,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'TRUE FEED',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.account_circle_outlined),
            onSelected: (value) {
              if (value == 'logout') {
                onLogout();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem<String>(
                enabled: false,
                child: Text('$userName\n$roleLabel'),
              ),
              const PopupMenuItem<String>(
                value: 'logout',
                child: Text('Log out'),
              ),
            ],
          ),
        ],
      ),
      
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CheckLinkScreen(viewModel: viewModel),
            ),
          );
        },
        icon: const Icon(Icons.add_link),
        label: const Text('Check a link'),
      ),

      body: ListenableBuilder(
        listenable: viewModel,
        builder: (context, child) {
          return ListView.builder(
            padding: const EdgeInsets.only(top: 8, bottom: 88),
            itemCount: viewModel.articles.length,
            itemBuilder: (context, index) {
              final article = viewModel.articles[index];
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
