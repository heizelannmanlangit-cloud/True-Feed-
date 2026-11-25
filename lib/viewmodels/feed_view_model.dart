import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/sample_articles.dart';
import '../models/article.dart';
import '../models/report.dart';
import '../services/article_service.dart';


class FeedViewModel extends ChangeNotifier {
  final String userId;
  final String userEmail;
  final bool isReviewer;

  FeedViewModel({
    required this.userId,
    required this.userEmail,
    required this.isReviewer,
  });

  final ArticleService _service = ArticleService();

  // Stories the user checked with "Check a link" (newest first)
  final List<Article> _checked = [];

  String _query = '';
  Credibility? _filter; 

  final Set<int> _savedIds = {};

  final Set<int> _unverifiedIds = {};

  final List<Report> _reports = [];

  bool _isChecking = false;
  String? _errorMessage;

  // The Home screen reads this list: checked stories first, then the samples
  List<Article> get articles {
    final all = [..._checked, ...sampleArticles];
    return all.map((a) {
      return _unverifiedIds.contains(a.id) ? a.markedByReviewer() : a;
    }).toList();
  }

  List<Report> get reports => _reports;

  String get query => _query;
  Credibility? get filter => _filter;
  bool get isChecking => _isChecking;
  String? get errorMessage => _errorMessage;

  // Search and filter 

  // Stories that match the search text AND the label filter
  List<Article> get searchResults {
    final text = _query.trim().toLowerCase();
    return articles.where((article) {
      final matchesText = text.isEmpty ||
          article.title.toLowerCase().contains(text) ||
          article.source.toLowerCase().contains(text) ||
          article.topic.toLowerCase().contains(text);
      final matchesFilter = _filter == null || article.credibility == _filter;
      return matchesText && matchesFilter;
    }).toList();
  }

  void setQuery(String value) {
    _query = value;
    notifyListeners(); 
  }

  void setFilter(Credibility? value) {
    _filter = value;
    notifyListeners();
  }


  // The Saved tab reads this list
  List<Article> get savedArticles =>
      articles.where((a) => _savedIds.contains(a.id)).toList();

  bool isSaved(Article article) => _savedIds.contains(article.id);

  void toggleSaved(Article article) {
    if (_savedIds.contains(article.id)) {
      _savedIds.remove(article.id);
    } else {
      _savedIds.add(article.id);
    }
    notifyListeners();
    _saveToPhone();
  }


  // Any logged in user can report a story
  void addReport(Article article, List<String> reasons, String comment) {
    _reports.insert(
      0,
      Report(
        id: DateTime.now().millisecondsSinceEpoch,
        articleId: article.id,
        articleTitle: article.title,
        reasons: reasons,
        comment: comment.trim(),
        reportedBy: userEmail,
      ),
    );
    notifyListeners();
    _saveToPhone();
  }

  // AUTHORIZATION: only a reviewer can dismiss a report
  void dismissReport(Report report) {
    if (!isReviewer) {
      return;
    }
    _reports.removeWhere((r) => r.id == report.id);
    notifyListeners();
    _saveToPhone();
  }

  // AUTHORIZATION: only a reviewer can change a story's label
  void markUnverified(Report report) {
    if (!isReviewer) {
      return;
    }
    _unverifiedIds.add(report.articleId);
    _reports.removeWhere((r) => r.articleId == report.articleId);
    notifyListeners();
    _saveToPhone();
  }


  void clearError() {
    _errorMessage = null;
  }

  // Reads the link, asks Gemini, and adds the new story to the feed.
  // Returns the new story, or null if something went wrong.
  Future<Article?> checkLink(String url) async {
    _isChecking = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final article = await _service.checkUrl(url);
      // Only keep real answers (yes / partial / no).
      // An "error" result is shown once but never added to the feed or saved.
      if (article.match != 'error') {
        _checked.insert(0, article);
        await _saveToPhone();
      }
      return article;
    } on CheckException catch (e) {
      _errorMessage = e.message;
    } catch (e) {
      _errorMessage =
          "Couldn't reach the website or Gemini. Check your internet and try again.";
    } finally {
      _isChecking = false;
      notifyListeners();
    }
    return null;
  }


  Future<void> loadSavedData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Saved stories are kept per user
      final ids = prefs.getStringList('savedIds_$userId') ?? [];
      for (final id in ids) {
        final number = int.tryParse(id);
        if (number != null) {
          _savedIds.add(number);
        }
      }

      final items = prefs.getStringList('checkedArticles') ?? [];
      var foundError = false;
      for (final item in items) {
        final map = jsonDecode(item) as Map<String, dynamic>;
        final article = Article.fromJson(map);
        // Skip old "Couldn't check" results that were saved before
        if (article.match == 'error') {
          foundError = true;
        } else {
          _checked.add(article);
        }
      }

      final unverified = prefs.getStringList('unverifiedIds') ?? [];
      for (final id in unverified) {
        final number = int.tryParse(id);
        if (number != null) {
          _unverifiedIds.add(number);
        }
      }

      final reportItems = prefs.getStringList('reports') ?? [];
      for (final item in reportItems) {
        final map = jsonDecode(item) as Map<String, dynamic>;
        _reports.add(Report.fromJson(map));
      }

      notifyListeners();

      // Save again without the error results so they are gone for good
      if (foundError) {
        await _saveToPhone();
      }
    } catch (e) {
    }
  }

  Future<void> _saveToPhone() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(
        'savedIds_$userId',
        _savedIds.map((id) => id.toString()).toList(),
      );
      await prefs.setStringList(
        'unverifiedIds',
        _unverifiedIds.map((id) => id.toString()).toList(),
      );
      await prefs.setStringList(
        'reports',
        _reports.map((r) => jsonEncode(r.toJson())).toList(),
      );
      await prefs.setStringList(
        'checkedArticles',
        _checked.map((a) => jsonEncode(a.toJson())).toList(),
      );
    } catch (e) {
    }
  }
}
