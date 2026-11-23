import 'package:flutter/material.dart';

import '../models/article.dart';
import '../viewmodels/feed_view_model.dart';
import '../widgets/article_card.dart';
import 'article_screen.dart';

class SearchScreen extends StatefulWidget {
  final FeedViewModel viewModel;

  const SearchScreen({super.key, required this.viewModel});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  late final TextEditingController searchController;

  @override
  void initState() {
    super.initState();
    searchController = TextEditingController(text: widget.viewModel.query);
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Widget _filterChip(String label, Credibility? value) {
    return ChoiceChip(
      label: Text(label),
      selected: widget.viewModel.filter == value,
      onSelected: (selected) => widget.viewModel.setFilter(value),
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = widget.viewModel;

    return Scaffold(
      appBar: AppBar(title: const Text('Search')),
        body: ListenableBuilder(
          listenable: viewModel,
            builder: (context, child) {
          final results = viewModel.searchResults;

          return Column(
            children: [
              Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: TextField(
                      controller: searchController,
                      onChanged: viewModel.setQuery,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.search),
                        hintText: 'Search headlines or topics',
                      ),
                    ),
                ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Wrap(
                    spacing: 8,
                    children: [
                      _filterChip('All', null),
                      _filterChip('Verified', Credibility.verified),
                      _filterChip('Caution', Credibility.caution),
                      _filterChip('Unverified', Credibility.unverified),
                    ],
                  ),
              ),

              Padding(
                padding: const EdgeInsets.all(16),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      results.length == 1
                          ? '1 story found'
                          : '${results.length} stories found',
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ),
               ),
              
              Expanded(
                child: ListView.builder(
                  itemCount: results.length,
                  itemBuilder: (context, index) {
                    final article = results[index];
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
                  ),
              ),
            ],
            );
        },
        ),
      );
  }
}
