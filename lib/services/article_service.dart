import 'dart:convert';

import 'package:html/dom.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:http/http.dart' as http;

import '../models/article.dart';
import 'headline_checker.dart';
import 'label_rules.dart';

// An error with a message we can show to the user
class CheckException implements Exception {
  final String message;
  CheckException(this.message);
}

// Checks a link: reads the page, asks Gemini, then builds an Article.
class ArticleService {
  Future<Article> checkUrl(String input) async {
    // 1. Clean up the link
    var url = input.trim();
    if (url.isEmpty) {
      throw CheckException('Please paste a link first.');
    }
    if (!url.startsWith('http')) {
      url = 'https://$url';
    }
    final uri = Uri.tryParse(url);
    if (uri == null || uri.host.isEmpty) {
      throw CheckException('That does not look like a link.');
    }

    // 2. Download the page and read the headline and the text
    final response = await http.get(
      uri,
      headers: {
        'User-Agent':
            'Mozilla/5.0 (Linux; Android 13) AppleWebKit/537.36 '
            '(KHTML, like Gecko) Chrome/120.0 Mobile Safari/537.36',
        'Accept-Language': 'en',
      },
    ).timeout(const Duration(seconds: 20));

    if (response.statusCode != 200) {
      throw CheckException(
        "Couldn't open that link (error ${response.statusCode}).",
      );
    }

    final page = html_parser.parse(
      utf8.decode(response.bodyBytes, allowMalformed: true),
    );

    var headline = _metaContent(page, 'og:title');
    headline ??= page.querySelector('title')?.text.trim();
    if (headline == null || headline.isEmpty) {
      throw CheckException("Couldn't find a headline on that page.");
    }

    final host = uri.host.toLowerCase().replaceFirst('www.', '');
    final source = _metaContent(page, 'og:site_name') ?? host;

    var text = _readParagraphs(page);
    if (text.length < 200) {
      // Some pages hide the text. Use the short description instead.
      final description = _metaContent(page, 'og:description');
      if (description != null && description.length > text.length) {
        text = description;
      }
    }
    if (text.length < 80) {
      throw CheckException(
        "Couldn't read this article. It may be paywalled or blocked. "
        'Try another link.',
      );
    }

    // 3. Ask Gemini if the headline matches the article by meaning
    final result = await checkHeadline(headline, text);

    // Gemini's score (0-100) is the match percent.
    // An error has score 0, so the story shows as Unverified.
    final match = result.score;

    // What the article says: its first line, kept short
    var articleSays = text.split('\n').first;
    if (articleSays.length > 200) {
      articleSays = '${articleSays.substring(0, 200)}...';
    }

    // 4. Our own rules decide the label
    final credibility = decideLabel(host, match);
    final sourceNote = isTrustedSource(host)
        ? 'Trusted source ($host).'
        : 'Source not in our rated list ($host).';

    return Article(
      id: DateTime.now().millisecondsSinceEpoch,
      title: headline,
      source: source,
      timeAgo: 'Just now',
      topic: 'Other',
      credibility: credibility,
      matchPercent: match,
      match: result.match,
      articleSays: articleSays,
      // For an error, show only the specific reason so it is easy to see
      whyRating: result.match == 'error'
          ? 'Could not check: ${result.reason}'
          : '$sourceNote ${result.reason}',
      url: url,
    );
  }

  // Reads a value like og:title from the page
  String? _metaContent(Document page, String property) {
    final tag = page.querySelector('meta[property="$property"]');
    final value = tag?.attributes['content']?.trim();
    if (value == null || value.isEmpty) {
      return null;
    }
    return value;
  }

  // Joins the paragraphs of the article into one text
  String _readParagraphs(Document page) {
    var paragraphs = page.querySelectorAll('article p');
    if (paragraphs.isEmpty) {
      paragraphs = page.querySelectorAll('p');
    }

    final lines = <String>[];
    for (final p in paragraphs) {
      final line = p.text.trim();
      if (line.length > 40) {
        lines.add(line);
      }
    }

    final text = lines.join('\n');
    if (text.length > 6000) {
      return text.substring(0, 6000);
    }
    return text;
  }
}
