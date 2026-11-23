// One report sent by a user about a story
class Report {
  final int id;
  final int articleId;
  final String articleTitle;
  final List<String> reasons;
  final String comment;
  final String reportedBy; // email of the user who reported

  const Report({
    required this.id,
    required this.articleId,
    required this.articleTitle,
    required this.reasons,
    required this.comment,
    required this.reportedBy,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'articleId': articleId,
      'articleTitle': articleTitle,
      'reasons': reasons,
      'comment': comment,
      'reportedBy': reportedBy,
    };
  }

  factory Report.fromJson(Map<String, dynamic> json) {
    return Report(
      id: json['id'] as int,
      articleId: json['articleId'] as int,
      articleTitle: json['articleTitle'] as String,
      reasons: List<String>.from(json['reasons'] as List),
      comment: json['comment'] as String,
      reportedBy: json['reportedBy'] as String,
    );
  }
}
