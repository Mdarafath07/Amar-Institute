import 'dart:convert';
import 'package:http/http.dart' as http;

class GeminiService {
  // TODO: Replace with your actual Gemini API key from Google AI Studio
  // Get your API key from: https://makersuite.google.com/app/apikey
  static const String apiKey = "api";
  static const String baseUrl = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent';

  Future<String> generateResponse(String prompt) async {
    if (apiKey == 'api') {
      return 'Please configure your Gemini API key in lib/services/gemini_service.dart';
    }

    try {
      final response = await http.post(
        Uri.parse('$baseUrl?key=$apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': prompt}
              ]
            }
          ]
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final candidates = data['candidates'];
        if (candidates != null && candidates.isNotEmpty) {
          final content = candidates[0]['content'];
          if (content != null && content['parts'] != null) {
            final text = content['parts'][0]['text'];
            return text ?? 'Sorry, I could not generate a response.';
          }
        }
        return 'Sorry, I could not generate a response.';
      } else {
        return 'Error: ${response.statusCode} - ${response.body}';
      }
    } catch (e) {
      return 'Error: ${e.toString()}';
    }
  }

  Future<String> getStudySummary(String subject, List<String> topics) async {
    final prompt = '''
You are an AI study assistant. Provide a concise summary for the subject: $subject
Topics to cover: ${topics.join(', ')}
Please provide a helpful study guide.
''';
    return await generateResponse(prompt);
  }

  Future<String> answerQuestion(String question, {String? context}) async {
    String prompt = question;
    if (context != null) {
      prompt = 'Context: $context\n\nQuestion: $question';
    }
    return await generateResponse(prompt);
  }
}

