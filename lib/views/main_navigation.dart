import 'package:flutter/material.dart';

import '../viewmodels/feed_view_model.dart';
import 'home_screen.dart';
import 'report_screen.dart';
import 'review_screen.dart';
import 'saved_screen.dart';
import 'search_screen.dart';

class MainNavigation extends StatefulWidget {
  final String userId;
  final String userEmail;
  final String userName;
  final bool isReviewer; 
  final VoidCallback onLogout;

  const MainNavigation({
    super.key,
    required this.userId,
    required this.userEmail,
    required this.userName,
    required this.isReviewer,
    required this.onLogout,
  });

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int selectedIndex = 0;

  late final FeedViewModel feedViewModel;

  @override
  void initState() {
    super.initState();
    feedViewModel = FeedViewModel(
      userId: widget.userId,
      userEmail: widget.userEmail,
      isReviewer: widget.isReviewer,
    );
    feedViewModel.loadSavedData();
  }

  @override
  void dispose() {
    feedViewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      HomeScreen(
        viewModel: feedViewModel,
        userName: widget.userName,
        roleLabel: widget.isReviewer ? 'Reviewer' : 'User',
        onLogout: widget.onLogout,
      ),
      SearchScreen(viewModel: feedViewModel),
      SavedScreen(
        viewModel: feedViewModel,
        onBrowseFeed: () {
          setState(() {
            selectedIndex = 0;
            });
          },
        ),
      ReportScreen(feedViewModel: feedViewModel),
      if (widget.isReviewer) ReviewScreen(viewModel: feedViewModel),
    ];

    return Scaffold(
      body: IndexedStack(index: selectedIndex, children: screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            selectedIndex = index;
          });
        },
        destinations: [
          const NavigationDestination(
              icon: Icon(Icons.home_outlined), label: 'Home'),
          const NavigationDestination(icon: Icon(Icons.search), label: 'Search'),
          const NavigationDestination(
              icon: Icon(Icons.bookmark_border), label: 'Saved'),
          const NavigationDestination(
              icon: Icon(Icons.flag_outlined), label: 'Report'),
          if (widget.isReviewer)
            const NavigationDestination(
                icon: Icon(Icons.fact_check_outlined), label: 'Reviews'),
        ],
        ),
      );
  }
}
