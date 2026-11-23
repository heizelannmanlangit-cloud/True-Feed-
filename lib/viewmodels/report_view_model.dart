import 'package:flutter/foundation.dart';

import '../models/article.dart';

class ReportViewModel extends ChangeNotifier {
  static const List<String> reasons = [
    "Headline doesn't match content",
    'False information',
    'Misleading source',
    'Other',
  ];

  // The story being reported
  Article? _article;

  final Set<String> _selectedReasons = {};
  String _comment = '';
  bool _submitted = false;

  Article? get article => _article;
  String get comment => _comment;
  bool get submitted => _submitted;

  // The button only works when a story and at least one reason are picked
  bool get canSubmit => _article != null && _selectedReasons.isNotEmpty;

  bool isSelected(String reason) => _selectedReasons.contains(reason);

  List<String> get selectedReasons => _selectedReasons.toList();

  void selectArticle(Article? value) {
    _article = value;
    notifyListeners();
  }

  void toggleReason(String reason) {
    if (_selectedReasons.contains(reason)) {
      _selectedReasons.remove(reason);
    } else {
      _selectedReasons.add(reason);
    }
    notifyListeners();
  }

  void setComment(String value) {
    _comment = value;
  }

  void submit() {
    if (!canSubmit) {
      return;
    }
    _submitted = true;
    notifyListeners();
  }

  void reset() {
    _article = null;
    _selectedReasons.clear();
    _comment = '';
    _submitted = false;
    notifyListeners();
  }
}
