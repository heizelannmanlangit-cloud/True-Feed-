import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

// The answer from the headline check.
//   match:  "yes", "partial", "no", or "error"
//   reason: one sentence explaining the answer
//   score:  0 to 100, how well the article supports the headline
//           (error results always have score 0)
class MatchResult {
  final String match;
  final String reason;
  final int score;

  MatchResult(this.match, this.reason, [this.score = 0]);
}

// The key is given when running the app:
//   flutter run --dart-define=GEMINI_KEY=your_key
const String geminiKey = String.fromEnvironment('GEMINI_KEY');

// The main model, and a smaller backup model if the main one keeps failing.
// (gemini-2.5-flash-lite is closed to new keys, so we use 3.5-flash-lite.)
const String mainModel = 'gemini-3.8-flash';
const String backupModel = 'gemini-3.5-flash-lite';

// Asks Gemini if the headline matches the article by meaning,
// not just by the exact words used.
Future<MatchResult> checkHeadline(String headline, String article) async {
  if (geminiKey.isEmpty) {
    return MatchResult(
      'error',
      'No Gemini key. Run the app with --dart-define=GEMINI_KEY=your_key',
    );
  }

  // Only send the first 3000 characters to keep the request small
  var shortArticle = article;
  if (shortArticle.length > 3000) {
    shortArticle = shortArticle.substring(0, 3000);
  }

  final prompt = '''
Compare this news headline with the article below.
Judge by meaning, not by exact words. The article may use different
words that mean the same thing.

Headline: $headline

Article:
$shortArticle

The score is how well the article supports the headline's claim,
judged by meaning, not by exact words. Use these ranges:
- "yes" = score 80 to 100
- "partial" = score 40 to 79
- "no" = score 0 to 39

Reply in JSON only:
{"match": "yes" or "partial" or "no", "score": a number from 0 to 100, "reason": "one sentence"}
''';

  try {
    var response = await sendToGemini(mainModel, prompt);
    var usedBackup = false;

    // 429 = too many requests, 503 = Gemini is busy.
    // Wait 2 seconds and try again, up to 2 times.
    var retries = 0;
    while ((response.statusCode == 429 || response.statusCode == 503) &&
        retries < 2) {
      retries++;
      debugPrint('Gemini busy. Retry $retries of 2 in 2 seconds...');
      await Future.delayed(const Duration(seconds: 2));
      response = await sendToGemini(mainModel, prompt);
    }

    // Still not working: try the backup model once
    if (response.statusCode != 200) {
      debugPrint('Main model failed. Trying backup model $backupModel...');
      response = await sendToGemini(backupModel, prompt);
      usedBackup = true;
    }
    if (response.statusCode != 200) {
      return statusError(response.statusCode);
    }

    var data = jsonDecode(utf8.decode(response.bodyBytes));
    var answerText = getAnswerText(data);

    // Blocked or empty answer: try the backup model once
    if (answerText == null && !usedBackup) {
      debugPrint('Empty or blocked answer. Trying backup model $backupModel...');
      response = await sendToGemini(backupModel, prompt);
      if (response.statusCode != 200) {
        return statusError(response.statusCode);
      }
      data = jsonDecode(utf8.decode(response.bodyBytes));
      answerText = getAnswerText(data);
    }
    if (answerText == null) {
      return MatchResult('error', emptyReason(data));
    }

    // Read the JSON that Gemini wrote
    Map answer;
    try {
      answer = jsonDecode(answerText) as Map;
    } catch (e) {
      debugPrint('Could not read Gemini answer. Raw text: $answerText');
      return MatchResult('error', 'Gemini replied in an unexpected format.');
    }

    final match = answer['match'].toString().toLowerCase().trim();
    if (match != 'yes' && match != 'partial' && match != 'no') {
      debugPrint('Unknown match value. Raw text: $answerText');
      return MatchResult('error', 'Gemini replied in an unexpected format.');
    }
    final reason = (answer['reason'] ?? '').toString();

    // Read the score. If it is missing or not a number, use a default.
    var score = double.tryParse(answer['score'].toString())?.round();
    if (score == null) {
      if (match == 'yes') score = 90;
      if (match == 'partial') score = 60;
      if (match == 'no') score = 20;
    }
    score ??= 0;
    // Keep it between 0 and 100
    if (score < 0) score = 0;
    if (score > 100) score = 100;

    return MatchResult(match, reason, score);
  } on http.ClientException catch (e) {
    // A real network problem (no internet, could not connect).
    // The http package also uses this for SocketException.
    debugPrint('Network error: $e');
    return MatchResult(
      'error',
      'Could not reach Gemini. Check your internet and try again.',
    );
  } on TimeoutException {
    debugPrint('Gemini did not answer in 30 seconds.');
    return MatchResult(
      'error',
      'Gemini took too long to answer. Please try again.',
    );
  } catch (e) {
    // Anything else: show what actually went wrong
    debugPrint('Headline check failed: $e');
    return MatchResult('error', 'Something went wrong while checking: $e');
  }
}

// A friendly message for each error status code
MatchResult statusError(int statusCode) {
  if (statusCode == 429) {
    return MatchResult(
      'error',
      'Too many checks right now. Please wait a minute and try again.',
    );
  }
  if (statusCode == 503) {
    return MatchResult(
      'error',
      'Gemini is busy right now. Please try again in a few minutes.',
    );
  }
  return MatchResult(
    'error',
    'Could not check the headline (error $statusCode).',
  );
}

// Gets Gemini's answer text, or null if the answer is empty or blocked.
// The text is inside candidates -> content -> parts -> text
String? getAnswerText(dynamic data) {
  if (data is! Map) return null;

  final candidates = data['candidates'];
  if (candidates is! List || candidates.isEmpty) return null;

  final content = candidates[0]['content'];
  if (content is! Map) return null;

  final parts = content['parts'];
  if (parts is! List || parts.isEmpty) return null;

  final text = parts[0]['text'];
  if (text is! String || text.trim().isEmpty) return null;

  return text;
}

// Explains why Gemini gave no answer text
String emptyReason(dynamic data) {
  if (data is Map) {
    // The whole request was blocked
    final feedback = data['promptFeedback'];
    if (feedback is Map && feedback['blockReason'] != null) {
      return 'Gemini blocked this response (${feedback['blockReason']}).';
    }

    // Gemini started an answer but stopped, for example SAFETY
    final candidates = data['candidates'];
    if (candidates is List && candidates.isNotEmpty) {
      final finishReason = candidates[0]['finishReason'];
      if (finishReason != null && finishReason != 'STOP') {
        return 'Gemini blocked this response ($finishReason).';
      }
    }
  }
  return 'Gemini returned an empty response.';
}


// Sends the prompt to one Gemini model and returns the raw response
Future<http.Response> sendToGemini(String model, String prompt) async {
  final url = 'https://generativelanguage.googleapis.com/v1beta/'
      'models/$model:generateContent';

  final response = await http
      .post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'x-goog-api-key': geminiKey,
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
            'temperature': 0,
            'responseMimeType': 'application/json',
          },
        }),
      )
      .timeout(const Duration(seconds: 30));

  // Shows the real answer from Gemini in the debug console
  debugPrint('Gemini ($model) status: ${response.statusCode}');
  debugPrint('Gemini ($model) body: ${response.body}');

  return response;
}
