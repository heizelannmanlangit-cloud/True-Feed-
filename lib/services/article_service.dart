import 'dart:convert';

import 'package:html/dom.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:http/http.dart' as http;

import '../models/article.dart';
import 'label_rules.dart';

// An error with a message we can show to the user
class CheckException implements Exception {
  final String message;
  CheckException(this.message);
}

// Checks a link: reads the page, asks Gemini, then builds an Article.
class ArticleService {
  // The key is given when running the app:
  //   flutter run --dart-define=GEMINI_KEY=your_key_here
  static const String apiKey = String.fromEnvironment('GEMINI_KEY');

  // Gemini model names. The app tries them one by one until one works.
  // If none work, check the current names in Google AI Studio.
  static const List<String> models = [
    'gemini-3.8-flash',
    'gemini-3.6-flash',
    'gemini-flash-latest',
    'gemini-2.5-flash',
  ];

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

    // 3. Ask Gemini how well the headline matches the article.
    // If Gemini does not work (no key, limit reached, error), use a basic
    // word match instead so the app still gives an answer.
    Map<String, dynamic> result;
    try {
      result = await _askGemini(headline, text);
    } catch (e) {
      result = _basicCheck(headline, text);
    }

    var match = double.tryParse(result['matchPercent'].toString())?.round() ?? 0;
    if (match < 0) match = 0;
    if (match > 100) match = 100;

    final articleSays = (result['articleSays'] ?? '').toString();
    final reason = (result['reason'] ?? '').toString();
    final topic = (result['topic'] ?? 'Other').toString();

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
      topic: topic,
      credibility: credibility,
      matchPercent: match,
      articleSays: articleSays,
      whyRating: '$sourceNote $reason',
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

  // Sends the headline and the text to Gemini and gets JSON back
  Future<Map<String, dynamic>> _askGemini(String headline, String text) async {
    if (apiKey.isEmpty) {
      throw CheckException(
        'No Gemini key. Run the app with --dart-define=GEMINI_KEY=your_key',
      );
    }

    final prompt = '''
You check whether a news headline matches the article under it.

Headline: $headline

Article text:
$text

Reply with JSON only, using exactly these keys:
- "matchPercent": whole number 0 to 100. 100 means the headline accurately
  reflects the article. Give a low number if the headline exaggerates, is
  clickbait, or says something the article does not say.
- "articleSays": one sentence (max 25 words) on what the article really says.
- "reason": one sentence explaining why the headline matches or does not match.
- "topic": one of Education, Politics, Local, Tech, Health, Other.
''';

    var lastError = 'No Gemini model worked.';

    for (final model in models) {
      final response = await http
          .post(
            Uri.parse(
              'https://generativelanguage.googleapis.com/v1beta/models/'
              '$model:generateContent',
            ),
            headers: {
              'Content-Type': 'application/json',
              'x-goog-api-key': apiKey,
            },
            body: jsonEncode({
              'contents': [
                {
                  'parts': [
                    {'text': prompt},
                  ],
                },
              ],
              'generationConfig': {
                'responseMimeType': 'application/json',
                'temperature': 0.2,
              },
            }),
          )
          .timeout(const Duration(seconds: 40));

      // 404 = model name not found, 429 = limit reached. Try the next model.
      if (response.statusCode == 404 || response.statusCode == 429) {
        lastError = 'Gemini said: ${_errorText(response)} ($model)';
        continue;
      }
      if (response.statusCode != 200) {
        throw CheckException(
          'Gemini error ${response.statusCode}: ${_errorText(response)}',
        );
      }

      try {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final parts = data['candidates'][0]['content']['parts'] as List;
        var answer = parts.map((p) => p['text'] ?? '').join();
        answer = answer.replaceAll('```json', '').replaceAll('```', '').trim();
        return jsonDecode(answer) as Map<String, dynamic>;
      } catch (e) {
        throw CheckException('Gemini gave an unreadable answer. Try again.');
      }
    }

    throw CheckException(lastError);
  }

  // Backup check without AI: how many key words of the headline
  // also appear in the article text?
  Map<String, dynamic> _basicCheck(String headline, String text) {
    const skipWords = [
      'that', 'this', 'with', 'from', 'have', 'will', 'says', 'after',
      'over', 'into', 'about', 'their', 'they', 'been', 'were', 'what',
      'when', 'your', 'more', 'than', 'also',
    ];

    final lowerText = text.toLowerCase();
    final words = headline
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\s]'), ' ')
        .split(RegExp(r'\s+'))
        .where((w) => w.length > 3 && !skipWords.contains(w))
        .toSet();

    var found = 0;
    for (final word in words) {
      if (lowerText.contains(word)) {
        found++;
      }
    }

    final percent = words.isEmpty ? 50 : (found * 100 / words.length).round();

    var firstLine = text.split('\n').first;
    if (firstLine.length > 200) {
      firstLine = '${firstLine.substring(0, 200)}...';
    }

    return {
      'matchPercent': percent,
      'articleSays': firstLine,
      'reason': 'Gemini was not available, so this is a basic check: '
          '$found of ${words.length} key words from the headline appear '
          'in the article.',
      'topic': 'Other',
    };
  }

  // Gets the error message out of a Gemini error reply
  String _errorText(http.Response response) {
    try {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      return data['error']['message'].toString();
    } catch (e) {
      return 'unknown error';
    }
  }
}
