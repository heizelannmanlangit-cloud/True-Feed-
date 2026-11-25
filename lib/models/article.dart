enum Credibility { verified, caution, unverified }

// "Model" part in MVVM.
class Article {
  final int id;
  final String title; //headline
  final String source;
  final String timeAgo;
  final String topic;
  final Credibility credibility;
  final int matchPercent; // how closely the headline matches the article
  final String match; // Gemini answer: "yes", "partial", "no", "error" ('' for old stories)
  final String articleSays; // what the article actually says
  final String whyRating; // short reason for the label
  final String url; // link to the real article ('' for sample stories)

  const Article({
    required this.id,
    required this.title,
    required this.source,
    required this.timeAgo,
    required this.topic,
    required this.credibility,
    required this.matchPercent,
    this.match = '',
    required this.articleSays,
    required this.whyRating,
    this.url = '',
  });

  // Short text for the headline check, e.g. "Matches"
  String get matchLabel {
    var answer = match;
    // Older stories have no answer saved, so use the percent instead
    if (answer.isEmpty) {
      if (matchPercent >= 75) {
        answer = 'yes';
      } else if (matchPercent >= 50) {
        answer = 'partial';
      } else {
        answer = 'no';
      }
    }
    if (answer == 'yes') return 'Matches';
    if (answer == 'partial') return 'Partly matches';
    if (answer == 'no') return "Doesn't match";
    return "Couldn't check";
  }

  // The label with the percent, e.g. "Matches - 92%"
  String get matchWithPercent {
    if (match == 'error') {
      return matchLabel; // no percent when the check failed
    }
    return '$matchLabel - $matchPercent%';
  }

  // Two stories are the same story if they have the same id
  @override
  bool operator ==(Object other) => other is Article && other.id == id;

  @override
  int get hashCode => id.hashCode;

  // A copy of this story that a reviewer marked as Unverified
  Article markedByReviewer() {
    return Article(
      id: id,
      title: title,
      source: source,
      timeAgo: timeAgo,
      topic: topic,
      credibility: Credibility.unverified,
      matchPercent: matchPercent,
      match: match,
      articleSays: articleSays,
      whyRating: 'A reviewer marked this story Unverified after reports. '
          '$whyRating',
      url: url,
    );
  }

  // Turns an Article into a Map so it can be saved on the phone
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'source': source,
      'timeAgo': timeAgo,
      'topic': topic,
      'credibility': credibility.name,
      'matchPercent': matchPercent,
      'match': match,
      'articleSays': articleSays,
      'whyRating': whyRating,
      'url': url,
    };
  }

  // Turns a saved Map back into an Article
  factory Article.fromJson(Map<String, dynamic> json) {
    return Article(
      id: json['id'] as int,
      title: json['title'] as String,
      source: json['source'] as String,
      timeAgo: json['timeAgo'] as String,
      topic: json['topic'] as String,
      credibility: Credibility.values.byName(json['credibility'] as String),
      matchPercent: json['matchPercent'] as int,
      match: (json['match'] as String?) ?? '',
      articleSays: json['articleSays'] as String,
      whyRating: json['whyRating'] as String,
      url: (json['url'] as String?) ?? '',
    );
  }
}
